//
//  Helper.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 5/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//


import UIKit
import CoreData
import MapKit

// This is a helper class, stores all global variables and functions, therefore, all data will be synchronised all the time.

var managedObject: NSManagedObjectContext!
var appDelegate: AppDelegate!

var tmpCategoryList: [Category] = []

func fetchCategorysFromCoreData() -> [Category]
{
    tmpCategoryList.removeAll()
    // Retreive the data from database.
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
    let entityDescription = NSEntityDescription.entity(forEntityName: "Category", in: managedObject)
    fetchRequest.entity = entityDescription
    
    // Try to retrieve data from entity.
    do
    {
        tmpCategoryList = try managedObject.fetch(fetchRequest) as! [Category]
        tmpCategoryList.sort(by: {
            return $0.index.intValue < $1.index.intValue
        })
    }
    catch
    {
        let fetchError = error as NSError
        print(fetchError)
    }
    
    return tmpCategoryList
}

func loadCurrentReminderList(inCategory category: Category) -> [Reminder]
{
    var list = category.reminderList.allObjects as! [Reminder]
    
    list.sort(by: {
        if $0.completed.boolValue != $1.completed.boolValue
        {
            // If completion state is not same, then display not completed reminder first
            return $0.completed.intValue < $1.completed.intValue
        }
        else if $0.hasDueDate.boolValue && $1.hasDueDate.boolValue
        {
            // If both reminders have due date, then display the earliest first
            return $0.dueDate!.compare($1.dueDate! as Date) == ComparisonResult.orderedAscending
        }
        else if !$0.hasDueDate.boolValue && !$1.hasDueDate.boolValue
        {
            // If none of them has due date, then compare their title.
            return $0.title < $1.title
        }
        else
        {
            // If only one has due date, then display reminder has due date first
            return $0.hasDueDate.intValue > $1.hasDueDate.intValue
        }
    })
    
    return list
}

func resetCategoryListOrder()
{
    for i in 0..<tmpCategoryList.count
    {
        tmpCategoryList[i].index = NSNumber(i)
    }
}

func saveData()
{
    do
    {
        try managedObject.save()
    }
    catch let error
    {
        print(error)
    }
}

// Parse MKPlacemark to address
// Source from https://www.thorntech.com/2016/01/how-to-search-for-location-using-apples-mapkit/
func parseAddress(_ selectedItem:MKPlacemark) -> String {
    
    // put a space between "4" and "Melrose Place"
    let firstSpace = (selectedItem.subThoroughfare != nil &&
        selectedItem.thoroughfare != nil) ? " " : ""
    
    // put a comma between street and city/state
    let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) &&
        (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
    
    // put a space between "Washington" and "DC"
    let secondSpace = (selectedItem.subAdministrativeArea != nil &&
        selectedItem.administrativeArea != nil) ? " " : ""
    
    let addressLine = String(
        format:"%@%@%@%@%@%@%@",
        // street number
        selectedItem.subThoroughfare ?? "",
        firstSpace,
        // street name
        selectedItem.thoroughfare ?? "",
        comma,
        // city
        selectedItem.locality ?? "",
        secondSpace,
        // state
        selectedItem.administrativeArea ?? ""
    )
    
    return addressLine
}
