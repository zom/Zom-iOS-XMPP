//
//  ZomStickerMessageMedia.swift
//  Zom
//

import UIKit
import ChatSecureCore

open class ZomStickerMessageMedia: OTRMediaItem {

    private var imageView:UIView?
    private var filePath:String?
    
    public init(filePath: String?) {
        super.init()
        self.filePath = filePath
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public required init(dictionary dictionaryValue: [AnyHashable: Any]!) throws {
        try super.init(dictionary: dictionaryValue)
    }
    
    required public init!(uniqueId: String) {
        super.init(uniqueId: uniqueId)
    }
    
    override open func mediaView() -> UIView! {
        if (imageView == nil && filePath != nil && FileManager.default.fileExists(atPath: filePath!)) {
            if let image = UIImage(contentsOfFile: filePath!) {
                let size = self.mediaViewDisplaySize()
                imageView = UIImageView(image: image)
                imageView!.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                imageView!.contentMode = UIViewContentMode.scaleAspectFit
                imageView!.clipsToBounds = true
                JSQMessagesMediaViewBubbleImageMasker.applyBubbleImageMask(toMediaView: imageView, isOutgoing: false)
            }
        }
        return imageView
    }
}
