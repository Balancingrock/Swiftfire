//
//  CDPathPart+CoreDataProperties.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 01/08/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//

import Foundation
import CoreData

extension CDPathPart {

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDPathPart> {
        return NSFetchRequest<CDPathPart>(entityName: "CDPathPart");
    }

    @NSManaged var doNotTrace: Bool
    @NSManaged var foreverCount: Int64
    @NSManaged var pathPart: String?
    @NSManaged var counterList: CDCounter?
    @NSManaged var domains: CDDomains?
    @NSManaged var next: NSSet?
    @NSManaged var previous: CDPathPart?

}
