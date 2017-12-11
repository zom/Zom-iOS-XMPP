//
//  ZomGalleryHandler.swift
//  Zom
//
//  Created by N-Pex on 2017-11-07.
//

public protocol ZomGalleryHandlerDelegate {
    func galleryHandlerDidStartFetching(_ galleryHandler: ZomGalleryHandler)
    func galleryHandlerDidFinishFetching(_ galleryHandler: ZomGalleryHandler, images:[ZomPhotoStreamImage], initialImage:ZomPhotoStreamImage?)
}

public class ZomGalleryHandler: NSObject {
    
    let connection: YapDatabaseConnection
    var internalQueue:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Image loading queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    public var images:[ZomPhotoStreamImage] = []
    var isCanceled = false
    
    deinit {
        internalQueue.cancelAllOperations()
        for image in images {
            image.releaseImages()
        }
    }
    
    @objc public init(connection: YapDatabaseConnection) {
        self.connection = connection
        super.init()
    }
    
    public func cancelFetching() {
        isCanceled = true
        internalQueue.cancelAllOperations()
        images = []
    }
    
    public func fetchImagesAsync(for threadIdentifier:String?, initialPhoto:OTRImageItem?, delegate:ZomGalleryHandlerDelegate) {

        internalQueue.cancelAllOperations()
        images = []
        isCanceled = false
        delegate.galleryHandlerDidStartFetching(self)
        
        connection.asyncRead({ (transaction) in
            var array:[OTRImageItem] = [OTRImageItem]()
            let collection = OTRMediaItem.collection
            let allMediaItemKeys = transaction.allKeys(inCollection: collection)
            allMediaItemKeys.forEach({ (key) in
                if let object = transaction.object(forKey: key, inCollection: collection) as? OTRImageItem, object.transferProgress == 1 {
                    if threadIdentifier == nil || object.parentMessage(with: transaction)?.threadId == threadIdentifier {
                    array.append(object)
                }
                }
            })
            var initialPhotoObject:ZomPhotoStreamImage?
            if array.count > 0 {
                self.images = [ZomPhotoStreamImage]()
                array.forEach({ (mediaItem) in
                    if let message = mediaItem.parentMessage(with: transaction) {
                        do {
                            let dataLength = try OTRMediaFileManager.shared.dataLength(for: mediaItem, buddyUniqueId: message.threadId)
                            if dataLength.intValue > 0 {
                                let p = ZomPhotoStreamImage(mediaItem: mediaItem, message: message, threadOwner:message.threadOwner(with: transaction), operationQueue: self.internalQueue)
                                self.images.append(p)
                                if initialPhoto?.uniqueId.compare(mediaItem.uniqueId) == .orderedSame {
                                    initialPhotoObject = p
                                }
                            }
                        } catch {
                        }
                    }
                })
                self.images.sort(by: { (item1, item2) -> Bool in
                    return item1.date().compare(item2.date()) == .orderedAscending
                })
            }
            DispatchQueue.main.async {
                if !self.isCanceled {
                    delegate.galleryHandlerDidFinishFetching(self, images: self.images, initialImage: initialPhotoObject)
                }
            }
        });
    }
}
