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
    var indexPathToEdit: IndexPath?
    let largeSize = CGSize(width: 350, height: 420)
    let smallSize = CGSize(width: 350, height: 320)
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        adjustContentSize()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        // If this view is called from category list table rather than add new category, then categoryToEdit must not be nil, so load data for a particular category.
        switch cellId {
        case "CategoryTitleCell":
            categoryTitleCell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! CategoryTitleCell
            categoryTitleCell.delegate = self
            categoryTitleCell.inputTitleTextField.text = categoryToEdit?.title ?? nil
            
            return categoryTitleCell
        case "CategoryColorCell":
            categoryColorCell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
            categoryColorCell.textLabel?.text = currentCell["text"] as? String
            // Set default color label to red
            if categoryToEdit != nil
            {
                categoryColorCell.textLabel?.textColor = NSKeyedUnarchiver.unarchiveObject(with: categoryToEdit!.color as Data) as! UIColor
            }
            else
            {
                categoryColorCell.textLabel?.textColor = UIColor.red
            }
            
            return categoryColorCell
        case "ChooseLocationCell":
            chooseLocationCell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
            chooseLocationCell.textLabel?.text = currentCell["text"] as? String
            chooseLocationCell.detailTextLabel?.text = categoryToEdit == nil ? (annotation?.title ?? nil) : categoryToEdit?.annotationTitle
            chooseLocationCell.detailTextLabel?.textColor = UIColor.gray
            
            return chooseLocationCell
        case "NotificationCell":
            notificationCell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! NotificationCell
            notificationCell.notificationLabel.text = currentCell["text"] as? String
            notificationCell.remindMeSwitch.setOn(categoryToEdit?.remindMe.boolValue ?? false, animated: true)
            if let remindMe = categoryToEdit?.remindMe.boolValue, categoryToEdit != nil
            {
                if remindMe
                {
                    toggleNotification(notificationCell.remindMeSwitch)
                }
            }
            notificationCell.delegate = self
            
            return notificationCell
        case "NotificationRadiusCell":
            notificationRadiusCell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? NotificationRadiusCell
            notificationRadiusCell?.radiusLabel.text = currentCell["text"] as? String
            var selectedRadius: Int? {
                if let radius = categoryToEdit?.remindRadius, categoryToEdit != nil {
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
            notificationMethodCell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? NotificationMethodCell
            notificationMethodCell?.textLabel?.text = currentCell["text"] as? String
            notificationMethodCell?.methodSegment.selectedSegmentIndex = categoryToEdit?.remindMethod as? Int ?? 0
            
            return notificationMethodCell ?? UITableViewCell()
        default:
            return UITableViewCell()
        }
    }
    
    func toggleNotification(_ sender: UISwitch)
    {
        // If local notification is enabled, user can have further options, otherwise display an alert to tell user notification is disabled.
        if UIApplication.shared.currentUserNotificationSettings?.types.rawValue != 0
        {
            tableView.beginUpdates()
            
            // Get the notification cell first, then fetch switch's state. Then set following two rows' visibility according to switch.
            let section = 1
            let row = 0
            
            // Set two more cells to visible in cell descriptors.
            cellDescriptors[section][row].setValue(notificationCell?.remindMeSwitch.isOn, forKey: "isExpanded")
            cellDescriptors[section][row + 1].setValue(notificationCell?.remindMeSwitch.isOn, forKey: "isVisible")
            cellDescriptors[section][row + 2].setValue(notificationCell?.remindMeSwitch.isOn, forKey: "isVisible")
            
            // Get visible cells then reload this section
            getIndexOfVisibleCells()
            
            // If switch is on, then add two rows, otherwise delete two rows.
            if sender.isOn
            {
                tableView.insertRows(at: [IndexPath(row: row + 1, section: section), IndexPath(row: row + 2, section: section)], with: .top)
            }
            else
            {
                tableView.deleteRows(at: [IndexPath(row: row + 1, section: section), IndexPath(row: row + 2, section: section)], with: .top)
            }
            notificationCell?.previousValue = sender.isOn
            adjustContentSize()
            
            tableView.endUpdates()
        }
        else
        {
            let alert = UIAlertController(title: "Notification Services Off", message: "Turn on Notification in Settings > Notification to allow i-Reminder to send you nofitication at a place", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
                (alert: UIAlertAction) in sender.setOn(false, animated: true)
            }))
            present(alert, animated: true, completion: nil)
        }
        
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 999
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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
        if let path = Bundle.main.path(forResource: "CellDescriptor", ofType: "plist")
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
    
    func getCellDescriptorForIndexPath(_ indexPath: IndexPath) -> [String: AnyObject] {
        // Get cell descriptor for a particular index path.
        let indexOfVisibleRow = visibleCellsPerSection[indexPath.section][indexPath.row]
        let cellDescriptor = (cellDescriptors[indexPath.section] as! NSArray)[indexOfVisibleRow] as! [String: AnyObject]
        return cellDescriptor
    }
    
    func textDidChange(_ textField: UITextField) {
        // If either title or location is empty, display "Done" button.
        doneButton.isEnabled = textField.text?.characters.count != 0 && annotation != nil
    }
    
    func setPickerTextColor(_ color: UIColor)
    {
        categoryColorCell?.textLabel?.textColor = color
    }
    
    @IBAction func click(_ sender: UIButton) {
        // Popover a color picker to let user select a color for this category.
        let popoverVC = storyboard?.instantiateViewController(withIdentifier: "colorPickerPopover") as! ColorPickerViewController
        popoverVC.modalPresentationStyle = .popover
        popoverVC.preferredContentSize = CGSize(width: 284, height: 446)
        if let popoverController = popoverVC.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = CGRect(x: 0, y: 0, width: 85, height: 30)
            popoverController.permittedArrowDirections = .any
            popoverController.delegate = self
            popoverVC.delegate = self
        }
        present(popoverVC, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // Force iPhone to display popover rather than push a new view.
        return .none
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "chooseLocationSegue"
        {
            // Configure destination view controller.
            let vc = segue.destination as! LocationViewController
            vc.delegate = self
            navigationController?.preferredContentSize = largeSize
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
    @IBAction func cancelAddCategory(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneAddCategory(_ sender: UIBarButtonItem) {
        
        // When done button is clicked, get all information from cells.
        let title = categoryTitleCell.inputTitleTextField.text!
        let color = categoryColorCell.textLabel!.textColor
        let annotationTitle: String = annotation!.title!
        let latitude: Double = annotation!.coordinate.latitude
        let longitude: Double = annotation!.coordinate.longitude
        let remindMe = notificationCell.remindMeSwitch.isOn
        var remindRadius: Int? {
            if notificationCell.remindMeSwitch.isOn
            {
                switch notificationRadiusCell!.radiusPicker.selectedRow(inComponent: 0) {
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
            if notificationCell.remindMeSwitch.isOn
            {
                return notificationMethodCell?.methodSegment.selectedSegmentIndex
            }
            return nil
        }
        
        // Then if category to edit is nil, it means user is adding a new category, so add a new one in the core data.
        if categoryToEdit == nil
        {
            // Add new item into core data as well as temporary list
            let category = NSEntityDescription.insertNewObject(forEntityName: "Category", into: managedObject) as! Category
            category.title = title
            category.color = NSKeyedArchiver.archivedData(withRootObject: color)
            category.annotationTitle = annotationTitle
            category.latitude = NSNumber(latitude)
            category.longitude = NSNumber(longitude)
            category.remindMe = remindMe as NSNumber
            category.remindRadius = remindRadius as! NSNumber
            category.remindMethod = remindMethod as! NSNumber
            category.index = NSNumber(tmpCategoryList.count)
            category.completed = false
            tmpCategoryList.append(category)
        }
        else
        {
            // Otherwise modify the category selected by a user.
            categoryToEdit?.title = title
            categoryToEdit?.color = NSKeyedArchiver.archivedData(withRootObject: color)
            categoryToEdit?.annotationTitle = annotationTitle
            categoryToEdit?.latitude = NSNumber(latitude)
            categoryToEdit?.longitude = NSNumber(longitude)
            categoryToEdit?.remindMe = remindMe as NSNumber
            categoryToEdit?.remindRadius = remindRadius as! NSNumber
            categoryToEdit?.remindMethod = remindMethod as! NSNumber
        }
        
        saveData()
        dismiss(animated: true, completion: {
            self.delegate?.tableView.reloadData()
            if self.mapDelegate?.mapView != nil
            {
                self.mapDelegate?.loadData()
            }
        })
        appDelegate.refreshGeofencing()
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
        navigationController?.preferredContentSize = notificationCell.remindMeSwitch.isOn ? largeSize : smallSize
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
