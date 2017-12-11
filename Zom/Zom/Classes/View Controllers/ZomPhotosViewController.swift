//
//  ZomPhotosViewController.swift
//  Zom
//
//  Created by N-Pex on 2017-10-27.
//

import UIKit
import ChatSecureCore
import INSPhotoGallery
import MobileCoreServices

public protocol ZomPhotosViewControllerDelegate {
    func didDeletePhoto(photo:ZomPhotoStreamImage)
}

open class ZomPhotosViewController: INSPhotosViewController {
    
    open var delegate: ZomPhotosViewControllerDelegate?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        super.deletePhotoHandler = {
            (photo: INSPhotoViewable?) -> Void in
            if let currentPhoto = photo as? ZomPhotoStreamImage {
                currentPhoto.releaseImages()
                OTRMediaFileManager.shared.deleteData(for: currentPhoto.mediaItem, buddyUniqueId: currentPhoto.message.threadId, completion: { (success, error) in
                    if success, let delegate = self.delegate {
                        delegate.didDeletePhoto(photo: currentPhoto)
                    }
                }, completionQueue: nil)
            }
        }
        if let overlayView = UINib(nibName: "ZomPhotoOverlayView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? INSPhotosOverlayViewable {
            self.overlayView = overlayView
        }
    }
}

