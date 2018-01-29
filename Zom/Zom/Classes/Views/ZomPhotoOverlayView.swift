//
//  ZomPhotoOverlayView.swift
//  Zom
//
//  Created by N-Pex on 2017-12-11.
//

import UIKit
import INSPhotoGallery
import MobileCoreServices

public class ZomPhotoOverlayView : UIView, INSPhotosOverlayViewable {
    @IBOutlet public var navigationBar: UINavigationBar!
    @IBOutlet public var toolbar: UIToolbar!
    @IBOutlet public var label: UILabel!
    private var currentPhoto:INSPhotoViewable?
    public var photosViewController: INSPhotosViewController?
    
    public func populateWithPhoto(_ photo: INSPhotoViewable) {
        self.currentPhoto = photo
        self.toolbar.setBackgroundImage(UIImage(),
                                        forToolbarPosition: .any,
                                        barMetrics: .default)
        self.toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.label.attributedText = photo.attributedTitle
    }
    
    // Pass the touches down to other views
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitView = super.hitTest(point, with: event) , hitView != self {
            return hitView
        }
        return nil
    }
    
//    open override func layoutSubviews() {
//        // The navigation bar has a different intrinsic content size upon rotation, so we must update to that new size.
//        // Do it without animation to more closely match the behavior in `UINavigationController`
//        UIView.performWithoutAnimation { () -> Void in
//            self.navigationBar.invalidateIntrinsicContentSize()
//            self.navigationBar.layoutIfNeeded()
//        }
//        super.layoutSubviews()
//        self.updateShadowFrames()
//    }
    
    open func setHidden(_ hidden: Bool, animated: Bool) {
        if self.isHidden == hidden {
            return
        }
        
        if animated {
            self.isHidden = false
            self.alpha = hidden ? 1.0 : 0.0
            
            UIView.animate(withDuration: 0.4, delay: 0.0, options: [.allowAnimatedContent, .allowUserInteraction], animations: { () -> Void in
                self.alpha = hidden ? 0.0 : 1.0
            }, completion: { result in
                self.alpha = 1.0
                self.isHidden = hidden
            })
        } else {
            self.isHidden = hidden
        }
    }
    
    @IBAction func actionButtonTapped(_ sender: UIBarButtonItem) {
        if let currentPhoto = currentPhoto {
            currentPhoto.loadImageWithCompletionHandler({ [weak self] (image, error) -> () in
                if let image = (image ?? currentPhoto.thumbnailImage) {
                    let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                    activityController.popoverPresentationController?.barButtonItem = sender
                    self?.photosViewController?.present(activityController, animated: true, completion: nil)
                }
            });
        }
    }
    
    @IBAction func sendButtonTapped(_ sender: UIBarButtonItem) {
        if let currentPhoto = currentPhoto as? ZomPhotoStreamImage, let viewController = self.photosViewController {
            currentPhoto.loadImageWithCompletionHandler({ [weak self] (image, error) -> () in
                if let image = (image ?? currentPhoto.thumbnailImage) {
                    let _ = ZomImportManager.shared.handleImport(image: image, type: kUTTypeImage as String, viewController: viewController)
                }
            });
        }
    }
    
    @IBAction func deleteButtonTapped(_ sender: UIBarButtonItem) {
        if let viewController = self.photosViewController {
            viewController.handleDeleteButtonTapped()
        }
    }
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        if let viewController = self.photosViewController {
            viewController.dismiss(animated: true, completion: nil)
        }
    }
}
