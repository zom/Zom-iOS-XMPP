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

public class ZomPickColorViewController: UICollectionViewController {
    
    
    private var colors: [UIColor] = []
    private var selectedColor:UIColor? = nil
    
    public override func viewDidLoad() {
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
    
    public override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    public override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell:UICollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath)
        cell.backgroundView?.backgroundColor = colors[indexPath.item]
        cell.backgroundColor = colors[indexPath.item]
        return cell
    }
    
    public override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedColor = colors[indexPath.item]
        self.performSegueWithIdentifier("unwindPickColorSegue", sender: self)
    }
    
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if (segue.destinationViewController is ZomDiscoverViewController) {
            let vc:ZomDiscoverViewController = segue.destinationViewController as! ZomDiscoverViewController
            if (selectedColor != nil) {
                vc.selectThemeColor(selectedColor)
            }
        }
    }
    
}
