//
//  ZomChooseAccountViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-18.
//
//

import UIKit
import ChatSecureCore

public class ZomChooseAccountViewController: OTRChooseAccountViewController, UITableViewDelegate {

    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    var selectedAccount:OTRAccount? = nil
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let accounts = OTRAccountsManager.allAccountsAbleToAddBuddies()
        if (accounts.count == 1)
        {
            self.selectedAccount = accounts[0] as? OTRAccount
            self.performSegueWithIdentifier("addNewBuddySegue", sender: self)
        }
        
        //Super view changed our bar button item, so get our cancel button back!
        self.navigationItem.rightBarButtonItems = [self.cancelBarButtonItem]
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let accounts:[AnyObject] = OTRAccountsManager.allAccountsAbleToAddBuddies()
        self.selectedAccount = accounts[indexPath.row] as? OTRAccount
        self.performSegueWithIdentifier("addNewBuddySegue", sender: self)
    }
    
    // MARK: - Navigation
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addNewBuddySegue" {
            let vc:ZomNewBuddyViewController = segue.destinationViewController as! ZomNewBuddyViewController
            vc.account = self.selectedAccount
        }
        super.prepareForSegue(segue, sender:sender)
    }
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
