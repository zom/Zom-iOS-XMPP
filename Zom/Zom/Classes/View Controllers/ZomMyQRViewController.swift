//
//  ZomMyQRViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-23.
//
//

import UIKit
import ChatSecureCore
import ZXingObjC

open class ZomMyQRViewController: UIViewController, OTRAttachmentPickerDelegate {

    var account: OTRAccount? {
        didSet {
            onAccountUpdated()
        }
    }
    var qrString: String? = nil

    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var inviteLinkLabel: UILabel!
    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.qrImageView.contentMode = UIViewContentMode.scaleAspectFit
        self.qrImageView.layer.magnificationFilter = kCAFilterNearest
        self.qrImageView.layer.shouldRasterize = true
        self.view.backgroundColor = ZomTheme().lightThemeColor
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapAvatarImage(_:)))
        self.avatarImageView.isUserInteractionEnabled = true
        self.avatarImageView.addGestureRecognizer(tapRecognizer)
        updateUI()
    }
    
    private func onAccountUpdated() {
        self.qrString = nil
        if (account != nil) {
            var types = Set<NSNumber>()
            types.insert(NSNumber(value: OTRFingerprintType.OTR.rawValue))
            account!.generateShareURL(withFingerprintTypes: types, completion: { (url, error) -> Void in
                if (url != nil && error == nil) {
                    self.qrString = url?.absoluteString
                }
            })
        }
        if (self.isViewLoaded) {
            updateUI()
        }
    }
    
    open override func viewDidLayoutSubviews() {
        updateUI()
    }
    
    func updateUI() {
        if (self.qrString != nil) {
            self.inviteLinkLabel.text = self.qrString
            self.activityIndicator.stopAnimating()
            self.qrImageView.image = self.imageForQRString(self.qrString, size:self.qrImageView.frame.size)
        } else {
            self.inviteLinkLabel.text = ""
            self.qrImageView.image = nil
            self.activityIndicator.startAnimating()
        }
        if (self.account != nil) {
            self.accountLabel.text = self.account?.username
            setDefaultAvatar()
        } else {
            self.accountLabel.text = nil
            setDefaultAvatar()
        }
    }
    
    func setDefaultAvatar() {
        self.avatarImageView.image = UIImage(named: "onboarding_avatar", in: OTRAssets.resourcesBundle, compatibleWith: nil)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    func imageForQRString(_ qrString:String?, size:CGSize) -> UIImage? {
        if (qrString == nil) {
            return nil
        }
        
        let writer:ZXMultiFormatWriter = ZXMultiFormatWriter()
        let hints:ZXEncodeHints = ZXEncodeHints()
        hints.margin = 0
        let result:ZXBitMatrix? = try? writer.encode(qrString, format: kBarcodeFormatQRCode, width: Int32(size.width), height: Int32(size.height), hints: hints)
        if (result != nil) {
            return UIImage(cgImage: ZXImage(matrix: result, on: UIColor.black.cgColor, offColor: ZomTheme().lightThemeColor.cgColor).cgimage)
        }
        return nil
    }
    
    func didTapAvatarImage(_ sender: UITapGestureRecognizer? = nil) {
        if let parentViewController = self.tabBarController?.parent {
            let photoPicker = OTRAttachmentPicker(parentViewController: parentViewController, delegate: self)
            photoPicker.showAlertController(fromSourceView: self.avatarImageView, withCompletion: nil)
        }
    }
    
    open func attachmentPicker(_ attachmentPicker: OTRAttachmentPicker!, gotVideoURL videoURL: URL!) {
    }
    
    open func attachmentPicker(_ attachmentPicker: OTRAttachmentPicker!, gotPhoto photo: UIImage!, withInfo info: [AnyHashable: Any]!) {
    }
}
