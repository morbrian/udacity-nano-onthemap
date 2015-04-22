//
//  ViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/18/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    var webClient: UdacityWebClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webClient = UdacityWebClient()
    }


    @IBAction func performLogin(sender: UIButton) {
        
        let username = usernameTextField.text
        let password = passwordTextField.text
        
        println("login tapped")
        webClient.authenticateByUsername(username, withPassword: password) {
            userIdentity, error in
            if let userIdentity = userIdentity {
                self.webClient.fetchUserDataForUserIdentity(userIdentity) {
                    userData, error in
                    println("UserData: \(userData)")
                }
            } else {
                println("Login failed with code \(error?.code) \(error?.description)")
            }
        }
        println("login request sent")
        
    }
    

}

