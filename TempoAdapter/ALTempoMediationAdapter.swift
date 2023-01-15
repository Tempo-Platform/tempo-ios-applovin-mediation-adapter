import Foundation

import TempoSDK
import AppLovinSDK

@objc(ALTempoMediationAdapter)
public class ALTempoMediationAdapter  : ALMediationAdapter, MAInterstitialAdapter, MARewardedAdapter, TempoInterstitialListener {

    var interstitial: TempoInterstitial? = nil
    var isAdReady: Bool = false
    var interstitialDelegate: MAInterstitialAdapterDelegate? = nil
    var rewardedDelegate: MARewardedAdapterDelegate? = nil

    public override var sdkVersion : String {
        return String(TempoSDKVersionNumber)
    }

    public override var adapterVersion : String {
        return "0.1.0"
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
                self.interstitial!.loadAd(cpmFloor:cpmFloor)
              }
        } else {
            self.interstitialDelegate?.didFailToLoadInterstitialAdWithError(MAAdapterError.notInitialized)
        }
    }
    
    public func showInterstitialAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MAInterstitialAdapterDelegate) {
        self.interstitialDelegate = delegate
        if (!isAdReady) {
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
        print(parameters.customParameters)
        self.rewardedDelegate = delegate
        if self.interstitial == nil {
            let appId: String = parameters.customParameters["app_id"] as! String
            self.interstitial = TempoInterstitial(parentViewController: nil, delegate: self, appId: appId)
        }
        if self.interstitial != nil {
            let appId: String = parameters.customParameters["app_id"] as! String
            self.interstitial!.updateAppId(appId: appId)
            let cpmFloor: Float = ((parameters.customParameters["cpm_floor"] ?? "0") as! NSString).floatValue
            DispatchQueue.main.async {
                self.interstitial!.loadAd(cpmFloor:cpmFloor)
              }
        } else {
            self.rewardedDelegate?.didFailToLoadRewardedAdWithError(MAAdapterError.notInitialized)
        }
    }
    
    public func showRewardedAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MARewardedAdapterDelegate) {
        self.rewardedDelegate = delegate
        if (!isAdReady) {
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
        self.interstitial!.updateViewController(parentViewController: viewController!)
        self.interstitial!.showAd()
    }

    public func onAdFetchSucceeded() {
        if (self.interstitialDelegate != nil) {
            self.interstitialDelegate?.didLoadInterstitialAd()
        }
        if (self.rewardedDelegate != nil) {
            self.rewardedDelegate?.didLoadRewardedAd()
        }
        isAdReady = true
    }
    
    public func onAdFetchFailed() {
        if (self.interstitialDelegate != nil) {
            self.interstitialDelegate?.didFailToLoadInterstitialAdWithError(MAAdapterError.unspecified)
        }
        if (self.rewardedDelegate != nil) {
            self.rewardedDelegate?.didFailToLoadRewardedAdWithError(MAAdapterError.unspecified)
        }
    }
    
    public func onAdClosed() {
        if (self.interstitialDelegate != nil) {
            self.interstitialDelegate?.didHideInterstitialAd()
        }
        if (self.rewardedDelegate != nil) {
            self.rewardedDelegate?.didRewardUser(with: MAReward())
            self.rewardedDelegate?.didHideRewardedAd()
        }
        self.interstitial = nil
        self.interstitialDelegate = nil
        self.rewardedDelegate = nil
        isAdReady = false
    }
    
    public func onAdDisplayed() {
        if (self.interstitialDelegate != nil) {
            self.interstitialDelegate?.didDisplayInterstitialAd()
        }
        if (self.rewardedDelegate != nil) {
            self.rewardedDelegate?.didDisplayRewardedAd()
        }
    }

    public func onAdClicked() {
        if (self.interstitialDelegate != nil) {
            self.interstitialDelegate?.didClickInterstitialAd()
        }
        if (self.rewardedDelegate != nil) {
            self.rewardedDelegate?.didClickRewardedAd()
        }
    }
}
