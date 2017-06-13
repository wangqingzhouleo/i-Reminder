//
//  CategoryTitleCell.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 2/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//

import UIKit

class CategoryTitleCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet weak var inputTitleTextField: UITextField!
    var delegate: AddCategoryTableViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        inputTitleTextField.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(self.textDidChange), name: nil, object: nil)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func textDidChange()
    {
        delegate?.textDidChange(inputTitleTextField)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }
    
}
