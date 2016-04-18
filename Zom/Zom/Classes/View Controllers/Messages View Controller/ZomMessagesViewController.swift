//
//  ZomMessagesViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-11.
//
//

import UIKit
import ChatSecureCore
import JSQMessagesViewController
import OTRAssets
import BButton

public class ZomMessagesViewController: OTRMessagesHoldTalkViewController {
    
    private var shieldIcon:UIImage? = nil;
    
    public func attachmentPicker(attachmentPicker: OTRAttachmentPicker!, addAdditionalOptions alertController: UIAlertController!) {
        
        let sendStickerAction: UIAlertAction = UIAlertAction(title: OTRLanguageManager.translatedString("Sticker"), style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            let storyboard = UIStoryboard(name: "StickerShare", bundle: nil)
            let vc = storyboard.instantiateInitialViewController()
            self.presentViewController(vc!, animated: true, completion: nil)
        })
        alertController.addAction(sendStickerAction)
    }
    
    @IBAction func unwindPickSticker(unwindSegue: UIStoryboardSegue) {
    }
    
    public func selectSticker(filePath: String) {
        super.sendImageFilePath(filePath, asJPEG: false, shouldResize: false)
    }
    
    public override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let string:NSMutableAttributedString = super.collectionView(collectionView, attributedTextForCellBottomLabelAtIndexPath: indexPath) as! NSMutableAttributedString

        let lock = NSString.fa_stringForFontAwesomeIcon(FAIcon.FALock);
        let unlock = NSString.fa_stringForFontAwesomeIcon(FAIcon.FAUnlock);
        
        let asd:NSString = string.string

        let rangeLock:NSRange = asd.rangeOfString(lock);
        if (rangeLock.location != NSNotFound) {
            let attachment = textAttachment(12)
            let newLock = NSAttributedString.init(attachment: attachment);
            string.replaceCharactersInRange(rangeLock, withAttributedString: newLock)
        }

        let rangeUnLock:NSRange = asd.rangeOfString(unlock);
        if (rangeUnLock.location != NSNotFound) {
            let nothing = NSAttributedString.init(string: "");
            string.replaceCharactersInRange(rangeUnLock, withAttributedString: nothing)
        }
        return string;
    }
    
    func textAttachment(fontSize: CGFloat) -> NSTextAttachment {
        var font:UIFont? = UIFont(name: kFontAwesomeFont, size: fontSize)
        if (font == nil) {
            font = UIFont.systemFontOfSize(fontSize)
        }
        let textAttachment = NSTextAttachment()
        let image = getTintedShieldIcon()
        textAttachment.image = image
        let aspect = image.size.width / image.size.height
        let height = font?.capHeight
        textAttachment.bounds = CGRectIntegral(CGRect(x:0,y:0,width:(height! * aspect),height:height!))
        return textAttachment
    }
    
    func getTintedShieldIcon() -> UIImage {
        if (self.shieldIcon == nil) {
            let image = UIImage.init(named: "ic_security_white_36pt")
            self.shieldIcon = image?.tint(UIColor.lightGrayColor(), blendMode: CGBlendMode.Multiply)
        }
        return shieldIcon!
    }
}

extension UIImage
{
    func tint(color: UIColor, blendMode: CGBlendMode) -> UIImage
    {
        let drawRect = CGRectMake(0.0, 0.0, size.width, size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()
        CGContextScaleCTM(context, 1.0, -1.0)
        CGContextTranslateCTM(context, 0.0, -self.size.height)
        CGContextClipToMask(context, drawRect, CGImage)
        color.setFill()
        UIRectFill(drawRect)
        drawInRect(drawRect, blendMode: blendMode, alpha: 1.0)
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage
    }
}

