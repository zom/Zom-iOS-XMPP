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
    typealias ObjcYapDatabaseViewGroupingWithObjectBlock = @convention(block)
        (YapDatabaseReadTransaction, String, String, Any) -> String?
    
    static var extensionName:String = "Zom" + OTRAllBuddiesDatabaseViewExtensionName
    static var filteredExtensionName:String = "Zom" + OTRArchiveFilteredBuddiesName
    open static var openInGroupMode:Bool = false
    
    var wasOpenedInGroupMode = false
    
    static let imageActionButtonCellIdentifier = "imageActionCell"
    static let imageActionCreateGroupIdentifier = "imageActionCellCreateGroup"
    static let imageActionAddFriendIdentifier = "imageActionCellAddFriend"

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(OTRBuddyApprovalCell.self, forCellReuseIdentifier: OTRBuddyApprovalCell.reuseIdentifier())
        
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

    override open func didSetupMappings(_ handler: OTRYapViewHandler) {
        super.didSetupMappings(handler)
        if (handler == self.viewHandler) {
            // If we have not done so, register our extension and change the viewHandler to our own.
            if registerZomSortedView() {
                useZomSortedView()
            }
        }
    }
    
    override open func viewDidLayoutSubviews() {
        // Hide the upstream add friends option
        let hideAddFriends = !(parent is UINavigationController)
        self.tableViewHeader.setView(ADD_BUDDY_STRING(), hidden: true)
        self.tableViewHeader.setView(JOIN_GROUP_STRING(), hidden: true)
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
    
    func registerZomSortedView() -> Bool {
        // This sets up a database view that is identical to the original "OTRAllBuddiesDatabaseView" but
        // with the difference that  XMPPBuddies that are avaiting approval are ordered to the top of the list.
        //
        if OTRDatabaseManager.shared.database?.registeredExtension(ZomComposeViewController.extensionName) == nil {
            if let originalView:YapDatabaseAutoView = OTRDatabaseManager.sharedInstance().database?.registeredExtension(OTRAllBuddiesDatabaseViewExtensionName) as? YapDatabaseAutoView {
                let sorting = YapDatabaseViewSorting.withObjectBlock({ (transaction, group, collection1, group1, object1, collection2, group2, object2) -> ComparisonResult in
                    let askingApproval1 = (object1 as? OTRXMPPBuddy)?.askingForApproval ?? false
                    let askingApproval2 = (object2 as? OTRXMPPBuddy)?.askingForApproval ?? false
                    if (askingApproval1 && !askingApproval2) {
                        return .orderedAscending
                    } else if (!askingApproval1 && askingApproval2) {
                        return .orderedDescending
                    }
                    let pendingApproval1 = (object1 as? OTRXMPPBuddy)?.pendingApproval ?? false
                    let pendingApproval2 = (object2 as? OTRXMPPBuddy)?.pendingApproval ?? false
                    if (pendingApproval1 && !pendingApproval2) {
                        return .orderedAscending
                    } else if (!pendingApproval1 && pendingApproval2) {
                        return .orderedDescending
                    }
                    if let buddy1 = (object1 as? OTRXMPPBuddy), let buddy2 = (object2 as? OTRXMPPBuddy) {
                        let name1 = (buddy1.displayName.count > 0) ? buddy1.displayName : buddy1.username
                        let name2 = (buddy2.displayName.count > 0) ? buddy2.displayName : buddy2.username
                        return name1.caseInsensitiveCompare(name2)
                    }
                    let blockObject:AnyObject = originalView.sorting.block as AnyObject
                    let originalBlock = unsafeBitCast(blockObject, to: ObjcYapDatabaseViewSortingWithObjectBlock.self)
                    return originalBlock(transaction, group, collection1, group1, object1, collection2, group2, object2)
                })
                let grouping = YapDatabaseViewGrouping.withObjectBlock({ (transaction, collection, key, object) -> String? in
                    let blockObject:AnyObject = originalView.grouping.block as AnyObject
                    let originalBlock = unsafeBitCast(blockObject, to: ObjcYapDatabaseViewGroupingWithObjectBlock.self)
                    var group = originalBlock(transaction, collection, key, object)
                    if group == nil, let buddy = object as? OTRXMPPBuddy, buddy.askingForApproval {
                        group = OTRBuddyGroup
                    }
                    return group
                })
                
                let options = YapDatabaseViewOptions()
                options.isPersistent = false
                let newView = YapDatabaseAutoView(grouping: grouping, sorting: sorting, versionTag: NSUUID().uuidString, options: options)
                OTRDatabaseManager.sharedInstance().database?.register(newView, withName: ZomComposeViewController.extensionName)
            }
        }
        
        if OTRDatabaseManager.shared.database?.registeredExtension(ZomComposeViewController.filteredExtensionName) == nil, OTRDatabaseManager.shared.database?.registeredExtension(OTRArchiveFilteredBuddiesName) != nil {
            let options = YapDatabaseViewOptions()
            options.isPersistent = false
            let filtering = getFilteringBlock(false)
            let filteredView = YapDatabaseFilteredView(parentViewName: ZomComposeViewController.extensionName, filtering: filtering, versionTag: NSUUID().uuidString, options: options)
            OTRDatabaseManager.sharedInstance().database?.register(filteredView, withName: ZomComposeViewController.filteredExtensionName)
            return true
        }
        return false
    }
    
    func useZomSortedView() {
        self.viewHandler = OTRYapViewHandler(databaseConnection: OTRDatabaseManager.shared.longLivedReadOnlyConnection!, databaseChangeNotificationName: DatabaseNotificationName.LongLivedTransactionChanges)
        if let viewHandler = self.viewHandler {
            viewHandler.delegate = self as? OTRYapViewHandlerDelegateProtocol
            viewHandler.setup(ZomComposeViewController.filteredExtensionName, groups: [OTRBuddyGroup])
        }
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let threadOwner = super.threadOwner(at: indexPath, with: tableView) as? OTRXMPPBuddy, threadOwner.askingForApproval {
            let cell = tableView.dequeueReusableCell(withIdentifier: OTRBuddyApprovalCell.reuseIdentifier(), for: indexPath)
            if let cell = cell as? OTRBuddyApprovalCell {
                cell.actionBlock = { (cell:OTRBuddyApprovalCell?, approved:Bool) -> Void in
                    //TODO Fixme: quick hack to get going
                    if let tabController = self.tabBarController as? ZomMainTabbedViewController {
                        if let conversationController = tabController.viewControllers?[0] as? OTRConversationViewController {
                            conversationController.handleSubscriptionRequest(threadOwner, approved: approved)
                        }
                    }
                }
                cell.selectionStyle = .none
                cell.avatarImageView.layer.cornerRadius = (80.0-2.0*OTRBuddyImageCellPadding)/2.0
                cell.setThread(threadOwner)
            }
            return cell
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
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
