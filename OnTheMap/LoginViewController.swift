//
//  ViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/18/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit
import FBSDKLoginKit

// LoginViewController
// Presents username / password enabling user to login to appliction.
// Displays error messages if login is not successful.
class LoginViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginStatusLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var facebookButton: FBSDKLoginButton!
    
    // central data management object
    private var dataManager: StudentDataAccessManager!
    
    // remember how far we moved the view after the keyboard displays
    private var viewShiftDistance: CGFloat? = nil
    
    // network activity properties
    var activityInProgress = false
    private var spinnerBaseTransform: CGAffineTransform!

    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataManager = StudentDataAccessManager()
        navigationController?.navigationBar.hidden = true
        // TODO: Consider using GBDeviceInfo, although this check is sufficient for our simple needs
        if view.bounds.height <= CGFloat(Constants.DeviceiPhone5Height) {
            // for iPhone5 or smaller, make some of the fonts smaller
            signupButton.titleLabel?.font = signupButton.titleLabel?.font.fontWithSize(CGFloat(16.0))
            loginStatusLabel.font = loginStatusLabel.font.fontWithSize(CGFloat(12.0))
        }
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        view.addGestureRecognizer(tapRecognizer)
        spinnerBaseTransform = self.imageView.transform
        facebookButton.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        resetLoginStatusLabel()
        // register action if keyboard will show
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        if let token = FBSDKAccessToken.currentAccessToken() {
            networkActivity(true)
            dataManager.authenticateByFacebookToken(FBSDKAccessToken.currentAccessToken().tokenString,
                completionHandler: handleAuthenticationResponse)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        // unregister keyboard actions when view not showing
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    // MARK: Keyboard Show/Hide Handling
    
    // shift the entire view up if bottom text field being edited
    func keyboardWillShow(notification: NSNotification) {
        var bottomOfLoginButton: CGFloat {
            var loginButtonOrigin =  view.convertPoint(loginButton.bounds.origin, fromView: loginButton)
            return loginButtonOrigin.y + loginButton.bounds.height
        }
        if viewShiftDistance == nil {
            var keyboardHeight = getKeyboardHeight(notification)
            var topOfKeyboard = view.bounds.maxY - keyboardHeight
            // we only need to move the view if the keyboard will cover up the login button and text fields
            if topOfKeyboard < bottomOfLoginButton {
                viewShiftDistance = bottomOfLoginButton - topOfKeyboard
                self.view.bounds.origin.y += viewShiftDistance!
            }
        }
    }
    
    // if bottom textfield just completed editing, shift the view back down
    func keyboardWillHide(notification: NSNotification) {
        if let shiftDistance = viewShiftDistance {
            self.view.bounds.origin.y -= shiftDistance
            viewShiftDistance = nil
        }
    }
    
    // return height of displayed keyboard
    private func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        Logger.info("we think the keyboard height is: \(keyboardSize.CGRectValue().height)")
        return keyboardSize.CGRectValue().height
    }
    
    // MARK: IB Actions
    
    @IBAction func beginEditTextfield(sender: UITextField) {
        resetLoginStatusLabel()
    }

    @IBAction func performLogin(sender: UIButton) {
        endTextEditing()
        loginStatusLabel.hidden = true
        let username = usernameTextField.text
        let password = passwordTextField.text
        
        networkActivity(true)
        dataManager.authenticateByUsername(username, withPassword: password,
            completionHandler: handleAuthenticationResponse)
    }
    
    @IBAction func gotoAccountSignup(sender: UIButton) {
        UIApplication.sharedApplication().openURL(NSURL(string: Constants.UdacitySignupUrlString)!)
    }
    
    @IBAction func proceedAsGuest(sender: UIButton) {
        transitionSucessfulLoginSegue()
    }
    
    // MARK: Segue Transition
    
    private func transitionSucessfulLoginSegue() {
        dispatch_async(dispatch_get_main_queue()) {
            self.performSegueWithIdentifier(Constants.SuccessfulLoginSegue, sender: self.dataManager)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? ManagingTabBarController,
            dataManager = sender as? StudentDataAccessManager {
            destination.dataManager = dataManager
        } else {
            Logger.error("Unrecognized Segue Destination Class For Segue: \(segue.identifier ?? nil)")
        }
    }
    
    // MARK: Support Helpers
    
    // provide acivity indicators and animations
    func networkActivity(active: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = active
            self.activityInProgress = active
            self.usernameTextField.enabled = !active
            self.passwordTextField.enabled = !active
            self.loginButton.enabled = !active
            self.signupButton.enabled = !active
            if (active) {
                self.animate()
            } else if let transform = self.spinnerBaseTransform {
                self.imageView.transform = transform
            }
        }
    }
    
    // animate Udacity imageView while network activity
    func animate() {
        dispatch_async(dispatch_get_main_queue()) {
            UIView.animateWithDuration(0.001,
                delay: 0.0,
                options: UIViewAnimationOptions.CurveEaseInOut,
                animations: { self.imageView.transform =
                    CGAffineTransformConcat(self.imageView.transform, CGAffineTransformMakeRotation((CGFloat(60.0) * CGFloat(M_PI)) / CGFloat(180.0)) )},
                completion: { something in
                    if self.activityInProgress {
                        self.animate()
                    } else {
                        // TODO: this snaps to position at then end, we should perform the final animation.
                        self.imageView.transform = self.spinnerBaseTransform
                    }
            })
        }
    }

    func resetLoginStatusLabel() {
        loginStatusLabel?.text = ""
        loginStatusLabel?.hidden = true
    }
    
    func endTextEditing() {
        usernameTextField?.endEditing(false)
        passwordTextField?.endEditing(false)
    }
    
    // MARK: Gestures
    
    func handleTap(sender: UIGestureRecognizer) {
        endTextEditing()
    }
    
    // MARK: Authentication
    
    func handleAuthenticationResponse(#success: Bool, error: NSError?) {
        self.networkActivity(false)
        if success {
            self.transitionSucessfulLoginSegue()
        } else {
            Logger.info("Login failed with code \(error?.code) \(error?.description)")
            
            dispatch_async(dispatch_get_main_queue()) {
                if let reason = error?.localizedDescription {
                    self.loginStatusLabel?.text = "!! \(reason)"
                } else {
                    self.loginStatusLabel?.text = "!! Login failed"
                }
                self.loginStatusLabel.hidden = false
            }
        }
    }
    
    func resetStateAfterUserLogout() {
        Logger.info("Logging out...")
        dataManager = StudentDataAccessManager()
        resetLoginStatusLabel()
    }
    
    @IBAction func segueToLoginScreen(segue: UIStoryboardSegue) {
        resetStateAfterUserLogout()
    }
}

// MARK: - FBSDKLoginButtonDelegate

extension LoginViewController: FBSDKLoginButtonDelegate {
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        networkActivity(true)
        if let token = result.token {
            dataManager.authenticateByFacebookToken(token.tokenString,
            completionHandler: handleAuthenticationResponse)
        } else if let error = error {
            handleAuthenticationResponse(success: false, error: error)
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        resetStateAfterUserLogout()
    }
}
