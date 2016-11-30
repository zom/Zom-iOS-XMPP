//
//  ZomCompactTraitViewController.swift
//  Zom
//
//  Created by N-Pex on 2016-11-30.
//
//

class ZomCompactTraitViewController: UIViewController, UISplitViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        performOverrideTraitCollection()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        performOverrideTraitCollection()
    }
    
    private func performOverrideTraitCollection() {
        for childVC in self.childViewControllers {
            setOverrideTraitCollection(UITraitCollection(horizontalSizeClass: .Compact), forChildViewController: childVC)
        }
    }
}
