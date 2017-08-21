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
    
    @IBOutlet weak var qrCodeButton:UIButton?
    
    public override init(databaseConnection:YapDatabaseConnection, roomKey:String) {
        super.init(databaseConnection: databaseConnection, roomKey: roomKey)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        qrCodeButton?.backgroundColor = UIColor.white //reset this, set by appearance proxy
        
        // Hide the QR for now
        qrCodeButton?.isHidden = true
    }
}
