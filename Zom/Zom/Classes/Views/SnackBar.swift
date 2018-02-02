//
//  SnackBar.swift
//  Zom
//
//  Created by N-Pex on 2/2/2018
//

import UIKit

public class SnackBar : UIView {
    @IBOutlet public var icon: UILabel!
    @IBOutlet public var titleLabel: UILabel!
    @IBOutlet public var button: UIButton!
    public var buttonCallback:(() -> Void)?
    
    @IBAction func buttonPressed(_ sender: Any) {
        if let callback = buttonCallback {
            callback()
        }
    }
}
