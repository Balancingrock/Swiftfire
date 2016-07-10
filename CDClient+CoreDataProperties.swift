//
//  CDClient+CoreDataProperties.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 22/06/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension CDClient {

    @NSManaged var address: String?
    @NSManaged var doNotTrace: Bool
    @NSManaged var clients: CDClients?
    @NSManaged var records: NSSet?

}
