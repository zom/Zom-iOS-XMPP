//
//  ZomIntroViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-11.
//
//

import UIKit
import ChatSecureCore

public class ZomIntroViewController: OTRWelcomeViewController {
    
    public var showCancelButton:Bool = false
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        if (showCancelButton) {
            self.navigationController!.setNavigationBarHidden(false, animated: animated)
            self.navigationItem.setHidesBackButton(true, animated: false)
        }
    }
    
    // MARK: - Navigation
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "useExistingAccountSegue" {
        }
        super.prepareForSegue(segue, sender:sender)
    }
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
}