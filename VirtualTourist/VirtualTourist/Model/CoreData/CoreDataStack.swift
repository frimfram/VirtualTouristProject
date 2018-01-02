//
//  CoreDataStack.swift
//  VirtualTourist
//
//  Created by Jean Ro on 12/17/17.
//  Copyright © 2017 Jean Ro. All rights reserved.
//

import CoreData

struct CoreDataStack {
    private let model: NSManagedObjectModel
    private let modelURL: URL
    internal let coordinator: NSPersistentStoreCoordinator
    internal let dbURL: URL
    internal let persistingContext: NSManagedObjectContext
    internal let backgroundContext: NSManagedObjectContext
    let context: NSManagedObjectContext
    
    init?(modelName: String) {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            print("Unable to find \(modelName) in the main bundle")
            return nil
        }
        self.modelURL = modelURL
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            print("Unable to create model from \(modelURL)")
            return nil
        }
        self.model = model
        self.coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        self.persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.persistingContext.persistentStoreCoordinator = coordinator
        
        self.context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.context.parent = persistingContext
        
        self.backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.backgroundContext.parent = self.context
        
        let fm = FileManager.default
        guard let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to reach the documents folder")
            return nil
        }
        self.dbURL = docUrl.appendingPathComponent("model.sqlilte")
        let options = [NSInferMappingModelAutomaticallyOption: true, NSMigratePersistentStoresAutomaticallyOption: true]
        do {
            try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: options as [NSObject:AnyObject]?)
        } catch {
            print("Unable to add store at \(dbURL)")
        }
    }
    
    func addStoreCoordinator(_ storeType: String, configuration: String?, storeURL: URL, options: [NSObject:AnyObject]?) throws {
        try self.coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: nil)
    }
}

internal extension CoreDataStack {
    func dropAllData() throws {
        //delete all the objects in the db.  This won't delete the files.  It will just leave empty tables.
        try coordinator.destroyPersistentStore(at: dbURL, ofType: NSSQLiteStoreType, options: nil)
        try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: nil)
    }
}

extension CoreDataStack {
    typealias Batch = (_ workerContext: NSManagedObjectContext) -> ()
    func performBackgroundBatchOperation(_ batch: @escaping Batch) {
        backgroundContext.perform {
            batch(self.backgroundContext)
            do {
                try self.backgroundContext.save()
            } catch {
                fatalError("Error while saving backgroundContext: \(error)")
            }
        }
    }
}

extension CoreDataStack {
    func save() {
        context.performAndWait {
            if self.context.hasChanges {
                do {
                    try self.context.save()
                } catch {
                    fatalError("Error while saving main context: \(error)")
                }
                self.persistingContext.perform {
                    do {
                        try self.persistingContext.save()
                    } catch {
                        fatalError("Error while saving persisting context: \(error)")
                    }
                }
            }
        }
    }
    
    func autoSave(_ delayInSeconds: Int) {
        if delayInSeconds > 0 {
            do {
                try self.context.save()
                print("Autosaving")
            } catch {
                print("Error while autosaving")
            }
        }
        let delayInNanoSeconds = UInt64(delayInSeconds) * NSEC_PER_SEC
        let time = DispatchTime.now() + Double(Int64(delayInNanoSeconds)) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: time) {
            self.autoSave(delayInSeconds)
        }
    }
}













