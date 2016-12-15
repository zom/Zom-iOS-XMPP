//
//  ZomDiscoverViewController.swift
//  Zom
//
//  Created by N-Pex on 2016-11-15.
//
//

import Foundation
import XMPPFramework
import OTRKit

public class ZomDiscoverViewController: UIViewController {

    @IBAction func didPressZomServicesButtonWithSender(sender: AnyObject) {
        if let appDelegate = UIApplication.sharedApplication().delegate as? ZomAppDelegate {
            if let buddy = getZombotBuddy() {
                appDelegate.splitViewCoordinator.enterConversationWithBuddy(buddy.uniqueId)
            }
        }
    }
    
    @IBAction func didPressCreateGroupButtonWithSender(sender: AnyObject) {
        if let appDelegate = UIApplication.sharedApplication().delegate as? ZomAppDelegate {
            ZomComposeViewController.openInGroupMode = true
            appDelegate.conversationViewController.performSelector(#selector(appDelegate.conversationViewController.composeButtonPressed(_:)), withObject: sender)
        }
    }
    
    @IBAction func didPressChangeThemeButtonWithSender(sender: AnyObject) {
        self.performSegueWithIdentifier("segueToPickColor", sender: self)
    }
    
    @IBAction func unwindPickColorWithUnwindSegue(unwindSegue: UIStoryboardSegue) {
        print("Unwind!")
    }
    
    func selectThemeColor(color: UIColor?) {
        if (color != nil) {
            if let appDelegate = UIApplication.sharedApplication().delegate as? OTRAppDelegate {
                (appDelegate.theme as! ZomTheme).selectMainThemeColor(color)
                self.navigationController?.navigationBar.barTintColor = appDelegate.theme.mainThemeColor
                self.navigationController?.navigationBar.backgroundColor = appDelegate.theme.mainThemeColor
                self.tabBarController?.tabBar.backgroundColor = appDelegate.theme.mainThemeColor
                self.tabBarController?.tabBar.barTintColor = appDelegate.theme.mainThemeColor
            }
        }
    }
    
    private func getZombotBuddy() -> OTRBuddy? {
        var buddy:OTRBuddy? = nil
        if let appDelegate = UIApplication.sharedApplication().delegate as? ZomAppDelegate {
            let account:OTRAccount = appDelegate.getDefaultAccount()
            OTRDatabaseManager.sharedInstance().readWriteDatabaseConnection.readWriteWithBlock { (transaction) in
                buddy = OTRXMPPBuddy.fetchBuddyWithUsername("", withAccountUniqueId: account.uniqueId, transaction: transaction)
                if (buddy == nil) {
                    buddy = OTRXMPPBuddy()
                    buddy!.username = "zombot@home.zom.im"
                    buddy!.accountUniqueId = account.uniqueId
                    // hack to show buddy in conversations view
                    //buddy!.lastMessageDate = NSDate()
                    //buddy!.setDisplayName("ZomBot")
                    //(buddy as! OTRXMPPBuddy).pendingApproval = false
                    buddy!.saveWithTransaction(transaction)
                }
                
                if let proto:OTRProtocol? = OTRProtocolManager.sharedInstance().protocolForAccount(account) {
                    proto?.addBuddy(buddy)
                }
                
            }
        }
        return buddy;
    }
}
