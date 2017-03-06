//
//  ZomPickLanguageViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-24.
//
//

import UIKit
import ChatSecureCore

public protocol ZomPickLanguageViewControllerDelegate {
    func dismissViewController(_ wasSaved:Bool) -> Void
}

open class ZomPickLanguageViewController: OTRLanguageListSettingViewController {

    var delegate:ZomPickLanguageViewControllerDelegate? = nil
    var saveWasCalled:Bool = false

    open override func loadView() {
        let lb = self.navigationItem.leftBarButtonItem
        let rb = self.navigationItem.rightBarButtonItem
        super.loadView()
        self.navigationItem.leftBarButtonItem = lb
        self.navigationItem.rightBarButtonItem = rb
    }
    
    @IBAction func cancelButtonPressed(_ sender: AnyObject) {
        if (delegate != nil) {
            self.delegate?.dismissViewController(false)
        } else {
            super.dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func saveButtonPressed(_ sender: AnyObject) {
        saveWasCalled = true
        self.save(self)
    }

    // We are shown in a navigation view controller, so don't dismiss us here
    open override func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        if (delegate != nil) {
            delegate!.dismissViewController(self.saveWasCalled)
        } else {
            super.dismiss(animated: flag, completion: completion)
        }
    }
}
