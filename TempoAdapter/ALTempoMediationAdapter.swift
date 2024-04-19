import Foundation

import TempoSDK
import AppLovinSDK

@objc(ALTempoMediationAdapter)
public class ALTempoMediationAdapter  : ALMediationAdapter, MAInterstitialAdapter, MARewardedAdapter, TempoAdListener {

    let ADAPTER_TYPE: String = "APPLOVIN"
    let TEMPO_ADAPTER_VERSION: String = "1.5.0"
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
        
        // Run any backups
        TempoDataBackup.initCheck()
        
        // Run AppLovin initialisers
        completionHandler(MAAdapterInitializationStatus.initializedUnknown, nil)
    }
    
    /// Function used by AppLovin SDK when loading an INTERSTITIAL ad
    public func loadInterstitialAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MAInterstitialAdapterDelegate) {
        //TempoUtils.Say(msg: "👉 customParameters\(parameters.customParameters)")
        
        // We use this value to trigger AppLovin callbacks
        self.interstitialDelegate = delegate
        
        // Get values from AppLovin and custom parameters
        let placementId: String? = parameters.thirdPartyAdPlacementIdentifier
        var appId: String? = ""
        var cpmFloor: Float = 0
        
        // Check for App ID in custom parameters, if missing (or typo) parameter value will be nil
        appId = getParameterString(paramKey: CUST_APP_ID, alParams: parameters)
        
        // Check for CPM Floor in custom parameters, if missing (or typo) parameter value will be nil
        cpmFloor = getParameterAsFloat(paramKey: CUST_CPM_FLR, alParams: parameters)
        
        TempoUtils.Say(msg: "AppID=\(appId ?? "<appId?>"), CPMFloor=\(cpmFloor), PlacementID=\(placementId ?? "<placementId?>")")
        
        if self.interstitial == nil {
            self.interstitial = TempoAdController(tempoAdListener: self, appId: appId)
            
            if self.interstitial == nil {
                self.interstitialDelegate?.didFailToLoadInterstitialAdWithError(MAAdapterError.notInitialized)
                return
            }
        }
        
        // Load ad, provided the ad controller is not null
        self.interstitial?.loadAd(isInterstitial: true, cpmFloor: cpmFloor, placementId: placementId)
        
        
    }
    
    /// Function used by AppLovin SDK when selecting to play a loaded  INTERSTITIAL ad
    public func showInterstitialAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MAInterstitialAdapterDelegate) {
        
        // Set AL delegate
        self.interstitialDelegate = delegate
        
//        if (!isInterstitialReady) {
//            self.interstitialDelegate?.didFailToDisplayInterstitialAdWithError(MAAdapterError.adNotReady)
//            return
//        }
//
//        self.interstitial!.showAd(parentViewController: getTopVC(parameters: parameters))
        
        // Send ad not ready error if needed
        guard isInterstitialReady else {
            self.interstitialDelegate?.didFailToDisplayInterstitialAdWithError(MAAdapterError.adNotReady)
            return
        }

        // Checks that parent/base ViewController is valid and then shows ad
        if let topVC = getTopVC(parameters: parameters) {
            self.interstitial?.showAd(parentViewController: topVC)
        } else {
            self.onTempoAdShowFailed(isInterstitial: true, reason: "Could not get a parent ViewController")
        }
    }
   
    /// Function used by AppLovin SDK when loading an REWARDED ad
    public func loadRewardedAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MARewardedAdapterDelegate) {
        //TempoUtils.Say(msg: "👉 customParameters\(parameters.customParameters)")
        
        // We use this value to trigger AppLovin callbacks
        self.rewardedDelegate = delegate
        
        // Get values from AppLovin and custom parameters
        let placementId: String? = parameters.thirdPartyAdPlacementIdentifier
        var appId: String? = ""
        var cpmFloor: Float = 0
        
        // Check for App ID in custom parameters, if missing (or typo) parameter value will be nil
        appId = getParameterString(paramKey: CUST_APP_ID, alParams: parameters)
        
        // Check for CPM Floor in custom parameters, if missing (or typo) parameter value will be nil
        cpmFloor = getParameterAsFloat(paramKey: CUST_CPM_FLR, alParams: parameters)
        
        TempoUtils.Say(msg: "AppID=\(appId ?? "<appId?>"), CPMFloor=\(cpmFloor), PlacementID=\(placementId ?? "<placementId?>")")

        if self.rewarded == nil {
            self.rewarded = TempoAdController(tempoAdListener: self, appId: appId)
            
            if self.rewarded == nil {
                self.rewardedDelegate?.didFailToLoadRewardedAdWithError(MAAdapterError.notInitialized)
                return
            }
        }
        
        // Load ad, provided the ad controller is not null
        self.rewarded?.loadAd(isInterstitial: false, cpmFloor: cpmFloor, placementId: placementId)
    }
    
    /// Function used by AppLovin SDK when selecting to play a loaded REWARDED ad
    public func showRewardedAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MARewardedAdapterDelegate) {

        // Set AL delegate
        self.rewardedDelegate = delegate
        
//        if (!isRewardedReady) {
//            self.rewardedDelegate?.didFailToDisplayRewardedAdWithError(MAAdapterError.adNotReady)
//            return
//        }
//        
//        self.rewarded!.showAd(parentViewController: getTopVC(parameters: parameters))
        
        // Send ad not ready error if needed
        guard isRewardedReady else {
            self.rewardedDelegate?.didFailToDisplayRewardedAdWithError(MAAdapterError.adNotReady)
            return
        }

        // Checks that parent/base ViewController is valid and then shows ad
        if let topVC = getTopVC(parameters: parameters) {
            self.rewarded?.showAd(parentViewController: topVC)
        } else {
            self.onTempoAdShowFailed(isInterstitial: false, reason: "Could not get a parent ViewController")
        }
    }
    
    /// Validates parameter String values
    func getParameterString(paramKey: String, alParams: MAAdapterResponseParameters) -> String {
        var returningString = ""
        let stringParam = alParams.customParameters[paramKey]
        if(stringParam != nil) {
            if let rawString = stringParam as? String {
                returningString = rawString
                TempoUtils.Say(msg: "✅ customParameters[\(paramKey)] is valid: \(returningString ?? "")")
            } else {
                TempoUtils.Say(msg:"❌ customParameters[\(paramKey)] is not a String")
            }
        } else {
            TempoUtils.Say(msg:"❌ customParameters[\(paramKey)] is nil")
        }
        
        return returningString
    }
    
    /// Validates parameter Float values
    func getParameterAsFloat(paramKey: String, alParams: MAAdapterResponseParameters) -> Float {
        let rawParam = alParams.customParameters[CUST_CPM_FLR]
        var returningFloat: Float = 0
        if(rawParam != nil)
        {
            if let rawString = rawParam as? NSString {
                if let floatValue = Float(rawString as Substring) {
                    returningFloat = floatValue
                    TempoUtils.Say(msg:"✅ customParameters[\(CUST_CPM_FLR)] is valid: \(returningFloat)")
                } else {
                    TempoUtils.Say(msg:"❌ customParameters[\(CUST_CPM_FLR)] Substring does not cast to a Float")
                }
            } else {
                TempoUtils.Say(msg:"❌ customParameters[\(CUST_CPM_FLR)] is String")
            }
        }
        else
        {
            TempoUtils.Say(msg:"❌ customParameters[\(CUST_CPM_FLR)] is nil")
        }
        
        return returningFloat
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
