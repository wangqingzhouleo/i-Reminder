//
//  MasterTabBarViewController.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 2/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class TabBarViewController: UITabBarController, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet var editButton: UIBarButtonItem!
//    @IBOutlet var editButton: UIBarButtonItem!
    let navigationTitle = ["List", "Map"]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationItem.title = navigationTitle[0]
        
        // Change navigation item back button's title, so all navigation bar will have a button with "back" as title on the left.
        let backButton = UIBarButtonItem()
        backButton.title = "Back"
        navigationItem.backBarButtonItem = backButton
        
        UITabBar.appearance().tintColor = UIColor(red: 0.0392, green: 0.8078, blue: 0.1647, alpha: 1)
        let masterController = viewControllers![0] as? CategoryMasterTableViewController
        masterController?.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let barItems = tabBar.items, tabBar.items?.count > 0
        {
            // Change navigation bar title according to which tab item is selected.
            switch item {
            case barItems[0]:
                navigationItem.title = navigationTitle[0]
                navigationItem.leftBarButtonItem = editButton
            case barItems[1]:
                navigationItem.title = navigationTitle[1]
                navigationItem.leftBarButtonItem = nil
            default:
                break
            }
        }
    }
    
    @IBAction func toggleEditMode(_ sender: UIBarButtonItem) {
        // Change "Edit" button's title and table's editing mode.
        let master = viewControllers![0] as! CategoryMasterTableViewController
        master.setEditing(!master.tableView.isEditing, animated: true)
        editButton.style = editButton.style == .plain ? .done : .plain
        editButton.title = editButton.title == "Edit" ? "Done" : "Edit"
    }

    @IBAction func addCategory(_ sender: UIBarButtonItem) {
        // Present a popover to let user add category.
        let popoverVC = storyboard?.instantiateViewController(withIdentifier: "addCategoryPopover") as! UINavigationController
        popoverVC.modalPresentationStyle = .popover
        if let popoverController = popoverVC.popoverPresentationController {
            popoverController.barButtonItem = sender
            popoverController.sourceRect = CGRect(x: 0, y: 0, width: 85, height: 30)
            popoverController.permittedArrowDirections = .any
            popoverController.delegate = self
        }
        present(popoverVC, animated: true, completion: nil)
        let vc = popoverVC.topViewController as! AddCategoryTableViewController
        vc.delegate = viewControllers![0] as? CategoryMasterTableViewController
        vc.mapDelegate = viewControllers![1] as? MapMasterViewController
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // Force iPhone to display popover rather than push a new view.
        return .none
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
