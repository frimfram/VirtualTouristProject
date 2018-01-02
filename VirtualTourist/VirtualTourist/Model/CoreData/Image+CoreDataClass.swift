//
//  Image+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Jean Ro on 12/17/17.
//  Copyright © 2017 Jean Ro. All rights reserved.
//
//

import Foundation
import CoreData


public class Image: NSManagedObject {
    convenience init(url: String, data: NSData?, context: NSManagedObjectContext) {
        if let entityDesc = NSEntityDescription.entity(forEntityName: "Image", in: context) {
            self.init(entity: entityDesc, insertInto: context)
            self.imageURL = url
            self.imageBinary = data
        }else{
            fatalError("Error while querying data")
        }
    }
}
