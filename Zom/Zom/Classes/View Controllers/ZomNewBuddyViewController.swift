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

open class ZomNewBuddyViewController: OTRNewBuddyViewController,
MFMessageComposeViewControllerDelegate, OTRNewBuddyViewControllerDelegate {

    @IBOutlet weak var xmppAddressTf: UITextField!
    @IBOutlet weak var usersXmppAddressLb: UILabel!
    @IBOutlet var scrollView: UIScrollView?
    @IBOutlet weak var whatsAppBt: UIButton!
    @IBOutlet weak var iMessageBt: UIButton!
    @IBOutlet weak var qrCodeBt: UIButton!
    
    private static let whatsAppLink = "whatsapp://send?text=%@"
    
    private var shareLink:String? = nil
    
    open static func addBuddyToDefaultAccount(_ navController: UINavigationController?) {
        let accounts = OTRAccountsManager.allAccounts()
        guard accounts.count > 0 else {
            return
        }

        let storyboard = UIStoryboard(name: "AddBuddy", bundle: Bundle.main)

        if (accounts.count == 1) {
            if let vc = storyboard.instantiateViewController(withIdentifier: "addNewBuddy") as? ZomNewBuddyViewController {
                vc.account = accounts[0]
                navController?.pushViewController(vc, animated: true)
            }
        } else {
            // More than one account
            var defaultAccount:OTRAccount? = nil
            if let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate {
                defaultAccount = appDelegate.getDefaultAccount()
            }

            if let defaultAccount = defaultAccount, accounts.contains( where: { element in
                return element.uniqueId == defaultAccount.uniqueId
            }) {
                // We have a default, use that
                if let vc = storyboard.instantiateViewController(withIdentifier: "addNewBuddy") as? ZomNewBuddyViewController {
                    vc.account = defaultAccount
                    navController?.pushViewController(vc, animated: true)
                }
            } else {
                if let vc = storyboard.instantiateInitialViewController() {
                    navController?.present(vc, animated: true, completion: nil)
                }
            }
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        // Override base class fields, so we can reuse some code from there.
        super.delegate = self
        super.accountNameTextField = xmppAddressTf

        // Set username to label, to help user understand, how a XMPP address looks like.
        usersXmppAddressLb.text = account.username

        // Create the share link.
        var types = Set<NSNumber>()
        types.insert(NSNumber(value: OTRFingerprintType.OTR.rawValue))
        account!.generateShareURL(withFingerprintTypes: types, completion: { (url, error) -> Void in
            if let url = url, error == nil {
                self.shareLink = url.absoluteString
            }
        })

        // Add Gesture Recognizer so the user can hide the keyboard again by tapping somewhere else
        // than the text field.
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGestureRecognizer)
        
        // Remove toolbar items. For an unkown reason, there would be a "+" there, otherwise.
        navigationItem.rightBarButtonItems = nil

        // Remove the title from the back button. It's rather long and moves this scene's title
        // to the right which the designers don't like.
        navigationController?.navigationBar.topItem?.title = ""

        // Only show WhatsApp button, if WhatsApp is installed.
        if let whatsAppUrl = URL(string: String(format: ZomNewBuddyViewController.whatsAppLink, "test")) {
            if !UIApplication.shared.canOpenURL(whatsAppUrl) {
                whatsAppBt.isHidden = true
            }
        } else {
            whatsAppBt.isHidden = true
        }

        // Only show iMessage button, if we can send SMS/iMessages. (Happens on simulators and on
        // iPads/iPods without iMessage configured.
        if !MFMessageComposeViewController.canSendText() {
            iMessageBt.isHidden = true
        }

        // Only show scan if we can actually scan QR codes.
        if !QRCodeReader.supportsMetadataObjectTypes([AVMetadataObject.ObjectType.qr]) {
            qrCodeBt.isHidden = true
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(didShowKeyboard(_:)),
                                               name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didHideKeyboard(_:)),
                                               name: .UIKeyboardDidHide, object: nil)
    }

    open override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardDidHide, object: nil)

        super.viewWillDisappear(animated)
    }

    // MARK: MFMessageComposeViewControllerDelegate
    
    open func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                           didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }

    // MARK: OTRNewBuddyViewController

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0 // We don't use the UITableView stuff from upstream.
    }
    
    open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    open override func populate(fromQRResult result: String!) {
        super.populate(fromQRResult: result)
        super.doneButtonPressed(self)
    }

    // MARK: OTRNewBuddyViewControllerDelegate

    open func controller(_ viewController: OTRNewBuddyViewController!, didAdd buddy: OTRBuddy!) {
        if let presenter = self.navigationController?.presentingViewController {
            presenter.dismiss(animated: true, completion: nil)
        } else {
            _ = self.navigationController?.popViewController(animated: true) // Pop back to friend list!
        }
        if let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate {
            appDelegate.splitViewCoordinator.enterConversationWithBuddy(buddy.uniqueId)
        }
    }

    // MARK: Keyboard handling

    /**
     Callback for NotificationCenter .UIKeyboardDidShow observer.

     Adjusts the bottom inset of the scrollView, so the user can always scroll the full scene.

     - parameter notification: Provided by NotificationCenter.
    */
    @objc func didShowKeyboard(_ notification: Notification) {
        if let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue {

            let bottom = keyboardFrame.cgRectValue.height
            scrollView?.contentInset.bottom = bottom
            scrollView?.scrollIndicatorInsets.bottom = bottom
        }
    }

    /**
     Callback for NotificationCenter .UIKeyboardDidHide observer.

     Adjusts the bottom inset of the scrollView, so the user can always scroll the full scene.

     - parameter notification: Provided by NotificationCenter.
     */
    @objc func didHideKeyboard(_ notification: Notification) {
        scrollView?.contentInset.bottom = 0
        scrollView?.scrollIndicatorInsets.bottom = 0
    }

    /**
     Dismisses the keyboard by ending editing on the only TextField we have here.

     - parameter sender: The sending UITapGestureRecognizer.
    */
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        xmppAddressTf.endEditing(true)
    }

    override open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)

        addFriend(textField)

        return false;
    }

    // MARK: Action callbacks

    /**
     Add friend with XMPP ID from xmppAddressTf

     - parameter sender: The button triggering this action.
     */
    @IBAction func addFriend(_ sender: Any) {
        if self.checkFields(), let friendId = xmppAddressTf.text,
            !friendId.contains("@") {
            xmppAddressTf.text = friendId + "@home.zom.im" // TODO: Hardcoded seems like a bad idea. How to fetch this from configuration?
        }

        super.doneButtonPressed(sender)
    }

    /**
     Send invite link directly to WhatsApp.
    */
    @IBAction func sendWhatsAppInvite() {
        if let shareLink = shareLink?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            let whatsAppUrl = URL(string: String(format: ZomNewBuddyViewController.whatsAppLink, shareLink))

            if let whatsAppUrl = whatsAppUrl, UIApplication.shared.canOpenURL(whatsAppUrl) {
                UIApplication.shared.openURL(whatsAppUrl)
            }
        }
    }

    /**
     Send invite link via SMS or iMessage. Will show system's message compose scene.
    */
    @IBAction func sendSmsInvite() {
        if let shareLink = shareLink {
            // Thanks to stupid apple bug we need to temporarily hack the appearance proxy for
            // navigation bars to have the MFMessageComposeViewController use the right color for
            // UINavigation bar. http://openradar.appspot.com/radar?id=6165359065300992
            let attrs = UIBarButtonItem.appearance().titleTextAttributes(for: .normal)
            UIBarButtonItem.appearance().setTitleTextAttributes(
                [NSAttributedStringKey.foregroundColor: GlobalTheme.shared.mainThemeColor],
                for: .normal)

            let composeVC = MFMessageComposeViewController()

            // Reset title attributes
            if let attrs = attrs {
                var oldAttrs = [NSAttributedStringKey:Any]()

                for key in attrs.keys {
                    oldAttrs[NSAttributedStringKey(key)] = attrs[key]
                }

                UIBarButtonItem.appearance().setTitleTextAttributes(oldAttrs, for: .normal)
            }

            composeVC.body = shareLink
            composeVC.messageComposeDelegate = self
            navigationController?.present(composeVC, animated: true, completion: nil)
        }
    }

    /**
     Show QR code scan camera view.

     - parameter sender: The button triggering this action.
    */
    @IBAction func scanQrCode(_ sender: Any) {
        super.qrButtonPressed(sender)
    }

    /**
     Show system's modal share dialog. This is used from the three-dots button ("...") AND
     the AirDrop button. There is no specific way to leverage AirDrop. It's all in the share
     dialog.

     Using two different buttons here for the same functionality, is just to get the user thinking
     about AirDrop.

     - parameter sender: The button triggering this action.
    */
    @IBAction func showShareDialog(_ sender: Any) {
        ShareController.shareAccount(self.account, sender: sender, viewController: self)
    }
}

