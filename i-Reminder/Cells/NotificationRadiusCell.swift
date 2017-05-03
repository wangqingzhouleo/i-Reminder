//
//  NotificationRadiusCell.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 3/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//

import UIKit

class NotificationRadiusCell: UITableViewCell, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var radiusLabel: UILabel!
    @IBOutlet weak var radiusPicker: UIPickerView!
    let radiusList = ["50 m", "250 m", "1 km"]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        radiusPicker.dataSource = self
        radiusPicker.delegate = self
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return radiusList.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return radiusList[row]
    }

}
