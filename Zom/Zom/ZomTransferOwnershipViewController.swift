//
//  ZomTransferOwnershipViewController.swift
//  Zom
//
//  Created by N-Pex on 2018-04-05.
//

import Foundation

fileprivate enum DynamicCellIdentifier: String {
    case buddy = "buddy"
}

protocol ZomTransferOwnershipViewControllerDelegate {
    func didSelectOccupants(_ occupants: [OTRXMPPRoomOccupant], from viewController:UIViewController)
    func didNotSelectOccupants(from viewController:UIViewController)
}

class ZomTransferOwnershipViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    public var delegate:ZomTransferOwnershipViewControllerDelegate?
    
    public var occupants:[OTRXMPPRoomOccupant] = []
    private var selected:[OTRXMPPRoomOccupant] = []
    private var imageChecked:UIImage? = OTRImages.checkmark(with: GlobalTheme.shared.mainThemeColor)
    private var imageUnchecked:UIImage? = OTRImages.checkmark(with: .white)

    @IBOutlet weak var buddyTable: UITableView!
    @IBOutlet weak var leaveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.buddyTable.dataSource = self
        self.buddyTable.delegate = self
        let nib = UINib(nibName: "ZomAddFriendsTableCell", bundle: nil)
        self.buddyTable.register(nib, forCellReuseIdentifier: DynamicCellIdentifier.buddy.rawValue)
    }
    
    public func setOccupants(_ occupants:[OTRXMPPRoomOccupant]) {
        self.occupants.removeAll()
        self.selected.removeAll()
        self.occupants.append(contentsOf: occupants)
    }
    
    @IBAction func didPressCancel(_ sender: UIButton) {
        if let delegate = self.delegate {
            delegate.didNotSelectOccupants(from: self)
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didPressLeave(_ sender: UIButton) {
        if let delegate = self.delegate {
            delegate.didSelectOccupants(self.selected, from: self)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.occupants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let occupant = self.occupants[indexPath.row]
        var buddy:OTRXMPPBuddy? = nil
        OTRDatabaseManager.shared.connections?.ui.read({ (transaction) in
            buddy = occupant.buddy(with: transaction)
        })
        
        let cell:ZomAddFriendsTableCell = tableView.dequeueReusableCell(withIdentifier: DynamicCellIdentifier.buddy.rawValue, for: indexPath) as! ZomAddFriendsTableCell
        let isSelected = self.selected.contains(occupant)
        let imageView = UIImageView(image: isSelected ? self.imageChecked : self.imageUnchecked)
        imageView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        cell.displayNameLabel.text = buddy?.displayName
        cell.usernameLabel.text = buddy?.username ?? occupant.realJID?.bare ?? occupant.jid?.bare
        cell.avatarImageView.image = buddy?.avatarImage ?? occupant.avatarImage()
        cell.accessoryView = imageView
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let occupant = self.occupants[indexPath.row]
        if let idx = selected.index(of: occupant) {
            selected.remove(at: idx)
        } else {
            selected.append(occupant)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
}
