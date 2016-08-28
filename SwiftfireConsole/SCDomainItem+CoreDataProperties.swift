//
//  SCDomainItem+CoreDataProperties.swift
//  Swiftfire
//
//  Created by Marinus van der Lugt on 26/08/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//

import Foundation
import CoreData

extension SCDomainItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SCDomainItem> {
        return NSFetchRequest<SCDomainItem>(entityName: "SCDomainItem");
    }

    @NSManaged public var name: String?
    @NSManaged public var nameIsEditable: Bool
    @NSManaged public var sequence: Int16
    @NSManaged public var value: String?
    @NSManaged public var valueIsEditable: Bool
    @NSManaged public var isServer: Bool
    @NSManaged public var child: NSSet?
    @NSManaged public var parent: SCDomainItem?

}

// MARK: Generated accessors for child
extension SCDomainItem {

    @objc(addChildObject:)
    @NSManaged public func addToChild(_ value: SCDomainItem)

    @objc(removeChildObject:)
    @NSManaged public func removeFromChild(_ value: SCDomainItem)

    @objc(addChild:)
    @NSManaged public func addToChild(_ values: NSSet)

    @objc(removeChild:)
    @NSManaged public func removeFromChild(_ values: NSSet)

}
