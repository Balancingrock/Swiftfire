//
//  CDClients+CoreDataProperties.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 01/08/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//

import Foundation
import CoreData

extension CDClients {

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDClients> {
        return NSFetchRequest<CDClients>(entityName: "CDClients");
    }

    @NSManaged var clients: NSSet?

}
