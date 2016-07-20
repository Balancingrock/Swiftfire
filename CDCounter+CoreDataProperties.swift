//
//  CDCounter+CoreDataProperties.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 18/07/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension CDCounter {

    @NSManaged var count: Int64
    @NSManaged var instanceId: Int64
    @NSManaged var startDate: Int64
    @NSManaged var clientRecords: NSSet?
    @NSManaged var next: CDCounter?
    @NSManaged var pathPart: CDPathPart?
    @NSManaged var previous: CDCounter?

}
