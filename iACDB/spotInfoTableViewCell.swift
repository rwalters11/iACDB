//
//  spotInfoTableViewCell.swift
//  iACDB
//
//  Created by Richard Walters on 13/12/2016.
//  Copyright © 2016 Richard Walters. All rights reserved.
//

import UIKit

class spotInfoTableViewCell: UITableViewCell {
    
    // MARK: Properties
    
    @IBOutlet weak var lblRegistration: UILabel!
    
    @IBOutlet weak var lblLocation: UILabel!
    
    @IBOutlet weak var lblTypeSeries: UILabel!
    
    @IBOutlet weak var lblDayDate: UILabel!
    
    @IBOutlet weak var imgUploaded: UIImageView!
    
    @IBOutlet weak var lblOperator: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
