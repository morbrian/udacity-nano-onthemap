//
//  ViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/18/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    private var dataManager: StudentDataAccessManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataManager = StudentDataAccessManager()
    }


    @IBAction func performLogin(sender: UIButton) {
        
        let username = usernameTextField.text
        let password = passwordTextField.text
        
        println("login tapped")
        dataManager.authenticateByUsername(username, withPassword: password) {
            success, error in
            if success {
                dispatch_async(dispatch_get_main_queue()) {
                    self.performSegueWithIdentifier("SuccessfulLoginSegue", sender: self.dataManager)
                }
            } else {
                println("Login failed with code \(error?.code) \(error?.description)")
            }
        }
        println("login request sent")
        
    }
    
    @IBAction func proceedAsGuest(sender: UIButton) {
        println("proceed as guest")
        self.performSegueWithIdentifier("SuccessfulLoginSegue", sender: self.dataManager)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? ManagingTabBarController {
            println("dest ok")
        } else {
            println("dest misunderstood")
        }
        if let destination = segue.destinationViewController as? ManagingTabBarController,
            dataManager = sender as? StudentDataAccessManager {
            destination.dataManager = dataManager
        } else {
            println("expecting crash... why though?")
        }
    }

}

