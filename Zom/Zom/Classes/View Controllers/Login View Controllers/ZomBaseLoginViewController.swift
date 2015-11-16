//
//  ZomBaseLoginViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-13.
//
//


import UIKit
import ChatSecureCore

public class ZomBaseLoginViewController: OTRBaseLoginViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        let nib:UINib = UINib(nibName: "ZomTableViewSectionHeader", bundle: nil)
        self.tableView.registerNib(nib, forHeaderFooterViewReuseIdentifier: "zomTableSectionHeader")
    }

    public override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header:ZomTableViewSectionHeader = tableView.dequeueReusableHeaderFooterViewWithIdentifier("zomTableSectionHeader") as! ZomTableViewSectionHeader
        header.labelView.text = self.tableView(tableView, titleForHeaderInSection: section)
        return header
    }
    
    public override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let title:String? = self.tableView(tableView, titleForHeaderInSection: section)
        if (title == nil || title!.isEmpty) {
            return 0
        }
        return 50
    }
}
