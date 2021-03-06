//
//  CategoryMasterCell.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 2/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//

import UIKit

class CategoryMasterCell: UITableViewCell {

    @IBOutlet var tagButton: RadioButton!
    @IBOutlet weak var categoryLabel: UILabel!
    
    var indexPath: IndexPath?
    var delegate: CategoryMasterTableViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func tapButton(_ sender: RadioButton) {
        delegate?.tapButton(indexPath!)
    }
}
