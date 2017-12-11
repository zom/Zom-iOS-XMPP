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
    public let mediaItem:OTRMediaItem
    public let message:OTRMessageProtocol
    public var threadOwner:OTRThreadOwner?
    private var operationQueue:OperationQueue?
    private var loadOperation:Operation?
    
    public var attributedTitle: NSAttributedString?
    
    private var thumbIdentifier:String {
        get {
            return String(format: "%@_thumb", self.mediaItem.uniqueId)
        }
    }
    
    public init(mediaItem: OTRMediaItem, message: OTRMessageProtocol, threadOwner: OTRThreadOwner?,operationQueue:OperationQueue) {
        self.mediaItem = mediaItem
        self.message = message
        self.threadOwner = threadOwner
        self.operationQueue = operationQueue
        super.init()
        
        let caption = NSMutableAttributedString()
        if let buddy = self.threadOwner as? OTRBuddy {
            caption.append(NSAttributedString(string: buddy.displayName))
            caption.append(NSAttributedString(string: "\n"))
            let range = NSRange(location: 0, length: caption.length)
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            caption.addAttributes([NSAttributedStringKey.foregroundColor : UIColor.white, NSAttributedStringKey.paragraphStyle: paragraph], range: range)
        }
        caption.append(JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.messageDate))
        self.attributedTitle = caption
    }
    
    public func date() -> Date {
        return message.messageDate
    }
    
    func releaseImages() {
        thumbnailImage = nil
        loadOperation?.cancel()
        loadOperation = nil
    }
    
    private func getCachedThumbnail() -> UIImage? {
        return self.thumbnailImage ?? OTRImages.image(withIdentifier: thumbIdentifier)
    }
    
    public func loadImage(withPriority priority: Operation.QueuePriority, completion: @escaping (UIImage?, Error?) -> ()) {
        if let threadIdentifier = threadOwner?.threadIdentifier {
            if let previousLoad = loadOperation, !previousLoad.isFinished {
                previousLoad.cancel()
            }
            loadOperation = BlockOperation(block: {
                do {
                    let data = try OTRMediaFileManager.shared.data(for: self.mediaItem, buddyUniqueId: threadIdentifier)
                    
                    // Check if we are cancelled
                    guard !(self.loadOperation?.isCancelled ?? true) else {return}
                    
                    // TODO - if we know the image size, use UIImage(data:scale:)
                    var image = UIImage(data: data)
                    
                    // Scale images for low memory devices
                    guard !(self.loadOperation?.isCancelled ?? true) else {return}
                    let memory = ProcessInfo.processInfo.physicalMemory
                    if memory <= 1024 * 1024 * 512, let original = image {
                        let screenWidth = UIScreen.main.bounds.width
                        let screenHeight = UIScreen.main.bounds.height
                        image = original.aspectFill(size: CGSize(width: screenWidth, height: screenHeight))
                    }
                    guard !(self.loadOperation?.isCancelled ?? true) else {return}
                    DispatchQueue.main.async {
                        completion(image, nil)
                    }
                } catch {
                }
            })
            if let loadOperation = loadOperation {
                loadOperation.queuePriority = priority
                operationQueue?.addOperation(loadOperation)
            }
        }
    }
    
    public func loadThumbnailImageWithSizeAndCompletionHandler(_ size:CGSize, completion: @escaping (UIImage?, Error?) -> ()) {
        
        let doneLoading:(() -> Bool) = {() in
            if let thumbnail = self.getCachedThumbnail() {
                DispatchQueue.main.async {
                    completion(thumbnail, nil)
                }
                return true
            }
            return false
        }
        if !doneLoading() {
            loadImage(withPriority: .normal, completion: { (image, error) in
                if let image = image {
                    self.thumbnailImage = image.aspectFill(size: size)
                    if let thumbnail = self.thumbnailImage {
                        OTRImages.setImage(thumbnail, forIdentifier: self.thumbIdentifier)
                    }
                }
                if !doneLoading() {
                    DispatchQueue.main.async {
                        completion(nil, nil)
                    }
                }
            })
        }
    }
    
    // MARK: INSPhotoViewable
    public func loadImageWithCompletionHandler(_ completion: @escaping (UIImage?, Error?) -> ()) {
        loadImage(withPriority: .high, completion: completion)
    }
    
    public func loadThumbnailImageWithCompletionHandler(_ completion: @escaping (UIImage?, Error?) -> ()) {
        completion(getCachedThumbnail(), nil)
    }
    
    public var isDeletable: Bool {
        return false
    }
}

extension UIImage {
    func aspectFill(size:CGSize) -> UIImage? {
        if self.size.width > size.width || self.size.height > size.height {
            let aspect = max(self.size.width / size.width, self.size.height / size.height)
            return UIImage.otr_image(with: self, scaledTo: CGSize(width:self.size.width / aspect, height:self.size.height / aspect))
        }
        return self
    }
}
