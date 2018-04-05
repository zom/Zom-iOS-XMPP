//
//  ZomTheme.swift
//  Zom
//
//  Created by Benjamin Erhart on 21.03.18.
//

import UIKit

extension UIColor {

    public static let zomRed = UIColor(hexString: "#FFE7275A")
    public static let zomGreen = UIColor(hexString: "#FF7ED321")
    public static let zomGray = UIColor(hexString: "#FFF1F2F3")

    @objc convenience init(hexString: String) {
        let scanner = Scanner(string: hexString)
        scanner.scanLocation = 1

        var hex: UInt32 = 0
        if scanner.scanHexInt32(&hex) {
            self.init(netHex: UInt(hex))
        }
        else {
            self.init(netHex: 0xFFFFFFFF)
        }
    }

    @objc func hexString() -> String {
        var r: Float = 0
        var g: Float = 0
        var b: Float = 0
        var a: Float = 0

        if let components = cgColor.components {
            r = Float(components[0])
            g = Float(components[1])
            b = Float(components[2])
            a = Float(components[3])
        }

        return String(format: "#%02lX%02lX%02lX%02lX",
                      lroundf(a * 255),
                      lroundf(r * 255),
                      lroundf(g * 255),
                      lroundf(b * 255))
    }

    @objc func asImage() -> UIImage? {
        let rect = CGRect.init(x: 0, y: 0, width: 1, height: 1)

        UIGraphicsBeginImageContext(rect.size)
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(cgColor)
            context.fill(rect)
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}

@objc class ZomTheme: NSObject, AppTheme {

    private static let USER_DEFAULTS_THEME_COLOR_KEY = "zom_ThemeColor"

    private var connections: DatabaseConnections? {
        return OTRDatabaseManager.shared.connections
    }

    @objc override init() {
        if let themeColorString = UserDefaults.standard.string(forKey: ZomTheme.USER_DEFAULTS_THEME_COLOR_KEY) {
            mainThemeColor = UIColor(hexString: themeColorString)
        }
        else {
            mainThemeColor = UIColor.zomRed
        }
    }

    /**
     Resets the main theme color and the appearance of all `UIView`s to the given color. 

     - parameter color: If nil, will use the default red-ish color.
    */
    @objc func selectMainThemeColor(_ color: UIColor?) {
        let color = color ?? UIColor.zomRed

        mainThemeColor = color
        setupAppearance()

        let defaults = UserDefaults.standard
        defaults.set(color.hexString(), forKey: ZomTheme.USER_DEFAULTS_THEME_COLOR_KEY)
        defaults.synchronize()
    }


    // MARK: AppColors

    @objc var mainThemeColor: UIColor
    @objc var lightThemeColor = UIColor.zomGray
    @objc var buttonLabelColor = UIColor.white

    // MARK: AppAppearance

    @objc func setupAppearance() {
        UIView.appearance().tintColor = mainThemeColor

        var navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.isTranslucent = false
        navBarAppearance.tintColor = .white
        navBarAppearance.barTintColor = mainThemeColor
        navBarAppearance.backgroundColor = mainThemeColor
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        // On iOS 11 bar button items are descendants of button...
        UIButton.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = UIColor.white

        let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.tintColor = .white
        tabBarAppearance.barTintColor = mainThemeColor
        tabBarAppearance.backgroundColor = mainThemeColor

        UIBarButtonItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)

        UITableView.appearance().backgroundColor = lightThemeColor

        UIApplication.shared.statusBarStyle = .lightContent

        UISwitch.appearance().tintColor = mainThemeColor
        UISwitch.appearance().onTintColor = mainThemeColor

        UILabel.appearance(whenContainedInInstancesOf: [ZomTableViewSectionHeader.self]).textColor = mainThemeColor

        var buttonAppearance = UIButton.appearance(whenContainedInInstancesOf: [UITableView.self])
        buttonAppearance.backgroundColor = mainThemeColor
        buttonAppearance.tintColor = .white

        buttonAppearance = UIButton.appearance(whenContainedInInstancesOf: [UITableViewCell.self, UITableView.self])
        buttonAppearance.backgroundColor = nil
        buttonAppearance.tintColor = nil

        // Migration button style
        buttonAppearance = UIButton.appearance(whenContainedInInstancesOf:
            [UIView.self, UITableView.self, ZomConversationViewController.self])
        buttonAppearance.backgroundColor = .clear
        buttonAppearance.tintColor = mainThemeColor

