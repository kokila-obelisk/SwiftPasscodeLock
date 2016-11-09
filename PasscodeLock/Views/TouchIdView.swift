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
    @IBOutlet var touchImageview: UIImageView!
    @IBOutlet var closeImageview: UIImageView!
    @IBOutlet var closeView: UIView!
    
    class func instanceFromNib() -> TouchIdView {
        let nibName = "TouchIdView"
        let bundle: NSBundle = bundleForResource(nibName, ofType: "nib")
         let nibviews = bundle.loadNibNamed("TouchIdView", owner: self, options: nil)
        if nibviews != nil && nibviews!.count > 0 {
            print("nib found:\(nibviews)")
            return nibviews![0] as! TouchIdView
        }
        return UINib(nibName: "TouchIdView", bundle: bundle).instantiateWithOwner(nil, options: nil)[0] as! TouchIdView
    }


}
