//
//  Category+CoreDataProperties.swift
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

extension Category {

    @NSManaged var title: String
    @NSManaged var color: Data
    @NSManaged var annotationTitle: String
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var remindMe: NSNumber
    @NSManaged var remindRadius: NSNumber?
    @NSManaged var remindMethod: NSNumber?
    @NSManaged var completed: NSNumber
    @NSManaged var index: NSNumber
    @NSManaged var reminderList: NSSet
    
    func addReminder(_ reminder: Reminder)
    {
        let list = mutableSetValue(forKey: "reminderList")
        list.add(reminder)
    }
    
    func removeReminder(_ reminder: Reminder?)
    {
        let list = mutableSetValue(forKey: "reminderList")
        if reminder != nil && list.contains(reminder!)
        {
            list.remove(reminder!)
        }
    }

}
