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
    var selectedCategoryIndexPath: IndexPath?
    var currentList: [Reminder]?
    var delegate: CategoryMasterTableViewController?

    @IBOutlet weak var rightBarButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        rightBarButton.isEnabled = selectedCategoryIndexPath != nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return currentList?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryDetailCell", for: indexPath) as! CategoryDetailCell

        // Configure the cell...
        cell.delegate = self
        cell.indexPath = indexPath
        
        // Configure the button's color based on category master's color
        cell.tagButton.circleColor = masterButtonColor ?? UIColor.red
        cell.tagButton.setTitle(nil, for: .selected)
        
        // Get reminder from current reminder list, then load reminder information and add to cell.
        if let reminder = currentList?[indexPath.row]
        {
            cell.tagButton.isSelected = reminder.completed.boolValue
            cell.reminderLabel.textColor = reminder.completed.boolValue ? UIColor.lightGray : UIColor.black
            
            var text = reminder.title
            if reminder.note != nil
            {
                text += "\n\(reminder.note!)"
            }
            if reminder.hasDueDate.boolValue
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEE, dd/MM/yyyy, HH:mm"
                text += "\n\(formatter.string(from: reminder.dueDate! as Date))"
                if reminder.completed.boolValue
                {
                    cell.reminderLabel.textColor = UIColor.lightGray
                }
                else if Date().compare(reminder.dueDate! as Date) == ComparisonResult.orderedDescending
                {
                    cell.reminderLabel.textColor = UIColor.red
                }
                else
                {
                    cell.reminderLabel.textColor = UIColor.black
                }
            }
            cell.reminderLabel.text = text
        }
        cell.reminderLabel.numberOfLines = 0
        
        return cell
    }
    
    func tapButton(_ indexPath: IndexPath) {
        // First step get which button is clicked.
        let cell = tableView.cellForRow(at: indexPath) as! CategoryDetailCell
        // Then set button selected state to opposite state.
        cell.tagButton.isSelected = !cell.tagButton.isSelected
        
        // Adjust text color based on button selection state.
        let reminder = currentList![indexPath.row]
        switch cell.tagButton.isSelected {
        case true:
            cell.reminderLabel.textColor = UIColor.lightGray
        case false:
            if reminder.hasDueDate.boolValue
            {
                // If reminder has a due date and is over due, then set text color to red, otherwise set to black.
                cell.reminderLabel.textColor = Date().compare(reminder.dueDate! as Date) == ComparisonResult.orderedDescending ? UIColor.red : UIColor.black
            }
            else
            {
                // If reminder does not has due date, set text color to black.
                cell.reminderLabel.textColor = UIColor.black
            }
        }
        reminder.completed = cell.tagButton.isSelected as NSNumber
        
        // Save changes to database and load list again.
        saveData()
        currentList = loadCurrentReminderList(inCategory: tmpCategoryList[selectedCategoryIndexPath!.row])
        // Then reload the table.
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .default, title: "Delete", handler: { _,_ in
            
            // Remove from core data first, then remove from local list.
            managedObject.delete(self.currentList![indexPath.row])
            self.currentList?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            saveData()
        })
        let more = UITableViewRowAction(style: .normal, title: "More", handler: { _,_ in
            self.editCategory(indexPath, x: 100)
        })
        
        return [delete, more]
    }
    
    func editCategory(_ indexPath: IndexPath, x: Int)
    {
        // Present a popover to let user modify the selected reminder.
        let popoverVC = storyboard?.instantiateViewController(withIdentifier: "addReminderPopover") as! UINavigationController
        popoverVC.modalPresentationStyle = .popover
        if let popoverController = popoverVC.popoverPresentationController {
            popoverController.sourceView = tableView.cellForRow(at: indexPath)!
            popoverController.sourceRect = CGRect(x: x, y: 0, width: 85, height: 30)
            popoverController.permittedArrowDirections = .any
            popoverController.delegate = self
        }
        present(popoverVC, animated: true, completion: nil)
        let vc = popoverVC.topViewController as! AddReminderTableViewController
        vc.delegate = self
        vc.reminderToEdit = currentList![indexPath.row]
        vc.indexPathToEdit = indexPath
    }
    
    @IBAction func addReminder(_ sender: UIBarButtonItem) {
        // When user click add button on the top, present a popover to let user add a new reminder.
        let popoverVC = storyboard?.instantiateViewController(withIdentifier: "addReminderPopover") as! UINavigationController
        popoverVC.modalPresentationStyle = .popover
        if let popoverController = popoverVC.popoverPresentationController {
            popoverController.barButtonItem = sender
            popoverController.sourceRect = CGRect(x: 0, y: 0, width: 85, height: 30)
            popoverController.permittedArrowDirections = .any
            popoverController.delegate = self
        }
        present(popoverVC, animated: true, completion: nil)
        let vc = popoverVC.topViewController as! AddReminderTableViewController
        vc.delegate = self
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // Force iPhone to display popover rather than push a new view.
        return .none
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 999
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
