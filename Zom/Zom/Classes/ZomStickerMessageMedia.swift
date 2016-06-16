//
//  ZomStickerMessageMedia.swift
//  Zom
//

import UIKit
import ChatSecureCore

public class ZomStickerMessageMedia: OTRMediaItem {

    private var imageView:UIView?
    private var filePath:String?
    
    public init(filePath: String?) {
        super.init()
        self.filePath = filePath
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public required init(dictionary dictionaryValue: [NSObject : AnyObject]!) throws {
        try super.init(dictionary: dictionaryValue)
    }
    
    override public func mediaView() -> UIView! {
        if (imageView == nil && filePath != nil && NSFileManager.defaultManager().fileExistsAtPath(filePath!)) {
            if let image = UIImage(contentsOfFile: filePath!) {
                let size = self.mediaViewDisplaySize()
                imageView = UIImageView(image: image)
                imageView!.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                imageView!.contentMode = UIViewContentMode.ScaleAspectFit
                imageView!.clipsToBounds = true
                JSQMessagesMediaViewBubbleImageMasker.applyBubbleImageMaskToMediaView(imageView, isOutgoing: false)
            }
        }
        return imageView
    }
}