//
//  ZomImportManager.swift
//  Zom
//
//  Created by N-Pex on 2017-11-03.
//

import Foundation
import ChatSecureCore
import MobileCoreServices

@objc public class ZomImportManager: NSObject, OTRConversationViewControllerDelegate, OTRComposeViewControllerDelegate {
    
    @objc public static let shared = ZomImportManager()
    
    private var fileUrl:URL?
    private var image:UIImage?
    private var type:String = ""
    private var account:OTRAccount?
    private var threadOwner:OTRThreadOwner?
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
            self.threadOwner = self.viewController?.threadObject(with: transaction)
        })
        guard self.account != nil, self.threadOwner != nil else { return }
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
        self.threadOwner = threadOwner
        guard self.account != nil, self.threadOwner != nil else { return }
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
        if let account = self.account, let xmpp = OTRProtocolManager.shared.protocol(for: account) as? XMPPManager {
            xmpp.removeObserver(self, forKeyPath: "connectionStatus", context: &observerContext)
        }
        if let navController = modalNavigationController {
            navController.dismiss(animated: true, completion: nil)
        }
    }
            
    @objc public func handleImport(url:URL?, type:String, viewController:UIViewController?) -> Bool {
        return handleImport(url: url, image: nil, type: type, viewController: viewController)
    }
 
    @objc public func handleImport(image:UIImage?, type:String, viewController:UIViewController?) -> Bool {
        return handleImport(url: nil, image: image, type: type, viewController: viewController)
    }
    
    private func handleImport(url:URL?, image:UIImage?, type:String, viewController:UIViewController?) -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate, let presenter = viewController else {
            return false
        }
        
        self.fileUrl = url
        self.image = image
        self.type = type
        self.viewController = appDelegate.messagesViewController

        let vc = appDelegate.theme.conversationViewController()
        if let conversationViewController = vc as? OTRConversationViewController {
            conversationViewController.delegate = self
            let _ = conversationViewController.view
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.didCancelImport(_:)))
            let barButtonAddChat = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(self.conversationViewController(_:didSelectCompose:)))
            vc.navigationItem.rightBarButtonItem = barButtonAddChat
        }
        modalNavigationController = UINavigationController(rootViewController: vc)
        if let modalNavigationController = modalNavigationController {
            modalNavigationController.modalPresentationStyle = .formSheet
            presenter.present(modalNavigationController, animated: true, completion: nil)
            return true
        }
        return false
    }
    
    func sendWhenOnline() {
        guard let account = self.account, self.viewController != nil else { return }
        if let xmpp = OTRProtocolManager.shared.protocol(for: account) as? XMPPManager {
            if xmpp.connectionStatus == .connected {
                doSend(xmpp)
            } else {
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
        if let xmpp = object as? XMPPManager, xmpp.connectionStatus == .connected {
            // Stop observing
            xmpp.removeObserver(self, forKeyPath: "connectionStatus", context: &observerContext)
            doSend(xmpp)
        }
    }
    
    private func doSend(_ xmpp:XMPPManager) {
        guard let threadOwner = self.threadOwner else {return}
        if UTTypeConformsTo(type as CFString, kUTTypeImage) {
            if let image = self.image {
                xmpp.fileTransferManager.send(image: image, thread: threadOwner)
            } else if let url = self.fileUrl {
                DispatchQueue.global().async {
                    do {
                        let data = try Data(contentsOf: url)
                        if let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                xmpp.fileTransferManager.send(image: image, thread: threadOwner)
                            }
                        }
                    } catch {}
                }
            }
        } else if let url = self.fileUrl{
            xmpp.fileTransferManager.send(audioURL: url, thread: threadOwner)
        }
    }
}
