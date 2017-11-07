//
//  ZomPhotoStreamCell.swift
//  Zom
//
//  Created by N-Pex on 2017-06-14.
//
//

import UIKit

open class ZomPhotoStreamCell: UICollectionViewCell {
    @IBOutlet weak var imageView:UIImageView!
    private var photo:ZomPhotoStreamImage?
    
    override open func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
        photo?.releaseImages()
        self.photo = nil
    }
    
    open func populateWithPhoto(_ photo: ZomPhotoStreamImage) {
        self.photo = photo
        photo.loadThumbnailImageWithSizeAndCompletionHandler(imageView.bounds.size, completion: { (image, error) in
            self.imageView.image = image
        })
    }
}
