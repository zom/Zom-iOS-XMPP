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

open class ZomPhotoStreamViewController: UICollectionViewController, ZomGalleryHandlerDelegate {
    
    fileprivate var assetGridThumbnailSize:CGSize = CGSize()
    private var loadingIndicator:UIActivityIndicatorView?
    private var galleryHandler:ZomGalleryHandler?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        guard let dbConnection = OTRDatabaseManager.shared.readOnlyDatabaseConnection else {return}
        galleryHandler = ZomGalleryHandler(connection: dbConnection)
        galleryHandler?.fetchImagesAsync(for: nil, initialPhoto: nil, delegate: self)
    }
    
    public func galleryHandlerDidStartFetching(_ galleryHandler: ZomGalleryHandler) {
        loadingIndicator = UIActivityIndicatorView(frame: self.view.frame)
        if let loadingIndicator = loadingIndicator {
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
            loadingIndicator.startAnimating();
            view.addSubview(loadingIndicator)
        }
    }
    
    public func galleryHandlerDidFinishFetching(_ galleryHandler: ZomGalleryHandler, images: [ZomPhotoStreamImage], initialImage: ZomPhotoStreamImage?) {
        collectionView?.reloadData()
        loadingIndicator?.stopAnimating()
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
}
