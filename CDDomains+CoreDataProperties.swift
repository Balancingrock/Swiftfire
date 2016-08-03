//
//  CDDomains+CoreDataProperties.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 01/08/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//

import Foundation
import CoreData

extension CDDomains {

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDDomains> {
        return NSFetchRequest<CDDomains>(entityName: "CDDomains");
    }

    @NSManaged var domains: NSSet?

}
