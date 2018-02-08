//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Benjamin Erhart on 08.02.18.
//

import UIKit
import Social
import MobileCoreServices

/**
 Share extension to share (currently only one) photo using the Zom app.

 Since we're currently unable to move a lot of code into shared libraries (e.g. the encrypted
 database access stuff, the XMPP stuff, the OTR and OMEMO stuff), we can't handle everything here,
 but instead copy the shared photo into a shared folder and call the app using a special URL.

 Since the URL handler "zom" is already registered due to another feature, which enables e-mail
 attachement sharing with Zom, we just reuse that functionality.

 Idea taken from: https://stackoverflow.com/questions/27506413/share-extension-to-open-containing-app
 */
class ShareViewController: UIViewController {

    var sharePath: URL?
    let fm = FileManager.default

    override func viewDidLoad() {
        super.viewDidLoad()

        sharePath = fm.containerURL(forSecurityApplicationGroupIdentifier: ZomAppGroupId)?
            .appendingPathComponent(ZomShareFolder)

        if let sharePath = sharePath {
            // Try to create the "share" directory, if it doesn not exist, yet.
            try? fm.createDirectory(at: sharePath,
                                    withIntermediateDirectories: true,
                                    attributes: nil)

            // Try to delete all old files, if there are any.
            if let files = try? fm.contentsOfDirectory(at: sharePath,
                                                       includingPropertiesForKeys: nil,
                                                       options: []) {
                for file in files {
                    try? fm.removeItem(at: file)
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        MBProgressHUD.showAdded(to: self.view, animated: true)

        DispatchQueue.global(qos: .background).async {
            let group = DispatchGroup()

            if let sharePath = self.sharePath,
                let items = self.extensionContext?.inputItems as? [NSExtensionItem] {

                for item in items {
                    if let providers = item.attachments as? [NSItemProvider] {
                        for provider in providers {
                            group.enter()

                            provider.loadItem(forTypeIdentifier: kUTTypeData as String, options: nil) { data, error in
                                if error == nil {
                                    if let source = data as? URL {
                                        if let name = source.pathComponents.last {
                                            try? self.fm
                                                .copyItem(at: source,
                                                          to: sharePath.appendingPathComponent(name))
                                        }
                                    }
                                    else if let source = data as? UIImage {
                                        if let data = UIImagePNGRepresentation(source) {
                                            try? data.write(to: sharePath.appendingPathComponent("image.png"))
                                        }
                                    }
                                    else if let source = data as? Data {
                                        try? source.write(to: sharePath.appendingPathComponent("image"))
                                    }
                                }

                                group.leave()
                            }
                        }
                    }
                }
            }

            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
            }

            group.notify(queue: DispatchQueue.main) {
                if let url = URL(string: ZomShareUrl) {
                    _ = self.openURL(url)
                }

                self.extensionContext?.completeRequest(returningItems: []) { (expired) in
                    self.dismiss(animated: false)
                }
            }
        }
    }

    /**
     Function must be named exactly like this so a selector can be found by the compiler!
     Anyway - it's another selector in another instance that would be "performed" instead.
    */
    @objc func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self

        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            responder = responder?.next
        }

        return false
    }
}
