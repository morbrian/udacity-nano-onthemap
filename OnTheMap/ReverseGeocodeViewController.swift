//
//  ReverseGeocodeViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 5/2/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit
import CoreLocation

class ReverseGeocodeViewController: UIViewController {
    
    @IBOutlet weak var findOnMapButton: UIButton!
    @IBOutlet weak var placeNameTextField: UITextField!
    
    var dataManager: StudentDataAccessManager?
    
    override func viewDidLoad() {
        Logger.info("has datamanager with \(dataManager?.studentLocationCount) items")
        
        findOnMapButton.layer.cornerRadius = 8.0
    }
    
    @IBAction func reverseGeocodeAction(sender: UIButton) {
        Logger.info("Find \(placeNameTextField.text)")
        var geocoder = CLGeocoder()
        
        
        geocoder.geocodeAddressString(placeNameTextField.text) {
            placemarks, error in
            for anyObject in placemarks {
                if let placemark = anyObject as? CLPlacemark {
                    println("\(placemark)")
                    placemark.location.coordinate
                }
            }
        }
    }
}
