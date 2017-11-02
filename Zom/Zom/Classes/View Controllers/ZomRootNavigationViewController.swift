//
//  ZomRootNavigationViewController.swift
//  Zom
//
//  Created by N-Pex on 2017-11-02.
//

import UIKit
import ChatSecureCore

open class ZomRootNavigationViewController : UINavigationController, UIPopoverPresentationControllerDelegate {
    public func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        if popoverPresentationController.sourceView == nil {
            popoverPresentationController.sourceView = self.view
        }
    }
}

