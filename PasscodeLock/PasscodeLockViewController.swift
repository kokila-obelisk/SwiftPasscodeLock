//
//  PasscodeLockViewController.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import UIKit

public class PasscodeLockViewController: UIViewController, PasscodeLockTypeDelegate {
    
    public enum LockState {
        case EnterPasscode
        case SetPasscode
        case ChangePasscode
        case RemovePasscode
        
        func getState() -> PasscodeLockStateType {
            
            switch self {
            case .EnterPasscode: return EnterPasscodeState()
            case .SetPasscode: return SetPasscodeState()
            case .ChangePasscode: return ChangePasscodeState()
            case .RemovePasscode: return EnterPasscodeState(allowCancellation: true)
            }
        }
    }
    
    @IBOutlet public weak var titleLabel: UILabel?
    @IBOutlet public weak var descriptionLabel: UILabel!
    @IBOutlet public var placeholders: [PasscodeSignPlaceholderView] = [PasscodeSignPlaceholderView]()
    @IBOutlet public weak var cancelButton: UIButton?
    @IBOutlet public weak var deleteSignButton: UIButton?
    @IBOutlet public weak var touchIDButton: UIButton!
    @IBOutlet public weak var placeholdersX: NSLayoutConstraint?
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var keyboardBackImageView: UIImageView!
    @IBOutlet public var headerView: UIView!
    
    var isCancelButton: Bool = true
    var ifTouchEnabled: Bool = true
    var touchId: Bool = true
    var coverView: UIView!
    
    public var successCallback: ((_: PasscodeLockType) -> Void)?
    public var dismissCompletionCallback: (() -> Void)?
    public var animateOnDismiss: Bool
    public var notificationCenter: NSNotificationCenter?
    
    internal let passcodeConfiguration: PasscodeLockConfigurationType
    internal let passcodeLock: PasscodeLockType
    internal var isPlaceholdersAnimationCompleted = true
    
    private var shouldTryToAuthenticateWithBiometrics = true
    var screenName: String = ""
    var currectLock: PasscodeLockType!
    var currentState: LockState!
    var isTouchIdPopupShown: Bool = false
    public var titleAmount: String!
    public var breadCrumbView: UIView!
    
    // MARK: - Initializers
    
    public init(state: PasscodeLockStateType, configuration: PasscodeLockConfigurationType, animateOnDismiss: Bool = true) {
        
        self.animateOnDismiss = animateOnDismiss
        
        passcodeConfiguration = configuration
        passcodeLock = PasscodeLock(state: state, configuration: configuration)
        
        let nibName = "PasscodeLockView"
        let bundle: NSBundle = bundleForResource(nibName, ofType: "nib")
        
        super.init(nibName: nibName, bundle: bundle)
        
        passcodeLock.delegate = self
        notificationCenter = NSNotificationCenter.defaultCenter()
        self.isTouchIdPopupShown = false
    }
    
