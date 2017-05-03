//
//  ReminderTitleCell.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 4/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//

import UIKit

class ReminderTitleCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet weak var inputTitleTextField: UITextField!
    var delegate: AddReminderTableViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        inputTitleTextField.delegate = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.textDidChange), name: nil, object: nil)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func textDidChange()
    {
        delegate?.textDidChange(inputTitleTextField)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }

}
