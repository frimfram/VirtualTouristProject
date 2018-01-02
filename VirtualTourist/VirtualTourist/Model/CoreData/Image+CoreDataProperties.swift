//
//  Image+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Jean Ro on 12/17/17.
//  Copyright © 2017 Jean Ro. All rights reserved.
//
//

import Foundation
import CoreData


extension Image {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Image> {
        return NSFetchRequest<Image>(entityName: "Image")
    }

    @NSManaged public var imageBinary: NSData?
    @NSManaged public var imageURL: String?
    @NSManaged public var location: Location?

}
