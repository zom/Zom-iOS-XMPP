//
//  ZomInviteViewController.swift
//  Zom
//
//  Created by N-Pex on 2016-05-19.
//
//

import UIKit
import ChatSecureCore

public class ZomInviteViewController: OTRInviteViewController, OTRAttachmentPickerDelegate {
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let alreadyAdded = self.childViewControllers.contains { (controller) -> Bool in
            return controller.restorationIdentifier != nil && ("congrats".compare(controller.restorationIdentifier!) == NSComparisonResult.OrderedSame);
        }
        if (!alreadyAdded) {
            self.title = ""
            let storyboard = UIStoryboard(name: "Onboarding", bundle: OTRAssets.resourcesBundle())
            let vc = storyboard.instantiateViewControllerWithIdentifier("congrats")
            vc.restorationIdentifier = "congrats"
            self.addChildViewController(vc)
            vc.view.frame = self.view.frame
            self.view.addSubview(vc.view)
        }
    }
    
    @IBAction func settingsButtonPressed(sender: AnyObject) {
        self.skipPressed(sender)
        if let appDelegate = UIApplication.sharedApplication().delegate as? OTRAppDelegate {
            if let conversationController = appDelegate.conversationViewController {
                
                // Open settings
                conversationController.settingsButtonPressed(self)
                
                // On iPads, make sure the the split view controller shows the settings pane
                if let navigationController = conversationController.navigationController {
                    if let opener = navigationController.parentViewController {
                        if let splitController = opener as? UISplitViewController{
                            if (!splitController.collapsed) {
                                let btn = splitController.displayModeButtonItem()
                                btn.target?.performSelector(btn.action, withObject: btn)
                            }
                        }
                    }
                }
            }
        }
    }

    @IBAction func avatarButtonPressed(sender: AnyObject) {
        let photoPicker = OTRAttachmentPicker(parentViewController: self, delegate: self)
        photoPicker.showAlertControllerWithCompletion(nil)
    }
    
    public func attachmentPicker(attachmentPicker: OTRAttachmentPicker!, gotVideoURL videoURL: NSURL!) {
    }
    
    public func attachmentPicker(attachmentPicker: OTRAttachmentPicker!, gotPhoto photo: UIImage!, withInfo info: [NSObject : AnyObject]!) {
    }
}