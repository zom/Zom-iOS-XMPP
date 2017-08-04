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
    
    @IBOutlet weak var qrCodeButton:UIButton!
    var navigationBarShadow:UIImage?
    
    public override init(databaseConnection:YapDatabaseConnection, roomKey:String) {
        super.init(databaseConnection: databaseConnection, roomKey: roomKey)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBarShadow = self.navigationController?.navigationBar.shadowImage
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barTintColor = UIColor.clear
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
        self.navigationController?.navigationBar.isTranslucent = true
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = UINavigationBar.appearance().barTintColor
        self.navigationController?.navigationBar.backgroundColor = UINavigationBar.appearance().backgroundColor
        self.navigationController?.navigationBar.shadowImage = self.navigationBarShadow
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        qrCodeButton.backgroundColor = UIColor.white //reset this, set by appearance proxy
    }
}
