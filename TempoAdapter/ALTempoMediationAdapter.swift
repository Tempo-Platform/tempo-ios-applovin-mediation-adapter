import Foundation

import TempoSDK
import AppLovinSDK

@objc(ALTempoMediationAdapter)
public class ALTempoMediationAdapter  : ALMediationAdapter, MAInterstitialAdapter, MARewardedAdapter, TempoAdListener {

    let tempoAdapterVersion: String = "1.1.0"
    var dynSdkVersion: String = Constants.SDK_VERSIONS
    
    var interstitial: TempoAdController? = nil
    var rewarded: TempoAdController? = nil
    var isInterstitialReady: Bool = false
    var isRewardedReady: Bool = false
    
    // ad type delegates
    var interstitialDelegate: MAInterstitialAdapterDelegate? = nil
    var rewardedDelegate: MARewardedAdapterDelegate? = nil
    
    // privacy/consent
    var alHasUserConsent: Bool?
    var isDoNotSell: Bool?
    var isAgeRestrictedUser: Bool?

    public override func initialize(with parameters: MAAdapterInitializationParameters, completionHandler: @escaping (MAAdapterInitializationStatus, String?) -> Void) {
        
        // Get current privacy/consent values
        alHasUserConsent = ALPrivacySettings.hasUserConsent()
        isDoNotSell = ALPrivacySettings.isDoNotSell()
        isAgeRestrictedUser = ALPrivacySettings.isAgeRestrictedUser()
        
        // Run AppLovin initialisers
        completionHandler(MAAdapterInitializationStatus.initializedUnknown, nil)
        
        // Run any backups
        TempoDataBackup.checkHeldMetrics(completion: Metrics.pushMetrics)
    }
    

    public func loadInterstitialAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MAInterstitialAdapterDelegate) {
        print(parameters.customParameters)
        
        let placementId: String? = parameters.thirdPartyAdPlacementIdentifier
        self.interstitialDelegate = delegate
        
        // Get values from AppLovin custom parameters
        let appId: String = parameters.customParameters["app_id"] as! String
        let cpmFloor: Float = ((parameters.customParameters["cpm_floor"] ?? "0") as! NSString).floatValue
        
        // Create if not already done so
        if self.interstitial == nil {
            self.interstitial = TempoAdController(tempoAdListener: self, appId: appId)
        }
        
        // Load ad with new data
        if self.interstitial != nil {
            DispatchQueue.main.async {
                self.interstitial!.loadAd(isInterstitial: true, cpmFloor:cpmFloor, placementId: placementId)
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
        var viewController: UIViewController? = (ALSdk.versionCode >= 11020199) ? parameters.presentingViewController ?? ALUtils.topViewControllerFromKeyWindow() : ALUtils.topViewControllerFromKeyWindow()
//
//        var viewController:UIViewController? = nil
//        if (ALSdk.versionCode >= 11020199) {
//            viewController = (parameters.presentingViewController != nil) ? parameters.presentingViewController : ALUtils.topViewControllerFromKeyWindow()
//        } else {
//            viewController = ALUtils.topViewControllerFromKeyWindow()
//        }
        //viewController = UIApplication.shared.keyWindow?.rootViewController - TODO: Why was this written over...?
        self.interstitial!.showAd(parentViewController: viewController!)
    }

    public func loadRewardedAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MARewardedAdapterDelegate) {
        print(parameters.customParameters)
        self.rewardedDelegate = delegate
        let placementId: String? = parameters.thirdPartyAdPlacementIdentifier
        
        // Get values from AppLovin custom parameters
        let appId: String = parameters.customParameters["app_id"] as! String
        let cpmFloor: Float = ((parameters.customParameters["cpm_floor"] ?? "0") as! NSString).floatValue
        
        if self.rewarded == nil {
            self.rewarded = TempoAdController(tempoAdListener: self, appId: appId)
        }
        
        
        // Load ad with new data
        if self.rewarded != nil {
            DispatchQueue.main.async {
                self.rewarded!.loadAd(isInterstitial: false, cpmFloor:cpmFloor, placementId: placementId)
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
        
        var viewController: UIViewController? = (ALSdk.versionCode >= 11020199) ? parameters.presentingViewController ?? ALUtils.topViewControllerFromKeyWindow() : ALUtils.topViewControllerFromKeyWindow()
//        var viewController:UIViewController? = nil
//        if (ALSdk.versionCode >= 11020199) {
//            viewController = (parameters.presentingViewController != nil) ? parameters.presentingViewController : ALUtils.topViewControllerFromKeyWindow()
//        } else {
//            viewController = ALUtils.topViewControllerFromKeyWindow()
//        }
//        viewController = UIApplication.shared.keyWindow?.rootViewController  - TODO: Why was this written over...?
        self.rewarded!.showAd(parentViewController: viewController!)
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

    public func onVersionExchange(sdkVersion: String) -> String? {
        dynSdkVersion = sdkVersion;
        return adapterVersion;
    }
 
    public func onGetAdapterType() -> String? {
        return "APPLOVIN"
    }

    public func hasUserConsent() -> Bool? {
        return alHasUserConsent
    }
    
    private func getTypeWord(isInterstitial: Bool) -> String {
        return isInterstitial ? "INTERSTIIAL" : "REWARDED"
    }
    
    public override var sdkVersion : String {
        return dynSdkVersion
    }

    public override var adapterVersion : String {
        return tempoAdapterVersion
    }
}
