//
//  ZomBatchAddFriendsViewController.swift
//  Zom
//
//  Created by N-Pex on 2018-03-23.
//

import Foundation

fileprivate enum DynamicCellIdentifier: String {
    case buddy = "buddy"
}

protocol ZomBatchAddFriendsViewControllerDelegate {
    func didSelectBuddies(_ buddies: [OTRXMPPBuddy], from viewController:ZomBatchAddFriendsViewController)
}

class ZomBatchAddFriendsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    public var delegate:ZomBatchAddFriendsViewControllerDelegate?
    
    public var buddies:[OTRXMPPBuddy] = []
    private var selectedBuddies:[OTRXMPPBuddy] = []
    private var imageChecked:UIImage? = UIImage(named: "zom_add_friend_selected_90")
    private var imageUnchecked:UIImage? = UIImage(named: "zom_add_friend_unselected_90")
    
    @IBOutlet weak var buddyTable: UITableView!
    @IBOutlet weak var addButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.buddyTable.dataSource = self
        self.buddyTable.delegate = self
        let nib = UINib(nibName: "ZomAddFriendsTableCell", bundle: nil)
        self.buddyTable.register(nib, forCellReuseIdentifier: DynamicCellIdentifier.buddy.rawValue)
        //self.buddyTable.register(ZomUserInfoProfileCell.self, forCellReuseIdentifier: DynamicCellIdentifier.buddy.rawValue)
    }

    public func setBuddies(_ buddies:[OTRXMPPBuddy]) {
        self.buddies.removeAll()
        self.selectedBuddies.removeAll()
        self.buddies.append(contentsOf: buddies)
        self.selectedBuddies.append(contentsOf: buddies)
    }
    
    @IBAction func didPressDeselectAll(_ sender: UIButton) {
        self.selectedBuddies.removeAll()
        self.buddyTable.reloadData()
        updateAddButton()
    }

    @IBAction func didPressCancel(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didPressAdd(_ sender: UIButton) {
        if let delegate = self.delegate {
            delegate.didSelectBuddies(self.selectedBuddies, from:self)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func updateAddButton() {
        self.addButton.isEnabled = selectedBuddies.count > 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.buddies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let buddy = self.buddies[indexPath.row]
        
        let cell:ZomAddFriendsTableCell = tableView.dequeueReusableCell(withIdentifier: DynamicCellIdentifier.buddy.rawValue, for: indexPath) as! ZomAddFriendsTableCell
        let isSelected = self.selectedBuddies.contains(buddy)
        let imageView = UIImageView(image: isSelected ? self.imageChecked : self.imageUnchecked)
        imageView.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        cell.displayNameLabel.text = buddy.displayName
        cell.usernameLabel.text = buddy.username
        cell.avatarImageView.image = buddy.avatarImage
        cell.accessoryView = imageView
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let buddy = self.buddies[indexPath.row]
        if let idx = selectedBuddies.index(of: buddy) {
            selectedBuddies.remove(at: idx)
        } else {
            selectedBuddies.append(buddy)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
        updateAddButton()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
}
