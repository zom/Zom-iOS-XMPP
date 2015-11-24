//
//  ZomConversationViewController.swift
//  Zom
//
//  Created by N-Pex 2015-11-17.
//
//

import UIKit
import ChatSecureCore

public class ZomConversationViewController: OTRConversationViewController, OTRConversationViewControllerDelegate {
    
    //Make: Properties
    
    
    var showPitchInvite:Bool = false
    var pitchInviteView:UIView? = nil
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        super.delegate = self
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.updatePitchView()
    }
    
    func updatePitchView() {
        let dataBaseConnection:YapDatabaseConnection = OTRDatabaseManager.sharedInstance().newConnection()
        dataBaseConnection.readWithBlock { (transaction) -> Void in
            let view:YapDatabaseViewTransaction = transaction.ext(OTRAllBuddiesDatabaseViewExtensionName) as! YapDatabaseViewTransaction
            let numBuddies = view.numberOfItemsInAllGroups()
            if (numBuddies < 50 && OTRAccountsManager.allAccountsAbleToAddBuddies().count > 0) {
                self.showPitchInvite = true
            }
            else {
                self.showPitchInvite = false;
            }
            self.tableView.reloadData()
        }
    }
    
    func getPitchInviteView() -> UIView {
        if (self.pitchInviteView == nil) {
            self.pitchInviteView = UINib(nibName: "PitchInviteView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as? UIView
        }
        return self.pitchInviteView!
    }
    
    public override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (self.showPitchInvite && section == 0) {
            return getPitchInviteView().sizeThatFits(UILayoutFittingCompressedSize).height + 1
        }
        return 0
    }
    
    public override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (self.showPitchInvite && section == 0) {
            return getPitchInviteView()
        }
        return nil
    }
    
    @IBAction func addFriendsButtonPressed(sender: AnyObject) {
        
        let accounts = OTRAccountsManager.allAccountsAbleToAddBuddies()
        if (accounts.count > 0)
        {
            let storyboard = UIStoryboard(name: "AddBuddy", bundle: nil)
            var vc:UIViewController? = nil
            if (accounts.count == 1) {
                vc = storyboard.instantiateViewControllerWithIdentifier("addNewBuddy")
                (vc as! ZomAddBuddyViewController).account = accounts[0] as? OTRAccount
                self.navigationController?.pushViewController(vc!, animated: true)
            } else {
                vc = storyboard.instantiateInitialViewController()
                self.navigationController?.presentViewController(vc!, animated: true, completion: nil)
            }
        }
    }
    
    public func controller(viewController: OTRConversationViewController!, didChangeNumberOfConnectedAccounts connectedAccounts: Int) {
        self.updatePitchView()
    }
}