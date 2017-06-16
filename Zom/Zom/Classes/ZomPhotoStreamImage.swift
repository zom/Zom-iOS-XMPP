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
    private let message:OTRMessageProtocol
    private var image:UIImage?
    private var buddy:OTRBuddy?
    public var progressUpdateBlock:IDMProgressUpdateBlock?
    
    public init(mediaItem: OTRMediaItem, message: OTRMessageProtocol) {
        self.mediaItem = mediaItem
        self.message = message
        super.init()
        OTRDatabaseManager.shared.readOnlyDatabaseConnection?.asyncRead({ (transaction) in
            self.buddy = self.message.threadOwner(with: transaction) as? OTRBuddy
        })
    }
    
    public func underlyingImage() -> UIImage? {
        return image
    }
    
    public func loadUnderlyingImageAndNotify() {
        self.loadUnderlyingImageAndNotify(callback: nil)
    }
 
    public func loadUnderlyingImageAndNotify(callback:((_ photo:ZomPhotoStreamImage) -> Void)?) {
        if let buddyUniqueId = buddy?.uniqueId {
            DispatchQueue.global().async {
                do {
                    let data = try OTRMediaFileManager.shared.data(for: self.mediaItem, buddyUniqueId: buddyUniqueId)
                    self.image = UIImage(data: data)
                    DispatchQueue.main.async {
                        if let cb = callback {
                            cb(self)
                        } else {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: IDMPhoto_LOADING_DID_END_NOTIFICATION), object: self)
                        }
                    }
                } catch {
                }
            }
        }
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
        caption.append(JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.messageDate))
        return caption
    }
    
    public func placeholderImage() -> UIImage? {
        return nil
    }
}
