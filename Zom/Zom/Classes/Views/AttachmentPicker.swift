//
//  AttachmentPicker.swift
//  Zom
//
//  Created by N-Pex on 2016-12-01.
//
//

import UIKit

public class AttachmentPicker: UIView {
    // MARK: - Views
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var cameraButton: UIBarButtonItem!
    @IBOutlet var photosButton: UIBarButtonItem!
    @IBOutlet var stickersButton: UIBarButtonItem!
    
    public func removeCameraButton() {
        var toolbarButtons = toolbar.items
        toolbarButtons!.remove(at: toolbarButtons!.index(of: cameraButton)!)
        toolbar.items = toolbarButtons
    }
    
    public func removePhotoButton() {
        var toolbarButtons = toolbar.items
        toolbarButtons!.remove(at: toolbarButtons!.index(of: photosButton)!)
        toolbar.items = toolbarButtons
    }
}
