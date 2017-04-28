//
//  ZomMigrationInfoViewController.swift
//  Zom
//
//  Created by N-Pex on 2017-04-28.
//
//

@objc public protocol ZomMigrationInfoViewControllerDelegateProtocol {
    func startAssistedMigration() -> Void
    func startAutomaticMigration() -> Void
}

class ZomMigrationInfoViewController: UIViewController {
    
    open weak var delegate:ZomMigrationInfoViewControllerDelegateProtocol?
    
    @IBAction func advancedButtonPressed(_ sender: AnyObject) {
        navigationController?.popViewController(animated: true)
        self.delegate?.startAssistedMigration()
    }
    
    @IBAction func upgradeNowButtonPressed(_ sender: AnyObject) {
        navigationController?.popViewController(animated: true)
        self.delegate?.startAutomaticMigration()
    }
}
