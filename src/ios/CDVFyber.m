#import "FyberSDK.h"
#import "FYBAdMob.h"
#import "FYBFacebookAudienceNetwork.h"
#import <AdSupport/ASIdentifierManager.h>
#import <CommonCrypto/CommonDigest.h>

#import "CDVFyber.h"

#import "MainViewController.h"

@interface CDVFyber()

- (void) __setOptions:(NSDictionary*) options;
- (void) __showInterstitial:(BOOL)show;
- (void) __showRewardedVideo:(BOOL)show;
- (void) __showPopupOffer:(BOOL)show;
- (void) __showOfferWall:(BOOL)show;
- (void) __showAppWall:(BOOL)show;
- (GADRequest*) __buildAdRequest;
- (NSString*) __md5: (NSString*) s;
- (NSString *) __getPersonalyDeviceId;

- (void) fireEvent:(NSString *)obj event:(NSString *)eventName withData:(NSString *)jsonStr;

@end

@implementation CDVFyber

@synthesize appKey;
@synthesize userId, securityToken, virtualCurrencyName;

#define DEFAULT_APP_KEY             @"27434"
#define DEFAULT_VC_NAME             @"mondos"
#define DEFAULT_USERID              @"5043b715c3bd823b760000ff"

#define INTERSTITIAL_REQUEST_CODE   @"8792"
#define OFFERWALL_REQUEST_CODE      @"8795"
#define REWARDED_VIDEO_REQUEST_CODE @"8796"

#define OPT_APPLICATION_KEY         @"appKey"
#define OPT_USER_ID                 @"userId"
#define OPT_SECURITY_TOKEN          @"securityToken"
#define OPT_VIRTUALCURRENCY_NAME    @"virtualCurrencyName"

#pragma mark Cordova JS bridge

- (void) pluginInitialize {
    [super pluginInitialize];
    if (self) {
        // These notifications are required for re-placing the ad on orientation
        // changes. Start listening for notifications here since we need to
        // translate the Smart Banner constants according to the orientation.
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(deviceOrientationChange:)
         name:UIDeviceOrientationDidChangeNotification
         object:nil];
    }

    appKey = DEFAULT_APP_KEY;
    userId = DEFAULT_USERID;
    virtualCurrencyName = DEFAULT_VC_NAME;

    srand((unsigned int)time(NULL));
}

- (void) executeInitialize:(CDVInvokedUrlCommand *)command {
    NSLog(@"setOptions");

    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;

    // Get the Interstitial Controller
    FYBInterstitialController *interstitialController = [FyberSDK interstitialController];

    // Set the Interstitial delegate
    interstitialController.delegate = self; 

    // Request an interstitial
    [interstitialController requestInterstitial];

    NSUInteger argc = [args count];
    if( argc >= 1 ) {
        NSDictionary* options = [command argumentAtIndex:0 withDefault:[NSNull null]];

        [self __setOptions:options];
    }

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) executeShowInterstitial:(CDVInvokedUrlCommand *)command {
    NSLog(@"executeShowInterstitial");

    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;

    FYBOfferWallViewController *offerWallViewController = [FyberSDK offerWallViewController];
    
    // If YES the offer wall will be dismissed after clicking on an offer
    offerWallViewController.shouldDismissOnRedirect = YES;

    // Showing the Offer Wall
    [offerWallViewController presentFromViewController:self animated:YES completion:^{
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } dismiss:^(NSError *error) {
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"interstitial not ready yet."];
    }];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) executeShowRewardedVideo:(CDVInvokedUrlCommand *)command {
    NSLog(@"executeShowRewardedVideo");

    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;

    // Get the Rewarded Video Controller
    FYBRewardedVideoController *rewardedVideoController = [FyberSDK rewardedVideoController];

    // Set the Video delegate
    rewardedVideoController.delegate = self; 

    // Request a Rewarded Video
    [rewardedVideoController requestVideo];

    if(! self.rewardedVideoView) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"rewardVideoAd is null, call createRewardVideo first."];

    } else {
        [self __showRewardedVideo:YES];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];

    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];

}

