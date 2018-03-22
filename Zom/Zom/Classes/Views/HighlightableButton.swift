//
//  MatchButton.swift
//  Zom
//
//  Created by Benjamin Erhart on 26.02.18.
//

import UIKit

/**
 UIButton which allows setting of background and border colors for normal and highlighted states.

 This can also be done using the Interface Builder via it's "User Defined Runtime Attributes"
 list.
 */
@objc class HighlightableButton: UIButton {

    @IBInspectable var normalBackgroundColor = UIColor.clear {
        didSet {
            backgroundColor = isHighlighted ? highlightedBackgroundColor : normalBackgroundColor
        }
    }

    @IBInspectable var highlightedBackgroundColor = UIColor.clear {
        didSet {
            backgroundColor = isHighlighted ? highlightedBackgroundColor : normalBackgroundColor
        }
    }

    @IBInspectable var normalBorderColor = UIColor.clear {
        didSet {
            layer.borderColor = isHighlighted ? highlightedBorderColor.cgColor : normalBorderColor.cgColor
        }
    }

    @IBInspectable var highlightedBorderColor = UIColor.clear {
        didSet {
            layer.borderColor = isHighlighted ? highlightedBorderColor.cgColor : normalBorderColor.cgColor
        }
    }

    override open var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? highlightedBackgroundColor : normalBackgroundColor
            layer.borderColor = isHighlighted ? highlightedBorderColor.cgColor : normalBorderColor.cgColor
        }
    }
}
