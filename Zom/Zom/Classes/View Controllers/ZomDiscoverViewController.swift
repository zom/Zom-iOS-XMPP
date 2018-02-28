//
//  ZomDiscoverViewController.swift
//  Zom
//
//  Created by N-Pex on 2016-11-15.
//
//

import Foundation
import XMPPFramework
import OTRKit
import INSPhotoGallery

open class ZomDiscoverViewController: UIViewController, ZomPickStickerViewControllerDelegate {

    @IBOutlet weak var pickStickerButton: UIButton!
    var shareStickerOnResume:String?
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (shareStickerOnResume != nil) {
            shareSticker(shareStickerOnResume!)
            shareStickerOnResume = nil;
        }
    }
    
    @IBAction func didPressZomServicesButtonWithSender(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "segueToZomBots", sender: self)
    }
    
    @IBAction func didPressCreateGroupButtonWithSender(_ sender: AnyObject) {
        if let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate {
            ZomComposeViewController.openInGroupMode = true
            appDelegate.conversationViewController.perform(#selector(appDelegate.conversationViewController.composeButtonPressed(_:)), with: sender)
        }
    }

    @IBAction func didPressPhotoStreamButtonWithSender(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "segueToPhotoStream", sender: self)
    }
    
    @IBAction func didPressChangeThemeButtonWithSender(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "segueToPickColor", sender: self)
    }

    @IBAction func didPressStickerShareButtonWithSender(_ sender: AnyObject) {
        let storyboard = UIStoryboard(name: "StickerShare", bundle: Bundle.main)
        let vc = storyboard.instantiateInitialViewController()
        self.tabBarController?.present(vc!, animated: true, completion: nil)
    }
    
    @IBAction func unwindPickColorWithUnwindSegue(_ unwindSegue: UIStoryboardSegue) {
        print("Unwind!")
    }
    
    func selectThemeColor(_ color: UIColor?) {
        if (color != nil) {
            if let theme = GlobalTheme.shared as? ZomTheme {
                theme.selectMainThemeColor(color)
                self.navigationController?.navigationBar.barTintColor = theme.mainThemeColor
                self.navigationController?.navigationBar.backgroundColor = theme.mainThemeColor
                self.tabBarController?.tabBar.backgroundColor = theme.mainThemeColor
                self.tabBarController?.tabBar.barTintColor = theme.mainThemeColor
            }
        }
    }
    
    @IBAction func unwindPickSticker(_ unwindSegue: UIStoryboardSegue) {
    }
    
    open func didPickSticker(_ sticker: String, inPack pack: String) {
        if let fileName =
            ZomStickerMessage.getFilenameForSticker(sticker, inPack: pack) {
            shareStickerOnResume = fileName
        }
    }
    
    private func shareSticker(_ fileName: String) {
        if let image = UIImage(contentsOfFile: fileName) {
            let shareItems:Array = [image]
            
            let activityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
            //activityViewController!.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypePostToWeibo, UIActivityTypeCopyToPasteboard, UIActivityTypeAddToReadingList, UIActivityTypePostToVimeo]
            if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone {
                self.tabBarController!.present(activityViewController, animated: true, completion: nil)
            } else {
                let popup: UIPopoverController = UIPopoverController(contentViewController: activityViewController)
                popup.present(from: pickStickerButton.bounds, in: pickStickerButton, permittedArrowDirections: UIPopoverArrowDirection.any, animated: true)
            }
        }
    }
}
