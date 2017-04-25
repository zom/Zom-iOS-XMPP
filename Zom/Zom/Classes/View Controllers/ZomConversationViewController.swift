//
//  ZomConversationViewController.swift
//  Zom
//
//  Created by N-Pex 2015-11-17.
//
//

import UIKit
import ChatSecureCore
import KVOController

open class ZomConversationViewController: OTRConversationViewController {
    
    //Mark: Properties
    
    var pitchInviteView:UIView? = nil
    //var pitchCreateGroupView:UIView? = nil
    var kvoobject:ZomConversationViewControllerKVOObject? = nil
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.kvoobject = ZomConversationViewControllerKVOObject(viewController:self)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updatePitchView()
    }
    
    func updatePitchView() {
        if let dataBaseConnection:YapDatabaseConnection = OTRDatabaseManager.sharedInstance().newConnection() {
        dataBaseConnection.read { (transaction) -> Void in
            let view:YapDatabaseViewTransaction = transaction.ext(OTRAllBuddiesDatabaseViewExtensionName) as! YapDatabaseViewTransaction
            let numBuddies = view.numberOfItemsInAllGroups()
            if (numBuddies == 0 && OTRAccountsManager.allAccounts().count > 0 && self.tableView.tableHeaderView == nil) {
                self.tableView.tableHeaderView = self.getPitchInviteView()
            //}
            //else if (numBuddies > 1){
            //    self.tableView.tableHeaderView = self.getPitchCreateGroupView()
            } else if (self.tableView.tableHeaderView == self.pitchInviteView) {
                self.tableView.tableHeaderView = nil;
            }
            }
        }
    }
    
    func getPitchInviteView() -> UIView {
        if (self.pitchInviteView == nil) {
            self.pitchInviteView = UINib(nibName: "PitchInviteView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? UIView
        }
        return self.pitchInviteView!
    }

//    func getPitchCreateGroupView() -> UIView {
//        if (self.pitchCreateGroupView == nil) {
//            self.pitchCreateGroupView = UINib(nibName: "PitchCreateGroupView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? UIView
//            self.pitchCreateGroupView!.frame.size.height = 180
//        }
//        return self.pitchCreateGroupView!
//    }
    
    @IBAction func addFriendsButtonPressed(_ sender: AnyObject) {
        ZomNewBuddyViewController.addBuddyToDefaultAccount(self.navigationController)
    }
    
    @IBAction func createGroupButtonPressed(_ sender: AnyObject) {
        ZomComposeViewController.openInGroupMode = true
        self.performSelector(inBackground: #selector(self.composeButtonPressed(_:)), with: sender)
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeHeaderToFit()
    }
    
    func sizeHeaderToFit() {
        if let headerView = tableView.tableHeaderView {
            if headerView == self.pitchInviteView {
                var frame = headerView.frame
                frame.size.height = CGFloat.init(integerLiteral: 180)
                headerView.frame = frame
                tableView.tableHeaderView = headerView
            }
        }
    }
}

public class ZomConversationViewControllerKVOObject : NSObject {
    var viewController:ZomConversationViewController? = nil
    public init(viewController:ZomConversationViewController) {
        super.init()
        self.viewController = viewController
        self.kvoController.observe(OTRProtocolManager.sharedInstance(), keyPath: "numberOfConnectedProtocols", options: NSKeyValueObservingOptions.new, block: { (observer, object, change) -> Void in
            DispatchQueue.main.async { [unowned self] in
                self.viewController?.updatePitchView()
            }
        });
    }
}
