//
//  ZomImportManager.swift
//  Zom
//
//  Created by N-Pex on 2017-11-03.
//

import Foundation
import ChatSecureCore

@objc public class ZomImportManager: NSObject, OTRConversationViewControllerDelegate, OTRComposeViewControllerDelegate {
    
    @objc public static let shared = ZomImportManager()
    
    private var fileUrl:URL?
    private var account:OTRAccount?
    private var modalNavigationController:UINavigationController?
    private var viewController:OTRMessagesViewController?
    private var observerContext = 0
    
    public func controller(_ viewController: OTRComposeViewController, didSelectBuddies buddies: [String]?, accountId: String?, name: String?) {
        viewController.dismiss(animated: true, completion: nil)
        guard let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate, let buddies = buddies, buddies.count > 0, let accountId = accountId else {
            return
        }
        if buddies.count == 1, let first = buddies.first {
            appDelegate.splitViewCoordinator.enterConversationWithBuddy(first)
        } else {
            appDelegate.splitViewCoordinator.enterConversationWithBuddies(buddies, accountKey: accountId, name: name)
        }
        OTRDatabaseManager.shared.readOnlyDatabaseConnection?.read({ (transaction) in
            self.account = OTRAccount.fetchObject(withUniqueID: accountId, transaction: transaction)
        })
        guard self.account != nil else { return }
        sendWhenOnline()
    }
    
    public func controllerDidCancel(_ viewController: OTRComposeViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    public func conversationViewController(_ conversationViewController: OTRConversationViewController!, didSelectThread threadOwner: OTRThreadOwner!) {
        conversationViewController.dismiss(animated: true, completion: nil)
        guard let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate else {
            return
        }
        OTRDatabaseManager.shared.readOnlyDatabaseConnection?.read({ (transaction) in
            self.account = threadOwner.account(with: transaction)
        })
        guard self.account != nil else { return }
        appDelegate.splitViewCoordinator.enterConversationWithThread(threadOwner, sender: self)
        sendWhenOnline()
    }
    
    public func conversationViewController(_ conversationViewController: OTRConversationViewController!, didSelectCompose sender: Any!) {
        guard let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate else {
            return
        }
        if let nav = modalNavigationController {
            let composeViewController = appDelegate.theme.composeViewController()
            if let composeViewController = composeViewController as? OTRComposeViewController {
                composeViewController.delegate = self
            }
            nav.pushViewController(composeViewController, animated: true)
        }
    }
    
    @objc open func didCancelImport(_ sender: Any) {
        if let account = self.account, let xmpp = OTRProtocolManager.shared.protocol(for: account) as? OTRXMPPManager {
            xmpp.removeObserver(self, forKeyPath: "connectionStatus", context: &observerContext)
        }
        if let navController = modalNavigationController {
            navController.dismiss(animated: true, completion: nil)
        }
    }
            
    @objc public func handleImport(url:URL?) -> Bool {
        guard let url = url, let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate else {
            return false
        }
        
        self.fileUrl = url
        self.viewController = appDelegate.messagesViewController

        let vc = appDelegate.theme.conversationViewController()
        if let conversationViewController = vc as? OTRConversationViewController {
            conversationViewController.delegate = self
            let _ = conversationViewController.view
            //vc.navigationItem.rightBarButtonItem = nil
            //vc.navigationItem.rightBarButtonItem = vc.navigationItem.leftBarButtonItem
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.didCancelImport(_:)))
            let barButtonAddChat = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(self.conversationViewController(_:didSelectCompose:)))
            vc.navigationItem.rightBarButtonItem = barButtonAddChat
        }
        modalNavigationController = UINavigationController(rootViewController: vc)
        if let modalNavigationController = modalNavigationController {
            modalNavigationController.modalPresentationStyle = .formSheet
            appDelegate.splitViewCoordinator.splitViewController?.present(modalNavigationController, animated: true, completion: nil)
            return true
        }
        return false
    }
    
    func sendWhenOnline() {
        guard let account = self.account, let url = self.fileUrl, let vc = self.viewController else { return }
        if OTRProtocolManager.shared.isAccountConnected(account) {
            vc.sendAudioFileURL(url)
        } else {
            if let xmpp = OTRProtocolManager.shared.protocol(for: account) as? OTRXMPPManager {
                xmpp.addObserver(self, forKeyPath: "connectionStatus", options: [.new,.old], context: &observerContext)
                OTRProtocolManager.shared.loginAccount(account)
            }
            }
        }

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        if let account=self.account, let url = self.fileUrl, let vc = self.viewController, OTRProtocolManager.shared.isAccountConnected(account) {

            // Stop observing
            if let xmpp = OTRProtocolManager.shared.protocol(for: account) as? OTRXMPPManager {
                xmpp.removeObserver(self, forKeyPath: "connectionStatus", context: &observerContext)
            }
            vc.sendAudioFileURL(url)
        }
    }
}
