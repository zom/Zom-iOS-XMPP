//
//  ZomStickerMessageMedia.swift
//  Zom
//

import UIKit
import ChatSecureCore

open class ZomStickerMessageMedia: OTRMediaItem {

    private var imageView:UIView?
    
    override open func mediaView() -> UIView! {
        if (imageView == nil && FileManager.default.fileExists(atPath: filename)) {
            if let image = UIImage(contentsOfFile: filename) {
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
