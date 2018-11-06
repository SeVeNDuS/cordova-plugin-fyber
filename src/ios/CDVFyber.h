#import <Cordova/CDV.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FyberSDK.h"

#pragma mark - JS requestAd options

#pragma mark Fyber Plugin

// This version of the Fyber plugin has been tested with Cordova version 2.5.0.

@interface CDVFyber : CDVPlugin <FYBRewardedVideoControllerDelegate, FYBInterstitialControllerDelegate, FYBBannerControllerDelegate> {
}

@property (nonatomic, retain) NSString* appKey;
@property (nonatomic, retain) NSString* virtualCurrencyName;
@property (nonatomic, retain) NSString* securityToken;
@property (nonatomic, retain) NSString* userId;

- (void) executeInitialize:(CDVInvokedUrlCommand *)command;
- (void) executeShowInterstitial:(CDVInvokedUrlCommand *)command;
- (void) executeShowRewardedVideo:(CDVInvokedUrlCommand *)command;
- (void) executeShowOfferwall:(CDVInvokedUrlCommand *)command;
- (void) executeShowBanner:(CDVInvokedUrlCommand *)command;

@end
