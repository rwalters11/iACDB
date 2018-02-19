//
//  spotHistoryTableViewCell.swift
//  iACDB
//
//  Created by Richard Walters on 16/02/2018.
//  Copyright © 2018 Richard Walters. All rights reserved.
//

import UIKit

class spotHistoryTableViewCell: UITableViewCell {

    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblCount: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
