//
//  ZomNewBuddyViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-12-04.
//
//

import UIKit
import ChatSecureCore

public class ZomNewBuddyViewController: OTRNewBuddyViewController, MFMessageComposeViewControllerDelegate, OTRNewBuddyViewControllerDelegate {
    @IBOutlet weak var addFriendsLabel: UILabel!
    @IBOutlet weak var gotInviteLabel: UILabel!
    @IBOutlet weak var tapInviteLabel: UILabel!
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var addToolbar: UIToolbar!
    @IBOutlet var shareSmsButtonItem: UIBarButtonItem!
    @IBOutlet var scanButtonItem: UIBarButtonItem!
    @IBOutlet var scrollView: UIScrollView!

    private var shareLink:String? = nil
    private var hasAdjustedButtonSize = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        super.delegate = self
        
        // Style
        if let appDelegate = UIApplication.sharedApplication().delegate as? ZomAppDelegate {
            addFriendsLabel.textColor = appDelegate.theme.mainThemeColor
            gotInviteLabel.textColor = appDelegate.theme.mainThemeColor
            separator.backgroundColor = appDelegate.theme.mainThemeColor
        }
        
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
                let contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0);
                scrollView.contentInset = contentInsets;
                scrollView.scrollIndicatorInsets = contentInsets;
            }
        }
    }

    func didHideKeyboard(notification: NSNotification) {
        let contentInsets = UIEdgeInsetsZero
        scrollView.contentInset = contentInsets;
        scrollView.scrollIndicatorInsets = contentInsets;
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if (!hasAdjustedButtonSize) {
            for item:UIBarButtonItem in self.addToolbar.items! {
                if (item.tag != 1) {
                    let w = self.addToolbar.frame.width / 4
                    item.width = w
                    if (w < 100) {
                        if let button = item.customView as? UIButton {
                            if let text = button.attributedTitleForState(UIControlState.Normal) {
                                button.setAttributedTitle(increaseFontSizeBy(text, pointSize: -8), forState: UIControlState.Normal)
                            }
                        }
                    }
                }
            }
            hasAdjustedButtonSize = true
        }
    }
    
    private func increaseFontSizeBy(text: NSAttributedString?, pointSize: CGFloat) -> NSAttributedString? {
        let fullRange = NSRange(location: 0, length: (text?.length)!)
        let mutableAttributeText = NSMutableAttributedString(attributedString: text!)
        mutableAttributeText.enumerateAttribute(NSFontAttributeName, inRange: fullRange, options: NSAttributedStringEnumerationOptions.LongestEffectiveRangeNotRequired) {
            (attribute: AnyObject?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
            if let attributeFont = attribute as? UIFont {
                let newPointSize = attributeFont.pointSize + pointSize
                let scaledFont = UIFont(descriptor: attributeFont.fontDescriptor(), size: newPointSize)
                mutableAttributeText.addAttribute(NSFontAttributeName, value: scaledFont, range: range)
            }
        }
        return mutableAttributeText
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
        // TODO - enter conversation with newly added buddy
        self.navigationController?.popViewControllerAnimated(true)
        if let appDelegate = UIApplication.sharedApplication().delegate as? OTRAppDelegate {
            appDelegate.splitViewCoordinator.enterConversationWithBuddy(buddy.uniqueId)
        }
    }
    
    public override func populateFromQRResult(result: String!) {
        super.populateFromQRResult(result)
        super.doneButtonPressed(self)
    }
}
 
