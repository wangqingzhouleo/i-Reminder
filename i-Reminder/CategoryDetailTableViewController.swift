//
//  CategoryDetailTableViewController.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 2/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//

import UIKit

class CategoryDetailTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
    var masterButtonColor: UIColor?
    var selectedCategoryIndexPath: NSIndexPath?
    var currentList: [Reminder]?
    var delegate: CategoryMasterTableViewController?

    @IBOutlet weak var rightBarButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        rightBarButton.enabled = selectedCategoryIndexPath != nil
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
        return currentList?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CategoryDetailCell", forIndexPath: indexPath) as! CategoryDetailCell

        // Configure the cell...
        cell.delegate = self
        cell.indexPath = indexPath
        
        // Configure the button's color based on category master's color
        cell.tagButton.circleColor = masterButtonColor ?? UIColor.redColor()
        cell.tagButton.setTitle(nil, forState: .Selected)
        
        // Get reminder from current reminder list, then load reminder information and add to cell.
        if let reminder = currentList?[indexPath.row]
        {
            cell.tagButton.selected = reminder.completed.boolValue
            cell.reminderLabel.textColor = reminder.completed.boolValue ? UIColor.lightGrayColor() : UIColor.blackColor()
            
            var text = reminder.title
            if reminder.note != nil
            {
                text += "\n\(reminder.note!)"
            }
            if reminder.hasDueDate.boolValue
            {
                let formatter = NSDateFormatter()
                formatter.dateFormat = "EEE, dd/MM/yyyy, HH:mm"
                text += "\n\(formatter.stringFromDate(reminder.dueDate!))"
                if reminder.completed.boolValue
                {
                    cell.reminderLabel.textColor = UIColor.lightGrayColor()
                }
                else if NSDate().compare(reminder.dueDate!) == NSComparisonResult.OrderedDescending
                {
                    cell.reminderLabel.textColor = UIColor.redColor()
                }
                else
                {
                    cell.reminderLabel.textColor = UIColor.blackColor()
                }
            }
            cell.reminderLabel.text = text
        }
        cell.reminderLabel.numberOfLines = 0
        
        return cell
    }
    
    func tapButton(indexPath: NSIndexPath) {
        // First step get which button is clicked.
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! CategoryDetailCell
        // Then set button selected state to opposite state.
        cell.tagButton.selected = !cell.tagButton.selected
        
        // Adjust text color based on button selection state.
        let reminder = currentList![indexPath.row]
        switch cell.tagButton.selected {
        case true:
            cell.reminderLabel.textColor = UIColor.lightGrayColor()
        case false:
            if reminder.hasDueDate.boolValue
            {
                // If reminder has a due date and is over due, then set text color to red, otherwise set to black.
                cell.reminderLabel.textColor = NSDate().compare(reminder.dueDate!) == NSComparisonResult.OrderedDescending ? UIColor.redColor() : UIColor.blackColor()
            }
            else
            {
                // If reminder does not has due date, set text color to black.
                cell.reminderLabel.textColor = UIColor.blackColor()
            }
        }
        reminder.completed = cell.tagButton.selected
        
        // Save changes to database and load list again.
        saveData()
        currentList = loadCurrentReminderList(inCategory: tmpCategoryList[selectedCategoryIndexPath!.row])
        // Then reload the table.
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .Default, title: "Delete", handler: { _,_ in
            
            // Remove from core data first, then remove from local list.
            managedObject.deleteObject(self.currentList![indexPath.row])
            self.currentList?.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            saveData()
        })
        let more = UITableViewRowAction(style: .Normal, title: "More", handler: { _,_ in
            self.editCategory(indexPath, x: 100)
        })
        
        return [delete, more]
    }
    
    func editCategory(indexPath: NSIndexPath, x: Int)
    {
        // Present a popover to let user modify the selected reminder.
        let popoverVC = storyboard?.instantiateViewControllerWithIdentifier("addReminderPopover") as! UINavigationController
        popoverVC.modalPresentationStyle = .Popover
        if let popoverController = popoverVC.popoverPresentationController {
            popoverController.sourceView = tableView.cellForRowAtIndexPath(indexPath)!
            popoverController.sourceRect = CGRect(x: x, y: 0, width: 85, height: 30)
            popoverController.permittedArrowDirections = .Any
            popoverController.delegate = self
        }
        presentViewController(popoverVC, animated: true, completion: nil)
        let vc = popoverVC.topViewController as! AddReminderTableViewController
        vc.delegate = self
        vc.reminderToEdit = currentList![indexPath.row]
        vc.indexPathToEdit = indexPath
    }
    
    @IBAction func addReminder(sender: UIBarButtonItem) {
        // When user click add button on the top, present a popover to let user add a new reminder.
        let popoverVC = storyboard?.instantiateViewControllerWithIdentifier("addReminderPopover") as! UINavigationController
        popoverVC.modalPresentationStyle = .Popover
        if let popoverController = popoverVC.popoverPresentationController {
            popoverController.barButtonItem = sender
            popoverController.sourceRect = CGRect(x: 0, y: 0, width: 85, height: 30)
            popoverController.permittedArrowDirections = .Any
            popoverController.delegate = self
        }
        presentViewController(popoverVC, animated: true, completion: nil)
        let vc = popoverVC.topViewController as! AddReminderTableViewController
        vc.delegate = self
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        // Force iPhone to display popover rather than push a new view.
        return .None
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 999
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let reminder = currentList![indexPath.row]
        if reminder.hasDueDate.boolValue && reminder.note != nil
        {
            // If reminder has both due data and note, then set row height to 80
            return 80
        }
        else if !reminder.hasDueDate.boolValue && reminder.note == nil
        {
            // If reminder has none of them, set row to default height.
            return 44
        }
        else
        {
            // If only has one of them, set height to 60.
            return 60
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        editCategory(indexPath, x: 0)
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

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
