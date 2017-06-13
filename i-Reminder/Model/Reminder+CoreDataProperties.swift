//
//  Reminder+CoreDataProperties.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 6/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Reminder {

    @NSManaged var title: String
    @NSManaged var note: String?
    @NSManaged var hasDueDate: NSNumber
    @NSManaged var dueDate: Date?
    @NSManaged var completed: NSNumber
    @NSManaged var inCategory: Category?

}
