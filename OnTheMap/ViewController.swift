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
    
    var udacityClient: UdacityWebClient!
    var onTheMapClient: OnTheMapParseWebClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        udacityClient = UdacityWebClient()
        onTheMapClient = OnTheMapParseWebClient()
    }


    @IBAction func performLogin(sender: UIButton) {
        
        let username = usernameTextField.text
        let password = passwordTextField.text
        
        println("login tapped")
        udacityClient.authenticateByUsername(username, withPassword: password) {
            userIdentity, error in
            if let userIdentity = userIdentity {
                self.udacityClient.fetchUserDataForUserIdentity(userIdentity) {
                    userData, error in
                    println("UserData: \(userData)")
                }
            } else {
                println("Login failed with code \(error?.code) \(error?.description)")
            }
        }
        println("login request sent")
        
    }
    
    
    @IBAction func requestStudentLocations(sender: UIButton) {
        println("student locations tapped")
        onTheMapClient.fetchStudentLocations() {
            data, error in
            println("nothing, probably not called yet")
        }
        println("student locations request sent")
    }
    

}

