//
//  ZomPhotoStreamViewController.swift
//  Zom
//
//  Created by N-Pex on 2017-06-14.
//
//

import UIKit
import ChatSecureCore
import IDMPhotoBrowser

open class ZomPhotoStreamViewController: UICollectionViewController, IDMPhotoBrowserDelegate {
    
    public var photos:[ZomPhotoStreamImage] = []
    
    fileprivate var assetGridThumbnailSize:CGSize = CGSize()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        OTRDatabaseManager.shared.readOnlyDatabaseConnection?.asyncRead({ (transaction) in
            var array:[OTRMediaItem] = [OTRMediaItem]()
            let collection = OTRMediaItem.collection
            let allMediaItemKeys = transaction.allKeys(inCollection: collection)
            allMediaItemKeys.forEach({ (key) in
                if let object = transaction.object(forKey: key, inCollection: collection) as? OTRMediaItem {
                    array.append(object)
                }
            })
            if array.count > 0 {
                var photos:[ZomPhotoStreamImage] = [ZomPhotoStreamImage]()
                array.forEach({ (mediaItem) in
                    if let message = mediaItem.parentMessage(with: transaction) {
                        let p = ZomPhotoStreamImage(mediaItem: mediaItem, message: message)
                        photos.append(p)
                    }
                })
                self.photos = photos
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                }
            }
        });
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Determine the size of the thumbnails to request from the PHCachingImageManager
        let scale:CGFloat = UIScreen.main.scale
        let cellSize:CGSize = (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize;
        assetGridThumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale);
    }
    
    // Mark - UICollectionViewDataSource
    
    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = photos[indexPath.item]
        let cell:ZomPhotoStreamCell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ZomPhotoStreamCell
        cell.populateWithPhoto(photo)
        return cell
    }
    
    open override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = self.collectionView?.cellForItem(at: indexPath)  as! ZomPhotoStreamCell
        if photos.count > 0, let browser = IDMPhotoBrowser(photos: photos, animatedFrom: cell.imageView)
        {
            browser.autoHideInterface = false
            browser.useWhiteBackgroundColor = true
            browser.delegate = self
            browser.setInitialPageIndex(UInt(indexPath.item))
            self.present(browser, animated: true, completion: nil)
        }
    }
    
    public func photoBrowser(_ photoBrowser: IDMPhotoBrowser!, captionViewForPhotoAt index: UInt) -> IDMCaptionView? {
        if let photo = photoBrowser.photo(at: index) as? ZomPhotoStreamImage {
            let captionView = IDMCaptionView(photo: photo)
            captionView?.label.attributedText = photo.attributedCaption()
            return captionView
        }
        return nil
    }
}
