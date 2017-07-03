//
//  spotListHeaderCellTableViewCell.swift
//  iACDB
//
//  Created by Richard Walters on 14/12/2016.
//  Copyright © 2016 Richard Walters. All rights reserved.
//

// Custom Section Header Cell which responds to taps

import UIKit

class spotListHeaderCellTableViewCell: UITableViewCell {
    
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var btnAddSpot: UIButton!
    
    var headerCellSection:Int?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
