//
//  SCBlacklistItem+CoreDataProperties.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 26/08/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//

import Foundation
import CoreData

extension SCBlacklistItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SCBlacklistItem> {
        return NSFetchRequest<SCBlacklistItem>(entityName: "SCBlacklistItem");
    }

    @NSManaged public var address: String?
    @NSManaged public var action: String?

}
