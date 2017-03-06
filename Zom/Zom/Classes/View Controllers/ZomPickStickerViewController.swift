//
//  ZomPickStickerViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-13.
//
//

import UIKit
import ChatSecureCore

public protocol ZomPickStickerViewControllerDelegate {
    func didPickSticker(_ sticker:String, inPack: String)
}

open class ZomPickStickerViewController: UICollectionViewController {
    
    open var stickerPack: String = ""
    private var stickers: [String] = []
    private var stickerPaths: [String] = []
    private var selectedSticker:String = ""
    
    fileprivate var assetGridThumbnailSize:CGSize = CGSize()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        let docsPath = Bundle.main.resourcePath! + "/Stickers/" + stickerPack
        let fileManager = FileManager.default
        do {
            let stickerFiles = try fileManager.contentsOfDirectory(atPath: docsPath)
            for item in stickerFiles {
                stickers.append((item as NSString).deletingPathExtension)
                stickerPaths.append(docsPath + "/" + item)
            }
        } catch {
            print(error)
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Determine the size of the thumbnails to request from the PHCachingImageManager
        let scale:CGFloat = UIScreen.main.scale
        let cellSize:CGSize = (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize;
        assetGridThumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale);
    }
    
    // Mark - UICollectionViewDataSource
    
    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickerPaths.count
    }
    
    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell:ZomPickStickerCell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ZomPickStickerCell
        cell.imageView.image = UIImage(contentsOfFile: stickerPaths[indexPath.item])
        return cell
    }
    
    open override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedSticker = stickers[indexPath.item]
        self.performSegue(withIdentifier: "unwindPickStickerSegue", sender: self)
    }

    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.destination is ZomPickStickerViewControllerDelegate) {
            let vc:ZomPickStickerViewControllerDelegate = segue.destination as! ZomPickStickerViewControllerDelegate
            if (!selectedSticker.isEmpty) {
                vc.didPickSticker(selectedSticker, inPack: stickerPack)
            }
        }
    }
    
}
