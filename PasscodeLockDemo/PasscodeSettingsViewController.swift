//
//  PasscodeSettingsViewController.swift
//  PasscodeLockDemo
//
//  Created by Yanko Dimitrov on 8/29/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import UIKit
import PasscodeLock

class PasscodeSettingsViewController: UIViewController {

    @IBOutlet weak var passcodeSwitch: UISwitch!
    @IBOutlet weak var changePasscodeButton: UIButton!
    @IBOutlet weak var testTextField: UITextField!
    @IBOutlet weak var testActivityButton: UIButton!

    private let configuration: PasscodeLockConfigurationType
var isTouchIdPopupShown: Bool = false

    init(configuration: PasscodeLockConfigurationType) {

        self.configuration = configuration

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {

        let repository = UserDefaultsPasscodeRepository()
        configuration = PasscodeLockConfiguration(repository: repository)

        super.init(coder: aDecoder)
    }

    // MARK: - View

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        updatePasscodeView()
    }

    func updatePasscodeView() {

        let hasPasscode = configuration.repository.hasPasscode

        changePasscodeButton.hidden = !hasPasscode
        passcodeSwitch.on = hasPasscode
    }

    // MARK: - Actions

    @IBAction func passcodeSwitchValueChange(sender: UISwitch) {

        var passcodeVC: PasscodeLockViewController

        if passcodeSwitch.on {

            passcodeVC = PasscodeLockViewController(state: .SetPasscode, configuration: configuration)

            passcodeVC.dismissCompletionCallback = {
                print("dismiss cllback")
                passcodeVC.successCallback = { lock in
                    print("success callback")
                    if !self.isTouchIdPopupShown {
                        self.isTouchIdPopupShown = true
                   /*passcodeVC = PasscodeLockViewController(state: .EnterPasscode, configuration: self.configuration)
                    passcodeVC.toCheckForTouchId(true)

                        self.presentViewController(passcodeVC, animated: true, completion: nil)*/
                    }
                }
            }
        } else {

            passcodeVC = PasscodeLockViewController(state: .RemovePasscode, configuration: configuration)

            passcodeVC.successCallback = { lock in

                lock.repository.deletePasscode()
            }
        }

        presentViewController(passcodeVC, animated: true, completion: nil)
    }

    @IBAction func changePasscodeButtonTap(sender: UIButton) {

        let repo = UserDefaultsPasscodeRepository()
        let config = PasscodeLockConfiguration(repository: repo)

        let passcodeLock = PasscodeLockViewController(state: .ChangePasscode, configuration: config)

        presentViewController(passcodeLock, animated: true, completion: nil)
    }

    @IBAction func testAlertButtonTap(sender: UIButton) {

        let alertVC = UIAlertController(title: "Test", message: "", preferredStyle: .Alert)

        alertVC.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))

        presentViewController(alertVC, animated: true, completion: nil)

    }

    @IBAction func testActivityButtonTap(sender: UIButton) {

        let activityVC = UIActivityViewController(activityItems: ["Test"], applicationActivities: nil)

        activityVC.popoverPresentationController?.sourceView = testActivityButton
        activityVC.popoverPresentationController?.sourceRect = CGRect(x: 10, y: 20, width: 0, height: 0)

        presentViewController(activityVC, animated: true, completion: nil)
    }

    @IBAction func dismissKeyboard() {

        testTextField.resignFirstResponder()
    }
}
