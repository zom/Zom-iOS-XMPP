//
//  ZomConversationViewController.swift
//  Zom
//
//  Created by N-Pex 2015-11-17.
//
//

import UIKit
import ChatSecureCore

public class ZomConversationViewController: OTRConversationViewController {
    
    //Mark: Properties
    
    var pitchInviteView:UIView? = nil
    var pitchCreateGroupView:UIView? = nil
    var kvoobject:ZomConversationViewControllerKVOObject? = nil
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.kvoobject = ZomConversationViewControllerKVOObject(viewController:self)
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.updatePitchView()
    }
    
    func updatePitchView() {
        if let dataBaseConnection:YapDatabaseConnection = OTRDatabaseManager.sharedInstance()?.newConnection() {
        dataBaseConnection.readWithBlock { (transaction) -> Void in
            //let view:YapDatabaseViewTransaction = transaction.ext(OTRAllBuddiesDatabaseViewExtensionName) as! YapDatabaseViewTransaction
            //let numBuddies = view.numberOfItemsInAllGroups()
            //if (numBuddies < 5 && OTRAccountsManager.allAccountsAbleToAddBuddies().count > 0) {
            //    self.tableView.tableHeaderView = self.getPitchInviteView()
            //}
            //else if (numBuddies > 1){
            //    self.tableView.tableHeaderView = self.getPitchCreateGroupView()
            //} else {
                self.tableView.tableHeaderView = nil;
            //}
            }
        }
    }
    
    func getPitchInviteView() -> UIView {
        if (self.pitchInviteView == nil) {
            self.pitchInviteView = UINib(nibName: "PitchInviteView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as? UIView
        }
        return self.pitchInviteView!
    }

    func getPitchCreateGroupView() -> UIView {
        if (self.pitchCreateGroupView == nil) {
            self.pitchCreateGroupView = UINib(nibName: "PitchCreateGroupView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as? UIView
            self.pitchCreateGroupView!.frame.size.height = 180
        }
        return self.pitchCreateGroupView!
    }
    
    @IBAction func addFriendsButtonPressed(sender: AnyObject) {
        
        let accounts = OTRAccountsManager.allAccountsAbleToAddBuddies()
        if (accounts.count > 0)
        {
            let storyboard = UIStoryboard(name: "AddBuddy", bundle: NSBundle.mainBundle())
            var vc:UIViewController? = nil
            if (accounts.count == 1) {
                vc = storyboard.instantiateViewControllerWithIdentifier("addNewBuddy")
                (vc as! ZomNewBuddyViewController).account = accounts[0] as? OTRAccount
                self.navigationController?.pushViewController(vc!, animated: true)
            } else {
                vc = storyboard.instantiateInitialViewController()
                self.navigationController?.presentViewController(vc!, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func createGroupButtonPressed(sender: AnyObject) {
        ZomComposeViewController.openInGroupMode = true
        self.performSelector(#selector(self.composeButtonPressed(_:)), withObject: sender)
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeHeaderToFit()
    }
    
    func sizeHeaderToFit() {
        if let headerView = tableView.tableHeaderView {
            var frame = headerView.frame
            frame.size.height = CGFloat.init(integerLiteral: 180)
            headerView.frame = frame
            tableView.tableHeaderView = headerView
        }
    }
}

public class ZomConversationViewControllerKVOObject : NSObject {
    var viewController:ZomConversationViewController? = nil
    public init(viewController:ZomConversationViewController) {
        super.init()
        self.viewController = viewController
        self.KVOController.observe(OTRProtocolManager.sharedInstance(), keyPath: "numberOfConnectedProtocols", options: NSKeyValueObservingOptions.New, block: { (observer, object, change) -> Void in
            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                self.viewController?.updatePitchView()
            }
        });
    }
}
