//
//  ZomStickerPackListViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-12.
//
//

import UIKit
import ChatSecureCore
import Photos

public class ZomStickerPackTableViewController: UITableViewController {

    private var stickerPacks: Array<String> = [];
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        let docsPath = NSBundle.mainBundle().resourcePath! + "/Stickers"
        let fileManager = NSFileManager.defaultManager()
        do {
            stickerPacks = try fileManager.contentsOfDirectoryAtPath(docsPath)
        } catch {
            print(error)
        }
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stickerPacks.count
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("stickerPackCell")!
        cell.textLabel!.text = String(format: "%@", stickerPacks[indexPath.row])
        return cell
    }

    // Mark - UIViewController
    
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if (segue.destinationViewController is ZomPickStickerViewController) {
        let cell:UITableViewCell? = (sender as? UITableViewCell)!
        if (cell == nil) {
            return
        }
        
        let vc:ZomPickStickerViewController = segue.destinationViewController as! ZomPickStickerViewController
    
        let indexPath:NSIndexPath = self.tableView.indexPathForCell(cell!)!
        let stickerPack:String = stickerPacks[indexPath.row]
        vc.stickerPack = stickerPack
        }
        super.prepareForSegue(segue, sender: sender)
    }
    
}