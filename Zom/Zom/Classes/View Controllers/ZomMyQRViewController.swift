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

    var qrString: String? = nil

    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var inviteLinkLabel: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.qrImageView.contentMode = UIViewContentMode.ScaleAspectFit
        self.qrImageView.layer.magnificationFilter = kCAFilterNearest
        self.qrImageView.layer.shouldRasterize = true
        self.view.backgroundColor = ZomTheme().lightThemeColor
        updateUI()
    }
    
    public func setQRString(qrString:String?) {
        self.qrString = qrString
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

}
