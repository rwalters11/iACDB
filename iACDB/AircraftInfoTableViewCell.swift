//
//  AircraftInfoTableViewCell.swift
//  iACDB
//
//  Created by Richard Walters on 09/12/2016.
//  Copyright © 2016 Richard Walters. All rights reserved.
//

import UIKit

class AircraftInfoTableViewCell: UITableViewCell {
    
    // MARK: Properties

    @IBOutlet weak var lblRegistration: UILabel!
    @IBOutlet weak var lblDetails: UILabel!
    @IBOutlet weak var lblOperator: UILabel!
    @IBOutlet weak var imgAircraft: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
