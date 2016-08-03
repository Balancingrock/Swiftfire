//
//  CDClientRecord+CoreDataProperties.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 01/08/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//

import Foundation
import CoreData

extension CDClientRecord {

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDClientRecord> {
        return NSFetchRequest<CDClientRecord>(entityName: "CDClientRecord");
    }

    @NSManaged var connectionAllocationCount: Int32
    @NSManaged var connectionObjectId: Int16
    @NSManaged var host: String?
    @NSManaged var httpResponseCode: String?
    @NSManaged var requestCompleted: Int64
    @NSManaged var requestReceived: Int64
    @NSManaged var responseDetails: String?
    @NSManaged var socket: Int32
    @NSManaged var url: String?
    @NSManaged var client: CDClient?
    @NSManaged var urlCounter: CDCounter?

}
