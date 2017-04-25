//
//  ZomChooseAccountViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-18.
//
//

import UIKit
import ChatSecureCore

open class ZomChooseAccountViewController: OTRChooseAccountViewController, UITableViewDelegate {

    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    var selectedAccount:OTRAccount? = nil
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        let accounts = OTRAccountsManager.allAccounts()
        if accounts.count == 1
        {
            self.selectedAccount = accounts[0]
            self.performSegue(withIdentifier: "addNewBuddySegue", sender: self)
        }
        
        //Super view changed our bar button item, so get our cancel button back!
        self.navigationItem.rightBarButtonItems = [self.cancelBarButtonItem]
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        let accounts:[Any] = OTRAccountsManager.allAccounts()
        self.selectedAccount = accounts[indexPath.row] as? OTRAccount
        self.performSegue(withIdentifier: "addNewBuddySegue", sender: self)
    }
    
    // MARK: - Navigation
    override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addNewBuddySegue" {
            let vc:ZomNewBuddyViewController = segue.destination as! ZomNewBuddyViewController
            vc.account = self.selectedAccount
        }
        super.prepare(for: segue, sender:sender)
    }
    
    @IBAction func cancelButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}
