//
//  CDMutation+CoreDataProperties.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 01/08/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//

import Foundation
import CoreData

extension CDMutation {

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDMutation> {
        return NSFetchRequest<CDMutation>(entityName: "CDMutation");
    }

    @NSManaged var client: String?
    @NSManaged var connectionAllocationCount: Int32
    @NSManaged var connectionObjectId: Int16
    @NSManaged var domain: String?
    @NSManaged var doNotTrace: Bool
    @NSManaged var httpResponseCode: String?
    @NSManaged var kind: Int16
    @NSManaged var requestCompleted: Int64
    @NSManaged var requestReceived: Int64
    @NSManaged var responseDetails: String?
    @NSManaged var socket: Int32
    @NSManaged var url: String?
    @NSManaged var next: CDMutation?
    @NSManaged var previous: CDMutation?

}
