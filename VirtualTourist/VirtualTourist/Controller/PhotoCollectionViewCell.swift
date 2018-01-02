//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Jean Ro on 12/3/17.
//  Copyright © 2017 Jean Ro. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    var taskToCancelCellIsReused: URLSessionTask? {
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
}
