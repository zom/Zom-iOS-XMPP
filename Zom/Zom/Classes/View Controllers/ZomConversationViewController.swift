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
    var kvoobject:ZomConversationViewControllerKVOObject? = nil

    public var migrationStep:Int = 0 {
        didSet {
            updateMigrationViewWithStep(view: self.migrationInfoHeaderView)
            if migrationStep == 0 && self.migrationInfoHeaderView != nil {
                // Remove it
                self.migrationInfoHeaderView = nil
                self.tableView.tableHeaderView = nil
            }
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.kvoobject = ZomConversationViewControllerKVOObject(viewController:self)
        
        // Constrain table view bottom to layout guide instead of superview
        let constraints = self.tableView.constraintsAffectingLayout(for: .vertical)
        self.view.removeConstraints(constraints)
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[topguide][tableView][guide]", options: NSLayoutFormatOptions(), metrics: nil, views: ["topguide":self.topLayoutGuide,"guide":self.bottomLayoutGuide,"tableView":self.tableView]))
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updatePitchView()
    }
    
    func updatePitchView() {
        OTRDatabaseManager.shared.readConnection?.read { (transaction) -> Void in
            guard let view:YapDatabaseViewTransaction = transaction.ext(OTRAllBuddiesDatabaseViewExtensionName) as?YapDatabaseViewTransaction else { return }
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

    override open func updateInboxArchiveFilteringAndShowArchived(_ showArchived: Bool) {
        super.updateInboxArchiveFilteringAndShowArchived(showArchived)
        OTRDatabaseManager.shared.writeConnection?.asyncReadWrite({ (transaction) in
            if let fvt = transaction.ext(OTRArchiveFilteredConversationsName) as? YapDatabaseFilteredViewTransaction {
                let filtering = YapDatabaseViewFiltering.withObjectBlock({ (transaction, group, collection, key, object) -> Bool in
                    if let threadOwner = object as? OTRThreadOwner {
                        if showArchived {
                            return threadOwner.isArchived
                        } else if let buddy = threadOwner as? OTRXMPPBuddy, buddy.askingForApproval {
                            return false // Remove approval requests from this view
                        } else {
                            return !threadOwner.isArchived
                        }
                    }
                    return !showArchived
                })
                fvt.setFiltering(filtering, versionTag: UUID().uuidString)
            }
        })
        self.view.setNeedsLayout()
    }
    
    open override func createMigrationHeaderView(_ account: OTRXMPPAccount) -> MigrationInfoHeaderView {
        let view = super.createMigrationHeaderView(account)
        updateMigrationViewWithStep(view: view)
        return view
    }
    
    public func updateMigrationViewWithStep(view:UIView?) {
        guard let view = view as? ZomMigrationInfoHeaderView else { return }
        view.autoMigrateButton.isHidden = (self.migrationStep != 0)
        view.assistedMigrateButton.isEnabled = (self.migrationStep == 0)
        view.workingButton.isHidden = (self.migrationStep != 1)
        view.doneButton.isHidden = (self.migrationStep != 2)
        view.infoLabel.isHidden = (self.migrationStep == 2)
        view.doneLabel.isHidden = (self.migrationStep != 2)
        var imageFile:String?
        switch migrationStep
        {
        case 1:
             imageFile = ZomStickerMessage.getFilenameForSticker("1thinking", inPack: "olo and shimi")
            break
        case 2:
            imageFile = ZomStickerMessage.getFilenameForSticker("9dancing", inPack: "olo and shimi")
            break
        default:
            imageFile = ZomStickerMessage.getFilenameForSticker("6yay", inPack: "olo and shimi")
            break
        }
        if let file = imageFile {
            view.imageView.image = UIImage(contentsOfFile: file)
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
