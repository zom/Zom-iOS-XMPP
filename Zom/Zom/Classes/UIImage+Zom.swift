//
//  UIImage+Zom.swift
//  Zom
//
//  Created by N-Pex on 2017-08-29.
//
//

import UIKit

extension UIImage
{
    func tint(_ color: UIColor, blendMode: CGBlendMode) -> UIImage
    {
        let drawRect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()
        context!.scaleBy(x: 1.0, y: -1.0)
        context!.translateBy(x: 0.0, y: -self.size.height)
        context!.clip(to: drawRect, mask: cgImage!)
        color.setFill()
        UIRectFill(drawRect)
        draw(in: drawRect, blendMode: blendMode, alpha: 1.0)
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage!
    }
    
    static func onePixelImage(_ color: UIColor) -> UIImage
    {
        let drawRect = CGRect(x: 0.0, y: 0.0, width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(CGSize(width:1,height:1), false, 1)
        color.setFill()
        UIRectFill(drawRect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
