//
//  AddReminderTableViewController.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 4/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//

import UIKit
import CoreData

class AddReminderTableViewController: UITableViewController {
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    var cellDescriptors: NSMutableArray!
    var visibleCellsPerSection = [[Int]]()
    
    var reminderTitleCell: ReminderTitleCell!
    var reminderNoteCell: ReminderNoteCell!
    var reminderDueDateCell: ReminderDueDateCell!
    var datePickerCell: DatePickerCell?
    
    var delegate: CategoryDetailTableViewController?
    var reminderToEdit: Reminder?
    var indexPathToEdit: NSIndexPath?
    let formatter = NSDateFormatter()
    var largeSize = CGSizeMake(320, 460)
    var smallSize = CGSizeMake(320, 250)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        loadCellDescriptors()
        formatter.dateFormat = "EEE, dd/MM/yyyy, HH:mm"
        tableView.contentInset.top = 20
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        adjustContentSize()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return cellDescriptors.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return visibleCellsPerSection[section].count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let currentCell = getCellDescriptorForIndexPath(indexPath)
        let cellId = currentCell["cellIdentifier"] as! String
        
        // Configure all cell's, to make this table as a static table view.
        // If this view is called from reminder list table rather than add new reminder, then reminderToEdit must not be nil, so load data for a particular reminder.
        switch cellId {
        case "ReminderTitleCell":
            reminderTitleCell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as! ReminderTitleCell
            reminderTitleCell.delegate = self
            reminderTitleCell.inputTitleTextField.text = reminderToEdit?.title ?? nil
            
            return reminderTitleCell
        case "ReminderNoteCell":
            reminderNoteCell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as! ReminderNoteCell
            reminderNoteCell.inputNoteTextField.text = reminderToEdit?.note ?? nil
            
            return reminderNoteCell ?? UITableViewCell()
        case "ReminderDueDateCell":
            reminderDueDateCell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as! ReminderDueDateCell
            reminderDueDateCell.dueDateLabel.text = currentCell["text"] as? String
            reminderDueDateCell.delegate = self
            reminderDueDateCell.dueDateSwitch.setOn(reminderToEdit?.hasDueDate.boolValue ?? false, animated: true)
            if let hasDueDate = reminderToEdit?.hasDueDate.boolValue where reminderToEdit != nil
            {
                if hasDueDate
                {
                    toggleDueDateStatus(reminderDueDateCell.dueDateSwitch)
                }
            }
            
            return reminderDueDateCell ?? UITableViewCell()
        case "DatePickerCell":
            datePickerCell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as? DatePickerCell
            datePickerCell?.delegate = self
            if reminderToEdit?.dueDate != nil
            {
                datePickerCell?.datePicker.setDate(reminderToEdit!.dueDate!, animated: false)
            }
            else
            {
                datePickerCell?.datePicker.setDate(NSDate().dateByAddingTimeInterval(1800), animated: false)
            }
            
            return datePickerCell ?? UITableViewCell()
        default:
            return UITableViewCell()
        }
    }
    
    func loadCellDescriptors()
    {
        // Load cell descriptors from plist.
        if let path = NSBundle.mainBundle().pathForResource("AddReminderCellDescriptor", ofType: "plist")
        {
            cellDescriptors = NSMutableArray(contentsOfFile: path)
            getIndexOfVisibleCells()
            tableView.reloadData()
        }
    }
    
    func getIndexOfVisibleCells()
    {
        visibleCellsPerSection.removeAll()
        
        // Search for all cells in cell descriptors, if it's visible then append to visible rows property.
        for currentSectionCells in cellDescriptors
        {
            var visibleRows = [Int]()
            
            for row in 0...((currentSectionCells as! [[String: AnyObject]]).count - 1)
            {
                if currentSectionCells[row]["isVisible"] as! Bool == true // Add filter for valid visa here
                {
                    visibleRows.append(row)
                }
            }
            
            visibleCellsPerSection.append(visibleRows)
        }
    }
    
    func getCellDescriptorForIndexPath(indexPath: NSIndexPath) -> [String: AnyObject] {
        // Get cell descriptor for a particular index path.
        let indexOfVisibleRow = visibleCellsPerSection[indexPath.section][indexPath.row]
        let cellDescriptor = (cellDescriptors[indexPath.section] as! NSArray)[indexOfVisibleRow] as! [String: AnyObject]
        return cellDescriptor
    }
    
    func textDidChange(textField: UITextField)
    {
        // Since title is mandatory, if text is empty then disable the button.
        // If selected index from category master table is nil, disable add button. This conidtion is used for iPad app.
        doneButton.enabled = textField.text?.characters.count != 0 && delegate?.selectedCategoryIndexPath != nil
    }
    
    func toggleDueDateStatus(sender: UISwitch)
    {
        tableView.beginUpdates()
        
        // Get the notification cell first, then fetch switch's state. Then set following two rows' visibility according to switch.
        let section = 1
        let row = 1
        
        cellDescriptors[section][row].setValue(sender.on, forKey: "isExpanded")
        cellDescriptors[section][row + 1].setValue(sender.on, forKey: "isVisible")
        
        // Get visible cells then reload this section
        getIndexOfVisibleCells()
        
        // If switch is on, then add two rows, otherwise delete two rows.
        if sender.on
        {
            tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: row + 1, inSection: section)], withRowAnimation: .Top)
        }
        else
        {
            tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: row + 1, inSection: section)], withRowAnimation: .Top)
        }
        reminderDueDateCell.previousValue = sender.on
        adjustContentSize()
        
        tableView.endUpdates()
        reminderDueDateCell?.dueDateLabel.text = sender.on ? formatter.stringFromDate(datePickerCell!.datePicker.date) : "Due date"
    }
    
    func datePickerValueChanged(datePicker: UIDatePicker)
    {
        // Change due date cell's text based on date picker's value.
        reminderDueDateCell?.dueDateLabel.text = formatter.stringFromDate(datePickerCell!.datePicker.date)
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 999
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 2
        {
            return UITableViewAutomaticDimension
        }
        else
        {
            return 44
        }
    }

    @IBAction func cancelAddReminder(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func doneAddReminder(sender: AnyObject) {
        // When done button is clicked, retrieve data form all cells first.
        let title = reminderTitleCell.inputTitleTextField.text!
        let note = reminderNoteCell?.inputNoteTextField.text
        let hasDueDate = reminderDueDateCell.dueDateSwitch.on
        let dueDate = datePickerCell?.datePicker.date
        
        if reminderToEdit == nil
        {
            // If reminderToEdit is nil, this means user is adding a new reminder. So add this into core data.
            let reminder = NSEntityDescription.insertNewObjectForEntityForName("Reminder", inManagedObjectContext: managedObject) as! Reminder
            reminder.title = title
            reminder.note = note?.characters.count == 0 ? nil : note
            reminder.hasDueDate = hasDueDate
            reminder.dueDate = dueDate
            reminder.completed = false
            
            let category = tmpCategoryList[delegate!.selectedCategoryIndexPath!.row]
            category.addReminder(reminder)
            delegate?.currentList = loadCurrentReminderList(inCategory: category)
            
        }
        else
        {
            // Otherwise make changes to the selected reminder.
            reminderToEdit?.title = title
            reminderToEdit?.note = note?.characters.count == 0 ? nil : note
            reminderToEdit?.hasDueDate = hasDueDate
            reminderToEdit?.dueDate = hasDueDate ? dueDate : nil
            
        }
        
        // Save data to core data.
        saveData()
        dismissViewControllerAnimated(true, completion: {
            self.delegate?.tableView.reloadData()
        })
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "required"
        default:
            return "optional"
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func adjustContentSize()
    {
        navigationController?.preferredContentSize = reminderDueDateCell.dueDateSwitch.on ? largeSize : smallSize
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
