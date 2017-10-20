//
//  ZomPhotoStreamImage.swift
//  Zom
//
//  Created by N-Pex on 2017-06-13.
//
//

import UIKit
import INSPhotoGallery

open class ZomPhotoStreamImage: NSObject, INSPhotoViewable {
    public var image: UIImage?
    public var thumbnailImage: UIImage?
    private let mediaItem:OTRMediaItem
    private let message:OTRMessageProtocol
    private var threadOwner:OTRThreadOwner?
    public var attributedTitle: NSAttributedString?

    public init(mediaItem: OTRMediaItem, message: OTRMessageProtocol, threadOwner: OTRThreadOwner?) {
        self.mediaItem = mediaItem
        self.message = message
        self.threadOwner = threadOwner
        super.init()
        
        let caption = NSMutableAttributedString()
        if let buddy = self.threadOwner as? OTRBuddy {
            caption.append(NSAttributedString(string: buddy.displayName))
            caption.append(NSAttributedString(string: "\n"))
            let range = NSRange(location: 0, length: caption.length)
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            caption.addAttributes([NSForegroundColorAttributeName : UIColor.white, NSParagraphStyleAttributeName: paragraph], range: range)
        }
        caption.append(JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.messageDate))
        self.attributedTitle = caption
    }
    
    public func date() -> Date {
        return message.messageDate
    }
    
    func releaseImages() {
        thumbnailImage = nil
    }
    
    public func loadImageWithCompletionHandler(_ completion: @escaping (UIImage?, Error?) -> ()) {
        if let threadIdentifier = threadOwner?.threadIdentifier() {
            DispatchQueue.global().async {
                do {
                    let data = try OTRMediaFileManager.shared.data(for: self.mediaItem, buddyUniqueId: threadIdentifier)
                    let image = UIImage(data: data)
                    DispatchQueue.main.async {
                        completion(image, nil)
                    }
                } catch {
                }
            }
        }
    }
    
    public func loadThumbnailImageWithCompletionHandler(_ completion: @escaping (UIImage?, Error?) -> ()) {
        completion(nil, nil)
    }

    public func loadThumbnailImageWithSizeAndCompletionHandler(_ size:CGSize, completion: @escaping (UIImage?, Error?) -> ()) {
        let doneLoading:(() -> Bool) = {() in
            if let thumbnail = self.thumbnailImage {
                DispatchQueue.main.async {
                    completion(thumbnail, nil)
                }
                return true
            }
            return false
        }
        if !doneLoading() {
            loadImageWithCompletionHandler({ (image, error) in
                if let image = image {
                    self.thumbnailImage = UIImage.otr_image(with: image, scaledTo: size)
                }
                if !doneLoading() {
                    DispatchQueue.main.async {
                        completion(nil, nil)
                    }
                }
            })
        }
    }
    
    public var isDeletable: Bool {
        return false
    }
}

