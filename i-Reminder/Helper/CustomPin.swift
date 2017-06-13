//
//  Annotation.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 5/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//

import UIKit
import MapKit

class CustomPin: MKPointAnnotation {
    
    var pinColor: UIColor!
    var reminderList: [Reminder]!
    var selectedIndex: IndexPath!
    var category: Category!
    
}
