//
//  addSpot_ToolbarSubClass.swift
//  iACDB
//
//  Created by Richard Walters on 23/07/2017.
//  Copyright © 2017 Richard Walters. All rights reserved.
//
//  Created to provide key click sounds on AddSpot accessoryView custom keys
//
//  For sounds to work they must be in a sub-class

import UIKit

class addSpot_ToolbarSubClass: UIToolbar, UIInputViewAudioFeedback{

    // Enable keyboard clicks for accessory view
    var enableInputClicksWhenVisible: Bool {
        return true
    }

}
