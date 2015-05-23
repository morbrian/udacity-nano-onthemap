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
    
    // MARK: Find Place Editor Outlets
    
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
    
    
    @IBOutlet weak var browseButton: UIButton!
    @IBOutlet weak var webBrowserPanel: UIView!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var bottomSectionPanel: UIView!
    
    var activitySpinner: SpinnerPanelView!

    private var viewShiftDistance: CGFloat? = nil
    
    private var updatedInformation: StudentInformation?
    
    var dataManager: StudentDataAccessManager?
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        activitySpinner = produceSpinner()
        view.addSubview(activitySpinner)
        
        configureButton(findOnMapButton)
        configureButton(cancelButton)
        configureButton(submitButton)
        configureButton(browseButton)
       
        mapView.mapType = .Standard
        searchBar.delegate = self
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
        button.layer.borderColor = UIColor.darkGrayColor().CGColor
    }
    
    private func produceSpinner() -> SpinnerPanelView {
        var activitySpinner = SpinnerPanelView(frame: view.bounds, spinnerImageView: UIImageView(image: UIImage(named: "Udacity")))
        activitySpinner.backgroundColor = UIColor.orangeColor()
        activitySpinner.alpha = CGFloat(0.5)
        return activitySpinner
    }
    
    // MARK: Keyboard Show/Hide Handling
    
    // shift the entire view up if bottom text field being edited
    func keyboardWillShow(notification: NSNotification) {
        var isShowingMap: Bool {
            return !mapContainerPanel.hidden
        }
        var buttonOrigin: CGPoint {
            if isShowingMap {
                return view.convertPoint(submitButton.bounds.origin, fromView: submitButton)
            } else {
                return view.convertPoint(findOnMapButton.bounds.origin, fromView: findOnMapButton)
            }
        }
        
        if !webBrowserPanel.hidden {
            return
        }
        
        if viewShiftDistance == nil {
            // we move the view up as far as we needed to avoid obsuring the button, but not further
            let buttonBottomEdge = buttonOrigin.y + findOnMapButton.bounds.size.height
            viewShiftDistance = getKeyboardHeight(notification) - (view.bounds.maxY - buttonBottomEdge)
        
            if isShowingMap {
                mapContainerPanel.bounds.origin.y += viewShiftDistance!
            } else {
                view.bounds.origin.y += viewShiftDistance!
            }
        }
    }
    
    // if bottom textfield just completed editing, shift the view back down
    func keyboardWillHide(notification: NSNotification) {
        if let shiftDistance = viewShiftDistance {
            if mapContainerPanel.hidden {
                view.bounds.origin.y -= shiftDistance
            } else {
                mapContainerPanel.bounds.origin.y -= viewShiftDistance!
            }
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
    
    @IBAction func useCurrentWebPage(sender: UIBarButtonItem) {
        urlTextField?.text = webView.request?.URL?.absoluteString
        webBrowserPanel.hidden = true
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
        urlTextField.endEditing(false)
        let enteredUrlString = urlTextField.text
        
        // we check the basic syntax of the URL using the provided NSURL class,
        // then we verify the protocol is http(s) because these should be web pages not some other link,
        // finally we'll do a lightweight HEAD check with a request.
        if var updatedInformation = updatedInformation,
            url = ToolKit.produceValidUrlFromString(enteredUrlString),
            urlString = url.absoluteString {
                
            self.networkActivity(true)
            WebClient().pingUrl(enteredUrlString) {
                reply, error in
                if reply {
                    updatedInformation.mediaUrl = urlString
                    self.dataManager?.storeStudentInformation(updatedInformation) {
                        success, error in
                        self.networkActivity(false)
                        if success {
                            dispatch_async(dispatch_get_main_queue()) {
                                self.dismissViewControllerAnimated(true, completion: nil)
                            }
                        } else if let error = error {
                            ToolKit.showErrorAlert(viewController: self, title: "Data Not Updated", message: error.localizedDescription)
                        } else {
                            ToolKit.showErrorAlert(viewController: self, title: "Data Not Updated", message: "We failed to store your updates, but we aren't sure why.")
                        }
                    }
                } else if let error = error {
                    self.networkActivity(false)
                    ToolKit.showErrorAlert(viewController: self, title: "Invalid Url", message: error.localizedDescription)
                }
            }
        } else {
            Logger.error("Bad URL: \(enteredUrlString)")
            ToolKit.showErrorAlert(viewController: self, title: "Invalid Url", message: "Try entering a valid URL.")
        }
    }
    
    @IBAction func showWebView(sender: UIButton) {
        urlTextField.endEditing(false)
        if let request = WebClient().createHttpRequestUsingMethod(WebClient.HttpGet, forUrlString: urlTextField.text) {
            webView.loadRequest(request)
        }
        webBrowserPanel.hidden = false
    }
    
    
    // MARK: Activity Display
    
    func networkActivity(active: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            self.activitySpinner?.spinnerActivity(active)
        }
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

// MARK: - UISearchBarDelegate

extension GeocodeViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        var searchText = searchBar.text

        if let url = ToolKit.produceValidUrlFromString(searchText),
               urlString = url.absoluteString,
            request = WebClient().createHttpRequestUsingMethod(WebClient.HttpGet, forUrlString: urlString) {
                webView.loadRequest(request)
        } else {
            Logger.error("Need to do something better here.")
            var alternateString = "http://www.bing.com"
            if let request = WebClient().createHttpRequestUsingMethod(WebClient.HttpGet, forUrlString: alternateString) {
                webView.loadRequest(request)
            }
        }

        
    }
}
