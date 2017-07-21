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
    
    @IBOutlet weak var groupInfoTableView: UITableView!
    var groupInfoTableViewDataSource:GroupInfoTableDataSource?
    
    public override init(databaseConnection:YapDatabaseConnection, roomKey:String) {
        super.init(databaseConnection: databaseConnection, roomKey: roomKey)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.groupInfoTableViewDataSource = GroupInfoTableDataSource(roomKey: self.roomKey!)
        groupInfoTableView.dataSource = self.groupInfoTableViewDataSource
        groupInfoTableView.delegate = self.groupInfoTableViewDataSource
        let image = OTRGroupAvatarGenerator.avatarImage(withUniqueIdentifier: self.roomKey!, width: Int(largeAvatarView.frame.width), height: Int(largeAvatarView.frame.height))
        largeAvatarView.image = image
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
}
