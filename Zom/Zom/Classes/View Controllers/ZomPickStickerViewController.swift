//
//  ZomPickStickerViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-13.
//
//

import UIKit
import ChatSecureCore

public protocol ZomPickStickerViewControllerDelegate {
    func didPickSticker(sticker:String, inPack: String)
}

public class ZomPickStickerViewController: UICollectionViewController {
    
    public var stickerPack: String = ""
    private var stickers: [String] = []
    private var stickerPaths: [String] = []
    private var selectedSticker:String = ""
    
    private var assetGridThumbnailSize:CGSize = CGSize()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let docsPath = NSBundle.mainBundle().resourcePath! + "/Stickers/" + stickerPack
        let fileManager = NSFileManager.defaultManager()
        do {
            let stickerFiles = try fileManager.contentsOfDirectoryAtPath(docsPath)
            for item in stickerFiles {
                stickers.append((item as NSString).stringByDeletingPathExtension)
                stickerPaths.append(docsPath + "/" + item)
            }
        } catch {
            print(error)
        }
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Determine the size of the thumbnails to request from the PHCachingImageManager
        let scale:CGFloat = UIScreen.mainScreen().scale
        let cellSize:CGSize = (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize;
        assetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale);
    }
    
    // Mark - UICollectionViewDataSource
    
    public override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickerPaths.count
    }
    
    public override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell:ZomPickStickerCell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! ZomPickStickerCell
        cell.imageView.image = UIImage(contentsOfFile: stickerPaths[indexPath.item])
        return cell
    }
    
    public override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedSticker = stickers[indexPath.item]
        self.performSegueWithIdentifier("unwindPickStickerSegue", sender: self)
    }

    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.destinationViewController is ZomPickStickerViewControllerDelegate) {
            let vc:ZomPickStickerViewControllerDelegate = segue.destinationViewController as! ZomPickStickerViewControllerDelegate
            if (!selectedSticker.isEmpty) {
                vc.didPickSticker(selectedSticker, inPack: stickerPack)
            }
        }
    }
    
}
