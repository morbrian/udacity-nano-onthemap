//
//  ReverseGeocodeViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 5/2/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

// GeocodeViewController
// prompts the user to add a new study location
class GeocodeViewController: UIViewController {
    
    @IBOutlet weak var cancelButton: UIButton!
    
    // MARK: Finde Place Editor Outlets
    
    @IBOutlet weak var whereStudyingPanel: UIView!
    @IBOutlet weak var placeNameEditorPanel: UIView!
    @IBOutlet weak var findOnMapButton: UIButton!
    @IBOutlet weak var placeNameTextField: UITextField!
    @IBOutlet weak var statusLabel: UILabel!
    
    // MARK: URL Editor Outlets
    
    @IBOutlet weak var urlEditorPanel: UIView!
    @IBOutlet weak var mapContainerPanel: UIView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Network Activity Outlets
    
    @IBOutlet weak var activitySpinner: UIImageView!
    @IBOutlet weak var spinnerPanel: UIView!

    private var spinnerBaseTransform: CGAffineTransform!
    private var activityInProgress = false
    private var viewShiftDistance: CGFloat? = nil
    
    private var updatedInformation: StudentInformation?
    
    var dataManager: StudentDataAccessManager?
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        spinnerBaseTransform = activitySpinner.transform
        configureButton(findOnMapButton)
        configureButton(cancelButton)
        configureButton(submitButton)
        mapView.mapType = .Standard
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
    
    private func configureButton(button: UIButton) {
        button.layer.cornerRadius = 8.0
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
    
    // MARK: IBActions
    
    @IBAction func cancelAction(sender: UIButton) {
       dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func reverseGeocodeAction(sender: UIButton) {
        placeNameTextField.endEditing(false)
        var geocoder = CLGeocoder()
        
        if let placename = placeNameTextField.text {
            networkActivity(true)
            geocoder.geocodeAddressString(placename) {
                placemarks, error in
                self.networkActivity(false)
                if let placemarks = placemarks {
                    if placemarks.count > 0 {
                        if let placemark = placemarks[0] as? CLPlacemark,
                            dataManager = self.dataManager,
                            var updatedInformation = dataManager.loggedInUser  {
                                // set the new coordinate information and placename
                                updatedInformation.latitude = Float(placemark.location.coordinate.latitude)
                                updatedInformation.longitude = Float(placemark.location.coordinate.longitude)
                                updatedInformation.mapString = placename
                                var distance: CLLocationDistance?
                                if let circularRegion = placemark.region as? CLCircularRegion {
                                    distance = circularRegion.radius
                                }
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.updatedInformation = updatedInformation
                                    self.transitionToUrlEditing(regionDistance: distance)
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
            networkActivity(true)
            dataManager?.storeStudentInformation(updatedInformation) {
                success, error in
                self.networkActivity(false)
                if success {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                } else {
                    Logger.error("Failed to submit, we should show error to user.")
                }
            }
        } else {
            Logger.error("Bad URL: \(enteredUrlString)")
        }
    }
    
    // MARK: Activity Display
    
    func networkActivity(active: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            self.activityInProgress = active
            self.spinnerPanel.hidden = !active
            if (active) {
                self.animate()
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = active
            
        }
    }
    
    func animate() {
        UIView.animateWithDuration(0.001,
            delay: 0.0,
            options: UIViewAnimationOptions.CurveEaseInOut,
            animations: { self.activitySpinner.transform =
                CGAffineTransformConcat(self.activitySpinner.transform, CGAffineTransformMakeRotation((CGFloat(60.0) * CGFloat(M_PI)) / CGFloat(180.0)) )},
            completion: { something in
                if self.activityInProgress {
                    self.animate()
                } else {
                    // TODO: this snaps to position at then end, we should perform the final animation.
                    self.activitySpinner.transform = self.spinnerBaseTransform
                }
        })
    }
    
    private func transitionToUrlEditing(#regionDistance: CLLocationDistance?) {
        whereStudyingPanel.hidden = true
        placeNameEditorPanel.hidden = true
        urlEditorPanel.hidden = false
        mapContainerPanel.hidden = false
        if let updatedInformation = updatedInformation,
            annotation = StudentAnnotation(student: updatedInformation) {
                mapView.addAnnotation(annotation)
                let distance = regionDistance ?? Constants.MapSpanDistanceMeters
                var region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, distance, distance)
                mapView.setRegion(region, animated: true)
        }
    }
    
}
