import Foundation

import TempoSDK
import AppLovinSDK

@objc(ALTempoMediationAdapter)
public class ALTempoMediationAdapter  : ALMediationAdapter, MAInterstitialAdapter, MARewardedAdapter, TempoAdListener {

    let ADAPTER_TYPE: String = "APPLOVIN"
    let TEMPO_ADAPTER_VERSION: String = "1.2.1"
    let CUST_CPM_FLR = "cpm_floor"
    let CUST_APP_ID = "app_id"
    
    var interstitial: TempoAdController? = nil
    var rewarded: TempoAdController? = nil
    
    var isInterstitialReady: Bool = false
    var isRewardedReady: Bool = false
    
    // Ad type delegates
    var interstitialDelegate: MAInterstitialAdapterDelegate? = nil
    var rewardedDelegate: MARewardedAdapterDelegate? = nil
    
    // Privacy/consent
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
        TempoDataBackup.initCheck()
    }
    
    /// Function used by AppLovin SDK when loading an INTERSTITIAL ad
    public func loadInterstitialAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MAInterstitialAdapterDelegate) {
        TempoUtils.Say(msg: "\(parameters.customParameters)")
        
        self.interstitialDelegate = delegate
        
        // Get values from AppLovin and custom parameters
        let placementId: String? = parameters.thirdPartyAdPlacementIdentifier
        let appId: String = parameters.customParameters[CUST_APP_ID] as! String
        let cpmFloor: Float = ((parameters.customParameters[CUST_CPM_FLR] ?? "0") as! NSString).floatValue
        
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
    
    /// Function used by AppLovin SDK when selecting to play a loaded  INTERSTITIAL ad
    public func showInterstitialAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MAInterstitialAdapterDelegate) {
        self.interstitialDelegate = delegate
        if (!isInterstitialReady) {
            self.interstitialDelegate?.didFailToDisplayInterstitialAdWithError(MAAdapterError.adNotReady)
            return
        }

        self.interstitial!.showAd(parentViewController: getTopVC(parameters: parameters))
    }
    
    /// Function used by AppLovin SDK when loading an REWARDED ad
    public func loadRewardedAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MARewardedAdapterDelegate) {
        TempoUtils.Say(msg: "\(parameters.customParameters)")
        self.rewardedDelegate = delegate
        
        // Get values from AppLovin and custom parameters
        let placementId: String? = parameters.thirdPartyAdPlacementIdentifier
        let appId: String = parameters.customParameters[CUST_APP_ID] as! String
        let cpmFloor: Float = ((parameters.customParameters[CUST_CPM_FLR] ?? "0") as! NSString).floatValue
        
        // Create if not already done so
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
    
    /// Function used by AppLovin SDK when selecting to play a loaded REWARDED ad
    public func showRewardedAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MARewardedAdapterDelegate) {
        self.rewardedDelegate = delegate
        if (!isRewardedReady) {
            self.rewardedDelegate?.didFailToDisplayRewardedAdWithError(MAAdapterError.adNotReady)
            return
        }
        
        self.rewarded!.showAd(parentViewController: getTopVC(parameters: parameters))
    }
    
    /// Function that selects the top-most ViewController to build the ad's WebView on top of
    func getTopVC(parameters: MAAdapterResponseParameters) -> UIViewController? {
        
        var viewController: UIViewController? = (ALSdk.versionCode >= 11020199) ? parameters.presentingViewController ?? ALUtils.topViewControllerFromKeyWindow() : ALUtils.topViewControllerFromKeyWindow()
        
        // If still nil? // TODO: Apparently this was deprecated in iOS 13 and may have issues with iPad apps that have multiple windows
        viewController = UIApplication.shared.keyWindow?.rootViewController
        return viewController

    }
    
    
    /// AppLovin overrides
    public override var sdkVersion : String {
        return Constants.SDK_VERSIONS
    }
    public override var adapterVersion : String {
        return TEMPO_ADAPTER_VERSION
    }
    
    /// TempoListener overrides
    public func onTempoAdFetchSucceeded(isInterstitial: Bool) {
        if (isInterstitial && (self.interstitialDelegate != nil)) {
            self.interstitialDelegate?.didLoadInterstitialAd()
            isInterstitialReady = true
        } else if (!isInterstitial && (self.rewardedDelegate != nil)) {
            self.rewardedDelegate?.didLoadRewardedAd()
            isRewardedReady = true
        }
    }
    public func onTempoAdFetchFailed(isInterstitial: Bool) {
        if (isInterstitial && (self.interstitialDelegate != nil)) {
            self.interstitialDelegate?.didFailToLoadInterstitialAdWithError(MAAdapterError.unspecified)
        } else if (!isInterstitial && (self.rewardedDelegate != nil)) {
            self.rewardedDelegate?.didFailToLoadRewardedAdWithError(MAAdapterError.unspecified)
        }
    }
    public func onTempoAdClosed(isInterstitial: Bool) {
        if (isInterstitial && (self.interstitialDelegate != nil)) {
            self.interstitialDelegate?.didHideInterstitialAd()
            self.interstitial = nil
            self.interstitialDelegate = nil
            self.isInterstitialReady = false
        } else if (!isInterstitial && (self.rewardedDelegate != nil)) {
            self.rewardedDelegate?.didRewardUser(with: MAReward())
            self.rewardedDelegate?.didHideRewardedAd()
            self.rewarded = nil
            self.rewardedDelegate = nil
            self.isRewardedReady = false
        }
    }
    public func onTempoAdDisplayed(isInterstitial: Bool) {
        if (isInterstitial && (self.interstitialDelegate != nil)) {
            self.interstitialDelegate?.didDisplayInterstitialAd()
        } else if (!isInterstitial && (self.rewardedDelegate != nil)) {
            self.rewardedDelegate?.didDisplayRewardedAd()
        }
    }
    public func onTempoAdClicked(isInterstitial: Bool) {
        if (isInterstitial && (self.interstitialDelegate != nil)) {
            self.interstitialDelegate?.didClickInterstitialAd()
        } else if (!isInterstitial && (self.rewardedDelegate != nil)) {
            self.rewardedDelegate?.didClickRewardedAd()
        }
    }
    public func getTempoAdapterVersion() -> String? {
        return TEMPO_ADAPTER_VERSION
    }
    public func getTempoAdapterType() -> String? {
        return ADAPTER_TYPE
    }
    public func hasUserConsent() -> Bool? {
        return alHasUserConsent
    }
    
}
