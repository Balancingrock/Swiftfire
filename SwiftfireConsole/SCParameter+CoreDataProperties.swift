//
//  SCParameter+CoreDataProperties.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 18/08/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//

import Foundation
import CoreData

extension SCParameter {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SCParameter> {
        return NSFetchRequest<SCParameter>(entityName: "SCParameter");
    }

    @NSManaged public var label: String?
    @NSManaged public var name: String?
    @NSManaged public var sequence: Int16
    @NSManaged public var value: String?

}
