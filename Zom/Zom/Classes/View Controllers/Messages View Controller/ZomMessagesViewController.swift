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

var ZomMessagesViewController_associatedObject1: UInt8 = 0

extension OTRMessagesViewController {
    public override class func initialize() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        // make sure this isn't a subclass
        if self !== OTRMessagesViewController.self {
            return
        }
        
        dispatch_once(&Static.token) {
            ZomUtil.swizzle(self, originalSelector: #selector(OTRMessagesViewController.collectionView(_:messageDataForItemAtIndexPath:)), swizzledSelector:#selector(OTRMessagesViewController.zom_collectionView(_:messageDataForItemAtIndexPath:)))
            ZomUtil.swizzle(self, originalSelector: #selector(OTRMessagesViewController.collectionView(_:attributedTextForCellBottomLabelAtIndexPath:)), swizzledSelector: #selector(OTRMessagesViewController.zom_collectionView(_:attributedTextForCellBottomLabelAtIndexPath:)))
        }
    }
    
    var shieldIcon:UIImage? {
        get {
            return objc_getAssociatedObject(self, &ZomMessagesViewController_associatedObject1) as? UIImage ?? nil
        }
        set {
            objc_setAssociatedObject(self, &ZomMessagesViewController_associatedObject1, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func zom_collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> ChatSecureCore.JSQMessageData! {
        let ret = self.zom_collectionView(collectionView, messageDataForItemAtIndexPath: indexPath)
        if (ret != nil && ZomStickerMessage.isValidStickerShortCode(ret.text!())) {
            return ZomStickerMessage(message: ret)
        }
        return ret
    }
    
    public func zom_collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let string:NSMutableAttributedString = self.zom_collectionView(collectionView, attributedTextForCellBottomLabelAtIndexPath: indexPath) as! NSMutableAttributedString
        
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

public class ZomMessagesViewController: OTRMessagesHoldTalkViewController, UIGestureRecognizerDelegate {
    
    private var hasFixedTitleViewConstraints:Bool = false
    private var attachmentPickerController:OTRAttachmentPicker? = nil
    private var attachmentPickerView:UIView? = nil
    private var attachmentPickerTapRecognizer:UITapGestureRecognizer? = nil
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.cameraButton.setTitle(NSString.fa_stringForFontAwesomeIcon(FAIcon.FAPlusSquareO), forState: UIControlState.Normal)
    }
    
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
    
    public func selectSticker(pack:String, sticker: String) {
        super.didPressSendButton(super.sendButton, withMessageText: ":" + pack + "-" + sticker + ":", senderId: super.senderId, senderDisplayName: super.senderDisplayName, date: NSDate())
    }
    
    override public func refreshTitleView() -> Void {
        super.refreshTitleView()
        if (OTRAccountsManager.allAccountsAbleToAddBuddies().count < 2) {
            // Hide the account name if only one
            if let view = self.navigationItem.titleView as? OTRTitleSubtitleView {
                view.subtitleLabel.hidden = true
                view.subtitleImageView.hidden = true
                if (!hasFixedTitleViewConstraints && view.constraints.count > 0) {
                    var removeThese:[NSLayoutConstraint] = [NSLayoutConstraint]()
                    for constraint:NSLayoutConstraint in view.constraints {
                        if ((constraint.firstItem as? NSObject != nil && constraint.firstItem as! NSObject == view.titleLabel) || (constraint.secondItem as? NSObject != nil && constraint.secondItem as! NSObject == view.titleLabel)) {
                            if (constraint.active && (constraint.firstAttribute == NSLayoutAttribute.Top || constraint.firstAttribute == NSLayoutAttribute.Bottom)) {
                                removeThese.append(constraint)
                            }
                        }
                    }
                    view.removeConstraints(removeThese)
                    let c:NSLayoutConstraint = NSLayoutConstraint(item: view.titleLabel, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: view.titleLabel.superview, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
                    view.addConstraint(c);
                    hasFixedTitleViewConstraints = true
                }
            }
        }
    }
    
    override public func setupDefaultSendButton() {
        // Override this to always show Camera and Mic icons. We never get here
        // in a "knock" scenario.
        self.inputToolbar?.contentView?.leftBarButtonItem = self.cameraButton
        self.inputToolbar?.contentView?.leftBarButtonItem.enabled = false
        if (self.state.hasText) {
            self.inputToolbar?.contentView?.rightBarButtonItem = self.sendButton
            self.inputToolbar?.sendButtonLocation = JSQMessagesInputSendButtonLocation.Right
            self.inputToolbar?.contentView?.rightBarButtonItem.enabled = self.state.isThreadOnline
        } else {
            self.inputToolbar?.contentView?.rightBarButtonItem = self.microphoneButton
            self.inputToolbar?.contentView?.rightBarButtonItem.enabled = false
        }
    }
    
    override public func didPressAccessoryButton(sender: UIButton!) {
        let pickerView = getPickerView()
        self.view.addSubview(pickerView)
        var newFrame = pickerView.frame;
        let superBounds = self.view.bounds;
        newFrame.origin.y = superBounds.size.height - newFrame.size.height;
        UIView.animateWithDuration(0.3) {
            pickerView.frame = newFrame;
        }
    }
    
    func getPickerView() -> UIView {
        if (self.attachmentPickerView == nil) {
            self.attachmentPickerView = UINib(nibName: "AttachmentPicker", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as? UIView
            self.attachmentPickerView!.frame.size.width = self.view.frame.width
            self.attachmentPickerView!.frame.size.height = 100
            self.attachmentPickerView!.frame.origin.y = self.view.frame.height // Start hidden (below screen)
         
             self.attachmentPickerView!.viewWithTag(1)?.userInteractionEnabled = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary)
            self.attachmentPickerView!.viewWithTag(2)?.userInteractionEnabled = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)
            
            self.attachmentPickerTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onTap(_:)))
            self.attachmentPickerTapRecognizer!.cancelsTouchesInView = true
            self.attachmentPickerTapRecognizer!.delegate = self
            self.view.addGestureRecognizer(self.attachmentPickerTapRecognizer!)
        }
        return self.attachmentPickerView!
    }
    
    func onTap(sender: UIGestureRecognizer) {
        closePickerView()
    }
    
    func closePickerView() {
        // Tapped outside attachment picker. Close it.
        if (self.attachmentPickerTapRecognizer != nil) {
            self.view.removeGestureRecognizer(self.attachmentPickerTapRecognizer!)
            self.attachmentPickerTapRecognizer = nil
        }
        if (self.attachmentPickerView != nil) {
            var newFrame = self.attachmentPickerView!.frame;
            let superBounds = self.view.bounds;
            newFrame.origin.y = superBounds.size.height;
            UIView.animateWithDuration(0.3, animations: {
                    self.attachmentPickerView!.frame = newFrame;
                },
                                       completion: { (success) in
                                        self.attachmentPickerView?.removeFromSuperview()
                                        self.attachmentPickerView = nil
            })
        }
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @IBAction func attachmentPickerSelectPhotoWithSender(sender: AnyObject) {
        closePickerView()
        attachmentPicker().showImagePickerForSourceType(UIImagePickerControllerSourceType.PhotoLibrary)
    }
    
    @IBAction func attachmentPickerTakePhotoWithSender(sender: AnyObject) {
        closePickerView()
        attachmentPicker().showImagePickerForSourceType(UIImagePickerControllerSourceType.Camera)
    }
    
    func attachmentPicker() -> OTRAttachmentPicker {
        if (self.attachmentPickerController == nil) {
            self.attachmentPickerController = OTRAttachmentPicker(parentViewController: self.parentViewController?.parentViewController, delegate: (self as! OTRAttachmentPickerDelegate))
        }
        return self.attachmentPickerController!
    }
    
    @IBAction func attachmentPickerStickerWithSender(sender: AnyObject) {
        closePickerView()
        let storyboard = UIStoryboard(name: "StickerShare", bundle: nil)
        let vc = storyboard.instantiateInitialViewController()
        self.presentViewController(vc!, animated: true, completion: nil)
    }
}

extension UIImage
{
    func tint(color: UIColor, blendMode: CGBlendMode) -> UIImage
    {
        let drawRect = CGRectMake(0.0, 0.0, size.width, size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()
        CGContextScaleCTM(context!, 1.0, -1.0)
        CGContextTranslateCTM(context!, 0.0, -self.size.height)
        CGContextClipToMask(context!, drawRect, CGImage!)
        color.setFill()
        UIRectFill(drawRect)
        drawInRect(drawRect, blendMode: blendMode, alpha: 1.0)
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage!
    }
}