- (void) executeShowOfferwall:(CDVInvokedUrlCommand *)command {
    NSLog(@"executeShowOfferwall");

    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;

    NSUInteger argc = [args count];
    if (argc >= 1) {
        NSDictionary* options = [command argumentAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
    }

    [self __cycleAppWall];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void) executeShowBanner:(CDVInvokedUrlCommand *)command {
    NSLog(@"executeShowBanner");

    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;

    NSUInteger argc = [args count];
    if (argc >= 1) {
        NSDictionary* options = [command argumentAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
    }

    FYBBannerController *bannerController = [FyberSDK bannerController];
    bannerController.delegate = self;
    bannerController.modalViewController = self;

    [self __cycleAppWall];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

#pragma mark Ad Banner logic

- (void) __setOptions:(NSDictionary*) options {
    if ((NSNull *)options == [NSNull null]) return;

    NSString* str = nil;

    str = [options objectForKey:OPT_APPLICATION_KEY];
    if (str && [str length] > 0) {
        appKey = str;
    }

    str = [options objectForKey:OPT_USERID];
    if (str && [str length] > 0) {
        userId = str;
    }
    
    NSDictionary *params = @{ [Personaly userIDKey]: userId,
                          [Personaly ageKey]: age,
                          [Personaly genderKey]: gender,
                          [Personaly dateOfBirthdayKey]: [dateOfBirth] };

    [Personaly configureWithAppID:appId parameters:params queue:dispatch_get_main_queue() completion:^(BOOL success, NSError * _Nullable error) {
        [Personaly setDelegate:self];
    }];
}

- (void) __cycleInterstitial {
    NSLog(@"__cycleInterstitial");

    // Clean up the old interstitial...
    if (self.interstitialView) {
        self.interstitialView.delegate = nil;
        self.interstitialView = nil;
    }

    // and create a new interstitial. We set the delegate so that we can be notified of when
    if (!self.interstitialView){
        self.interstitialView = [[GADInterstitial alloc] initWithAdUnitID:self.interstitialAdId];
        self.interstitialView.delegate = self;

        [self.interstitialView loadRequest:[self __buildAdRequest]];
    }
}

- (BOOL) __showInterstitial:(BOOL)show {
    NSLog(@"__showInterstitial");

    if (!self.interstitialView){
        [self __cycleInterstitial];
    }

    if (self.interstitialView && self.interstitialView.isReady) {
        [self.interstitialView presentFromRootViewController:self.viewController];
        return true;
    } else {
        NSLog(@"Ad wasn't ready");
        return false;
    }
}

- (void) __cycleRewardedVideo {
    NSLog(@"__cycleRewardedVideo");

    @synchronized(self.rewardededVideoLock) {
        if (!self.isRewardedVideoLoading) {
            self.isRewardedVideoLoading = true;

            // Clean up the old video...
            if (self.rewardedVideoView) {
                self.rewardedVideoView.delegate = nil;
                self.rewardedVideoView = nil;
            }

            // and create a new video. We set the delegate so that we can be notified of when
            if (!self.rewardedVideoView){
                self.rewardedVideoView = [GADRewardBasedVideoAd sharedInstance];
                self.rewardedVideoView.delegate = self;

                [self.rewardedVideoView loadRequest:[GADRequest request] withAdUnitID:self.rewardedVideoId];
            }
        }
    }
}

- (void) __showRewardedVideo:(BOOL)show {
    NSLog(@"__showRewardedVideo");

    if (!self.rewardVideoView){
        [self __cycleRewardedVideo];
    }

    if (self.rewardedVideoView && self.rewardVideoView.isReady) {
        [self.rewardedVideoView presentFromRootViewController:self.viewController];
    } else {
        NSLog(@"RewardedVideo wasn't ready");
    }
}

- (void) fireEvent:(NSString *)obj event:(NSString *)eventName withData:(NSString *)jsonStr {
    NSString* js;
    if(obj && [obj isEqualToString:@"window"]) {
        js = [NSString stringWithFormat:@"var evt=document.createEvent(\"UIEvents\");evt.initUIEvent(\"%@\",true,false,window,0);window.dispatchEvent(evt);", eventName];
    } else if(jsonStr && [jsonStr length]>0) {
        js = [NSString stringWithFormat:@"javascript:cordova.fireDocumentEvent('%@',%@);", eventName, jsonStr];
    } else {
        js = [NSString stringWithFormat:@"javascript:cordova.fireDocumentEvent('%@');", eventName];
    }
    [self.commandDelegate evalJs:js];
}

#pragma mark FYBRewardedVideoControllerDelegate implementation

- (void) rewardedVideoControllerDidReceiveVideo:(FYBRewardedVideoController: *)rewardedVideoController:
    [self fireEvent:@"" event:@"personaly.banner.events.LOAD" withData:nil];
    [self fireEvent:@"" event:@"onReceiveAd" withData:nil];
}

- (void) rewardedVideoController:(FYBRewardedVideoController *)rewardedVideoController:didFailToReceiveVideoWithError:(NSError *)error{
    NSLog(@"An error occured while receiving the video ad %@", error);
}

- (void) rewardedVideoControllerDidStartVideo:(FYBRewardedVideoController *)rewardedVideoController{
    NSLog(@"A video has just been presented");
}

- (void) rewardedVideoController:(FYBRewardedVideoController *)rewardedVideoController didFailToStartVideoWithError:(NSError *)error{
    NSLog(@"An error occured while presenting the video %@", error);
}

- (void) rewardedVideoController:(FYBRewardedVideoController *)rewardedVideoController didDismissVideoWithReason:(FYBRewardedVideoControllerDismissReason)reason{
    NSString *reasonDescription;
    switch (reason) {
        case FYBRewardedVideoControllerDismissReasonError:
            reasonDescription = @"because of an error during playing";      
            break;
        case FYBRewardedVideoControllerDismissReasonUserEngaged:
            reasonDescription = @"because the user clicked on it";
            break;
        case FYBRewardedVideoControllerDismissReasonAborted:
            reasonDescription = @"because the user explicitly closed it";
            break;
    }

    NSLog(@"The video ad was dismissed %@", reasonDescription);
}

#pragma mark FYBInterstitialControllerDelegate implementation

- (void) interstitialControllerDidReceiveInterstitial:(FYBInterstitialController *)interstitialController
{
      NSLog(@"An interstitial has been received");

    // Show the received interstitial
    [interstitialController presentInterstitialFromViewController:self];
}

- (void) interstitialController:(FYBInterstitialController *)interstitialController didFailToReceiveInterstitialWithError:(NSError *)error{
    NSLog(@"An error occured while receiving the interstitial ad %@", error);
}

- (void) interstitialControllerDidPresentInterstitial:(FYBInterstitialController *)interstitialController{
    NSLog(@"An interstitial has been presented");
}

- (void) interstitialController:(FYBInterstitialController *)interstitialController didFailToPresentInterstitialWithError:(NSError *)error{
  NSLog(@"An error occured while showing the interstitial %@", error);
}

- (void) interstitialController:(FYBInterstitialController *)interstitialController didDismissInterstitialWithReason:(FYBInterstitialControllerDismissReason)reason{
  NSString *reasonDescription;
  switch (reason) {
      case FYBInterstitialControllerDismissReasonUserEngaged:
          reasonDescription = @"because the user clicked on it";
          break;
      case FYBInterstitialControllerDismissReasonAborted:
          reasonDescription = @"because the user explicitly closed it";
          break;
      case FYBInterstitialControllerDismissReasonError:
          // error during playing
          break;
  }

  NSLog(@"The interstitial ad was dismissed %@", reasonDescription);
}

#pragma mark Cleanup

- (void) dealloc {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:UIDeviceOrientationDidChangeNotification
     object:nil];

    interstitialView_.delegate = nil;
    interstitialView_ = nil;
    rewardedVideoView_.delegate = nil;
    rewardedVideoView_ =  nil;
    popupOfferView_.delegate = nil;
    popupOfferView_ =  nil;
    offerWallView_.delegate = nil;
    offerWallView_ =  nil;
    appWallView_.delegate = nil;
    appWallView_ =  nil;

    self.interstitialView = nil;
    self.rewardedVideoView = nil;
    self.popupOfferView = nil;
    self.offerWallView = nil;
    self.appWallView = nil;
}

@end
