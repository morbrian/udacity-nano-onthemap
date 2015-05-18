//
//  SubmitInformationUpdateViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 5/17/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit
import MapKit

class SubmitInformationUpdateViewController: UIViewController {
    
    
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var updatedInformation: StudentInformation?
    var dataManager: StudentDataAccessManager?
    
    override func viewDidLoad() {
        mapView.mapType = .Standard
        submitButton.layer.cornerRadius = 8.0
        cancelButton.layer.cornerRadius = 8.0
        // we wait until the view appears so the user will see the map animate to position
        if let updatedInformation = updatedInformation,
            annotation = StudentAnnotation(student: updatedInformation) {
                mapView.addAnnotation(annotation)
                var region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, Constants.MapSpanDistanceMeters, Constants.MapSpanDistanceMeters)
                mapView.setRegion(region, animated: true)
        }
    }

    @IBAction func cancelAction(sender: UIButton) {
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func submitAction(sender: UIButton) {
        let enteredUrlString = urlTextField.text
        if var updatedInformation = updatedInformation,
            mediaUrl = NSURL(string: enteredUrlString),
            scheme = mediaUrl.scheme,
            hostname = mediaUrl.host
            where scheme.lowercaseString == "http" || scheme.lowercaseString == "https"
        {
            // it's probably good, but maybe not accessible
            Logger.info("Probably ok: \(enteredUrlString)")
            updatedInformation.mediaUrl = enteredUrlString
            dataManager?.storeStudentInformation(updatedInformation) {
                success, error in
                Logger.info("Submit called us back (but will Cristina?): \(success) or \(error)")
                if success {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.navigationController?.popToRootViewControllerAnimated(true)
                    }
                } else {
                    Logger.error("Failed to submit, we should show error to user.")
                }
            }
        } else {
            Logger.error("Bad URL: \(enteredUrlString)")
        }
    }
}



