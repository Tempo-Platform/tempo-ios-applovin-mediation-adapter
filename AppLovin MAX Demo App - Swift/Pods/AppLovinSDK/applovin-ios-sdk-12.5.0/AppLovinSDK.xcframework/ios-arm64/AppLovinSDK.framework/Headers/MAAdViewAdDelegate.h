//
//  MAAdViewAdDelegate.h
//  AppLovinSDK
//
//  Created by Thomas So on 8/10/18.
//  Copyright © 2020 AppLovin Corporation. All rights reserved.
//

#import <AppLovinSDK/MAAdDelegate.h>

@class MAAd;

NS_ASSUME_NONNULL_BEGIN

/**
 * This delegate is notified about ad view events.
 *
 * @see <a href="https://developers.applovin.com/en/ios/ad-formats/banner-and-mrec-ads#banners">MAX Integration Guide ⇒ iOS ⇒ Ad Formats ⇒ Banners</a>
 * @see <a href="https://developers.applovin.com/en/ios/ad-formats/banner-and-mrec-ads#mrecs">MAX Integration Guide ⇒ iOS ⇒ Ad Formats ⇒ MRECs</a>
 */
@protocol MAAdViewAdDelegate <MAAdDelegate>

/**
 * The SDK invokes this method when the @c MAAdView has expanded to the full screen.
 *
 * @param ad An ad for which the ad view expanded.
 */
- (void)didExpandAd:(MAAd *)ad;

/**
 * The SDK invokes this method when the @c MAAdView has collapsed back to its original size.
 *
 * @param ad An ad for which the ad view collapsed.
 */
- (void)didCollapseAd:(MAAd *)ad;

@end

NS_ASSUME_NONNULL_END
