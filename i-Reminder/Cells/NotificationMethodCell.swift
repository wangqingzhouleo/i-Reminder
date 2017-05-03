//
//  NotificationMethodCell.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 3/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//

import UIKit

class NotificationMethodCell: UITableViewCell {

    @IBOutlet weak var methodSegment: UISegmentedControl!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
