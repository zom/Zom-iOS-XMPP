//
//  ZomNewBuddyViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-12-04.
//
//

import UIKit
import ChatSecureCore

public class ZomNewBuddyViewController: OTRNewBuddyViewController {
    @IBOutlet weak var shareSmsButton: UIButton!
    @IBOutlet weak var shareLinkTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    
    private var shouldShowSmsButton:Bool = true
    private var keyboardVisible = false
    private var activeTextField:UITextField? = nil
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.showSmsButton(self.shouldShowSmsButton)
        self.accountNameTextField.resignFirstResponder()
        self.tableView!.bounces = false
        self.tableView!.scrollEnabled = true
    }
    
    public func showSmsButton(show:Bool) {
        self.shouldShowSmsButton = show
        if (self.isViewLoaded()) {
            if (show) {
                self.shareSmsButton.hidden = false
                self.shareLinkTopConstraint.priority = 850
            } else {
                self.shareSmsButton.hidden = true
                self.shareLinkTopConstraint.priority = 950
            }
            let tableHeader:UIView = self.tableView!.tableHeaderView!
            
            tableHeader.setNeedsLayout()
            tableHeader.layoutIfNeeded()
            let height = tableHeader.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            
            //update the header's frame and set it again
            var headerFrame:CGRect = tableHeader.frame;
            headerFrame.size.height = height;
            tableHeader.frame = headerFrame;
            self.tableView!.tableHeaderView = tableHeader;
        }
    }
    
    func registerForKeyboardNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self,
            selector: "keyboardWillBeShown:",
            name: UIKeyboardWillShowNotification,
            object: nil)
        notificationCenter.addObserver(self,
            selector: "keyboardWillBeHidden:",
            name: UIKeyboardWillHideNotification,
            object: nil)
    }
    
    func keyboardWillBeShown(sender: NSNotification) {
        if (self.tableViewBottomConstraint.constant == 0) {
            let info: NSDictionary = sender.userInfo!
            let value: NSValue = info.valueForKey(UIKeyboardFrameBeginUserInfoKey) as! NSValue
            let keyboardSize: CGSize = value.CGRectValue().size
            self.tableViewBottomConstraint.constant = keyboardSize.height
            tableViewScrollToBottomAnimated(true)
        }
    }
    
    func keyboardWillBeHidden(sender: NSNotification) {
        self.tableViewBottomConstraint.constant = 0
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.registerForKeyboardNotifications()
    }
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func tableViewScrollToBottomAnimated(animated:Bool) {
        let section = self.tableView!.numberOfSections - 1
        let numberOfRows = self.tableView!.numberOfRowsInSection(section)
        if (numberOfRows > 0) {
            self.tableView?.scrollToRowAtIndexPath(NSIndexPath(forRow: numberOfRows - 1, inSection: section), atScrollPosition: UITableViewScrollPosition.Bottom, animated: animated)
        }
    }
}
 