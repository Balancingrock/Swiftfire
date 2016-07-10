//
//  CDPathPart+CoreDataProperties.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 21/06/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension CDPathPart {

    @NSManaged var doNotTrace: Bool
    @NSManaged var pathPart: String?
    @NSManaged var foreverCount: Int64
    @NSManaged var next: NSSet?
    @NSManaged var previous: CDPathPart?
    @NSManaged var counterList: CDCounter?
    @NSManaged var domains: CDDomains?

}
