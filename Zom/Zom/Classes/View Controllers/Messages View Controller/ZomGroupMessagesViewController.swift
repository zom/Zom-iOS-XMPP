//
//  ZomGroupMessagesViewController.swift
//  Zom
//
//  Created by N-Pex on 2017-07-20.
//
//

import UIKit
import ChatSecureCore
import JSQMessagesViewController
import OTRAssets
import BButton
import AFNetworking

open class ZomGroupMessagesViewController: OTRMessagesGroupViewController {
    override open func didSelectOccupantsButton(_ sender: Any!) {
        let storyboard = UIStoryboard(name: "Zom", bundle: Bundle.main)
        let vc = storyboard.instantiateViewController(withIdentifier: "roomOccupants") as! ZomRoomOccupantsViewController
        vc.setupViewHandler(databaseConnection:OTRDatabaseManager.shared.longLivedReadOnlyConnection!, roomKey: self.threadKey!)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

