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
    var initialized: Bool = false
    @IBOutlet public var imageView: UIImageView!
    @IBOutlet public var autoMigrateButton: UIButton!
    @IBOutlet public var assistedMigrateButton: UIButton!
    @IBOutlet public var workingButton: UIButton!
    @IBOutlet public var doneButton: UIButton!
    @IBOutlet public var infoLabel: UILabel!
    @IBOutlet public var doneLabel: UIView!
    
    public override func layoutSubviews() {
        if !initialized, let text = infoLabel.text, let idxStart = text.range(of: "[["), let idxEnd = text.range(of: "]]") {
            let start = text.distance(from: text.startIndex, to: idxStart.lowerBound)
            let end = text.distance(from: text.startIndex, to: idxEnd.lowerBound) - 2
            if start < end {
                // Create attributed string
                var textCopy = text
                textCopy.removeSubrange(idxEnd)
                textCopy.removeSubrange(idxStart)
                let length = end - start
                let mutableAttrString = NSMutableAttributedString(string: textCopy)
                let range = NSRange(location: start, length: length)
                mutableAttrString.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: range)
                mutableAttrString.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFont(ofSize: infoLabel.font.pointSize), range: range)
                infoLabel.attributedText = mutableAttrString
            }
        }
        super.layoutSubviews()
        if !initialized {
            autoMigrateButton.backgroundColor = UIColor.yellow
            workingButton.backgroundColor = UIColor(white: 0, alpha: 0.3)
            workingButton.tintColor = UIColor.white
            doneButton.backgroundColor = UIColor.white
            initialized = true
        }
    }
}
