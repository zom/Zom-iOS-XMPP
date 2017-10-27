//
//  ZomPhotosViewController.swift
//  Zom
//
//  Created by N-Pex on 2017-10-27.
//

import UIKit
import ChatSecureCore
import INSPhotoGallery

open class ZomPhotosViewController: INSPhotosViewController {
    open override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override open func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        super.pageViewController(pageViewController, didFinishAnimating: finished, previousViewControllers: previousViewControllers, transitionCompleted: completed)
        for vc in previousViewControllers {
            if let photoViewController = vc as? INSPhotoViewController {
                let subviews = photoViewController.view.subviews
                for view in subviews {
                    view.removeFromSuperview()
                }
            }
        }
        
    }
}

