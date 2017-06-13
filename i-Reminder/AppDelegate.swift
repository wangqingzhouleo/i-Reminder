//
//  AppDelegate.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 2/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    let locationManager = CLLocationManager()
    var rootController: UISplitViewController!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        rootController = self.window?.rootViewController as! UISplitViewController
        rootController.delegate = self
        rootController.preferredDisplayMode = .allVisible
        
        // Enable local notifcations
        let supportedNotificationTypes:UIUserNotificationType = [.alert, .badge, .sound]
        let notificationSettings = UIUserNotificationSettings(types: supportedNotificationTypes, categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
        application.applicationIconBadgeNumber = 0
        
        managedObject = self.managedObjectContext
        appDelegate = self
        
        tmpCategoryList = fetchCategorysFromCoreData()
        
        // Initialize location manager.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.stopMonitoringSignificantLocationChanges()
        
        refreshGeofencing()
        
        return true
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        locationManager.startMonitoringSignificantLocationChanges()
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "FIT5140.i_Reminder" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "i_Reminder", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    func refreshGeofencing()
    {
        // For refresh geofencing, remove all current monitored region first.
        for item in locationManager.monitoredRegions
        {
            locationManager.stopMonitoring(for: item)
        }
        // If user wants notification, register the category to location manager to monitor
        for category in tmpCategoryList
        {
            if category.remindMe.boolValue && !category.completed.boolValue
            {
                var id = ""
                // Add string before title to distinguish which method does the user want to be notified.
                switch category.remindMethod {
                case 0?:
                    id += "arrived \(category.annotationTitle)<$>\(category.title)"
                default:
                    id += "left \(category.annotationTitle)<$>\(category.title)"
                }
                let coordinate = CLLocationCoordinate2D(latitude: category.latitude as Double, longitude: category.longitude as Double)
                let geofence = CLCircularRegion(center: coordinate, radius: category.remindRadius! as Double, identifier: id)
                locationManager.startMonitoring(for: geofence)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // Only show notification if the user want to be notified when arrive a place.
        if region.identifier.hasPrefix("arrived")
        {
            showAlert(region.identifier)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // Only show notification if the user want to be notified when leave a place.
        if region.identifier.hasPrefix("left")
        {
            showAlert(region.identifier)
        }
    }
    
    func showAlert(_ identifier: String)
    {
        // Configure the alert and the content to remind use.
        let title = "i-Reminder"
        let messages = identifier.components(separatedBy: "<$>")
        let message = "You have \(messages[0]), don't forget to complete \"\(messages[1])\""
        
        if UIApplication.shared.applicationState == .active
        {
            // Display an alert if app is active.
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            rootController.present(alert, animated: true, completion: nil)
        }
        else
        {
            // Otherwise send local notification.
            let notification = UILocalNotification()
            notification.alertTitle = title
            notification.alertBody = message
            notification.alertAction = "Open"
            UIApplication.shared.presentLocalNotificationNow(notification)
        }
    }

}

