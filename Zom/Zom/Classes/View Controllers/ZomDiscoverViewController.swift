//
//  ZomDiscoverViewController.swift
//  Zom
//
//  Created by N-Pex on 2016-11-15.
//
//

import Foundation

public class ZomDiscoverViewController: UIViewController {
    
    @IBAction func changeThemeButtonPressedWithSender(sender: AnyObject) {
        self.performSegueWithIdentifier("segueToPickColor", sender: self)
    }
    
    @IBAction func unwindPickColorWithUnwindSegue(unwindSegue: UIStoryboardSegue) {
        print("Unwind!")
    }
    
    func selectThemeColor(color: UIColor?) {
        if (color != nil) {
            if let appDelegate = UIApplication.sharedApplication().delegate as? OTRAppDelegate {
                (appDelegate.theme as! ZomTheme).selectMainThemeColor(color)
                self.navigationController?.navigationBar.barTintColor = appDelegate.theme.mainThemeColor
                self.navigationController?.navigationBar.backgroundColor = appDelegate.theme.mainThemeColor
                self.tabBarController?.tabBar.backgroundColor = appDelegate.theme.mainThemeColor
                self.tabBarController?.tabBar.barTintColor = appDelegate.theme.mainThemeColor
            }
        }
    }
    
}
