package com.mondocore.cordova.plugin.fyber;

import java.util.HashMap;
import java.util.Map;

import android.content.Intent;
import android.util.Log;

import com.fyber.Fyber;
import com.fyber.utils.FyberLogger;
import com.fyber.requesters.OfferWallRequester;

import com.fyber.ads.videos.RewardedVideoActivity;
import com.fyber.currency.VirtualCurrencyErrorResponse;
import com.fyber.currency.VirtualCurrencyResponse;
import com.fyber.requesters.RewardedVideoRequester;
import com.fyber.requesters.VirtualCurrencyCallback;
import com.fyber.requesters.VirtualCurrencyRequester;

import com.fyber.requesters.InterstitialRequester;

import com.fyber.ads.AdFormat;
import com.fyber.requesters.RequestCallback;
import com.fyber.requesters.RequestError;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class FyberPlugin extends CordovaPlugin implements VirtualCurrencyCallback{

    private static final String LOGTAG = "[FyberPlugin]";
    private static final String DEFAULT_APP_KEY = "27434";
    private static final String DEFAULT_VIRTUALCURRENCY_NAME = "mondos";

    protected static final int INTERSTITIAL_REQUEST_CODE = 8792;
    protected static final int OFFERWALL_REQUEST_CODE = 8795;
    protected static final int REWARDED_VIDEO_REQUEST_CODE = 8796;

    private static final String ACTION_INITIALIZE = "initialize";
    private static final String ACTION_SHOW_OFFERWALL = "showOfferwall";
    private static final String ACTION_SHOW_REWARDEDVIDEO = "showRewardedVideo";
    private static final String ACTION_SHOW_INTERSTITIAL = "showInterstitial";

    private static final String OPT_APPLICATION_KEY = "appKey";
    private static final String OPT_USER_ID = "userId";
    private static final String OPT_SECURITY_TOKEN = "securityToken";
    private static final String OPT_VIRTUALCURRENCY_NAME = "virtualCurrencyName";

    private String appKey = DEFAULT_APP_KEY;
    private String userId = "5043b715c3bd823b760000ff";
    private String securityToken = "";
    private String virtualCurrencyName = DEFAULT_VIRTUALCURRENCY_NAME;

    public static final String EVENT_FYBER_OFFERWALL_LOADED = "fyberOfferWallLoaded";
    public static final String EVENT_FYBER_OFFERWALL_NOT_AVAILABLE = "fyberOfferWallNotAvailable";
    public static final String EVENT_FYBER_OFFERWALL_ERROR = "fyberOfferWallError";
    public static final String EVENT_FYBER_REWARDEDVIDEO_LOADED = "fyberRewardedVideoLoaded";
    public static final String EVENT_FYBER_REWARDEDVIDEO_NOT_AVAILABLE = "fyberRewardedVideoNotAvailable";
    public static final String EVENT_FYBER_REWARDEDVIDEO_ERROR = "fyberRewardedVideoError";
    public static final String EVENT_FYBER_INTERSTITIAL_LOADED = "fyberInterstitialLoaded";
    public static final String EVENT_FYBER_INTERSTITIAL_NOT_AVAILABLE = "fyberInterstitialNotAvailable";
    public static final String EVENT_FYBER_INTERSTITIAL_ERROR = "fyberInterstitialError";
    public static final String EVENT_FYBER_VCFAILED = "fyberVCFailed";
    public static final String EVENT_FYBER_VCSUCCESS = "fyberVCSuccess";

    private Intent offerWallIntent;
    private Intent rewardedVideoIntent;
    private Intent interstitialIntent;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        PluginResult result = null;

        if (ACTION_INITIALIZE.equals(action)) {
            JSONObject options = args.optJSONObject(0);
            result = executeInitialize(options, callbackContext);
        } else if (ACTION_SHOW_OFFERWALL.equals(action)) {
            JSONObject options = args.optJSONObject(0);
            result = executeShowOfferwall(options, callbackContext);
        } else if (ACTION_SHOW_REWARDEDVIDEO.equals(action)) {
            JSONObject options = args.optJSONObject(0);
            result = executeShowRewardedVideo(options, callbackContext);
        } else if (ACTION_SHOW_INTERSTITIAL.equals(action)) {
            JSONObject options = args.optJSONObject(0);
            result = executeShowInterstitial(options, callbackContext);
        }

        if (result != null) {
            callbackContext.sendPluginResult(result);
        }

        return true;
    }

    private PluginResult executeInitialize(JSONObject options, CallbackContext callbackContext) {
        Log.w(LOGTAG, "executeInitialize");

        this.initialize(options);

        callbackContext.success();

        return null;
    }

    private void initialize(JSONObject options) {
        if (options.has(OPT_APPLICATION_KEY)) {
            this.appKey = options.optString(OPT_APPLICATION_KEY);
        }
        if (options.has(OPT_USER_ID)) {
            this.userId = options.optString(OPT_USER_ID);
        }
        if (options.has(OPT_SECURITY_TOKEN)) {
            this.securityToken = options.optString(OPT_SECURITY_TOKEN);
        }
        if (options.has(OPT_VIRTUALCURRENCY_NAME)) {
            this.virtualCurrencyName = options.optString(OPT_VIRTUALCURRENCY_NAME);
        }

        try {
            Fyber.Settings fyberSettings = Fyber
                    .with(this.appKey, cordova.getActivity())
                    .withUserId(this.userId)
                    .withSecurityToken(this.securityToken)
                    .start();
        } catch (IllegalArgumentException e) {
            Log.d(LOGTAG, e.getLocalizedMessage());
        }
    }

    private void fireEvent(final String event) {
        final CordovaWebView view = this.webView;
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                view.loadUrl("javascript:cordova.fireDocumentEvent('" + event + "');");
            }
        });
    }

    private void fireEvent(final String event, final JSONObject data) {
        final CordovaWebView view = this.webView;
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                view.loadUrl(String.format("javascript:cordova.fireDocumentEvent('%s', %s);", event, data.toString()));
            }
        });
    }

    private PluginResult executeShowOfferwall(JSONObject options, final CallbackContext callbackContext) {
        Log.w(LOGTAG, "executeShowOfferwall");

        this.cordova.getActivity().runOnUiThread(new Runnable() {
            RequestCallback requestCallback = new RequestCallback() {
                @Override
                public void onAdAvailable(Intent intent) {
                    offerWallIntent = intent;
                    Log.d(LOGTAG, "OfferWall are available");

                    JSONObject data = new JSONObject();
                    try {
                        data.put("adType", AdFormat.fromIntent(intent));
                    } catch (JSONException e) {
                    }
                    fireEvent(EVENT_FYBER_OFFERWALL_LOADED, data);

                    cordova.getActivity().startActivityForResult(offerWallIntent, OFFERWALL_REQUEST_CODE);
                }

                @Override
                public void onAdNotAvailable(AdFormat adFormat) {
                    // Since we don't have an ad, it's best to reset the video intent
                    offerWallIntent = null;
                    fireEvent(EVENT_FYBER_OFFERWALL_NOT_AVAILABLE);
                    Log.d(LOGTAG, "No ad available");
                }

                @Override
                public void onRequestError(RequestError requestError) {
                    // Since we don't have an ad, it's best to reset the video intent
                    offerWallIntent = null;
                    fireEvent(EVENT_FYBER_OFFERWALL_ERROR);
                    Log.d(LOGTAG, "Something went wrong with the request: " + requestError.getDescription());
                }
            };

            @Override
            public void run() {
                OfferWallRequester.create(requestCallback).request(cordova.getActivity());
                callbackContext.success();
            }
        });

        return null;
    }

    private PluginResult executeShowRewardedVideo(JSONObject options, final CallbackContext callbackContext) {
        Log.w(LOGTAG, "executeShowRewardedVideo");

        this.cordova.getActivity().runOnUiThread(new Runnable() {
            RequestCallback requestCallback = new RequestCallback() {
                @Override
                public void onAdAvailable(Intent intent) {
                    rewardedVideoIntent = intent;
                    Log.d(LOGTAG, "Rewarded Video are available");

                    JSONObject data = new JSONObject();
                    try {
                        data.put("adType", AdFormat.fromIntent(intent));
                    } catch (JSONException e) {
                    }
                    fireEvent(EVENT_FYBER_REWARDEDVIDEO_LOADED, data);

                    cordova.getActivity().startActivityForResult(rewardedVideoIntent, REWARDED_VIDEO_REQUEST_CODE);
                }

                @Override
                public void onAdNotAvailable(AdFormat adFormat) {
                    rewardedVideoIntent = null;
                    fireEvent(EVENT_FYBER_REWARDEDVIDEO_NOT_AVAILABLE);
                    Log.d(LOGTAG, "No ad available");
                }

                @Override
                public void onRequestError(RequestError requestError) {
                    rewardedVideoIntent = null;
                    fireEvent(EVENT_FYBER_REWARDEDVIDEO_ERROR);
                    Log.d(LOGTAG, "Something went wrong with the request: " + requestError.getDescription());
                }
            };

            @Override
            public void run() {
                RewardedVideoRequester.create(requestCallback).request(cordova.getActivity());
                callbackContext.success();
            }
        });

        return null;
    }

    private PluginResult executeShowInterstitial(JSONObject options, final CallbackContext callbackContext) {
        Log.w(LOGTAG, "executeShowInterstitial");

        this.cordova.getActivity().runOnUiThread(new Runnable() {
            RequestCallback requestCallback = new RequestCallback() {
                @Override
                public void onAdAvailable(Intent intent) {
                    interstitialIntent = intent;
                    Log.d(LOGTAG, "Interstitial are available");

                    JSONObject data = new JSONObject();
                    try {
                        data.put("adType", AdFormat.fromIntent(intent));
                    } catch (JSONException e) {
                    }
                    fireEvent(EVENT_FYBER_INTERSTITIAL_NOT_AVAILABLE, data);

                    cordova.getActivity().startActivityForResult(interstitialIntent, INTERSTITIAL_REQUEST_CODE);
                }

                @Override
                public void onAdNotAvailable(AdFormat adFormat) {
                    interstitialIntent = null;
                    fireEvent(EVENT_FYBER_INTERSTITIAL_NOT_AVAILABLE);
                    Log.d(LOGTAG, "No ad available");
                }

                @Override
                public void onRequestError(RequestError requestError) {
                    interstitialIntent = null;
                    fireEvent(EVENT_FYBER_INTERSTITIAL_ERROR);
                    Log.d(LOGTAG, "Something went wrong with the request: " + requestError.getDescription());
                }
            };

            @Override
            public void run() {
                InterstitialRequester.create(requestCallback).request(cordova.getActivity());
                callbackContext.success();
            }
        });

        return null;
    }

    private VirtualCurrencyRequester getVirtualCurrencyRequester() {
        return VirtualCurrencyRequester.create(this)
                .notifyUserOnReward(true)
                .forCurrencyId(this.virtualCurrencyName);
    }

    @Override
    public void onError(VirtualCurrencyErrorResponse virtualCurrencyErrorResponse) {
        Log.w(LOGTAG, "VCS error received - " + virtualCurrencyErrorResponse.getErrorMessage());

        JSONObject error = new JSONObject();
        try {
            error.put("code", virtualCurrencyErrorResponse.getErrorCode());
            error.put("message", virtualCurrencyErrorResponse.getErrorMessage());
        } catch (JSONException e) {
        }
        fireEvent(EVENT_FYBER_VCFAILED, error);
    }

    @Override
    public void onSuccess(VirtualCurrencyResponse virtualCurrencyResponse) {
        Log.w(LOGTAG, "VCS coins received - " + virtualCurrencyResponse.getDeltaOfCoins());

        JSONObject data = new JSONObject();
        try {
            data.put("currencyId", virtualCurrencyResponse.getCurrencyId());
            data.put("currencyName", virtualCurrencyResponse.getCurrencyName());
            data.put("transactionId", virtualCurrencyResponse.getLatestTransactionId());
            data.put("amount", virtualCurrencyResponse.getDeltaOfCoins());
        } catch (JSONException e) {
        }
        fireEvent(EVENT_FYBER_VCSUCCESS, data);
    }

    @Override
    public void onRequestError(RequestError requestError) {
        Log.w(LOGTAG, "Something went wrong with the request: " + requestError.getDescription());
    }
}