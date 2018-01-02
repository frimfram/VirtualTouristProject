//
//  Location+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Jean Ro on 12/17/17.
//  Copyright © 2017 Jean Ro. All rights reserved.
//
//

import Foundation
import CoreData


public class Location: NSManagedObject {
    convenience init(longitude: Double, latitude: Double, context: NSManagedObjectContext) {
        if let entityDesc = NSEntityDescription.entity(forEntityName: "Location", in: context) {
            self.init(entity: entityDesc, insertInto: context)
            self.longitude = longitude
            self.latitude = latitude
        }else{
            fatalError("Error while loading data")
        }
    }
}
