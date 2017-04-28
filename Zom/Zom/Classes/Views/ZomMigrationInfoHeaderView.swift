//
//  ZomMigrationInfoHeaderView.swift
//  Zom
//
//  Created by N-Pex on 2017-04-28.
//
//

import UIKit
import ChatSecureCore

public class ZomMigrationInfoHeaderView: MigrationInfoHeaderView {
    @IBOutlet public var imageView: UIImageView!
    @IBOutlet public var autoMigrateButton: UIButton!
    @IBOutlet public var assistedMigrateButton: UIButton!
    @IBOutlet public var workingButton: UIButton!
    @IBOutlet public var doneButton: UIButton!
    @IBOutlet public var infoLabel: UIView!
    @IBOutlet public var doneLabel: UIView!
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        autoMigrateButton.backgroundColor = UIColor.yellow
        workingButton.backgroundColor = UIColor(white: 0, alpha: 0.3)
        workingButton.tintColor = UIColor.white
        doneButton.backgroundColor = UIColor.white
    }
}
