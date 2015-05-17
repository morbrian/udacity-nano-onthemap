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
    @IBOutlet weak var statusLabel: UILabel!
    
    private var viewShiftDistance: CGFloat? = nil
    
    var dataManager: StudentDataAccessManager?
    
    override func viewDidLoad() {
        findOnMapButton.layer.cornerRadius = 8.0
    }
    
    override func viewWillAppear(animated: Bool) {
        statusLabel.hidden = true
        // register action if keyboard will show
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
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
            // we move the view up as far as we needed to avoid obsuring the button, but not further
            let buttonOrigin = view.convertPoint(findOnMapButton.bounds.origin, fromView: findOnMapButton)
            let buttonBottomEdge = buttonOrigin.y + findOnMapButton.bounds.size.height
            viewShiftDistance = getKeyboardHeight(notification) - (view.bounds.maxY - buttonBottomEdge)
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
    
    @IBAction func reverseGeocodeAction(sender: UIButton) {
        placeNameTextField.endEditing(false)
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
                                updatedInformation.mediaUrl = "asdf://blurp.totally.fake.domain.giberish"
                                dataManager.storeStudentInformation(updatedInformation)
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.dismissViewControllerAnimated(true, completion: nil)
                                }
                        }
                    }
                } else if let error = error {
                    dispatch_async(dispatch_get_main_queue()) {
                        switch error.code {
                        case 2: self.statusLabel.text = "Network Unavailable"
                        case 8: self.statusLabel.text = "Cound not find that place."
                        default: self.statusLabel.text = "Try another place."
                        }
                        self.statusLabel.hidden = false
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.statusLabel.text = "Could not find that place, try entering another."
                        self.statusLabel.hidden = false
                    }
                }
            }
        }
    }
    
    @IBAction func resetStatusLabel(sender: UITextField) {
        statusLabel.hidden = true
    }
    
}
