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

public class ZomDiscoverViewController: UIViewController, ZomPickStickerViewControllerDelegate {

    @IBOutlet weak var pickStickerButton: UIButton!
    var shareStickerOnResume:String?
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if (shareStickerOnResume != nil) {
            shareSticker(shareStickerOnResume!)
            shareStickerOnResume = nil;
        }
    }
    
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

    @IBAction func didPressStickerShareButtonWithSender(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "StickerShare", bundle: NSBundle.mainBundle())
        let vc = storyboard.instantiateInitialViewController()
        self.tabBarController?.presentViewController(vc!, animated: true, completion: nil)
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
                buddy = OTRXMPPBuddy.fetchBuddyWithUsername("zombot@home.zom.im", withAccountUniqueId: account.uniqueId, transaction: transaction)
                if (buddy == nil) {
                    let newBuddy = OTRXMPPBuddy()
                    newBuddy.username = "zombot@home.zom.im"
                    newBuddy.accountUniqueId = account.uniqueId
                    // hack to show buddy in conversations view
                    //buddy!.lastMessageDate = NSDate()
                    //buddy!.setDisplayName("ZomBot")
                    //(buddy as! OTRXMPPBuddy).pendingApproval = false
                    newBuddy.saveWithTransaction(transaction)

                    if let proto:OTRProtocol? = OTRProtocolManager.sharedInstance().protocolForAccount(account) {
                        proto?.addBuddy(newBuddy)
                    }
                    buddy = newBuddy
                }
            }
        }
        return buddy;
    }
    
    @IBAction func unwindPickSticker(unwindSegue: UIStoryboardSegue) {
    }
    
    public func didPickSticker(sticker: String, inPack pack: String) {
        if let fileName =
            ZomStickerMessage.getFilenameForSticker(sticker, inPack: pack) {
            shareStickerOnResume = fileName
        }
    }
    
    private func shareSticker(fileName: String) {
        if let image = UIImage(contentsOfFile: fileName) {
            let shareItems:Array = [image]
            
            let activityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
            //activityViewController!.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypePostToWeibo, UIActivityTypeCopyToPasteboard, UIActivityTypeAddToReadingList, UIActivityTypePostToVimeo]
            if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Phone {
                self.tabBarController!.presentViewController(activityViewController, animated: true, completion: nil)
            } else {
                let popup: UIPopoverController = UIPopoverController(contentViewController: activityViewController)
                popup.presentPopoverFromRect(pickStickerButton.bounds, inView: pickStickerButton, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
            }
        }
    }
}
