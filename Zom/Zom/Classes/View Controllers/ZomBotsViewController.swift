//
//  ZomBotsViewController.swift
//  Zom
//
//  Created by N-Pex on 2018-02-08.
//

import UIKit
import ChatSecureCore

fileprivate struct ZomBot {
    let name:String
    let jid:String
    let description:String
    let image:UIImage?
    let avatar:Data?
    
    static var allBots:[ZomBot] = {
        // Parse the plist to get all bots!
        var plistDictionary: NSDictionary?
        if let path = Bundle.main.path(forResource: "ZomBots", ofType: "plist") {
            plistDictionary = NSDictionary(contentsOfFile: path)
        }
        var bots:[ZomBot] = []
        if let dict = plistDictionary {
            for (key, bot) in dict {
                if let bot = bot as? NSDictionary {
                    let name = bot["name"] as? String
                    let jid = bot["jid"] as? String
                    let description = bot["description"] as? String
                    
                    // Get image
                    var image:UIImage? = nil
                    if let imageStringEncoded = bot["image"] as? String {
                        let dataDecoded : Data = Data(base64Encoded: imageStringEncoded, options: .ignoreUnknownCharacters)!
                        image = UIImage(data: dataDecoded)
                    }
                    
                    var avatar:Data? = nil
                    if let avatarStringEncoded = bot["avatar"] as? String {
                        avatar = Data(base64Encoded: avatarStringEncoded, options: .ignoreUnknownCharacters)!
                    }
                    let zomBot = ZomBot(name: name ?? "", jid: jid ?? "", description: description ?? "", image: image, avatar: avatar)
                    bots.append(zomBot)
                }
            }
        }
        return bots
    }()
}

open class ZomBotsViewController: UITableViewController {

    open override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ZomBot.allBots.count
    }

    open override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 175
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:ZomBotCell? = tableView.dequeueReusableCell(withIdentifier: "cellZomBot", for: indexPath) as? ZomBotCell
        if let cell = cell {
            let bot = ZomBot.allBots[indexPath.row]
            cell.botImageView.image = bot.image
            cell.titleLabel.text = bot.name
            cell.descriptionLabel.text = bot.description
            
            // Use tag to store index, used in didPressStartChatButton below
            cell.startChatButton.tag = indexPath.row
            cell.selectionStyle = .none
            return cell
        }
        return UITableViewCell() // Error
    }
    
    @IBAction func didPressStartChatButtonWithSender(_ sender: AnyObject) {
        if let button = sender as? UIButton {
            let bot = ZomBot.allBots[button.tag]
            if let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate,
                let buddy = getZombotBuddy(bot: bot) {
                self.navigationController?.popViewController(animated: false)
                appDelegate.splitViewCoordinator.enterConversationWithBuddy(buddy.uniqueId)
            }
        }
    }
    
    fileprivate func getZombotBuddy(bot: ZomBot) -> OTRBuddy? {
        var buddy:OTRBuddy? = nil
        if let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate, let botJid = XMPPJID(string: bot.jid) {
            if let account:OTRAccount = appDelegate.getDefaultAccount() {
                OTRDatabaseManager.shared.writeConnection?.readWrite { (transaction) in
                    buddy = OTRXMPPBuddy.fetchBuddy(jid: botJid, accountUniqueId: account.uniqueId, transaction: transaction)
                    if (buddy == nil) {
                        if let newBuddy = OTRXMPPBuddy() {
                            newBuddy.username = bot.jid
                            newBuddy.displayName = bot.name
                            newBuddy.accountUniqueId = account.uniqueId
                            // hack to show buddy in conversations view
                            newBuddy.lastMessageId = ""
                            newBuddy.avatarData = bot.avatar
                            newBuddy.save(with: transaction)
                            
                            if let proto = OTRProtocolManager.sharedInstance().protocol(for: account) {
                                proto.add(newBuddy)
                            }
                            buddy = newBuddy
                        }
                        
                    }
                }
            }
        }
        return buddy;
    }
}
