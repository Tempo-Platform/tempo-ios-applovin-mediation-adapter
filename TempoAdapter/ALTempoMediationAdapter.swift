import Foundation

import TempoSDK
import AppLovinSDK

@objc(ALTempoMediationAdapter)
public class ALTempoMediationAdapter  : ALMediationAdapter, MAInterstitialAdapter, TempoInterstitialListener {

    var interstitial: TempoInterstitial? = nil
    var isAdReady: Bool = false
    var delegate: MAInterstitialAdapterDelegate? = nil

    public override var sdkVersion : String {
        return String(TempoSDKVersionNumber)
    }

    public override var adapterVersion : String {
        return "0.0.2"
    }
    
    public override func initialize(with parameters: MAAdapterInitializationParameters, completionHandler: @escaping (MAAdapterInitializationStatus, String?) -> Void) {
        self.interstitial = TempoInterstitial(parentViewController: nil, delegate: self, appId: "PLACEHOLDER")
        completionHandler(MAAdapterInitializationStatus.initializedUnknown, nil)
    }

    public func loadInterstitialAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MAInterstitialAdapterDelegate) {
        print(parameters.customParameters)
        self.delegate = delegate
        if self.interstitial == nil {
            let appId: String = parameters.customParameters["app_id"] as! String
            self.interstitial = TempoInterstitial(parentViewController: nil, delegate: self, appId: appId)
        }
        if self.interstitial != nil {
            let appId: String = parameters.customParameters["app_id"] as! String
            let cpmFloor: Float = ((parameters.customParameters["cpm_floor"] ?? "0") as! NSString).floatValue
            DispatchQueue.main.async {
                self.interstitial!.loadAd(cpmFloor:cpmFloor)
              }
        } else {
            self.delegate?.didFailToLoadInterstitialAdWithError(MAAdapterError.notInitialized)
        }
    }
    
    public func showInterstitialAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MAInterstitialAdapterDelegate) {
        self.delegate = delegate
        if (!isAdReady) {
            self.delegate?.didFailToDisplayInterstitialAdWithError(MAAdapterError.adNotReady)
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
        self.delegate?.didLoadInterstitialAd()
        isAdReady = true
    }
    
    public func onAdFetchFailed() {
        self.delegate?.didFailToLoadInterstitialAdWithError(MAAdapterError.unspecified)  // TODO: more detail in errors here
    }
    
    public func onAdClosed() {
        self.delegate?.didHideInterstitialAd()
        self.interstitial = nil
        isAdReady = false
    }
    
    public func onAdDisplayed() {
        self.delegate?.didDisplayInterstitialAd()
    }

    public func onAdClicked() {
        self.delegate?.didClickInterstitialAd()
    }
}
