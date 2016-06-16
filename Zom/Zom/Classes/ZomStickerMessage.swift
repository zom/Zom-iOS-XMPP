//
//  ZomStickerMessage.swift
//  Zom
//

import UIKit
import ChatSecureCore

public class ZomStickerMessage: OTRMessage {

    private var originalMessage:ChatSecureCore.JSQMessageData!
    private var mediaObject:ZomStickerMessageMedia?
    
    public init(message : ChatSecureCore.JSQMessageData!) {
        super.init()
        originalMessage = message
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public required init(dictionary dictionaryValue: [NSObject : AnyObject]!) throws {
        try super.init(dictionary: dictionaryValue)
    }
    
    public override func senderId() -> String! {
        return originalMessage.senderId()
    }
    
    override public func isMediaMessage() -> Bool {
        return true
    }
    
    override public func media() -> ChatSecureCore.JSQMessageMediaData! {
        if (mediaObject == nil) {
            mediaObject = ZomStickerMessageMedia(filePath: ZomStickerMessage.getStickerFilenameFromMessage(originalMessage.text!()))
        }
        return mediaObject!
    }
    
    public static func isValidStickerShortCode(message:String?) -> Bool {
        if (message != nil && message!.hasPrefix(":") && message!.hasSuffix(":")) {
            if let fileName = getStickerFilenameFromMessage(message) {
                if (NSFileManager.defaultManager().fileExistsAtPath(fileName)) {
                    return true
                }
            }
        }
        return false
    }
    
    private static func getStickerFilenameFromMessage(message:String!) -> String? {
        let stickerDescription = message.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: ":"))
        let components = stickerDescription.componentsSeparatedByString("-")
        if (components.count == 2) {
            let regex = try! NSRegularExpression(pattern: "[^a-zA-Z0-9_&]+", options: [])
            let messagePack = regex.stringByReplacingMatchesInString(components[0], options: [], range: NSMakeRange(0, components[0].characters.count), withTemplate: "")
            let messageSticker = regex.stringByReplacingMatchesInString(components[1], options: [], range: NSMakeRange(0, components[1].characters.count), withTemplate: "")
            
            var foundPack:String?
            var foundSticker:String?
            
            // iOS is case sensitive, so need to match file case
            //
            let docsPath = NSBundle.mainBundle().resourcePath! + "/Stickers"
            let fileManager = NSFileManager.defaultManager()
            do {
                let stickerPacks = try fileManager.contentsOfDirectoryAtPath(docsPath)
                for stickerPack in stickerPacks {
                    if (stickerPack.caseInsensitiveCompare(messagePack) == NSComparisonResult.OrderedSame) {
                        foundPack = stickerPack
                        
                        let stickers = try fileManager.contentsOfDirectoryAtPath(docsPath + "/" + foundPack!)
                        for sticker in stickers {
                            if (sticker.caseInsensitiveCompare(messageSticker + ".png") == NSComparisonResult.OrderedSame) {
                                foundSticker = sticker
                                break
                            }
                        }
                        break
                    }
                }
            } catch {
                print(error)
            }
            
            if (foundPack != nil && foundSticker != nil) {
                return NSBundle.mainBundle().resourcePath! + "/Stickers/" + foundPack! + "/" + foundSticker!
            }
        }
        return nil
    }
}
   