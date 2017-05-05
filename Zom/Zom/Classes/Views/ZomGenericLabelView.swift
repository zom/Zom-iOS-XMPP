//
//  ZomGenericTableViewCell.swift
//  Zom
//
//  Created by N-Pex on 2017-05-05.
//
//

import UIKit

open class ZomGenericLabelView: UIView {
    override open func layoutSubviews() {
        super.layoutSubviews()
        for view in subviews {
            if let label = view as? UILabel {
                if label.numberOfLines == 0 {
                    label.preferredMaxLayoutWidth = label.bounds.width
                }
            }
        }
    }
}
