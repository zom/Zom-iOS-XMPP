//
//  ZomStickerMessage.swift
//  Zom
//

import UIKit
import ChatSecureCore
import JSQMessagesViewController

open class ZomStickerMessage: NSObject, JSQMessageData {

    private var originalMessage:JSQMessageData
    private lazy var mediaObject:ZomStickerMessageMedia? = { [unowned self] in
        return ZomStickerMessageMedia(filename: ZomStickerMessage.getStickerFilenameFromMessage(self.originalMessage.text!())!, mimeType: "image/png", isIncoming: true)
    }()
    
    public init(message : JSQMessageData) {
        originalMessage = message
    }
    
    open func senderDisplayName() -> String! {
        return self.originalMessage.senderDisplayName()
    }
    
    open func date() -> Date {
        return originalMessage.date()
    }

    open func messageHash() -> UInt {
        return originalMessage.messageHash()
    }
    
    open func senderId() -> String! {
        return originalMessage.senderId()
    }
    
    open func isMediaMessage() -> Bool {
        return true
    }
    
    open func media() -> JSQMessageMediaData! {
        return self.mediaObject!
    }
    
    open static func isValidStickerShortCode(_ message:String?) -> Bool {
        if (message != nil && message!.hasPrefix(":") && message!.hasSuffix(":")) {
            if let fileName = getStickerFilenameFromMessage(message) {
                if (FileManager.default.fileExists(atPath: fileName)) {
                    return true
                }
            }
        }
        return false
    }
    
    fileprivate static func getStickerFilenameFromMessage(_ message:String!) -> String? {
        let stickerDescription = message.trimmingCharacters(in: CharacterSet(charactersIn: ":"))
        if let firstDash = stickerDescription.index(of: "-") {
            let packPart = String(stickerDescription[..<firstDash])
            let stickerPart = String(stickerDescription[stickerDescription.index(firstDash, offsetBy: 1)...])
            let regex = try! NSRegularExpression(pattern: "[^a-zA-Z0-9_& -]+", options: [])
            let messagePack = regex.stringByReplacingMatches(in: packPart, options: [], range: NSMakeRange(0, packPart.count), withTemplate: "")
            let messageSticker = regex.stringByReplacingMatches(in: stickerPart, options: [], range: NSMakeRange(0, stickerPart.count), withTemplate: "")
            return getFilenameForSticker(messageSticker, inPack: messagePack)
        }
        return nil
    }
    
    open static func getFilenameForSticker(_ sticker:String, inPack pack:String) -> String? {
        var foundPack:String?
        var foundSticker:String?
        
        // iOS is case sensitive, so need to match file case
        //
        let docsPath = Bundle.main.resourcePath! + "/Stickers"
        let fileManager = FileManager.default
        do {
            let stickerPacks = try fileManager.contentsOfDirectory(atPath: docsPath)
            for stickerPack in stickerPacks {
                let stickerPackName = String(stickerPack[stickerPack.index(stickerPack.startIndex, offsetBy: 3)...])
                if (stickerPackName.caseInsensitiveCompare(pack) == ComparisonResult.orderedSame) {
                    foundPack = stickerPack
                    
                    let stickers = try fileManager.contentsOfDirectory(atPath: docsPath + "/" + foundPack!)
                    for s in stickers {
                        var sName = s
                        if s.hasPrefix("_") {
                            sName = String(s[s.index(s.startIndex, offsetBy: 1)...])
                        }
                        if (sName.caseInsensitiveCompare(sticker + ".png") == ComparisonResult.orderedSame) {
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
            return Bundle.main.resourcePath! + "/Stickers/" + foundPack! + "/" + foundSticker!
        }
        return nil
    }
}
   
