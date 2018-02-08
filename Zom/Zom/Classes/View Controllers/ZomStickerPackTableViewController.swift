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

open class ZomStickerPackTableViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    private var stickerPacks: Array<String> = [];
    private(set) lazy var orderedViewControllers: [UIViewController] = []
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        let docsPath = Bundle.main.resourcePath! + "/Stickers"
        let fileManager = FileManager.default
        do {
            // Sticker packs are sorted by a three character prefix of the file folders, like 00 losar
            stickerPacks = try fileManager.contentsOfDirectory(atPath: docsPath).sorted { (s1, s2) -> Bool in
                return s1.compare(s2) != .orderedDescending
            }
        } catch {
            print(error)
        }
        
        // Create view controllers
        for stickerPack in stickerPacks {
            let vc:ZomPickStickerViewController = self.storyboard?.instantiateViewController(withIdentifier: "pickStickerViewController") as! ZomPickStickerViewController
            vc.stickerPackFileName = stickerPack
            // Remove prefix
            vc.stickerPack = String(stickerPack[stickerPack.index(stickerPack.startIndex, offsetBy: 3)...])
            orderedViewControllers.append(vc)
        }
        dataSource = self
        delegate = self
        
        if let firstViewController:ZomPickStickerViewController = orderedViewControllers.first as? ZomPickStickerViewController {
            self.navigationItem.title = firstViewController.stickerPack
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
        }
    }
    
    open func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
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
    
    open func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
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
    
    open func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return orderedViewControllers.count
    }
    
    open func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstViewController = viewControllers?.first,
            let firstViewControllerIndex = orderedViewControllers.index(of: firstViewController) else {
                return 0
        }
        
        return firstViewControllerIndex
    }
    
    open func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let vc:ZomPickStickerViewController = pageViewController.viewControllers?[0] as? ZomPickStickerViewController {
            self.navigationItem.title = vc.stickerPack
        }
    }
}
