//
//  ZomNewBuddyViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-12-04.
//
//

import UIKit
import ChatSecureCore
import BButton
import QRCodeReaderViewController
import AVFoundation

open class ZomNewBuddyViewController: OTRNewBuddyViewController, MFMessageComposeViewControllerDelegate, OTRNewBuddyViewControllerDelegate {
    @IBOutlet weak var addFriendsLabel: UILabel?
    @IBOutlet weak var gotInviteLabel: UILabel?
    @IBOutlet weak var tapInviteLabel: UILabel?
    @IBOutlet weak var separator: UIView?
    @IBOutlet weak var addToolbar: UIToolbar!
    @IBOutlet var shareSmsButtonItem: UIBarButtonItem!
    @IBOutlet var shareButtonItem: UIBarButtonItem!
    @IBOutlet var scanButtonItem: UIBarButtonItem!
    @IBOutlet var scrollView: UIScrollView?
    @IBOutlet var imageView: UIImageView?

    private var shareLink:String? = nil
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        super.delegate = self
        
        // Style
        if let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate {
            addFriendsLabel?.textColor = appDelegate.theme.mainThemeColor
            gotInviteLabel?.textColor = appDelegate.theme.mainThemeColor
            separator?.backgroundColor = appDelegate.theme.mainThemeColor
        }
        
        if let button = shareSmsButtonItem.customView as? UIButton {
            let image = self.textToImage(NSString.fa_string(forFontAwesomeIcon: FAIcon.FAPaperPlaneO) as NSString, size: 30)
            button.setImage(image, for: UIControlState())
            button.titleLabel!.numberOfLines = 0
            button.titleLabel!.adjustsFontSizeToFitWidth = true
            button.titleLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
        }
        if let button = shareButtonItem.customView as? UIButton {
            let image = self.textToImage(NSString.fa_string(forFontAwesomeIcon: FAIcon.FAShareSquareO) as NSString, size: 30)
            button.setImage(image, for: UIControlState())
            button.titleLabel!.numberOfLines = 0
            button.titleLabel!.adjustsFontSizeToFitWidth = true
            button.titleLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
        }
        if let button = scanButtonItem.customView as? UIButton {
            let image = self.textToImage(NSString.fa_string(forFontAwesomeIcon: FAIcon.FACamera) as NSString, size: 30)
            button.setImage(image, for: UIControlState())
            button.titleLabel!.numberOfLines = 0
            button.titleLabel!.adjustsFontSizeToFitWidth = true
            button.titleLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
        }
        
        adjustButtons()
        
        // Remove toolbar items
        //
        self.navigationItem.rightBarButtonItems = nil
        
        // Hide SMS button, at least until we have a share link
        self.showButton(shareSmsButtonItem, show:false)

        // Only show scan if we can actually scan QR codes
        self.showButton(scanButtonItem, show:QRCodeReader.supportsMetadataObjectTypes([AVMetadataObjectTypeQRCode]))
        
        self.accountNameTextField.resignFirstResponder()
        
