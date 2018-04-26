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

    @IBOutlet weak var xmppAddressTf: UITextField!
    @IBOutlet weak var usersXmppAddressLb: UILabel!
    @IBOutlet var scrollView: UIScrollView?

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
        super.delegate = self
        
        // Remove toolbar items
        //
        navigationItem.rightBarButtonItems = nil

        // Only show scan if we can actually scan QR codes
//        self.showButton(scanButtonItem, show:QRCodeReader.supportsMetadataObjectTypes([AVMetadataObject.ObjectType.qr]))

        accountNameTextField.resignFirstResponder()
        
        // Create the share link
        var types = Set<NSNumber>()
        types.insert(NSNumber(value: OTRFingerprintType.OTR.rawValue))
        account!.generateShareURL(withFingerprintTypes: types, completion: { (url, error) -> Void in
            if let url = url, error == nil {
                self.shareLink = url.absoluteString
//                self.showButton(self.shareSmsButtonItem, show:MFMessageComposeViewController.canSendText())
            } else {
//                self.showButton(self.shareSmsButtonItem, show:false)
            }
        })
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

    // MARK: UIKeyboardDidShow/-Hide
    
    @objc func didShowKeyboard(_ notification: Notification) {
//        if let userInfo = notification.userInfo, let sep = self.separator, let scroll = scrollView {
//            let keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.size
//            // If the whole tableview is not visible, scroll up so that ADVANCED
//            // view is at the top (i.e. the separator is just off screen!
//            //
//            if ((self.tableView.frame.origin.y + self.tableView.frame.height) > self.view.frame.height - keyboardSize.height) {
//                let separatorY = sep.frame.origin.y + sep.frame.size.height
//                scroll.setContentOffset(CGPoint(x: 0, y: separatorY), animated: true)
//            }
//        }
    }

    @objc func didHideKeyboard(_ notification: Notification) {
        if let scroll = self.scrollView {
            scroll.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        }
    }

    // MARK: MFMessageComposeViewControllerDelegate
    
    open func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }

    // MARK: OTRNewBuddyViewController

    open override func updateReturnButtons(_ textField: UITextField) {
        textField.returnKeyType = UIReturnKeyType.done
    }
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 // Dont show the display name field!
    }
    
    open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
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
    
    open override func populate(fromQRResult result: String!) {
        super.populate(fromQRResult: result)
        super.doneButtonPressed(self)
    }
    
    // MARK: Action callbacks

    @IBAction func addFriend() {
    }

    @IBAction func sendWhatsAppInvite() {
        if let shareLink = shareLink?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            let whatsAppUrl = URL(string: "whatsapp://send?text=\(shareLink)")

            if let whatsAppUrl = whatsAppUrl, UIApplication.shared.canOpenURL(whatsAppUrl) {
                UIApplication.shared.openURL(whatsAppUrl)
            }
        }
    }

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

    @IBAction func scanQrCode(_ sender: Any) {
        super.qrButtonPressed(sender)
    }

    @IBAction func showShareDialog(_ sender: Any) {
        ShareController.shareAccount(self.account, sender: sender, viewController: self)
    }
}

