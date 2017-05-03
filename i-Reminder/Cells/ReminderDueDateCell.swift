//
//  ReminderDueDateCell.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 4/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//

import UIKit

class ReminderDueDateCell: UITableViewCell {

    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var dueDateSwitch: UISwitch!
    var delegate: AddReminderTableViewController?
    
    var previousValue = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func toggleDueDateStatus(sender: UISwitch) {
        if sender.on == previousValue
        {
            return
        }
        else
        {
            delegate?.toggleDueDateStatus(sender)
            previousValue = sender.on
        }
    }
}
