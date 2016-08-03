//
//  CDClient+CoreDataProperties.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 01/08/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//

import Foundation
import CoreData

extension CDClient {

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDClient> {
        return NSFetchRequest<CDClient>(entityName: "CDClient");
    }

    @NSManaged var address: String?
    @NSManaged var doNotTrace: Bool
    @NSManaged var clients: CDClients?
    @NSManaged var records: NSSet?

}
