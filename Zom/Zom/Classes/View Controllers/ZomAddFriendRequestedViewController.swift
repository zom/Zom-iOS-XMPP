//
//  ZomAddFriendRequestedViewController.swift
//  Zom
//
//  Created by N-Pex on 2018-03-26.
//

import Foundation

class ZomAddFriendRequestedViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func didTapView(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

