//
//  ZomPhotoStreamViewController.swift
//  Zom
//
//  Created by N-Pex on 2017-06-14.
//
//

import UIKit
import ChatSecureCore
import INSPhotoGallery
import MBProgressHUD

open class ZomPhotoStreamViewController: UICollectionViewController, ZomGalleryHandlerDelegate, ZomPhotosViewControllerDelegate {
    fileprivate var assetGridThumbnailSize:CGSize = CGSize()
    private var galleryLoadingIndicator:MBProgressHUD?
    private var galleryHandler:ZomGalleryHandler?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        guard let dbConnection = OTRDatabaseManager.shared.readOnlyDatabaseConnection else {return}
        galleryHandler = ZomGalleryHandler(connection: dbConnection)
        galleryHandler?.fetchImagesAsync(for: nil, initialPhoto: nil, delegate: self)
    }
    
    public func galleryHandlerDidStartFetching(_ galleryHandler: ZomGalleryHandler) {
        self.galleryLoadingIndicator = MBProgressHUD.showAdded(to: self.view, animated: true)
        self.galleryLoadingIndicator?.detailsLabel.text = NSLocalizedString("Cancel", comment: "Cancel loading gallery view")
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancelGalleryFetching))
        self.galleryLoadingIndicator?.addGestureRecognizer(tap)
    }
    
    @objc func cancelGalleryFetching() {
        galleryHandler?.cancelFetching()
        galleryLoadingIndicator?.hide(animated: true)
        galleryLoadingIndicator = nil
        self.navigationController?.popViewController(animated: true)
    }
    
    public func galleryHandlerDidFinishFetching(_ galleryHandler: ZomGalleryHandler, images: [ZomPhotoStreamImage], initialImage: ZomPhotoStreamImage?) {
        galleryLoadingIndicator?.hide(animated: true)
        galleryLoadingIndicator = nil
        collectionView?.reloadData()
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
        return galleryHandler?.images.count ?? 0
    }
    
    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell:ZomPhotoStreamCell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ZomPhotoStreamCell
        if let photo = galleryHandler?.images[indexPath.item] {
            cell.populateWithPhoto(photo)
        }
        return cell
    }
    
    open override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = self.collectionView?.cellForItem(at: indexPath)  as! ZomPhotoStreamCell
        if let galleryHandler = self.galleryHandler {
            let initialPhoto = galleryHandler.images[indexPath.item]
            let browser = ZomPhotosViewController(photos: galleryHandler.images, initialPhoto:initialPhoto, referenceView:cell.imageView)
            browser.delegate = self
            browser.referenceViewForPhotoWhenDismissingHandler = { [weak self] photo in
            if let index = galleryHandler.images.index(where: {$0 === photo}) {
                let indexPath = IndexPath(item: index, section: 0)
                return (collectionView.cellForItem(at: indexPath) as? ZomPhotoStreamCell)?.imageView
            }
            return nil
        }
        self.present(browser, animated: true, completion: nil)
        }
    }
    
    public func didDeletePhoto(photo: ZomPhotoStreamImage) {
        if let galleryHandler = self.galleryHandler, let index = galleryHandler.images.index(where: {$0 === photo}) {
            galleryHandler.images.remove(at: index)
            let indexPath = IndexPath(item: index, section: 0)
            collectionView?.deleteItems(at: [indexPath])
        }
    }
    
}
