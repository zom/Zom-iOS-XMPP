//
//  ZomStickerPackListViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-12.
//
//

import UIKit
import ChatSecureCore
import Photos

public class ZomStickerPackTableViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    private var stickerPacks: Array<String> = [];
    private(set) lazy var orderedViewControllers: [UIViewController] = []
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        let docsPath = NSBundle.mainBundle().resourcePath! + "/Stickers"
        let fileManager = NSFileManager.defaultManager()
        do {
            stickerPacks = try fileManager.contentsOfDirectoryAtPath(docsPath)
        } catch {
            print(error)
        }
        
        // Create view controllers
        for stickerPack in stickerPacks {
            let vc:ZomPickStickerViewController = self.storyboard?.instantiateViewControllerWithIdentifier("pickStickerViewController") as! ZomPickStickerViewController
            vc.stickerPack = stickerPack
            orderedViewControllers.append(vc)
        }
        dataSource = self
        delegate = self
        
        if let firstViewController:ZomPickStickerViewController = orderedViewControllers.first as? ZomPickStickerViewController {
            self.navigationItem.title = firstViewController.stickerPack
            setViewControllers([firstViewController],
                               direction: .Forward,
                               animated: true,
                               completion: nil)
        }
    }
    
    public func pageViewController(pageViewController: UIPageViewController,
                            viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.indexOf(viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    public func pageViewController(pageViewController: UIPageViewController,
                            viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.indexOf(viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
    public func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return orderedViewControllers.count
    }
    
    public func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        guard let firstViewController = viewControllers?.first,
            firstViewControllerIndex = orderedViewControllers.indexOf(firstViewController) else {
                return 0
        }
        
        return firstViewControllerIndex
    }
    
    public func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let vc:ZomPickStickerViewController = pageViewController.viewControllers?[0] as? ZomPickStickerViewController {
            self.navigationItem.title = vc.stickerPack
        }
    }
}