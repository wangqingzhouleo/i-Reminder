//
//  CategoryDetailCell.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 2/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//

import UIKit

class CategoryDetailCell: UITableViewCell {

    @IBOutlet weak var tagButton: RadioButton!
    @IBOutlet weak var reminderLabel: UILabel!
    
    var indexPath: IndexPath?
    var delegate: CategoryDetailTableViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func tapButtonAction(_ sender: AnyObject) {
        delegate?.tapButton(indexPath!)
    }
}
