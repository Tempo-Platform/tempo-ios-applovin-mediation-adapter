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
        return "0.0.1"
    }
    
    public override func initialize(with parameters: MAAdapterInitializationParameters, completionHandler: @escaping (MAAdapterInitializationStatus, String?) -> Void) {
        self.interstitial = TempoInterstitial(parentViewController: nil, delegate: self)
        completionHandler(MAAdapterInitializationStatus.initializedUnknown, nil)
    }

    public func loadInterstitialAd(for parameters: MAAdapterResponseParameters, andNotify delegate: MAInterstitialAdapterDelegate) {
        self.delegate = delegate
        if self.interstitial == nil {
            self.interstitial = TempoInterstitial(parentViewController: nil, delegate: self)
        }
        if self.interstitial != nil {
            DispatchQueue.main.async {
                self.interstitial!.loadAd()
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
        self.interstitial!.updateViewController(parentViewController: viewController)
        self.interstitial!.showAd()
    }

    public func onAdFetchSucceeded() {
        self.delegate?.didLoadInterstitialAd()
        isAdReady = true
    }
    
    public func onAdFetchFailed() {
        self.delegate?.didFailToLoadInterstitialAdWithError(MAAdapterError.unspecified)
    }
    
    public func onAdClosed() {
        self.delegate?.didHideInterstitialAd()
        self.interstitial = nil
        isAdReady = false
    }
    
    public func onAdDisplayed() {
        self.delegate?.didDisplayInterstitialAd()
    }
}
