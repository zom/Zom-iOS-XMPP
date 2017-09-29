//
//  ZomComposeViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-24.
//
//

import UIKit
import ChatSecureCore

open class ZomComposeViewController: OTRComposeViewController {

    typealias ObjcYapDatabaseViewSortingWithObjectBlock = @convention(block) (YapDatabaseReadTransaction, String, String, String, Any, String, String, Any) -> ComparisonResult
    
    static var extensionName:String = "Zom" + OTRAllBuddiesDatabaseViewExtensionName
    static var filteredExtensionName:String = "Zom" + OTRFilteredBuddiesName
    open static var openInGroupMode:Bool = false
    
    var wasOpenedInGroupMode = false
    
    static let imageActionButtonCellIdentifier = "imageActionCell"
    static let imageActionCreateGroupIdentifier = "imageActionCellCreateGroup"
    static let imageActionAddFriendIdentifier = "imageActionCellAddFriend"

    open override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.setupZomSortedView()
        }
        if (ZomComposeViewController.openInGroupMode) {
            ZomComposeViewController.openInGroupMode = false
            self.wasOpenedInGroupMode = true
            self.groupButtonPressed(self)
            navigationItem.title = ""
        } else {
            navigationItem.title = NSLocalizedString("Choose a Friend", comment: "When selecting friend")
            let nib = UINib(nibName: "ImageActionButtonCell", bundle: OTRAssets.resourcesBundle)
            self.tableView.register(nib, forCellReuseIdentifier: ZomComposeViewController.imageActionButtonCellIdentifier)
            
            if let cell = self.tableView.dequeueReusableCell(withIdentifier: ZomComposeViewController.imageActionButtonCellIdentifier) as? ZomImageActionButtonCell {
                cell.actionLabel.text = NSLocalizedString("Create a Group", comment: "Cell text for creating a group")
                cell.iconLabel.backgroundColor = UIColor(netHex: 0xff7ed321)
                self.tableViewHeader.addStackedSubview(cell, identifier: ZomComposeViewController.imageActionCreateGroupIdentifier, gravity: .bottom, height: OTRBuddyInfoCellHeight, callback: {
                    self.groupButtonPressed(cell)
                })
                cell.translatesAutoresizingMaskIntoConstraints = true
                cell.contentView.translatesAutoresizingMaskIntoConstraints = true
            }
            if let cell = self.tableView.dequeueReusableCell(withIdentifier: ZomComposeViewController.imageActionButtonCellIdentifier) as? ZomImageActionButtonCell {
                cell.actionLabel.text = ADD_BUDDY_STRING()
                cell.iconLabel.text = ""
                cell.iconLabel.backgroundColor = ZomAppDelegate.appDelegate.theme.mainThemeColor
                self.tableViewHeader.addStackedSubview(cell, identifier: ZomComposeViewController.imageActionAddFriendIdentifier, gravity: .bottom, height: OTRBuddyInfoCellHeight, callback: {
                    let accounts = OTRAccountsManager.allAccounts()
                    self.addBuddy(accounts)
                })
                cell.translatesAutoresizingMaskIntoConstraints = true
                cell.contentView.translatesAutoresizingMaskIntoConstraints = true
            }

            // Remove the "create group" option from navigation bar
            self.navigationItem.rightBarButtonItems = nil
        }
    }
    
    override open func viewDidLayoutSubviews() {
        // Hide the upstream add friends option
        let hideAddFriends = !(parent is UINavigationController)
        self.tableViewHeader.setView(ADD_BUDDY_STRING(), hidden: true)
        self.tableViewHeader.setView(ZomComposeViewController.imageActionCreateGroupIdentifier, hidden: hideAddFriends)
        self.tableViewHeader.setView(ZomComposeViewController.imageActionAddFriendIdentifier, hidden: hideAddFriends)
    }
    
    override open func updateInboxArchiveFilteringAndShowArchived(_ showArchived: Bool) {
        super.updateInboxArchiveFilteringAndShowArchived(showArchived)
        OTRDatabaseManager.shared.readWriteDatabaseConnection?.asyncReadWrite({ (transaction) in
            if let fvt = transaction.ext(ZomComposeViewController.filteredExtensionName) as? YapDatabaseFilteredViewTransaction {
                fvt.setFiltering(self.getFilteringBlock(showArchived), versionTag:NSUUID().uuidString)
            }
        })
        self.view.setNeedsLayout()
    }
    
    func setupZomSortedView() {
        // This sets up a database view that is identical to the original "OTRAllBuddiesDatabaseView" but
        // with the difference that  XMPPBuddies that are avaiting approval are ordered to the top of the list.
        //
        if OTRDatabaseManager.shared.database?.registeredExtension(ZomComposeViewController.extensionName) == nil {
            if let originalView:YapDatabaseAutoView = OTRDatabaseManager.sharedInstance().database?.registeredExtension(OTRAllBuddiesDatabaseViewExtensionName) as? YapDatabaseAutoView {
                let sorting = YapDatabaseViewSorting.withObjectBlock({ (transaction, group, collection1, group1, object1, collection2, group2, object2) -> ComparisonResult in
                    let pendingApproval1 = (object1 as? OTRXMPPBuddy)?.pendingApproval ?? false
                    let pendingApproval2 = (object2 as? OTRXMPPBuddy)?.pendingApproval ?? false
                    if (pendingApproval1 && !pendingApproval2) {
                        return .orderedAscending
                    } else if (!pendingApproval1 && pendingApproval2) {
                        return .orderedDescending
                    }
                    let blockObject:AnyObject = originalView.sorting.block as AnyObject
                    let originalBlock = unsafeBitCast(blockObject, to: ObjcYapDatabaseViewSortingWithObjectBlock.self)
                    return originalBlock(transaction, group, collection1, group1, object1, collection2, group2, object2)
                })
                let options = YapDatabaseViewOptions()
                options.isPersistent = false
                let newView = YapDatabaseAutoView(grouping: originalView.grouping, sorting: sorting, versionTag: "1", options: options)
                OTRDatabaseManager.sharedInstance().database?.register(newView, withName: ZomComposeViewController.extensionName)
            }
        }
        
        if OTRDatabaseManager.shared.database?.registeredExtension(ZomComposeViewController.filteredExtensionName) == nil, OTRDatabaseManager.shared.database?.registeredExtension(OTRFilteredBuddiesName) != nil {
            let options = YapDatabaseViewOptions()
            options.isPersistent = false
            let filtering = getFilteringBlock(false)
            let filteredView = YapDatabaseFilteredView(parentViewName: ZomComposeViewController.extensionName, filtering: filtering, versionTag: NSUUID().uuidString, options: options)
            OTRDatabaseManager.sharedInstance().database?.register(filteredView, withName: ZomComposeViewController.filteredExtensionName)
        }
        
        self.viewHandler = OTRYapViewHandler.init(databaseConnection: OTRDatabaseManager.sharedInstance().longLivedReadOnlyConnection!, databaseChangeNotificationName: DatabaseNotificationName.LongLivedTransactionChanges)
        self.viewHandler?.delegate = self as? OTRYapViewHandlerDelegateProtocol
        self.viewHandler?.setup(ZomComposeViewController.filteredExtensionName, groups: [OTRBuddyGroup])
    }
    
    open override func addBuddy(_ accountsAbleToAddBuddies: [OTRAccount]?) {
        if let accounts = accountsAbleToAddBuddies {
            if (accounts.count > 0)
            {
                ZomNewBuddyViewController.addBuddyToDefaultAccount(self.navigationController)
            }
        }
    }
    
    open override func groupButtonPressed(_ sender: Any!) {
        let storyboard = UIStoryboard(name: "OTRComposeGroup", bundle: OTRAssets.resourcesBundle)
        if let vc = storyboard.instantiateInitialViewController() as? OTRComposeGroupViewController {
            vc.delegate = self as? OTRComposeGroupViewControllerDelegate
            self.navigationController?.pushViewController(vc, animated: (sender as? UIViewController != self))
        }
    }
    
    override open func groupSelectionCancelled(_ composeViewController: OTRComposeGroupViewController!) {
        if composeViewController != nil && wasOpenedInGroupMode {
            dismiss(animated: true, completion: nil)
        }
    }
}