    public convenience init(state: LockState, configuration: PasscodeLockConfigurationType, animateOnDismiss: Bool = true) {
        self.init(state: state.getState(), configuration: configuration, animateOnDismiss: animateOnDismiss)
        self.currentState = state
    }
    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        
        clearEvents()
    }
    
    // MARK: - View
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        updatePasscodeView()
        deleteSignButton?.enabled = false
        configBackgroundImage()
        setupEvents()
        if screenName == "kPasscodeLockPresenterScreen" {
            customiseTouchIdButtonBeforeForeground()
        }
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldTryToAuthenticateWithBiometrics {
            
            authenticateWithBiometrics()
        }
    }
    
    func configBackgroundImage() {
        backgroundImageView.image = UIImage(named: "mobileRegistration")// To be added
        keyboardBackImageView.image = UIImage(named: "keyboard_back")
    }
    
    func customNavigationBarTitle() {
        let view = UIView()
        
        let logo = UIImage(named: "fluid_title_ic")
        let imageView = UIImageView(image:logo)
        imageView.frame =  CGRectMake(0, 2, 23, 36)
        view.addSubview(imageView)
        
        let labelOffsetX: CGFloat = 29
        let label = UILabel()
        label.textColor = UIColor.whiteColor()
        
        
        label.textAlignment = .Center
        if let value: String = titleAmount {
            label.text = value
            if let font = UIFont(name: "NeoSans-Bold", size: 24) {
                label.font = font
                let labelWidth = self.getTextWidth(value)
                label.frame = CGRectMake(labelOffsetX, 16, labelWidth, 24)
                view.frame = CGRectMake(0, 0, labelWidth + labelOffsetX, 44)
            }
        } else {
            label.frame = CGRectMake(labelOffsetX, 0, 164, 44)
            view.frame = CGRectMake(0, 0, 200, 44)
        }
        view.addSubview(label)
        
        self.navigationItem.titleView = view
    }
    
    func getTextWidth(text: String) -> CGFloat {
        let textString = text as NSString
        let textAttributes = [NSFontAttributeName: UIFont(name: "NeoSans-Bold", size: 24)!]
        
        let frame = textString.boundingRectWithSize(CGSizeMake(320, 44), options: .UsesLineFragmentOrigin, attributes: textAttributes, context: nil)
        return frame.size.width
    }
    
    internal func updatePasscodeView() {
        titleLabel?.text = passcodeLock.state.title
        titleLabel?.adjustsFontSizeToFitWidth = true
        //descriptionLabel?.text = passcodeLock.state.description
        touchIDButton?.hidden = !passcodeLock.isTouchIDAllowed
        touchIDButton?.enabled = true
        
        // headerView.addSubview(breadCrumbView)
        customNavigationBarTitle()
        
    }
    
    // MARK: - Events
    
    private func setupEvents() {
        
        notificationCenter?.addObserver(self, selector: #selector(PasscodeLockViewController.appWillEnterForegroundHandler(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)
        notificationCenter?.addObserver(self, selector: #selector(PasscodeLockViewController.appDidEnterBackgroundHandler(_:)), name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    private func clearEvents() {
        
        notificationCenter?.removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        notificationCenter?.removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    public func toCheckForTouchId(ifTouchEnabled: Bool) {
        self.ifTouchEnabled = ifTouchEnabled
        shouldTryToAuthenticateWithBiometrics = self.ifTouchEnabled
    }
    
    public func isFromScreen(screenName: String) {
        self.screenName = screenName
        
    }
    
    public func appWillEnterForegroundHandler(notification: NSNotification) {
        
        if shouldTryToAuthenticateWithBiometrics {
            authenticateWithBiometrics()
        }
        if !passcodeLock.isTouchIDAllowed {
            touchIDButton.hidden = true
        }
    }
    
    public func appDidEnterBackgroundHandler(notification: NSNotification) {
        
        shouldTryToAuthenticateWithBiometrics = self.ifTouchEnabled
        self.customiseTouchIdButtonBeforeForeground()
    }
    
    func customiseTouchIdButtonAfterForeground() {
        touchIDButton.hidden = false
        touchIDButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -35)
        touchIDButton.contentHorizontalAlignment = .Center
        touchIDButton.contentVerticalAlignment = .Center
        touchIDButton.setTitle("Cancel", forState: .Normal)
        touchIDButton.setImage(UIImage(), forState: .Normal)
        touchIDButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(PasscodeLockViewController.touchIdTapToCancel)))
    }
    
    func customiseTouchIdButtonBeforeForeground() {
        if passcodeConfiguration.shouldRequestTouchIDImmediately && passcodeLock.isTouchIDAllowed {
            if self.ifTouchEnabled {
                touchIDButton.setTitle("", forState: .Normal)
                touchIDButton.setImage(UIImage(named: ""), forState: .Normal) // finger print image
                let imageSize = touchIDButton.imageView?.frame.size
                let spacing = ((imageSize?.width)! / 2)
                touchIDButton.imageEdgeInsets = UIEdgeInsetsMake(spacing, spacing, spacing, spacing - 35)
                touchIDButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(PasscodeLockViewController.showTouchIdAlert)))
                
            } else {
                touchIDButton.hidden = true
            }
        } else {
            touchIDButton.hidden = true
        }
    }
    
    func addFrameToPasscodeLock() {
        //Remove the cover view first, so that the cover view is not added twice
        self.removeFrameFromView()
        
        self.coverView = UIView(frame: CGRectMake(0, 0, getDeviceWidth(), getDeviceHeight()))
        self.coverView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.9)
        self.coverView.tag = 100
        self.view.addSubview(self.coverView)
    }
    
    func removeFrameFromView() {
        if let viewWithTag = self.view.viewWithTag(100) {
            if self.coverView != nil {
                self.coverView.removeFromSuperview()
                self.coverView = nil
            }
        }
    }
    
    func addTouchIdPopup(lock: PasscodeLockType) {
        print("touch id called:\(passcodeLock.isTouchIDAllowed).. \(passcodeConfiguration.shouldRequestTouchIDImmediately)...:\(passcodeConfiguration.isTouchIDAllowed)")
        if passcodeConfiguration.shouldRequestTouchIDImmediately {
            print("add touch id view")
            self.currectLock = lock
            addChildView(self.view)
        } else {
            dismissPasscodeLock(lock, completionHandler: { [weak self] _ in
                self?.successCallback?(lock)
                })
        }
    }
    
    func addChildView(bgView: UIView) {
        self.isTouchIdPopupShown = true
        let childView = TouchIdView.instanceFromNib()
        childView.tag = 100
        childView.frame = CGRect(x: 0, y: 0, width: getDeviceWidth(), height: getDeviceHeight())
        bgView.addSubview(childView)
        childView.enableTouchIdButton.titleLabel?.adjustsFontSizeToFitWidth = true
        childView.disableTouchIdButton.titleLabel?.adjustsFontSizeToFitWidth = true
        childView.enableTouchIdButton.addTarget(self, action: #selector(enableTouchIdAction(_:)), forControlEvents: .TouchUpInside)
        childView.disableTouchIdButton.addTarget(self, action: #selector(disableTouchIdButton(_:)), forControlEvents: .TouchUpInside)
        childView.touchImageview.image = UIImage(named: "tapImage")
        childView.closeImageview.image = UIImage(named: "close")
        let gestureClose = UITapGestureRecognizer(target: self, action: #selector(dismissTouchIdPopup()))
        
        childView.closeView.addGestureRecognizer(gestureClose)
    }
    
    func enableTouchIdAction(sender: UIButton) {
        if let view = self.view.viewWithTag(100) {
            view.removeFromSuperview()
        }
        self.toCheckForTouchId(false)
        let nextState = EnterPasscodeState(allowCancellation: false)
        
        self.currectLock.changeStateTo(nextState)
    }
    
    func disableTouchIdButton(sender: UIButton) {
        dismissTouchIdPopup()
    }
    
    func dismissTouchIdPopup() {
        if let view = self.view.viewWithTag(100) {
            view.removeFromSuperview()
            dismissPasscodeLock(passcodeLock, completionHandler: { [weak self] _ in
                self?.successCallback?(self!.passcodeLock)
                })
        }
    }
    
    func getDeviceWidth() -> CGFloat {
        return UIScreen.mainScreen().bounds.width
    }
    
    //Method to get Device Height
    func getDeviceHeight() -> CGFloat {
        return UIScreen.mainScreen().bounds.height
    }
    
    func showTouchIdAlert() {
        //addFrameToPasscodeLock()
        passcodeLock.authenticateWithBiometrics()
    }
    
    func touchIdTapToCancel() {
        animateOnDismiss = true
        dismissPasscodeLock(passcodeLock)
    }
    
    // MARK: - Actions
    
    @IBAction func passcodeSignButtonTap(sender: PasscodeSignButton) {
        
        guard isPlaceholdersAnimationCompleted else { return }
        print("passcode sign:\(sender)")
        passcodeLock.addSign(sender.passcodeSign)
    }
    
    @IBAction func cancelButtonTap(sender: UIButton) {
        
        dismissPasscodeLock(passcodeLock)
    }
    
    @IBAction func deleteSignButtonTap(sender: UIButton) {
        
        passcodeLock.removeSign()
    }
    
    @IBAction func touchIDButtonTap(sender: UIButton) {
        
        passcodeLock.authenticateWithBiometrics()
    }
    
    private func authenticateWithBiometrics() {
        
        if passcodeConfiguration.shouldRequestTouchIDImmediately && passcodeLock.isTouchIDAllowed {
            passcodeLock.authenticateWithBiometrics()
        }
    }
    
    internal func dismissPasscodeLock(lock: PasscodeLockType, completionHandler: (() -> Void)? = nil) {
        
        // if presented as modal
        if presentingViewController?.presentedViewController == self {
            
            dismissViewControllerAnimated(animateOnDismiss, completion: { [weak self] _ in
                
                self?.dismissCompletionCallback?()
                
                completionHandler?()
                })
            
            return
            
            // if pushed in a navigation controller
        } else if navigationController != nil {
            
            navigationController?.popViewControllerAnimated(animateOnDismiss)
        }
        
        dismissCompletionCallback?()
        
        completionHandler?()
    }
    
    // MARK: - Animations
    
    internal func animateWrongPassword() {
        
        deleteSignButton?.enabled = false
        isPlaceholdersAnimationCompleted = false
        
        animatePlaceholders(placeholders, toState: .Error)
        
        placeholdersX?.constant = 0
        view.layoutIfNeeded()
        
        UIView.animateWithDuration(
            0.5,
            delay: 0,
            usingSpringWithDamping: 0.2,
            initialSpringVelocity: 0,
            options: [],
            animations: {
                
                self.placeholdersX?.constant = 0
                self.view.layoutIfNeeded()
            },
            completion: { completed in
                
                self.isPlaceholdersAnimationCompleted = true
                self.animatePlaceholders(self.placeholders, toState: .Inactive)
        })
    }
    
    internal func animatePlaceholders(placeholders: [PasscodeSignPlaceholderView], toState state: PasscodeSignPlaceholderView.State) {
        
        for placeholder in placeholders {
            
            placeholder.animateState(state)
        }
    }
    
    private func animatePlacehodlerAtIndex(index: Int, toState state: PasscodeSignPlaceholderView.State) {
        
        guard index < placeholders.count && index >= 0 else { return }
        
        placeholders[index].animateState(state)
    }
    
    // MARK: - PasscodeLockDelegate
    
    public func passcodeLockDidSucceed(lock: PasscodeLockType) {
        
        deleteSignButton?.enabled = true
        animatePlaceholders(placeholders, toState: .Inactive)
        // Show touch id popup
        if self.currentState == .SetPasscode && !self.isTouchIdPopupShown {
            self.addTouchIdPopup(lock)
        } else {
            dismissPasscodeLock(lock, completionHandler: { [weak self] _ in
                self?.successCallback?(lock)
                })
        }
    }
    
    public func removeFrameFromPasscodeLock() {
        self.removeFrameFromView()
    }
    
    public func passcodeLockDidFail(lock: PasscodeLockType) {
        
        animateWrongPassword()
    }
    
    public func passcodeLockDidChangeState(lock: PasscodeLockType) {
        
        updatePasscodeView()
        animatePlaceholders(placeholders, toState: .Inactive)
        deleteSignButton?.enabled = false
    }
    
    public func passcodeLock(lock: PasscodeLockType, addedSignAtIndex index: Int) {
        
        animatePlacehodlerAtIndex(index, toState: .Active)
        deleteSignButton?.enabled = true
    }
    
    public func passcodeLock(lock: PasscodeLockType, removedSignAtIndex index: Int) {
        
        animatePlacehodlerAtIndex(index, toState: .Inactive)
        
        if index == 0 {
            
            deleteSignButton?.enabled = false
        }
    }
}
