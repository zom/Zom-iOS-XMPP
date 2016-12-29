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

public class ZomNewBuddyViewController: OTRNewBuddyViewController, MFMessageComposeViewControllerDelegate, OTRNewBuddyViewControllerDelegate {
    @IBOutlet weak var addFriendsLabel: UILabel!
    @IBOutlet weak var gotInviteLabel: UILabel!
    @IBOutlet weak var tapInviteLabel: UILabel!
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var addToolbar: UIToolbar!
    @IBOutlet var shareSmsButtonItem: UIBarButtonItem!
    @IBOutlet var shareButtonItem: UIBarButtonItem!
    @IBOutlet var scanButtonItem: UIBarButtonItem!
    @IBOutlet var scrollView: UIScrollView!

    private var shareLink:String? = nil
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        super.delegate = self
        
        // Style
        if let appDelegate = UIApplication.sharedApplication().delegate as? ZomAppDelegate {
            addFriendsLabel.textColor = appDelegate.theme.mainThemeColor
            gotInviteLabel.textColor = appDelegate.theme.mainThemeColor
            separator.backgroundColor = appDelegate.theme.mainThemeColor
        }
        
        if let button = shareSmsButtonItem.customView as? UIButton {
            let image = self.textToImage(NSString.fa_stringForFontAwesomeIcon(FAIcon.FAPaperPlaneO), size: 30)
            button.setImage(image, forState: .Normal)
            button.titleLabel!.numberOfLines = 0
            button.titleLabel!.adjustsFontSizeToFitWidth = true
            button.titleLabel!.lineBreakMode = NSLineBreakMode.ByWordWrapping
        }
        if let button = shareButtonItem.customView as? UIButton {
            let image = self.textToImage(NSString.fa_stringForFontAwesomeIcon(FAIcon.FAShareSquareO), size: 30)
            button.setImage(image, forState: .Normal)
            button.titleLabel!.numberOfLines = 0
            button.titleLabel!.adjustsFontSizeToFitWidth = true
            button.titleLabel!.lineBreakMode = NSLineBreakMode.ByWordWrapping
        }
        if let button = scanButtonItem.customView as? UIButton {
            let image = self.textToImage(NSString.fa_stringForFontAwesomeIcon(FAIcon.FACamera), size: 30)
            button.setImage(image, forState: .Normal)
            button.titleLabel!.numberOfLines = 0
            button.titleLabel!.adjustsFontSizeToFitWidth = true
            button.titleLabel!.lineBreakMode = NSLineBreakMode.ByWordWrapping
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
        types.insert(NSNumber(int: OTRFingerprintType.OTR.rawValue))
        self.account!.generateShareURLWithFingerprintTypes(types, completion: { (url, error) -> Void in
            if (url != nil && error == nil) {
                self.shareLink = url.absoluteString
                self.showButton(self.shareSmsButtonItem, show:MFMessageComposeViewController.canSendText())
            } else {
                self.showButton(self.shareSmsButtonItem, show:false)
            }
        })
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didShowKeyboard(_:)), name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didHideKeyboard(_:)), name: UIKeyboardDidHideNotification, object: nil)
    }

    public override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidHideNotification, object: nil)
        super.viewWillDisappear(animated)
    }
    
    func didShowKeyboard(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardSize: CGSize = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue().size {
                // If the whole tableview is not visible, scroll up so that ADVANCED
                // view is at the top (i.e. the separator is just off screen!
                //
                if ((self.tableView.frame.origin.y + self.tableView.frame.height) > self.view.frame.height - keyboardSize.height) {
                    let separatorY = self.separator.frame.origin.y + self.separator.frame.size.height
                    scrollView.setContentOffset(CGPointMake(0, separatorY), animated: true)
                }
            }
        }
    }

    func didHideKeyboard(notification: NSNotification) {
        scrollView.setContentOffset(CGPointMake(0, 0), animated: true)
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
    
    public func showButton(item:UIBarButtonItem, show:Bool) {
        var toolbarButtons = addToolbar.items
        if (!show) {
            if let index = toolbarButtons!.indexOf(item) {
                toolbarButtons!.removeAtIndex(index)
            }
        } else {
            if (toolbarButtons!.contains(item) == false) {
                toolbarButtons!.insert(item, atIndex: 1) // After the flexible space!
            }
        }
        addToolbar.items = toolbarButtons
        adjustButtons()
    }

    @IBAction func shareSmsButtonPressedWithSender(sender: AnyObject) {
        if (self.shareLink != nil) {
            let messageComposeViewController:MFMessageComposeViewController = MFMessageComposeViewController()
            messageComposeViewController.body = self.shareLink
            messageComposeViewController.messageComposeDelegate = self
            self.navigationController!.presentViewController(messageComposeViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func shareButtonPressedWithSender(sender: AnyObject) {
        ShareController.shareAccount(self.account!, sender: sender, viewController: self)
    }

    @IBAction func scanButtonPressedWithSender(sender: AnyObject) {
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
    
    public func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    public override func updateReturnButtons(textField: UITextField!) {
        textField.returnKeyType = UIReturnKeyType.Done
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 // Dont show the display name field!
    }
    
    public override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    public func controller(viewController: OTRNewBuddyViewController!, didAddBuddy buddy: OTRBuddy!) {
        self.navigationController?.popViewControllerAnimated(true) // Pop back to friend list!
    }
    
    public override func populateFromQRResult(result: String!) {
        super.populateFromQRResult(result)
        super.doneButtonPressed(self)
    }
    
    func textToImage(text: NSString, size: CGFloat) -> UIImage{
        
        // Setup the font specific variables
        let textColor = UIColor.darkTextColor()
        let textFont = UIFont(name: kFontAwesomeFont, size: 20)!
        
        // Setup the image context using the passed image
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), false, 0)
        
        // Setup the font attributes that will be later used to dictate how the text should be drawn
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
            ]
        
        // Create a point within the space that is as big as the image
        let rect = CGRectMake(0, 0, size, size)
        
        // Draw the text into an image
        text.drawInRect(rect, withAttributes: textFontAttributes)
        
        // Create a new image out of the images we have created
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the context now that we have the image we need
        UIGraphicsEndImageContext()
        
        //Pass the image back up to the caller
        return newImage!
    }
}
 
