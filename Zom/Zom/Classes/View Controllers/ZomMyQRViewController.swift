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

public class ZomMyQRViewController: UIViewController, OTRAttachmentPickerDelegate {

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
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.qrImageView.contentMode = UIViewContentMode.ScaleAspectFit
        self.qrImageView.layer.magnificationFilter = kCAFilterNearest
        self.qrImageView.layer.shouldRasterize = true
        self.view.backgroundColor = ZomTheme().lightThemeColor
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapAvatarImage(_:)))
        self.avatarImageView.userInteractionEnabled = true
        self.avatarImageView.addGestureRecognizer(tapRecognizer)
        updateUI()
    }
    
    private func onAccountUpdated() {
        self.qrString = nil
        if (account != nil) {
            var types = Set<NSNumber>()
            types.insert(NSNumber(int: OTRFingerprintType.OTR.rawValue))
            account!.generateShareURLWithFingerprintTypes(types, completion: { (url, error) -> Void in
                if (url != nil && error == nil) {
                    self.qrString = url.absoluteString
                }
            })
        }
        if (self.isViewLoaded()) {
            updateUI()
        }
    }
    
    public override func viewDidLayoutSubviews() {
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
        self.avatarImageView.image = UIImage(named: "onboarding_avatar", inBundle: OTRAssets.resourcesBundle(), compatibleWithTraitCollection: nil)
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    func imageForQRString(qrString:String?, size:CGSize) -> UIImage? {
        if (qrString == nil) {
            return nil
        }
        
        let writer:ZXMultiFormatWriter = ZXMultiFormatWriter()
        let hints:ZXEncodeHints = ZXEncodeHints()
        hints.margin = 0
        let result:ZXBitMatrix? = try? writer.encode(qrString, format: kBarcodeFormatQRCode, width: Int32(size.width), height: Int32(size.height), hints: hints)
        if (result != nil) {
            return UIImage(CGImage: ZXImage(matrix: result, onColor: UIColor.blackColor().CGColor, offColor: ZomTheme().lightThemeColor.CGColor).cgimage)
        }
        return nil
    }
    
    func didTapAvatarImage(sender: UITapGestureRecognizer? = nil) {
        let photoPicker = OTRAttachmentPicker(parentViewController: self.tabBarController?.parentViewController, delegate: self)
        photoPicker.showAlertControllerFromSourceView(self.avatarImageView, withCompletion: nil)
    }
    
    public func attachmentPicker(attachmentPicker: OTRAttachmentPicker!, gotVideoURL videoURL: NSURL!) {
    }
    
    public func attachmentPicker(attachmentPicker: OTRAttachmentPicker!, gotPhoto photo: UIImage!, withInfo info: [NSObject : AnyObject]!) {
    }
}
