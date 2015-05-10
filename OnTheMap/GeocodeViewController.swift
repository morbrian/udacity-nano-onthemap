//
//  ReverseGeocodeViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 5/2/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit
import CoreLocation

// GeocodeViewController
// prompts the user to add a new study location
class GeocodeViewController: UIViewController {
    
    @IBOutlet weak var findOnMapButton: UIButton!
    @IBOutlet weak var placeNameTextField: UITextField!
    
    var dataManager: StudentDataAccessManager?
    
    override func viewDidLoad() {
        findOnMapButton.layer.cornerRadius = 8.0
    }
    
    @IBAction func reverseGeocodeAction(sender: UIButton) {
        var geocoder = CLGeocoder()
        
        if let placename = placeNameTextField.text {
            geocoder.geocodeAddressString(placename) {
                placemarks, error in
                if let placemarks = placemarks {
                    if placemarks.count > 0 {
                        if let placemark = placemarks[0] as? CLPlacemark,
                            dataManager = self.dataManager,
                            var updatedInformation = dataManager.loggedInUser  {
                                // set the new coordinate information and placename
                                updatedInformation.latitude = Float(placemark.location.coordinate.latitude)
                                updatedInformation.longitude = Float(placemark.location.coordinate.longitude)
                                updatedInformation.mapString = placename
                                updatedInformation.mediaUrl = "http://sometimesredsometimesblue.com"
                                dataManager.storeStudentInformation(updatedInformation)
                                self.dismissViewControllerAnimated(true, completion: nil)
                        }
                    }
                } else {
                    // TODO: we need to communicate this to the user to type in something else
                    Logger.info("No place found for the text typed in")
                }
            }
        }
    }
}
