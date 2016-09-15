//
//  TouchIdView.swift
//  PasscodeLock
//
//  Created by Kokila Ishwar on 9/15/16.
//  Copyright © 2016 Yanko Dimitrov. All rights reserved.
//

import UIKit

class TouchIdView: UIView {

    @IBOutlet var enableTouchIdButton: UIButton!
    @IBOutlet var disableTouchIdButton: UIButton!

    class func instanceFromNib() -> TouchIdView {
        return UINib(nibName: "TouchIdView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! TouchIdView
    }

}
