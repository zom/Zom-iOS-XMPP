//
//  NetworkSnackBarManager.swift
//  Zom
//
//  Created by N-Pex on 2/2/2018.
//

import Foundation
import AFNetworking
import PureLayout

public class NetworkSnackBarManager: NSObject {
    @objc public static let shared = NetworkSnackBarManager()
    
    private typealias SnackBarContainerInfo = (bottomOffset:CGFloat,snackBar:SnackBar?)
    
    public override init() {
        super.init()
        AFNetworkReachabilityManager.shared().setReachabilityStatusChange   { (status:AFNetworkReachabilityStatus) in
            self.updateSnackBar()
        }
    }
    
    /**
      The array of views that should show network information, like "no internet" etc
    */
    private var containers:[UIView:SnackBarContainerInfo] = [:]
    private var loginStatusObserver: NSKeyValueObservation? = nil
    private var xmppManager:XMPPManager? = nil
    
    @objc public func addSnackViewContainer(_ container:UIView?,bottomOffset:CGFloat) {
        guard let container = container else { return }
        if !containers.keys.contains(container) {
            containers.updateValue((bottomOffset,nil), forKey: container)
            if containers.count == 1 {
                if self.loginStatusObserver == nil, let appDelegate = ZomAppDelegate.appDelegate as? ZomAppDelegate {
                    if let account = appDelegate.getDefaultAccount(), let xmpp = OTRProtocolManager.shared.protocol(for: account) as? XMPPManager {
                        self.xmppManager = xmpp
                        self.loginStatusObserver = xmpp.observe(\.loginStatus) { [weak self] object, observedChange in
                            DispatchQueue.main.async {
                                self?.updateSnackBar()
                            }
                        }
                    }
                    // Will call updateSnackBar on initial update!
                    AFNetworkReachabilityManager.shared().startMonitoring()
                }
            } else {
                // Update this view
                updateSnackBar()
            }
        }
    }
    
    @objc public func removeSnackViewContainer(_ container:UIView?) {
        guard let container = container else { return }
        if containers.keys.contains(container) {
            if let containerInfo = containers.removeValue(forKey: container), let snackBar = containerInfo.snackBar {
                snackBar.removeFromSuperview()
            }
            if containers.count == 0 {
                AFNetworkReachabilityManager.shared().stopMonitoring()
                if let observer = self.loginStatusObserver {
                    observer.invalidate()
                }
                self.xmppManager = nil
                self.loginStatusObserver = nil
            }
        }
    }
    
    deinit {
        AFNetworkReachabilityManager.shared().stopMonitoring()
        if let observer = self.loginStatusObserver {
            observer.invalidate()
        }
        self.xmppManager = nil
        self.loginStatusObserver = nil
    }
        
    private func showSnackBar(icon:String,text:String, button:(title:String,callback:()->Void)?) {
        for container in self.containers.keys {
            showSnackBar(icon:icon, text: text, button:button, inContainer: container)
        }
    }
    
    private func showSnackBar(icon:String, text:String, button:(title:String,callback:()->Void)?, inContainer container:UIView) {
        if var containerInfo = self.containers[container] {
            if containerInfo.snackBar == nil {
                if let snackBar = UINib(nibName: "SnackBar", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? SnackBar {
                    containerInfo.snackBar = snackBar
                    snackBar.alpha = 0.0
                    container.addSubview(snackBar)
                    snackBar.autoMatch(.width, to: .width, of: container)
                    snackBar.autoPinEdge(.bottom, to: .bottom, of: container, withOffset: -containerInfo.bottomOffset)
                }
                self.containers[container] = containerInfo
            }
            if let snackBar = containerInfo.snackBar {
                snackBar.icon.text = icon
                snackBar.titleLabel.text = text
                if let button = button {
                    snackBar.button.setTitle(button.title, for: .normal)
                    snackBar.button.isHidden = false
                    snackBar.buttonCallback = button.callback
                } else {
                    snackBar.button.isHidden = true
                }
                snackBar.isHidden = false
                UIView.animate(withDuration: 0.5, animations: {
                    snackBar.alpha = 1.0
                }, completion: { (success) in
                })
            }
        }
    }
    
    private func hideSnackBar() {
        for container in self.containers.keys {
            hideSnackBar(inContainer: container)
        }
    }
    
    private func hideSnackBar(inContainer container:UIView) {
        if let containerInfo = self.containers[container] {
            if let snackBar = containerInfo.snackBar {
                UIView.animate(withDuration: 0.5, animations: {
                    snackBar.alpha = 0.0
                }, completion: { (success) in
                    snackBar.isHidden = true
                })
            }
        }
    }
    
    private func updateSnackBar() {
        if !AFNetworkReachabilityManager.shared().isReachable {
            showSnackBar(icon: "", text: NSLocalizedString("No Internet.", comment: "Text for snackbar when no Internet"), button: nil)
        } else if let xmpp = self.xmppManager {
            switch xmpp.loginStatus {
            case .connecting, .connected, .securing, .secured, .authenticating:
                showSnackBar(icon: "", text: NSLocalizedString("Signing in...", comment: "Text for snackbar when signing in"), button: nil)
            case .disconnected:
                showSnackBar(icon: "", text: NSLocalizedString("Network is offline.", comment: "Text for snackbar when disconnected"), button:(title:NSLocalizedString("CONNECT", comment: "Text for snackbar button when disconnected"),callback: {
                    if let xmppManager = self.xmppManager {
                        xmppManager.connectUserInitiated(true)
                    }
                }))
            default:
                hideSnackBar()
            }
        } else {
            hideSnackBar()
        }
    }
}
