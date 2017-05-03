//
//  DatePickerCell.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 4/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//

import UIKit

class DatePickerCell: UITableViewCell {

    @IBOutlet weak var datePicker: UIDatePicker!
    var delegate: AddReminderTableViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        datePicker.addTarget(self, action: #selector(self.datePickerValueChanged(_:)), forControlEvents: .ValueChanged)
        datePicker.minuteInterval = 5
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func datePickerValueChanged(datePicker: UIDatePicker)
    {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "EEE, dd/MM/yyyy, HH:mm"
        delegate?.reminderDueDateCell?.dueDateLabel.text = formatter.stringFromDate(datePicker.date)
    }

}
