function FyberPlugin() {}

FyberPlugin.prototype.initialize = function (appKey, userId, securityToken, virtualCurrencyName, success, error) {
	cordova.exec(success, error, 'FyberPlugin', 'initialize', [appKey, userId, securityToken, virtualCurrencyName]);
};

FyberPlugin.prototype.showOfferwall = function (success, error) {
	cordova.exec(success, error, 'FyberPlugin', 'showOfferwall', []);
};

FyberPlugin.prototype.showRewardedVideo = function (success, error) {
	cordova.exec(success, error, 'FyberPlugin', 'showRewardedVideo', []);
};

FyberPlugin.prototype.showInterstitial = function (success, error) {
	cordova.exec(success, error, 'FyberPlugin', 'showInterstitial', []);
};

module.exports = new FyberPlugin();