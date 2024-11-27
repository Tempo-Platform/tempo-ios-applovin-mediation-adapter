import Foundation

import TempoSDK
import AppLovinSDK

@objc(ALTempoMediationAdapter)
public class ALTempoMediationAdapter  : ALMediationAdapter, MAInterstitialAdapter, MARewardedAdapter, TempoAdListener {

    let ADAPTER_TYPE: String = "APPLOVIN"
    let TEMPO_ADAPTER_VERSION: String = "1.9.0"
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

    public override func initialize(with parameters: MAAdapterInitializationParameters, completionHandler: @escaping (MAAdapterInitializationStatus, String?) -> Void) {
        
        // Get current privacy/consent values
        alHasUserConsent = ALPrivacySettings.hasUserConsent()
        isDoNotSell = ALPrivacySettings.isDoNotSell()
        
        // Run any backups
        do {
            try TempoDataBackup.initCheck()
        } catch {
            TempoUtils.Warn(msg: "Error checking for backup metrics in adapter")
        }
        
        // Run AppLovin initialisers
        completionHandler(MAAdapterInitializationStatus.initializedUnknown, nil)
    }
    
    /// Function used by AppLovin SDK when loading an INTERSTITIAL ad
    public func loadInterstitialAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MAInterstitialAdapterDelegate) {
        
        // We use this value to trigger AppLovin callbacks
        self.interstitialDelegate = delegate
        
        // Check for valid App ID in response parameters
        let appId = getParameterString(paramKey: CUST_APP_ID, alParams: parameters)
        
        guard !appId.isEmpty else {
            TempoUtils.Warn(msg: "Invalid App ID")
            self.interstitialDelegate?.didFailToLoadInterstitialAdWithError(MAAdapterError.notInitialized)
            return
        }
        // Get values from AppLovin and custom parameters
        let placementId = parameters.thirdPartyAdPlacementIdentifier
        // Check for CPM Floor in custom parameters, if missing (or typo) parameter value will be nil
        let cpmFloor = getParameterAsFloat(paramKey: CUST_CPM_FLR, alParams: parameters)
        
        
        TempoUtils.Say(msg: "AppID=\(appId ?? "<appId?>"), CPMFloor=\(cpmFloor), PlacementID=\(placementId ?? "<placementId?>")")
        
        // Create new interstitial AdController - nil check just in case
        if self.interstitial == nil {
            self.interstitial = TempoAdController(tempoAdListener: self, appId: appId)
        }
        
        // Guards if something went wrong during creation
        guard self.interstitial != nil else {
            self.interstitialDelegate?.didFailToLoadInterstitialAdWithError(MAAdapterError.notInitialized)
            return
        }
        
        // Load ad, provided the ad controller is not null
        self.interstitial!.loadAd(isInterstitial: true, cpmFloor: cpmFloor, placementId: placementId)
    }
    
    /// Function used by AppLovin SDK when selecting to play a loaded  INTERSTITIAL ad
    public func showInterstitialAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MAInterstitialAdapterDelegate) {
        
        // Set AL delegate
        self.interstitialDelegate = delegate
        
        // Send ad not ready error if needed
        guard isInterstitialReady else {
            self.interstitialDelegate?.didFailToDisplayInterstitialAdWithError(MAAdapterError.adNotReady)
            return
        }

        // Checks that parent/base ViewController is valid and then shows ad
        guard let topVC = getTopVC(parameters: parameters), self.interstitial != nil else {
            self.onTempoAdShowFailed(isInterstitial: true, reason: "Could not get a parent ViewController")
            return
        }
        
        guard self.interstitial != nil else {
            self.onTempoAdShowFailed(isInterstitial: true, reason: "Tempo interstitial AdController was nil")
            return
        }
        
        self.interstitial!.showAd(parentViewController: topVC)
    }
   
    /// Function used by AppLovin SDK when loading an REWARDED ad
    public func loadRewardedAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MARewardedAdapterDelegate) {
        
        // We use this value to trigger AppLovin callbacks
        self.rewardedDelegate = delegate
        
        // Check for valid App ID in response parameters
        let appId = getParameterString(paramKey: CUST_APP_ID, alParams: parameters)
        
        guard !appId.isEmpty else {
            TempoUtils.Warn(msg: "Invalid App ID")
            self.rewardedDelegate?.didFailToLoadRewardedAdWithError(MAAdapterError.notInitialized)
            return
        }
        // Get values from AppLovin and custom parameters
        let placementId = parameters.thirdPartyAdPlacementIdentifier
        // Check for CPM Floor in custom parameters, if missing (or typo) parameter value will be nil
        let cpmFloor = getParameterAsFloat(paramKey: CUST_CPM_FLR, alParams: parameters)
        
        TempoUtils.Say(msg: "AppID=\(appId ?? "<appId?>"), CPMFloor=\(cpmFloor), PlacementID=\(placementId ?? "<placementId?>")")

        // Create new rewarded Ad Controller - nil check just in case
        if self.rewarded == nil {
            self.rewarded = TempoAdController(tempoAdListener: self, appId: appId)
        }
        guard self.rewarded != nil else {
            self.rewardedDelegate?.didFailToLoadRewardedAdWithError(MAAdapterError.notInitialized)
            return
        }
        
        // Load ad, provided the ad controller is not null
        self.rewarded!.loadAd(isInterstitial: false, cpmFloor: cpmFloor, placementId: placementId)
    }
    
    /// Function used by AppLovin SDK when selecting to play a loaded REWARDED ad
    public func showRewardedAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MARewardedAdapterDelegate) {

        // Set AL delegate
        self.rewardedDelegate = delegate
        
        // Send ad not ready error if needed
        guard isRewardedReady else {
            self.rewardedDelegate?.didFailToDisplayRewardedAdWithError(MAAdapterError.adNotReady)
            return
        }
        
        // Checks that parent/base ViewController is valid and then shows ad
        guard let topVC = getTopVC(parameters: parameters), self.rewarded != nil else {
            self.onTempoAdShowFailed(isInterstitial: false, reason: "Could not get a parent ViewController")
            return
        }
        
        guard self.rewarded != nil else {
            self.onTempoAdShowFailed(isInterstitial: false, reason: "Tempo rewarded AdController was nil")
            return
        }
        
        self.rewarded!.showAd(parentViewController: topVC)
    }
    
    /// Validates parameter String values
    func getParameterString(paramKey: String, alParams: MAAdapterResponseParameters) -> String {
        if let validatedString = alParams.customParameters[paramKey] as? String {
              TempoUtils.Say(msg: "✅ customParameters[\(paramKey)] is valid: \(validatedString)")
              return validatedString
          } else {
              TempoUtils.Say(msg: "❌ customParameters[\(paramKey)] is either nil or not a String")
              return ""
          }
    }
    
    /// Validates parameter Float values
    func getParameterAsFloat(paramKey: String, alParams: MAAdapterResponseParameters) -> Float {
        if let validatedString = alParams.customParameters[paramKey] as? String, let floatValue = Float(validatedString) {
            TempoUtils.Say(msg: "✅ customParameters[\(paramKey)] is valid: \(floatValue)")
            return floatValue
        } else {
            TempoUtils.Say(msg: "❌ customParameters[\(paramKey)] is either nil, not a String, or cannot be converted to a Float")
            return 0
        }
    }
    
    /// Function that selects the top-most ViewController to build the ad's WebView on top of
    func getTopVC(parameters: MAAdapterResponseParameters) -> UIViewController? {
        
        // TODO: Apparently this was deprecated in iOS 13 and may have issues with iPad apps that have multiple windows
        let viewController = UIApplication.shared.keyWindow?.rootViewController
        return viewController
//        
//        // TODO: was originally in front of above returning code (with 'var viewController') - look into this
//        // Check if ALSdk version is sufficient for using presentingViewController
//        if ALSdk.versionCode >= 11020199 {
//            return parameters.presentingViewController ?? ALUtils.topViewControllerFromKeyWindow()
//        } else {
//            // Fallback for older ALSdk versions
//            return ALUtils.topViewControllerFromKeyWindow()
//        }
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
    public func onTempoAdFetchFailed(isInterstitial: Bool, reason: String?) {
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
    public func onTempoAdShowFailed(isInterstitial: Bool, reason: String?) {
        if (isInterstitial && (self.interstitialDelegate != nil)) {
            self.interstitialDelegate?.didFailToDisplayInterstitialAdWithError(MAAdapterError.internalError)
        } else if (!isInterstitial && (self.rewardedDelegate != nil)) {
            self.rewardedDelegate?.didFailToDisplayRewardedAdWithError(MAAdapterError.internalError)
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
