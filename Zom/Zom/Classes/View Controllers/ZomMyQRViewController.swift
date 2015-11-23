//
//  ZomMyQRViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-23.
//
//

import UIKit
import ChatSecureCore

public class ZomMyQRViewController: UIViewController {

    public var qrString: String? = nil

    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var inviteLinkLabel: UILabel!
    @IBOutlet weak var shareLinkButton: UIButton!
    @IBOutlet weak var shareSMSButton: UIButton!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.qrImageView.contentMode = UIViewContentMode.ScaleAspectFit
        self.qrImageView.layer.magnificationFilter = kCAFilterNearest
        self.qrImageView.layer.shouldRasterize = true
        self.view.backgroundColor = ZomTheme().lightThemeColor
        self.inviteLinkLabel.text = self.qrString
        self.shareSMSButton.setTitle(OTRLanguageManager.translatedString("Invite SMS"), forState: UIControlState.Normal)
        self.shareLinkButton.setTitle(OTRLanguageManager.translatedString("Share Invite Link"), forState: UIControlState.Normal)
        if (!MFMessageComposeViewController.canSendText()) {
            self.shareSMSButton.hidden = true
        }
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.qrImageView.image = self.imageForQRString(self.qrString, size:self.qrImageView.frame.size)
    }
    
    func imageForQRString(qrString:String?, size:CGSize) -> UIImage? {
        if (qrString == nil) {
            return nil
        }
        
        let writer:ZXMultiFormatWriter = ZXMultiFormatWriter()
        let result:ZXBitMatrix? = try? writer.encode(qrString, format: kBarcodeFormatQRCode, width: Int32(size.width), height: Int32(size.height))
        if (result != nil) {
            return UIImage(CGImage: ZXImage(matrix: result, onColor: UIColor.blackColor().CGColor, offColor: ZomTheme().lightThemeColor.CGColor).cgimage)
        }
        return nil
    }

}