        // Create the share link
        var types = Set<NSNumber>()
        types.insert(NSNumber(value: OTRFingerprintType.OTR.rawValue))
        self.account!.generateShareURL(withFingerprintTypes: types, completion: { (url, error) -> Void in
            if (url != nil && error == nil) {
                self.shareLink = url?.absoluteString
                self.showButton(self.shareSmsButtonItem, show:MFMessageComposeViewController.canSendText())
            } else {
                self.showButton(self.shareSmsButtonItem, show:false)
            }
        })
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(didShowKeyboard(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didHideKeyboard(_:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
    }

    open override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        super.viewWillDisappear(animated)
    }
    
    func didShowKeyboard(_ notification: Notification) {
        
        if let userInfo = notification.userInfo, let sep = self.separator, let scroll = self.scrollView {
            let keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.size
            // If the whole tableview is not visible, scroll up so that ADVANCED
            // view is at the top (i.e. the separator is just off screen!
            //
            if ((self.tableView.frame.origin.y + self.tableView.frame.height) > self.view.frame.height - keyboardSize.height) {
                let separatorY = sep.frame.origin.y + sep.frame.size.height
                scroll.setContentOffset(CGPoint(x: 0, y: separatorY), animated: true)
            }
        }
    }

    func didHideKeyboard(_ notification: Notification) {
        if let scroll = self.scrollView {
            scroll.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        }
    }

    private func adjustButtons() {
        let numButtons = self.addToolbar.items!.count - 2
        for item:UIBarButtonItem in self.addToolbar.items! {
            if (item.tag != 1) {
                let w = (self.view.frame.width - 40) / CGFloat(numButtons)
                item.width = w
                if let button = item.customView as? UIButton {
                    button.frame.size.width = w
                }
//                if (w < 100) {
//                    if let button = item.customView as? UIButton {
//                        if let font = button.titleLabel?.font {
//                            button.titleLabel?.font = font.fontWithSize(font.pointSize - 6)
//                        }
//                    }
//                }
            }
        }
        self.addToolbar.setNeedsUpdateConstraints()
        self.addToolbar.setNeedsLayout()
    }
    
    open func showButton(_ item:UIBarButtonItem, show:Bool) {
        var toolbarButtons = addToolbar.items
        if (!show) {
            if let index = toolbarButtons!.index(of: item) {
                toolbarButtons!.remove(at: index)
            }
        } else {
            if (toolbarButtons!.contains(item) == false) {
                toolbarButtons!.insert(item, at: 1) // After the flexible space!
            }
        }
        addToolbar.items = toolbarButtons
        adjustButtons()
    }

    @IBAction func shareSmsButtonPressedWithSender(_ sender: AnyObject) {
        if (self.shareLink != nil) {
            let messageComposeViewController:MFMessageComposeViewController = MFMessageComposeViewController()
            messageComposeViewController.body = self.shareLink
            messageComposeViewController.messageComposeDelegate = self
            self.navigationController!.present(messageComposeViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func shareButtonPressedWithSender(_ sender: AnyObject) {
        ShareController.shareAccount(self.account!, sender: sender, viewController: self)
    }

    @IBAction func scanButtonPressedWithSender(_ sender: AnyObject) {
//        if (!QRCodeReader.supportsMetadataObjectTypes([AVMetadataObjectTypeQRCode])) {
//                    let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
//                    if (status == AVAuthorizationStatus.NotDetermined) {
//                        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (enabled) in
//                            if (enabled) {
//                                super.qrButtonPressed(sender)
//                            }
//                        })
//                    }
//        } else {
            super.qrButtonPressed(sender)
//        }
    }
    
    open func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    open override func updateReturnButtons(_ textField: UITextField!) {
        textField.returnKeyType = UIReturnKeyType.done
    }
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 // Dont show the display name field!
    }
    
    open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    open func controller(_ viewController: OTRNewBuddyViewController!, didAdd buddy: OTRBuddy!) {
       _ = self.navigationController?.popViewController(animated: true) // Pop back to friend list!
    }
    
    open override func populate(fromQRResult result: String!) {
        super.populate(fromQRResult: result)
        super.doneButtonPressed(self)
    }
    
    func textToImage(_ text: NSString, size: CGFloat) -> UIImage{
        
        // Setup the font specific variables
        let textColor = UIColor.darkText
        let textFont = UIFont(name: kFontAwesomeFont, size: 20)!
        
        // Setup the image context using the passed image
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0)
        
        // Setup the font attributes that will be later used to dictate how the text should be drawn
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
            ]
        
        // Create a point within the space that is as big as the image
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        
        // Draw the text into an image
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        // Create a new image out of the images we have created
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the context now that we have the image we need
        UIGraphicsEndImageContext()
        
        //Pass the image back up to the caller
        return newImage!
    }
    
    open static func addBuddyToDefaultAccount(_ navController:UINavigationController?) {
        guard let accounts = OTRAccountsManager.allAccountsAbleToAddBuddies(), accounts.count > 0 else {
            return
        }

        let storyboard = UIStoryboard(name: "AddBuddy", bundle: Bundle.main)
        var vc:UIViewController? = nil
        if (accounts.count == 1) {
            vc = storyboard.instantiateViewController(withIdentifier: "addNewBuddy")
            (vc as! ZomNewBuddyViewController).account = accounts[0] as? OTRAccount
            navController?.pushViewController(vc!, animated: true)
        } else {
            // More than one account
            var defaultAccount:OTRAccount? = nil
            if let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate {
                defaultAccount = appDelegate.getDefaultAccount()
            }
            if (defaultAccount != nil && accounts.contains( where: { element in
                if let a:OTRAccount = element as? OTRAccount {
                    return a.uniqueId == defaultAccount!.uniqueId
                }
                return false
            })) {
                // We have a default, use that
                vc = storyboard.instantiateViewController(withIdentifier: "addNewBuddy")
                (vc as! ZomNewBuddyViewController).account = defaultAccount!
                navController?.pushViewController(vc!, animated: true)
            } else {
                vc = storyboard.instantiateInitialViewController()
                navController?.present(vc!, animated: true, completion: nil)
            }
        }
    }
}

