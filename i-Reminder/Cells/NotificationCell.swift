//
//  NotificationCell.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 2/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//

import UIKit

class NotificationCell: UITableViewCell {

    @IBOutlet weak var remindMeSwitch: UISwitch!
    @IBOutlet weak var notificationLabel: UILabel!
    var delegate: AddCategoryTableViewController?
    
    var previousValue = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func toggleNotification(_ sender: UISwitch) {
        if sender.isOn == previousValue
        {
            return
        }
        else
        {
            delegate?.toggleNotification(sender)
        }
    }
}
