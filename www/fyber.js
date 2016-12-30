function FyberPlugin() {}

FyberPlugin.prototype.initialize = function (appKey, userId, securityToken, virtualCurrencyName, success, error) {
	cordova.exec(success, error, 'Fyber', 'initialize', [appKey, userId, securityToken, virtualCurrencyName]);
};

FyberPlugin.prototype.showOfferwall = function (success, error) {
	cordova.exec(success, error, 'Fyber', 'showOfferwall', []);
};

FyberPlugin.prototype.showRewardedVideo = function (success, error) {
	cordova.exec(success, error, 'Fyber', 'showRewardedVideo', []);
};

FyberPlugin.prototype.showInterstitial = function (success, error) {
	cordova.exec(success, error, 'Fyber', 'showInterstitial', []);
};

module.exports = new FyberPlugin();