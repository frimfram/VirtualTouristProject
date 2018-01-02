//
//  Location+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Jean Ro on 12/17/17.
//  Copyright © 2017 Jean Ro. All rights reserved.
//
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var totalFlickrPages: Int32
    @NSManaged public var longitude: Double
    @NSManaged public var latitude: Double
    @NSManaged public var images: NSSet?

}

// MARK: Generated accessors for images
extension Location {

    @objc(addImagesObject:)
    @NSManaged public func addToImages(_ value: Image)

    @objc(removeImagesObject:)
    @NSManaged public func removeFromImages(_ value: Image)

    @objc(addImages:)
    @NSManaged public func addToImages(_ values: NSSet)

    @objc(removeImages:)
    @NSManaged public func removeFromImages(_ values: NSSet)

}
