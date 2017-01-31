//
//  ZomStickerMessage.swift
//  Zom
//

import UIKit
import ChatSecureCore
import JSQMessagesViewController

public class ZomStickerMessage: NSObject, JSQMessageData {

    private var originalMessage:JSQMessageData
    private lazy var mediaObject:ZomStickerMessageMedia? = { [unowned self] in
        return ZomStickerMessageMedia(filePath: ZomStickerMessage.getStickerFilenameFromMessage(self.originalMessage.text!()))
    }()
    
    public init(message : JSQMessageData) {
        originalMessage = message
    }
    
    public func senderDisplayName() -> String! {
        return self.originalMessage.senderDisplayName()
    }
    
    public func date() -> NSDate {
        return originalMessage.date()
    }

    public func messageHash() -> UInt {
        return originalMessage.messageHash()
    }
    
    public func senderId() -> String! {
        return originalMessage.senderId()
    }
    
    public func isMediaMessage() -> Bool {
        return true
    }
    
    public func media() -> JSQMessageMediaData! {
        return self.mediaObject
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
            let regex = try! NSRegularExpression(pattern: "[^a-zA-Z0-9_& ]+", options: [])
            let messagePack = regex.stringByReplacingMatchesInString(components[0], options: [], range: NSMakeRange(0, components[0].characters.count), withTemplate: "")
            let messageSticker = regex.stringByReplacingMatchesInString(components[1], options: [], range: NSMakeRange(0, components[1].characters.count), withTemplate: "")
            return getFilenameForSticker(messageSticker, inPack: messagePack)
        }
        return nil
    }
    
    public static func getFilenameForSticker(sticker:String, inPack pack:String) -> String? {
        var foundPack:String?
        var foundSticker:String?
        
        // iOS is case sensitive, so need to match file case
        //
        let docsPath = NSBundle.mainBundle().resourcePath! + "/Stickers"
        let fileManager = NSFileManager.defaultManager()
        do {
            let stickerPacks = try fileManager.contentsOfDirectoryAtPath(docsPath)
            for stickerPack in stickerPacks {
                if (stickerPack.caseInsensitiveCompare(pack) == NSComparisonResult.OrderedSame) {
                    foundPack = stickerPack
                    
                    let stickers = try fileManager.contentsOfDirectoryAtPath(docsPath + "/" + foundPack!)
                    for s in stickers {
                        if (s.caseInsensitiveCompare(sticker + ".png") == NSComparisonResult.OrderedSame) {
                            foundSticker = s
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
        return nil
    }
}
   
