//
//  ZomCompactTraitViewController.swift
//  Zom
//
//  Created by N-Pex on 2016-11-30.
//
//

import UIKit

class ZomCompactTraitViewController: UIViewController, UISplitViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        performOverrideTraitCollection()
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.performOverrideTraitCollection()
    }
    
    private func performOverrideTraitCollection() {
        for childVC in self.childViewControllers {
            setOverrideTraitCollection(UITraitCollection(horizontalSizeClass: .compact), forChildViewController: childVC)
        }
    }
}
