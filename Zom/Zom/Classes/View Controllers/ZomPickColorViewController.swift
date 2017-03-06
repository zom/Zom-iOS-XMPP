//
//  ZomPickColorViewController.swift
//  Zom
//
//  Created by N-Pex on 2016-11-15.
//
//

import UIKit
import ChatSecureCore

extension UIColor {
    convenience init(a: UInt, red: UInt, green: UInt, blue: UInt) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: CGFloat(a) / 255.0)
    }
    
    convenience init(netHex:UInt) {
        self.init(a: (netHex >> 24) & 0xff, red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}

open class ZomPickColorViewController: UICollectionViewController {
    
    
    private var colors: [UIColor] = []
    private var selectedColor:UIColor? = nil
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        colors.append(UIColor(colorLiteralRed: 231/255.0, green: 39/255.0, blue: 90/255.0, alpha: 1.0))
        colors.append(UIColor(netHex: 0xFFECEFF1))
        colors.append(UIColor(netHex: 0xcc00ddff))
        colors.append(UIColor(netHex: 0xffff00dd))
        colors.append(UIColor(netHex: 0xcc99cc00))
        colors.append(UIColor(netHex: 0xcccc0000))
        colors.append(UIColor(netHex: 0xccffbb33))
    }
    
    // Mark - UICollectionViewDataSource
    
    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell:UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.backgroundView?.backgroundColor = colors[indexPath.item]
        cell.backgroundColor = colors[indexPath.item]
        return cell
    }
    
    open override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedColor = colors[indexPath.item]
        self.performSegue(withIdentifier: "unwindPickColorSegue", sender: self)
    }
    
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if (segue.destination is ZomDiscoverViewController) {
            let vc:ZomDiscoverViewController = segue.destination as! ZomDiscoverViewController
            if (selectedColor != nil) {
                vc.selectThemeColor(selectedColor)
            }
        }
    }
    
}
