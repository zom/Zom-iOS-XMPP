//
//  UIApplication+Zom.swift
//  Zom
//
//  Created by N-Pex on 2017-03-22.
//
//
import ChatSecureCore

public extension UIApplication {
    
    public func showLocalNotificationForApprovedBuddy(_ thread:OTRThreadOwner?) {
        var name = SOMEONE_STRING()
        if let buddyName = (thread as? OTRBuddy)?.displayName {
            name = buddyName
        } else if let threadName = thread?.threadName() {
            name = threadName
        }
        
        let message = String(format: NSLocalizedString("You and %@ are now friends on Zom", comment: "Text for approved buddy notification"), name)
        
        let unreadCount = self.applicationIconBadgeNumber + 1
        self.showLocalNotificationFor(thread, text: message, unreadCount: unreadCount)
    }
}
