import Foundation

import TempoSDK
import AppLovinSDK

@objc(ALTempoMediationAdapter)
public class ALTempoMediationAdapter  : ALMediationAdapter, MAInterstitialAdapter, MARewardedAdapter, TempoInterstitialListener {

    var interstitial: TempoInterstitial? = nil
    var rewarded: TempoInterstitial? = nil
    var isInterstitialReady: Bool = false
    var isRewardedReady: Bool = false
    var interstitialDelegate: MAInterstitialAdapterDelegate? = nil
    var rewardedDelegate: MARewardedAdapterDelegate? = nil

    public override var sdkVersion : String {
        return "0.2.9"
    }

    public override var adapterVersion : String {
        return "0.2.9"
    }
    
    public override func initialize(with parameters: MAAdapterInitializationParameters, completionHandler: @escaping (MAAdapterInitializationStatus, String?) -> Void) {
        self.interstitial = TempoInterstitial(parentViewController: nil, delegate: self, appId: "PLACEHOLDER")
        completionHandler(MAAdapterInitializationStatus.initializedUnknown, nil)
    }

    public func loadInterstitialAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MAInterstitialAdapterDelegate) {
        print(parameters.customParameters)
        self.interstitialDelegate = delegate
        if self.interstitial == nil {
            let appId: String = parameters.customParameters["app_id"] as! String
            self.interstitial = TempoInterstitial(parentViewController: nil, delegate: self, appId: appId)
        }
        if self.interstitial != nil {
            let appId: String = parameters.customParameters["app_id"] as! String
            self.interstitial!.updateAppId(appId: appId)
            let cpmFloor: Float = ((parameters.customParameters["cpm_floor"] ?? "0") as! NSString).floatValue
            DispatchQueue.main.async {
                self.interstitial!.loadAd(isInterstitial: true, cpmFloor:cpmFloor)
              }
        } else {
            self.interstitialDelegate?.didFailToLoadInterstitialAdWithError(MAAdapterError.notInitialized)
        }
    }
    
    public func showInterstitialAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MAInterstitialAdapterDelegate) {
        self.interstitialDelegate = delegate
        if (!isInterstitialReady) {
            self.interstitialDelegate?.didFailToDisplayInterstitialAdWithError(MAAdapterError.adNotReady)
            return
        }
        var viewController:UIViewController? = nil
        if (ALSdk.versionCode >= 11020199) {
            viewController = (parameters.presentingViewController != nil) ? parameters.presentingViewController : ALUtils.topViewControllerFromKeyWindow()
        } else {
            viewController = ALUtils.topViewControllerFromKeyWindow()
        }
        viewController = UIApplication.shared.keyWindow?.rootViewController
        self.interstitial!.updateViewController(parentViewController: viewController!)
        self.interstitial!.showAd()
    }

    public func loadRewardedAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MARewardedAdapterDelegate) {
        self.rewardedDelegate = delegate
        if self.rewarded == nil {
            let appId: String = parameters.customParameters["app_id"] as! String
            self.rewarded = TempoInterstitial(parentViewController: nil, delegate: self, appId: appId)
        }
        if self.rewarded != nil {
            let appId: String = parameters.customParameters["app_id"] as! String
            self.rewarded!.updateAppId(appId: appId)
            let cpmFloor: Float = ((parameters.customParameters["cpm_floor"] ?? "0") as! NSString).floatValue
            DispatchQueue.main.async {
                self.rewarded!.loadAd(isInterstitial: false, cpmFloor:cpmFloor)
              }
        } else {
            self.rewardedDelegate?.didFailToLoadRewardedAdWithError(MAAdapterError.notInitialized)
        }
    }
    
    public func showRewardedAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MARewardedAdapterDelegate) {
        self.rewardedDelegate = delegate
        if (!isRewardedReady) {
            self.rewardedDelegate?.didFailToDisplayRewardedAdWithError(MAAdapterError.adNotReady)
            return
        }
        var viewController:UIViewController? = nil
        if (ALSdk.versionCode >= 11020199) {
            viewController = (parameters.presentingViewController != nil) ? parameters.presentingViewController : ALUtils.topViewControllerFromKeyWindow()
        } else {
            viewController = ALUtils.topViewControllerFromKeyWindow()
        }
        viewController = UIApplication.shared.keyWindow?.rootViewController
        self.rewarded!.updateViewController(parentViewController: viewController!)
        self.rewarded!.showAd()
    }

    public func onAdFetchSucceeded(isInterstitial: Bool) {
        if (isInterstitial && (self.interstitialDelegate != nil)) {
            self.interstitialDelegate?.didLoadInterstitialAd()
            isInterstitialReady = true
        }
        if (!isInterstitial && (self.rewardedDelegate != nil)) {
            self.rewardedDelegate?.didLoadRewardedAd()
            isRewardedReady = true
        }
    }
    
    public func onAdFetchFailed(isInterstitial: Bool) {
        if (isInterstitial && (self.interstitialDelegate != nil)) {
            self.interstitialDelegate?.didFailToLoadInterstitialAdWithError(MAAdapterError.unspecified)
        }
        if (!isInterstitial && (self.rewardedDelegate != nil)) {
            self.rewardedDelegate?.didFailToLoadRewardedAdWithError(MAAdapterError.unspecified)
        }
    }
    
    public func onAdClosed(isInterstitial: Bool) {
        if (isInterstitial && (self.interstitialDelegate != nil)) {
            self.interstitialDelegate?.didHideInterstitialAd()
            self.interstitial = nil
            self.interstitialDelegate = nil
            self.isInterstitialReady = false
        }
        if (!isInterstitial && (self.rewardedDelegate != nil)) {
            self.rewardedDelegate?.didRewardUser(with: MAReward())
            self.rewardedDelegate?.didHideRewardedAd()
            self.rewarded = nil
            self.rewardedDelegate = nil
            self.isRewardedReady = false
        }
    }
    
    public func onAdDisplayed(isInterstitial: Bool) {
        if (isInterstitial && (self.interstitialDelegate != nil)) {
            self.interstitialDelegate?.didDisplayInterstitialAd()
        }
        if (!isInterstitial && (self.rewardedDelegate != nil)) {
            self.rewardedDelegate?.didDisplayRewardedAd()
        }
    }

    public func onAdClicked(isInterstitial: Bool) {
        if (isInterstitial && (self.interstitialDelegate != nil)) {
            self.interstitialDelegate?.didClickInterstitialAd()
        }
        if (!isInterstitial && (self.rewardedDelegate != nil)) {
            self.rewardedDelegate?.didClickRewardedAd()
        }
    }
}
