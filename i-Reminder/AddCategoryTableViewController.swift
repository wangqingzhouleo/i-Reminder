//
//  AddCategoryTableViewController.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 2/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class AddCategoryTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    var cellDescriptors: NSMutableArray!
    var visibleCellsPerSection = [[Int]]()
    
    var categoryTitleCell: CategoryTitleCell!
    var categoryColorCell: UITableViewCell!
    var chooseLocationCell: UITableViewCell!
    var notificationCell: NotificationCell!
    var notificationRadiusCell: NotificationRadiusCell?
    var notificationMethodCell: NotificationMethodCell?
    
    var delegate: CategoryMasterTableViewController?
    var mapDelegate: MapMasterViewController?
    var annotation: MKPointAnnotation?
    var categoryToEdit: Category?
    var indexPathToEdit: NSIndexPath?
    let largeSize = CGSizeMake(350, 420)
    let smallSize = CGSizeMake(350, 320)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        loadCellDescriptors()
//        doneButton.enabled = false
        
        let back = UIBarButtonItem()
        back.title = ""
        navigationItem.backBarButtonItem = back
        tableView.contentInset.top = 20
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        adjustContentSize()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        // If this view is called from category list table rather than add new category, then categoryToEdit must not be nil, so load data for a particular category.
        switch cellId {
        case "CategoryTitleCell":
            categoryTitleCell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as! CategoryTitleCell
            categoryTitleCell.delegate = self
            categoryTitleCell.inputTitleTextField.text = categoryToEdit?.title ?? nil
            
            return categoryTitleCell
        case "CategoryColorCell":
            categoryColorCell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath)
            categoryColorCell.textLabel?.text = currentCell["text"] as? String
            // Set default color label to red
            if categoryToEdit != nil
            {
                categoryColorCell.textLabel?.textColor = NSKeyedUnarchiver.unarchiveObjectWithData(categoryToEdit!.color) as! UIColor
            }
            else
            {
                categoryColorCell.textLabel?.textColor = UIColor.redColor()
            }
            
            return categoryColorCell
        case "ChooseLocationCell":
            chooseLocationCell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath)
            chooseLocationCell.textLabel?.text = currentCell["text"] as? String
            chooseLocationCell.detailTextLabel?.text = categoryToEdit == nil ? (annotation?.title ?? nil) : categoryToEdit?.annotationTitle
            chooseLocationCell.detailTextLabel?.textColor = UIColor.grayColor()
            
            return chooseLocationCell
        case "NotificationCell":
            notificationCell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as! NotificationCell
            notificationCell.notificationLabel.text = currentCell["text"] as? String
            notificationCell.remindMeSwitch.setOn(categoryToEdit?.remindMe.boolValue ?? false, animated: true)
            if let remindMe = categoryToEdit?.remindMe.boolValue where categoryToEdit != nil
            {
                if remindMe
                {
                    toggleNotification(notificationCell.remindMeSwitch)
                }
            }
            notificationCell.delegate = self
            
            return notificationCell
        case "NotificationRadiusCell":
            notificationRadiusCell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as? NotificationRadiusCell
            notificationRadiusCell?.radiusLabel.text = currentCell["text"] as? String
            var selectedRadius: Int? {
                if let radius = categoryToEdit?.remindRadius where categoryToEdit != nil {
                    switch radius {
                    case 50:
                        return 0
                    case 250:
                        return 1
                    default:
                        return 2
                    }
                }
                return 0
            }
            notificationRadiusCell?.radiusPicker.selectRow(selectedRadius ?? 0, inComponent: 0, animated: false)
            
            return notificationRadiusCell ?? UITableViewCell()
        case "NotificationMethodCell":
            notificationMethodCell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as? NotificationMethodCell
            notificationMethodCell?.textLabel?.text = currentCell["text"] as? String
            notificationMethodCell?.methodSegment.selectedSegmentIndex = categoryToEdit?.remindMethod as? Int ?? 0
            
            return notificationMethodCell ?? UITableViewCell()
        default:
            return UITableViewCell()
        }
    }
    
    func toggleNotification(sender: UISwitch)
    {
        // If local notification is enabled, user can have further options, otherwise display an alert to tell user notification is disabled.
        if UIApplication.sharedApplication().currentUserNotificationSettings()?.types.rawValue != 0
        {
            tableView.beginUpdates()
            
            // Get the notification cell first, then fetch switch's state. Then set following two rows' visibility according to switch.
            let section = 1
            let row = 0
            
            // Set two more cells to visible in cell descriptors.
            cellDescriptors[section][row].setValue(notificationCell?.remindMeSwitch.on, forKey: "isExpanded")
            cellDescriptors[section][row + 1].setValue(notificationCell?.remindMeSwitch.on, forKey: "isVisible")
            cellDescriptors[section][row + 2].setValue(notificationCell?.remindMeSwitch.on, forKey: "isVisible")
            
            // Get visible cells then reload this section
            getIndexOfVisibleCells()
            
            // If switch is on, then add two rows, otherwise delete two rows.
            if sender.on
            {
                tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: row + 1, inSection: section), NSIndexPath(forRow: row + 2, inSection: section)], withRowAnimation: .Top)
            }
            else
            {
                tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: row + 1, inSection: section), NSIndexPath(forRow: row + 2, inSection: section)], withRowAnimation: .Top)
            }
            notificationCell?.previousValue = sender.on
            adjustContentSize()
            
            tableView.endUpdates()
        }
        else
        {
            let alert = UIAlertController(title: "Notification Services Off", message: "Turn on Notification in Settings > Notification to allow i-Reminder to send you nofitication at a place", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: {
                (alert: UIAlertAction) in sender.setOn(false, animated: true)
            }))
            presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 999
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // Return different height for cell at different index
        if indexPath.section == 0 && indexPath.row == 2
        {
            return 60
        }
        else if indexPath.section == 1 && indexPath.row == 2
        {
            return 36
        }
        else if indexPath.section == 1 && indexPath.row == 1
        {
            return 80
        }
        return 44
    }
    
    func loadCellDescriptors()
    {
        // Load cell descriptors from plist.
        if let path = NSBundle.mainBundle().pathForResource("CellDescriptor", ofType: "plist")
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
    
    func textDidChange(textField: UITextField) {
        // If either title or location is empty, display "Done" button.
        doneButton.enabled = textField.text?.characters.count != 0 && annotation != nil
    }
    
    func setPickerTextColor(color: UIColor)
    {
        categoryColorCell?.textLabel?.textColor = color
    }
    
    @IBAction func click(sender: UIButton) {
        // Popover a color picker to let user select a color for this category.
        let popoverVC = storyboard?.instantiateViewControllerWithIdentifier("colorPickerPopover") as! ColorPickerViewController
        popoverVC.modalPresentationStyle = .Popover
        popoverVC.preferredContentSize = CGSizeMake(284, 446)
        if let popoverController = popoverVC.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = CGRect(x: 0, y: 0, width: 85, height: 30)
            popoverController.permittedArrowDirections = .Any
            popoverController.delegate = self
            popoverVC.delegate = self
        }
        presentViewController(popoverVC, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        // Force iPhone to display popover rather than push a new view.
        return .None
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "chooseLocationSegue"
        {
            // Configure destination view controller.
            let vc = segue.destinationViewController as! LocationViewController
            vc.delegate = self
            navigationController?.preferredContentSize = largeSize
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
    @IBAction func cancelAddCategory(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func doneAddCategory(sender: UIBarButtonItem) {
        
        // When done button is clicked, get all information from cells.
        let title = categoryTitleCell.inputTitleTextField.text!
        let color = categoryColorCell.textLabel!.textColor
        let annotationTitle: String = annotation!.title!
        let latitude: Double = annotation!.coordinate.latitude
        let longitude: Double = annotation!.coordinate.longitude
        let remindMe = notificationCell.remindMeSwitch.on
        var remindRadius: Int? {
            if notificationCell.remindMeSwitch.on
            {
                switch notificationRadiusCell!.radiusPicker.selectedRowInComponent(0) {
                case 0:
                    return 50
                case 1:
                    return 250
                case 2:
                    return 1000
                default:
                    return nil
                }
            }
            return nil
        }
        var remindMethod: Int? {
            if notificationCell.remindMeSwitch.on
            {
                return notificationMethodCell?.methodSegment.selectedSegmentIndex
            }
            return nil
        }
        
        // Then if category to edit is nil, it means user is adding a new category, so add a new one in the core data.
        if categoryToEdit == nil
        {
            // Add new item into core data as well as temporary list
            let category = NSEntityDescription.insertNewObjectForEntityForName("Category", inManagedObjectContext: managedObject) as! Category
            category.title = title
            category.color = NSKeyedArchiver.archivedDataWithRootObject(color)
            category.annotationTitle = annotationTitle
            category.latitude = latitude
            category.longitude = longitude
            category.remindMe = remindMe
            category.remindRadius = remindRadius
            category.remindMethod = remindMethod
            category.index = tmpCategoryList.count
            category.completed = false
            tmpCategoryList.append(category)
        }
        else
        {
            // Otherwise modify the category selected by a user.
            categoryToEdit?.title = title
            categoryToEdit?.color = NSKeyedArchiver.archivedDataWithRootObject(color)
            categoryToEdit?.annotationTitle = annotationTitle
            categoryToEdit?.latitude = latitude
            categoryToEdit?.longitude = longitude
            categoryToEdit?.remindMe = remindMe
            categoryToEdit?.remindRadius = remindRadius
            categoryToEdit?.remindMethod = remindMethod
        }
        
        saveData()
        dismissViewControllerAnimated(true, completion: {
            self.delegate?.tableView.reloadData()
            if self.mapDelegate?.mapView != nil
            {
                self.mapDelegate?.loadData()
            }
        })
        appDelegate.refreshGeofencing()
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
        navigationController?.preferredContentSize = notificationCell.remindMeSwitch.on ? largeSize : smallSize
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
