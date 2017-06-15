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
        photo?.unloadUnderlyingImage()
    }
    
    open func populateWithPhoto(_ photo: ZomPhotoStreamImage) {
        self.photo = photo
        imageView.image = photo.underlyingImage()
        if (imageView.image == nil) {
            photo.loadUnderlyingImageAndNotify(callback: { (image) in
                if (self.photo == image) {
                    self.imageView.image = image.underlyingImage()
                }
            })
        }
    }
}