        // Group compose cell button
        buttonAppearance = UIButton.appearance(whenContainedInInstancesOf:
            [OTRComposeGroupBuddyCell.self, UICollectionView.self, UITableView.self, UIViewController.self])
        buttonAppearance.backgroundColor = .clear
        buttonAppearance.tintColor = .lightGray

        // Checkmark icon in group compose view
        UIImageView.appearance(whenContainedInInstancesOf:
            [OTRBuddyInfoCheckableCell.self, UITableView.self, UIViewController.self])
            .tintColor = mainThemeColor

        // Group compose QR button
        buttonAppearance = UIButton.appearance(whenContainedInInstancesOf:
            [UIView.self, UITableView.self, ZomComposeGroupViewController.self])
        buttonAppearance.backgroundColor = .white
        buttonAppearance.tintColor = .black

        // Buttons on photo overlay
        UIBarButtonItem.appearance(whenContainedInInstancesOf:
            [UIToolbar.self, UIView.self, ZomPhotosViewController.self]).tintColor = .white
        UIButton.appearance(whenContainedInInstancesOf:
            [UIToolbar.self, UIView.self, ZomPhotosViewController.self]).tintColor = .white

        let photosBarColor = UIColor.black.withAlphaComponent(0.7)
        navBarAppearance = UINavigationBar.appearance(whenContainedInInstancesOf: [ZomPhotosViewController.self])
        navBarAppearance.tintColor = .white
        navBarAppearance.isTranslucent = true
        navBarAppearance.barTintColor = photosBarColor
        navBarAppearance.backgroundColor = photosBarColor

        let pageControlAppearance = UIPageControl.appearance()
        pageControlAppearance.pageIndicatorTintColor = mainThemeColor
        pageControlAppearance.currentPageIndicatorTintColor = .black
        pageControlAppearance.backgroundColor = .white
    }

    // MARK: ViewControllerFactory
    
    @objc func conversationViewController() -> UIViewController {
        return ZomConversationViewController();
    }

    @objc func messagesViewController() -> UIViewController {
        return ZomMessagesViewController()
    }

    @objc func settingsViewController() -> UIViewController {
        let svc = ZomSettingsViewController()
        let settingsManager = ZomSettingsManager()

        svc.settingsManager = settingsManager
        settingsManager.viewController = svc

        return svc;
    }

    @objc func composeViewController() -> UIViewController {
        return ZomComposeViewController()
    }

    @objc func inviteViewController(account: OTRAccount) -> UIViewController {
        return ZomInviteViewController(account: account)
    }

    @objc func keyManagementViewController(account: OTRXMPPAccount) -> UIViewController {
        guard let connections = self.connections else {
            return UIViewController()
        }

        let form = KeyManagementViewController.profileFormDescriptorForAccount(
            account, buddies: [], connection: connections.ui)

        return KeyManagementViewController(
            accountKey: account.uniqueId, connections: connections, form: form)
    }

    @objc func keyManagementViewController(buddy: OTRXMPPBuddy) -> UIViewController {
        return ZomVerificationDetailViewController(buddy: buddy)
    }

    @objc func groupKeyManagementViewController(buddies: [OTRXMPPBuddy]) -> UIViewController {
        // TODO: This scene can currently only handle one buddy. Not sure, if there are situations,
        // where Zom actually calls this with multiple buddies.
        return ZomVerificationDetailViewController(buddy: buddies[0])
    }

    @objc func newUntrustedKeyViewController(buddies: [OTRXMPPBuddy]) -> UIViewController {
        // TODO: This scene can currently only handle one buddy. Not sure, if there are situations,
        // where Zom actually calls this with multiple buddies.
        return ZomVerificationViewController(buddy: buddies[0])
    }

    @objc func accountDetailViewController(account: OTRXMPPAccount) -> UIViewController {
        guard let connections = self.connections,
            let xmpp = OTRProtocolManager.shared.xmppManager(for: account) else {
                return UIViewController()
        }

        return ZomAccountDetailViewController(account: account,
                                              xmpp: xmpp,
                                              longLivedReadConnection: connections.longLivedRead,
                                              readConnection: connections.ui,
                                              writeConnection: connections.write)
    }
}
