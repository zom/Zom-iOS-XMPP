//
//  ZomPhotoStreamImage.swift
//  Zom
//
//  Created by N-Pex on 2017-06-13.
//
//

import UIKit
import IDMPhotoBrowser

open class ZomPhotoStreamImage: NSObject, IDMPhotoProtocol {

    private let mediaItem:OTRMediaItem
    private let message:OTRBaseMessage
    private var image:UIImage?
    private var buddy:OTRBuddy?
    public var progressUpdateBlock:IDMProgressUpdateBlock?
    
    public init(mediaItem: OTRMediaItem, message: OTRBaseMessage) {
        self.mediaItem = mediaItem
        self.message = message
        super.init()
        OTRDatabaseManager.shared.readOnlyDatabaseConnection?.asyncRead({ (transaction) in
            self.buddy = self.message.buddy(with: transaction)
        })
    }
    
    public func underlyingImage() -> UIImage? {
        return image
    }
    
    public func loadUnderlyingImageAndNotify() {
        self.loadUnderlyingImageAndNotify(callback: nil)
    }
 
    public func loadUnderlyingImageAndNotify(callback:((_ photo:ZomPhotoStreamImage) -> Void)?) {
        OTRMediaFileManager.sharedInstance().data(for: mediaItem, buddyUniqueId: message.buddyUniqueId, completion: { (data, error) in
            if error == nil, let data = data {
                self.image = UIImage(data: data)
                if let cb = callback {
                    cb(self)
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: IDMPhoto_LOADING_DID_END_NOTIFICATION), object: self)
                }
            }
        }, completionQueue: nil)
    }
    
    public func unloadUnderlyingImage() {
        self.image = nil
    }
    
    public func caption() -> String? {
        return nil
    }
    
    public func attributedCaption() -> NSAttributedString? {
        let caption = NSMutableAttributedString()
        if let buddy = buddy {
            caption.append(NSAttributedString(string: buddy.username))
            caption.append(NSAttributedString(string: "\n"))
        }
        caption.append(JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date))
        return caption
    }
    
    public func placeholderImage() -> UIImage? {
        return nil
    }
}
