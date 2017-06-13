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
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let index = tableView.indexPathForSelectedRow
        {
            tableView.deselectRow(at: index, animated: true)
        }
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
        return tmpCategoryList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryMasterCell", for: indexPath) as! CategoryMasterCell

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
        
        cell.tagButton.setTitle(nil, for: .selected)
        // Configure the button based on user's selection, including color and state.
        cell.tagButton.circleColor = NSKeyedUnarchiver.unarchiveObject(with: category.color as Data) as! UIColor
        cell.tagButton.isSelected = category.completed.boolValue
        cell.categoryLabel.textColor = category.completed.boolValue ? UIColor.lightGray : UIColor.black

        return cell
    }
    
                   
    func tapButton(_ indexPath: IndexPath)
    {
        // First step get which button is clicked.
        let cell = tableView.cellForRow(at: indexPath) as! CategoryMasterCell
        // Then set button selected state to opposite state.
        cell.tagButton.isSelected = !cell.tagButton.isSelected
        
        // Adjust text color based on button selection state.
        switch cell.tagButton.isSelected {
        case true:
            cell.categoryLabel.textColor = UIColor.lightGray
        case false:
            cell.categoryLabel.textColor = UIColor.black
        }
        // Save changes to array and core data.
        tmpCategoryList[indexPath.row].completed = cell.tagButton.isSelected as NSNumber
        saveData()
        appDelegate.refreshGeofencing()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        // The table should not perform segue if no row is selected, if don't set this method, iPad version will has error when launch app.
        if identifier == "showCategoryDetailSegue" && tableView.indexPathForSelectedRow != nil
        {
            return true
        }
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCategoryDetailSegue"
        {
            // Configure destination controller.
            let navigationVC = segue.destination as! UINavigationController
            let vc = navigationVC.topViewController! as! CategoryDetailTableViewController
            let selectedIndex = tableView.indexPathForSelectedRow!
            vc.masterButtonColor = (tableView.cellForRow(at: selectedIndex) as! CategoryMasterCell).tagButton.circleColor
            vc.selectedCategoryIndexPath = selectedIndex
            vc.currentList = loadCurrentReminderList(inCategory: tmpCategoryList[selectedIndex.row])
            vc.delegate = self
        }
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath != destinationIndexPath
        {
            // Move the item in the category list first.
            tmpCategoryList.insert(tmpCategoryList.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)
            // Then reset all category's order in core data.
            resetCategoryListOrder()
            
            // This method has to be here, otherwise buttons will not reordered correctly.
            tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
            
            for item in tmpCategoryList
            {
                // Reset all button's index to correct position.
                let cell = tableView.cellForRow(at: IndexPath(row: item.index as Int, section: 0)) as! CategoryMasterCell
                cell.indexPath = IndexPath(row: item.index as Int, section: 0)
            }
            
            saveData()
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .default, title: "Delete", handler: { _,_ in
            // Display an alert to confirm deletion
            let category = tmpCategoryList[indexPath.row]
            let alert = UIAlertController(title: "Delete \"\(category.title)\"?", message: "This will permanently delete all reminders in \"\(category.title)\".", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (UIAlertAction) in
                // Remove from core data first, then remove from global array
                managedObject.delete(tmpCategoryList[indexPath.row])
                tmpCategoryList.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                saveData()
                resetCategoryListOrder()
                appDelegate.refreshGeofencing()
            }))
            self.present(alert, animated: true, completion: nil)
        })
        let more = UITableViewRowAction(style: .normal, title: "More", handler: { _,_ in
            self.editCategory(indexPath)
        })
        
        return [delete, more]
    }
    
    func editCategory(_ indexPath: IndexPath) {
        // Present the same popover as add category, then pass selected row to the controller for edit purpose.
        let popoverVC = storyboard?.instantiateViewController(withIdentifier: "addCategoryPopover") as! UINavigationController
        popoverVC.modalPresentationStyle = .popover
        if let popoverController = popoverVC.popoverPresentationController {
            popoverController.sourceView = self.tableView.cellForRow(at: indexPath)
            popoverController.sourceRect = CGRect(x: 100, y: 0, width: 85, height: 30)
            popoverController.permittedArrowDirections = .any
            popoverController.delegate = self
        }
        present(popoverVC, animated: true, completion: nil)
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
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // Force iPhone to display popover rather than push a new view.
        return .none
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 999
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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
