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

open class ZomPhotosViewController: INSPhotosViewController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        let sendItem = UIBarButtonItem(barButtonSystemItem: .reply, target: self, action: #selector(self.sendButtonTapped(_:)))
        if let overlayView = overlayView as? INSPhotosOverlayView {
            if let actionItem = overlayView.navigationItem.rightBarButtonItem {
                overlayView.navigationItem.rightBarButtonItem = nil
                overlayView.navigationItem.rightBarButtonItems = [actionItem, sendItem]
            } else {
                overlayView.navigationItem.rightBarButtonItems = [sendItem]
            }
        }
    }
    
    @objc private func sendButtonTapped(_ sender: UIBarButtonItem) {
        if let currentPhoto = currentPhoto as? ZomPhotoStreamImage {
            currentPhoto.loadImageWithCompletionHandler({ [weak self] (image, error) -> () in
                if let image = (image ?? currentPhoto.thumbnailImage) {
                    let _ = ZomImportManager.shared.handleImport(image: image, type: kUTTypeImage as String, viewController: self)
                }
            });
        }
    }
}

open class ZomPhotosViewControllerOverlay: INSPhotosOverlayView {
    private var currentPhoto: INSPhotoViewable?
    
    open override func populateWithPhoto(_ photo: INSPhotoViewable) {
        currentPhoto = photo
        super.populateWithPhoto(photo)
    }
}
