//
//  ZomGroupInfoViewController.swift
//  Zom
//
//  Created by N-Pex on 2017-07-20.
//
//

import UIKit
import ChatSecureCore

open class ZomRoomOccupantsViewController : OTRRoomOccupantsViewController {
    
    @IBOutlet weak var tableViewHeader:UIView!
    @IBOutlet weak var largeAvatarView:UIImageView!
    @IBOutlet weak var qrCodeButton:UIButton!
    
    @IBOutlet weak var groupInfoTableView: UITableView!
    var groupInfoTableViewDataSource:GroupInfoTableDataSource?
    
    var groupTableViewDataSource:GroupTableDataSource?
    
    @IBOutlet weak var groupFooterTableView: UITableView!
    var groupFooterTableViewDataSource:GroupFooterTableDataSource?
    
    public override init(databaseConnection:YapDatabaseConnection, roomKey:String) {
        super.init(databaseConnection: databaseConnection, roomKey: roomKey)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.groupTableViewDataSource = GroupTableDataSource(dataSource: self.tableView.dataSource!)
        self.tableView.dataSource = self.groupTableViewDataSource
        self.groupInfoTableViewDataSource = GroupInfoTableDataSource(roomKey: self.roomKey!)
        groupInfoTableView.dataSource = self.groupInfoTableViewDataSource
        groupInfoTableView.delegate = self.groupInfoTableViewDataSource
        self.groupFooterTableViewDataSource = GroupFooterTableDataSource(roomKey: self.roomKey!)
        groupFooterTableView.dataSource = self.groupFooterTableViewDataSource
        groupFooterTableView.delegate = self.groupFooterTableViewDataSource
        let image = OTRGroupAvatarGenerator.avatarImage(withUniqueIdentifier: self.roomKey!, width: Int(largeAvatarView.frame.width), height: Int(largeAvatarView.frame.height))
        largeAvatarView.image = image
        qrCodeButton.backgroundColor = UIColor.white //reset this, set by appearance proxy
    }
    
    class GroupTableDataSource: NSObject, UITableViewDataSource {
        let superSource:UITableViewDataSource
        
        init(dataSource:UITableViewDataSource) {
            self.superSource = dataSource
            super.init()
        }
        
        func numberOfSections(in tableView: UITableView) -> Int {
            return superSource.numberOfSections!(in:tableView)
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return superSource.tableView(tableView, numberOfRowsInSection:section)
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            return superSource.tableView(tableView, cellForRowAt:indexPath)
        }
    }
    
    class GroupInfoTableDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
        let roomKey:String
        
        enum GroupInfoRows: Int {
            case name
            case share
            case addZomFriends
            case mute
            case members
            static let allValues = [name, share, addZomFriends, mute, members]
        }
        
        init(roomKey:String) {
            self.roomKey = roomKey
            super.init()
        }
        
        func numberOfSections(in tableView: UITableView) -> Int {
            return 1
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return GroupInfoRows.allValues.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            var cell:UITableViewCell?
            if let row = GroupInfoRows(rawValue: indexPath.row) {
                switch row {
                case .name:
                    cell = tableView.dequeueReusableCell(withIdentifier: "cellGroupName", for: indexPath)
                    OTRDatabaseManager.shared.readOnlyDatabaseConnection?.read({ (transaction) in
                        if let room = OTRXMPPRoom.fetchObject(withUniqueID: self.roomKey, transaction: transaction) {
                            cell?.textLabel?.text = room.subject
                            cell?.detailTextLabel?.text = "" // Do we have creation date?
                        }
                    })
                    cell?.selectionStyle = .none
                case .share:
                    cell = tableView.dequeueReusableCell(withIdentifier: "cellGroupShare", for: indexPath)
                case .addZomFriends:
                    cell = tableView.dequeueReusableCell(withIdentifier: "cellGroupAddZomFriends", for: indexPath)
                case .mute:
                    cell = tableView.dequeueReusableCell(withIdentifier: "cellGroupMute", for: indexPath)
                case .members:
                    cell = tableView.dequeueReusableCell(withIdentifier: "cellGroupMembers", for: indexPath)
                    cell?.selectionStyle = .none
                }
            }
            return cell!
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            guard let row = GroupInfoRows(rawValue: indexPath.row) else {
                return
            }
            switch row {
            case .share:
                print("share")
            case .addZomFriends:
                print("add")
            case .mute:
                print("mute")
            default:
                print("ignore")
            }
        }
    }
    
    class GroupFooterTableDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
        let roomKey:String
        
        enum GroupFooterRows: Int {
            case leave
            static let allValues = [leave]
        }
        
        init(roomKey:String) {
            self.roomKey = roomKey
            super.init()
        }
        
        func numberOfSections(in tableView: UITableView) -> Int {
            return 1
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return GroupFooterRows.allValues.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            var cell:UITableViewCell?
            if let row = GroupFooterRows(rawValue: indexPath.row) {
                switch row {
                case .leave:
                    cell = tableView.dequeueReusableCell(withIdentifier: "cellGroupLeave", for: indexPath)
                }
            }
            return cell!
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            guard let row = GroupFooterRows(rawValue: indexPath.row) else {
                return
            }
            switch row {
            case .leave:
                print("leave")
            default:
                print("ignore")
            }
        }
    }

}
