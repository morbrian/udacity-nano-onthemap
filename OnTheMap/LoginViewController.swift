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
    
    private var dataManager: StudentDataAccessManager!
    
    private var viewShiftDistance: CGFloat? = nil
    
    private var networkActivityInProgress = false
    private var defaultTransform: CGAffineTransform?
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataManager = StudentDataAccessManager()
        navigationController?.navigationBar.hidden = true
        
        // TODO: Consider using GBDeviceInfo, although this check is sufficient for our simple need
        if view.bounds.height <= CGFloat(Constants.DeviceiPhone5Height) {
            // for iPhone5 or smaller, make some of the fonts smaller
            signupButton.titleLabel?.font = signupButton.titleLabel?.font.fontWithSize(CGFloat(16.0))
            loginStatusLabel.font = loginStatusLabel.font.fontWithSize(CGFloat(12.0))
        }
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        view.addGestureRecognizer(tapRecognizer)
        
        defaultTransform = self.imageView.transform
        
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
        if viewShiftDistance == nil {
            viewShiftDistance = getKeyboardHeight(notification)
            self.view.bounds.origin.y += viewShiftDistance!
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
    
    // provide basic status bar activity indicator.
    func networkActivity(active: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = active
            self.networkActivityInProgress = active
            self.usernameTextField.enabled = !active
            self.passwordTextField.enabled = !active
            self.loginButton.enabled = !active
            self.signupButton.enabled = !active
            if (active) {
                self.animateImageView(1)
            } else if let transform = self.defaultTransform {
                self.imageView.transform = transform
            }
        }
    }
    
    func animateImageView(interval: CGFloat) {
        UIView.animateWithDuration(0.1,
            delay: 0.0,
            options: UIViewAnimationOptions.CurveEaseInOut,
            animations: { self.imageView.transform = CGAffineTransformMakeRotation((interval * CGFloat(120.0) * CGFloat(M_PI)) / CGFloat(180.0)) },
            completion: { something in
                if self.networkActivityInProgress {
                    self.animateImageView(interval + 1)
                }
            })
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
