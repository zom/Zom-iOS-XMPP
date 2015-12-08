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
    func dismissViewController(wasSaved:Bool) -> Void
}

public class ZomPickLanguageViewController: OTRLanguageListSettingViewController {

    var delegate:ZomPickLanguageViewControllerDelegate? = nil
    var saveWasCalled:Bool = false

    public override func loadView() {
        let lb = self.navigationItem.leftBarButtonItem
        let rb = self.navigationItem.rightBarButtonItem
        super.loadView()
        self.navigationItem.leftBarButtonItem = lb
        self.navigationItem.rightBarButtonItem = rb
    }
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        if (delegate != nil) {
            self.delegate?.dismissViewController(false)
        } else {
            super.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    @IBAction func saveButtonPressed(sender: AnyObject) {
        saveWasCalled = true
        self.save(self)
    }

    // We are shown in a navigation view controller, so don't dismiss us here
    public override func dismissViewControllerAnimated(flag: Bool, completion: (() -> Void)?) {
        if (delegate != nil) {
            delegate!.dismissViewController(self.saveWasCalled)
        } else {
            super.dismissViewControllerAnimated(flag, completion: completion)
        }
    }
}