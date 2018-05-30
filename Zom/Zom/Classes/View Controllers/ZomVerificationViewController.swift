//
//  ZomVerificationViewController.swift
//  Zom
//
//  Created by Benjamin Erhart on 22.02.18.
//

/**
 Scene for verification of the latest fingerprint of a buddy.

 Use the `convenience init(buddy: OTRBuddy)` or set `self.buddy` immediately after init!
 
 The first OMEMO key exists, which has trust level `.untrustedNew`, will be used, otherwise the
 first OTR fingerprint with that trust level will be used.
*/
class ZomVerificationViewController: ZomFingerprintBaseViewController {

    @IBOutlet weak var infoLb: UILabel!
    @IBOutlet weak var fingerprintLb: UILabel!
    @IBOutlet weak var matchBt: UIButton!
    @IBOutlet weak var noMatchBt: UIButton!
    @IBOutlet weak var viewAllBt: UIButton!
    @IBOutlet weak var overlayContainer: UIView!
    @IBOutlet weak var successCheckmarkLb: UILabel!
    @IBOutlet weak var trustedLb: UILabel!

    private var fingerprintContainer: NSObject?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let titleView = navigationItem.titleView as? OTRTitleSubtitleView {
            titleView.titleLabel.text = NSLocalizedString("Compare Codes",
                                                          comment: "Title for code verification scene")
        }

        infoLb.text = NSLocalizedString(
            "Make sure this code matches your friend's latest Zom code on their phone.",
            comment: "Description for code verification scene")

        noMatchBt.titleLabel?.text = NSLocalizedString("Code Doesn't Match",
                                                       comment: "Verification scene button text")

        viewAllBt.titleLabel?.text = NSLocalizedString("View All", comment: "Verification scene button text")

        trustedLb.text = NSLocalizedString("Trusted", comment: "Verification scene success text")
    }

    /**
     Callback, when all OMEMO devices and all OTR fingerprints of our buddy are loaded.

     Show the first `.untrustedNew` OMEMO device key fingerprint or the first `.untrustedNew`
     OTR fingerprint if no OMEMO device found.
    */
    override func fingerprintsLoaded() {
        ZomFingerprintBaseViewController.setBadge(badgeLb, ok: countKeys().untrusted < 1)

        if let device = omemoDevices
            .filter({ (device) -> Bool in return device.trustLevel == .untrustedNew })
            .first
        {
            fingerprintContainer = device
            setFingerprint(device.humanReadableFingerprint)
        }
        else if let fingerprint = otrFingerprints
            .filter({ (fingerprint) -> Bool in return fingerprint.trustLevel == .untrustedNew })
            .first
        {
            fingerprintContainer = fingerprint
            setFingerprint((fingerprint.fingerprint as NSData).humanReadableFingerprint())
        }
        else {
            setFingerprintError()
        }
    }

    /**
     Callback, when user hits the "match" button.

     Sets the trust level of the OMEMO device key resp. the OTR fingerprint to `.trustedUser` and
     stores it.

     Will fade-in a green overlay displaying a checkmark and the text "Trusted".

     When animation is finished, dismisses this view controller.
    */
    @IBAction func match() {
        matchBt.isHighlighted = true

        if let device = fingerprintContainer as? OMEMODevice {
            device.trustLevel = .trustedUser
            ZomFingerprintBaseViewController.store(device)
        }
        else if let fingerprint = fingerprintContainer as? OTRFingerprint {
            fingerprint.trustLevel = .trustedUser
            ZomFingerprintBaseViewController.store(fingerprint)
        }

        if let window = view.window {
            overlayContainer.frame = window.frame
            window.addSubview(overlayContainer)
            UIView.transition(
                with: overlayContainer,
                duration: 0.5,
                options: .transitionCrossDissolve,
                animations: {
                    self.overlayContainer.isHidden = false
                },
                completion: { (_) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.dismiss(animated: true) {
                            self.overlayContainer.removeFromSuperview()
                            self.overlayContainer.isHidden = true
                        }
                    }
                })
        }
    }

    /**
     Callback, when user hits the "Code Doesn't Match" button.

     Shows an alert which explains, that there could be other fingerprints. Sends the user to
     the `ZomVerificationDetailViewController` on user interaction.

     Then remove this view controller from the view hirarchy.
    */
    @IBAction func noMatch() {
        let message = NSLocalizedString("View all Zom codes for \(buddyName()) to find a match.",
            comment: "Verification scene alert message")

        let alert = UIAlertController(
            title: NSLocalizedString("Code Doesn't Match", comment: "Verification scene alert title text"),
            message: message,
            preferredStyle: .alert)

        alert.addAction(UIAlertAction(
            title: NSLocalizedString("View All Codes", comment: "Verification scene alert title text"),
            style: .default, handler: { (action) in
                DispatchQueue.main.async {
                    self.viewAll()
                }
            }))

        present(alert, animated: true)
    }

    /**
     Sends the user to the `ZomVerificationDetailViewController` on user interaction.

     Then remove this view controller from the view hirarchy.
    */
    @IBAction func viewAll() {
        let vdvc = ZomVerificationDetailViewController(buddy: buddy, omemoDevices: omemoDevices,
                                                       otrFingerprints: otrFingerprints)

        if let nc = navigationController {
            nc.pushViewController(vdvc, animated: true)
            nc.viewControllers.remove(at: nc.viewControllers.count - 2)
        }
        else {
            present(vdvc, animated: true)
        }
    }

    /**
     Set text content of `self.fingerprintLb`.

     Copious amounts of letter and line spacing are used.

     - parameter text: Falls back to an error message, if nil.
    */
    private func setFingerprint(_ text: String?) {
        ZomFingerprintBaseViewController.setFingerprint(fingerprintLb, text: text,
                                                        alignment: .center, bold: false)
    }

    /**
     Set an error message instead of a fingerprint to `self.fingerprintLb`.
    */
    private func setFingerprintError() {
        setFingerprint(nil)
    }
}
