//
//  CDCounter+CoreDataProperties.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 01/08/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//

import Foundation
import CoreData

extension CDCounter {

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDCounter> {
        return NSFetchRequest<CDCounter>(entityName: "CDCounter");
    }

    @NSManaged var count: Int64
    @NSManaged var forDay: Int64
    @NSManaged var instanceId: Int64
    @NSManaged var clientRecords: NSSet?
    @NSManaged var next: CDCounter?
    @NSManaged var pathPart: CDPathPart?
    @NSManaged var previous: CDCounter?

}
