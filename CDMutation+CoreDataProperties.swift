//
//  CDMutation+CoreDataProperties.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 18/07/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension CDMutation {

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
