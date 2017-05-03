//
//  CategoryMasterTableViewController.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 2/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//

import UIKit
import MapKit

class CategoryMasterTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
    var delegate: TabBarViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if let index = tableView.indexPathForSelectedRow
        {
            tableView.deselectRowAtIndexPath(index, animated: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return tmpCategoryList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CategoryMasterCell", forIndexPath: indexPath) as! CategoryMasterCell

        // Configure the cell...
        let category = tmpCategoryList[indexPath.row]
        cell.categoryLabel.numberOfLines = 0
        var text = category.title
        
        // If user want this category to be notified at a location, then add location to the cell
        if category.remindMe.boolValue
        {
            switch category.remindMethod {
            case 0?:
                text += "\nArriving: \(category.annotationTitle)"
            default:
                text += "\nLeaving: \(category.annotationTitle)"
            }
            
        }
        cell.categoryLabel.text = text
        
        // Set index path and delegate for cell in order to distinguish which button is clicked later on.
        cell.indexPath = indexPath
        cell.delegate = self
        
        cell.tagButton.setTitle(nil, forState: .Selected)
        // Configure the button based on user's selection, including color and state.
        cell.tagButton.circleColor = NSKeyedUnarchiver.unarchiveObjectWithData(category.color) as! UIColor
        cell.tagButton.selected = category.completed.boolValue
        cell.categoryLabel.textColor = category.completed.boolValue ? UIColor.lightGrayColor() : UIColor.blackColor()

        return cell
    }
    
                   
    func tapButton(indexPath: NSIndexPath)
    {
        // First step get which button is clicked.
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! CategoryMasterCell
        // Then set button selected state to opposite state.
        cell.tagButton.selected = !cell.tagButton.selected
        
        // Adjust text color based on button selection state.
        switch cell.tagButton.selected {
        case true:
            cell.categoryLabel.textColor = UIColor.lightGrayColor()
        case false:
            cell.categoryLabel.textColor = UIColor.blackColor()
        }
        // Save changes to array and core data.
        tmpCategoryList[indexPath.row].completed = cell.tagButton.selected
        saveData()
        appDelegate.refreshGeofencing()
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        
        // The table should not perform segue if no row is selected, if don't set this method, iPad version will has error when launch app.
        if identifier == "showCategoryDetailSegue" && tableView.indexPathForSelectedRow != nil
        {
            return true
        }
        return false
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showCategoryDetailSegue"
        {
            // Configure destination controller.
            let navigationVC = segue.destinationViewController as! UINavigationController
            let vc = navigationVC.topViewController! as! CategoryDetailTableViewController
            let selectedIndex = tableView.indexPathForSelectedRow!
            vc.masterButtonColor = (tableView.cellForRowAtIndexPath(selectedIndex) as! CategoryMasterCell).tagButton.circleColor
            vc.selectedCategoryIndexPath = selectedIndex
            vc.currentList = loadCurrentReminderList(inCategory: tmpCategoryList[selectedIndex.row])
            vc.delegate = self
        }
    }

    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        if sourceIndexPath != destinationIndexPath
        {
            // Move the item in the category list first.
            tmpCategoryList.insert(tmpCategoryList.removeAtIndex(sourceIndexPath.row), atIndex: destinationIndexPath.row)
            // Then reset all category's order in core data.
            resetCategoryListOrder()
            
            // This method has to be here, otherwise buttons will not reordered correctly.
            tableView.moveRowAtIndexPath(sourceIndexPath, toIndexPath: destinationIndexPath)
            
            for item in tmpCategoryList
            {
                // Reset all button's index to correct position.
                let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: item.index as Int, inSection: 0)) as! CategoryMasterCell
                cell.indexPath = NSIndexPath(forRow: item.index as Int, inSection: 0)
            }
            
            saveData()
        }
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .Default, title: "Delete", handler: { _,_ in
            // Display an alert to confirm deletion
            let category = tmpCategoryList[indexPath.row]
            let alert = UIAlertController(title: "Delete \"\(category.title)\"?", message: "This will permanently delete all reminders in \"\(category.title)\".", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { (UIAlertAction) in
                // Remove from core data first, then remove from global array
                managedObject.deleteObject(tmpCategoryList[indexPath.row])
                tmpCategoryList.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                saveData()
                resetCategoryListOrder()
                appDelegate.refreshGeofencing()
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        })
        let more = UITableViewRowAction(style: .Normal, title: "More", handler: { _,_ in
            self.editCategory(indexPath)
        })
        
        return [delete, more]
    }
    
    func editCategory(indexPath: NSIndexPath) {
        // Present the same popover as add category, then pass selected row to the controller for edit purpose.
        let popoverVC = storyboard?.instantiateViewControllerWithIdentifier("addCategoryPopover") as! UINavigationController
        popoverVC.modalPresentationStyle = .Popover
        if let popoverController = popoverVC.popoverPresentationController {
            popoverController.sourceView = self.tableView.cellForRowAtIndexPath(indexPath)
            popoverController.sourceRect = CGRect(x: 100, y: 0, width: 85, height: 30)
            popoverController.permittedArrowDirections = .Any
            popoverController.delegate = self
        }
        presentViewController(popoverVC, animated: true, completion: nil)
        let vc = popoverVC.topViewController as! AddCategoryTableViewController
        vc.delegate = self
        let category = tmpCategoryList[indexPath.row]
        
        vc.categoryToEdit = category
        vc.indexPathToEdit = indexPath
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: category.latitude as Double, longitude: category.longitude as Double)
        annotation.title = category.annotationTitle
        vc.annotation = annotation
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        // Force iPhone to display popover rather than push a new view.
        return .None
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 999
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // If user want notification for a category, then return 60 as row height to display the address.
        let category = tmpCategoryList[indexPath.row]
        if category.remindMe.boolValue
        {
            return 60
        }
        return 44
    }
    
    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
