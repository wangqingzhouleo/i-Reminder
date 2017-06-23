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
    var cellDescriptors: [[NSDictionary]]!
    var visibleCellsPerSection = [[Int]]()
    
    var reminderTitleCell: ReminderTitleCell!
    var reminderNoteCell: ReminderNoteCell!
    var reminderDueDateCell: ReminderDueDateCell!
    var datePickerCell: DatePickerCell?
    
    var delegate: CategoryDetailTableViewController?
    var reminderToEdit: Reminder?
    var indexPathToEdit: IndexPath?
    let formatter = DateFormatter()
    var largeSize = CGSize(width: 320, height: 460)
    var smallSize = CGSize(width: 320, height: 250)
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        adjustContentSize()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return cellDescriptors.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return visibleCellsPerSection[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentCell = getCellDescriptorForIndexPath(indexPath)
        let cellId = currentCell["cellIdentifier"] as! String
        
        // Configure all cell's, to make this table as a static table view.
        // If this view is called from reminder list table rather than add new reminder, then reminderToEdit must not be nil, so load data for a particular reminder.
        switch cellId {
        case "ReminderTitleCell":
            reminderTitleCell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ReminderTitleCell
            reminderTitleCell.delegate = self
            reminderTitleCell.inputTitleTextField.text = reminderToEdit?.title ?? nil
            
            return reminderTitleCell
        case "ReminderNoteCell":
            reminderNoteCell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ReminderNoteCell
            reminderNoteCell.inputNoteTextField.text = reminderToEdit?.note ?? nil
            
            return reminderNoteCell ?? UITableViewCell()
        case "ReminderDueDateCell":
            reminderDueDateCell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ReminderDueDateCell
            reminderDueDateCell.dueDateLabel.text = currentCell["text"] as? String
            reminderDueDateCell.delegate = self
            reminderDueDateCell.dueDateSwitch.setOn(reminderToEdit?.hasDueDate.boolValue ?? false, animated: true)
            if let hasDueDate = reminderToEdit?.hasDueDate.boolValue, reminderToEdit != nil
            {
                if hasDueDate
                {
                    toggleDueDateStatus(reminderDueDateCell.dueDateSwitch)
                }
            }
            
            return reminderDueDateCell ?? UITableViewCell()
        case "DatePickerCell":
            datePickerCell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? DatePickerCell
            datePickerCell?.delegate = self
            if reminderToEdit?.dueDate != nil
            {
                datePickerCell?.datePicker.setDate(reminderToEdit!.dueDate! as Date, animated: false)
            }
            else
            {
                datePickerCell?.datePicker.setDate(Date().addingTimeInterval(1800), animated: false)
            }
            
            return datePickerCell ?? UITableViewCell()
        default:
            return UITableViewCell()
        }
    }
    
    func loadCellDescriptors()
    {
        // Load cell descriptors from plist.
        if let path = Bundle.main.path(forResource: "AddReminderCellDescriptor", ofType: "plist")
        {
            cellDescriptors = NSMutableArray(contentsOfFile: path) as! [[NSDictionary]]
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
            
            for row in 0 ..< currentSectionCells.count
            {
                if currentSectionCells[row]["isVisible"] as! Bool == true // Add filter for valid visa here
                {
                    visibleRows.append(row)
                }
            }
            
            visibleCellsPerSection.append(visibleRows)
        }
    }
    
    func getCellDescriptorForIndexPath(_ indexPath: IndexPath) -> [String: AnyObject] {
        // Get cell descriptor for a particular index path.
        let indexOfVisibleRow = visibleCellsPerSection[indexPath.section][indexPath.row]
        let cellDescriptor = cellDescriptors[indexPath.section][indexOfVisibleRow] as! [String: AnyObject]
        return cellDescriptor
    }
    
    func textDidChange(_ textField: UITextField)
    {
        // Since title is mandatory, if text is empty then disable the button.
        // If selected index from category master table is nil, disable add button. This conidtion is used for iPad app.
        doneButton.isEnabled = textField.text?.characters.count != 0 && delegate?.selectedCategoryIndexPath != nil
    }
    
    func toggleDueDateStatus(_ sender: UISwitch)
    {
        tableView.beginUpdates()
        
        // Get the notification cell first, then fetch switch's state. Then set following two rows' visibility according to switch.
        let section = 1
        let row = 1
        
        cellDescriptors[section][row].setValue(sender.isOn, forKey: "isExpanded")
        cellDescriptors[section][row + 1].setValue(sender.isOn, forKey: "isVisible")
        
        // Get visible cells then reload this section
        getIndexOfVisibleCells()
        
        // If switch is on, then add two rows, otherwise delete two rows.
        if sender.isOn
        {
            tableView.insertRows(at: [IndexPath(row: row + 1, section: section)], with: .top)
        }
        else
        {
            tableView.deleteRows(at: [IndexPath(row: row + 1, section: section)], with: .top)
        }
        reminderDueDateCell.previousValue = sender.isOn
        adjustContentSize()
        
        tableView.endUpdates()
        reminderDueDateCell?.dueDateLabel.text = sender.isOn ? formatter.string(from: datePickerCell!.datePicker.date) : "Due date"
    }
    
    func datePickerValueChanged(_ datePicker: UIDatePicker)
    {
        // Change due date cell's text based on date picker's value.
        reminderDueDateCell?.dueDateLabel.text = formatter.string(from: datePickerCell!.datePicker.date)
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 999
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 2
        {
            return UITableViewAutomaticDimension
        }
        else
        {
            return 44
        }
    }

    @IBAction func cancelAddReminder(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneAddReminder(_ sender: AnyObject) {
        // When done button is clicked, retrieve data form all cells first.
        let title = reminderTitleCell.inputTitleTextField.text!
        let note = reminderNoteCell?.inputNoteTextField.text
        let hasDueDate = reminderDueDateCell.dueDateSwitch.isOn
        let dueDate = datePickerCell?.datePicker.date
        
        if reminderToEdit == nil
        {
            // If reminderToEdit is nil, this means user is adding a new reminder. So add this into core data.
            let reminder = NSEntityDescription.insertNewObject(forEntityName: "Reminder", into: managedObject) as! Reminder
            reminder.title = title
            reminder.note = note?.characters.count == 0 ? nil : note
            reminder.hasDueDate = hasDueDate as NSNumber
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
            reminderToEdit?.hasDueDate = hasDueDate as NSNumber
            reminderToEdit?.dueDate = hasDueDate ? dueDate : nil
            
        }
        
        // Save data to core data.
        saveData()
        dismiss(animated: true, completion: {
            self.delegate?.tableView.reloadData()
        })
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "required"
        default:
            return "optional"
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func adjustContentSize()
    {
        navigationController?.preferredContentSize = reminderDueDateCell.dueDateSwitch.isOn ? largeSize : smallSize
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
