//
//  StudentMapViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/28/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit
import MapKit

// StudentMapViewController
// Displays a map showing geo-positions of all student study locations
class StudentMapViewController: OnTheMapBaseViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var activitySpinner: SpinnerPanelView!
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        activitySpinner = produceSpinner()
        view.addSubview(activitySpinner)
        mapView.mapType = .Satellite
        mapView.delegate = self
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplayFromModel()
        centerMapOnCurrentUser()
    }
    
    
    // a custom spinner used during network activity
    private func produceSpinner() -> SpinnerPanelView {
        let activitySpinner = SpinnerPanelView(frame: view.bounds, spinnerImageView: UIImageView(image: UIImage(named: "Udacity")))
        activitySpinner.backgroundColor = UIColor.orangeColor()
        activitySpinner.alpha = CGFloat(0.5)
        return activitySpinner
    }
    
    // MARK: Overrides From OnTheMapBaseViewController
    
    // clear existing annotations and reload from datamanager cache
    override func updateDisplayFromModel() {
        if let studentLocations = dataManager?.studentLocations {
            let optionalAnnotations = studentLocations.map() { StudentAnnotation(student: $0) }
            let filteredAnnotations = optionalAnnotations.filter() { $0 != nil }
            let studentAnnotations = filteredAnnotations.map() { $0! as StudentAnnotation }
            dispatch_async(dispatch_get_main_queue()) {
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.addAnnotations(studentAnnotations)
                if let willCenterOnUser = self.dataManager?.loggedInUserDoesHaveLocation()
                    where !willCenterOnUser {
                    self.mapView.showAnnotations(studentAnnotations, animated: true)
                }
            }
        }
    }
    
    // display custom spinner
    override func networkActivity(active: Bool, intrusive: Bool = true) {
        dispatch_async(dispatch_get_main_queue()) {
            if (intrusive) {
                self.activitySpinner.spinnerActivity(active)
            } else {
                super.networkActivity(active)
            }
        }
    }
    
    // after user data downloaded, center map on that location
    override func currentUserDataNowAvailable() {
        dispatch_async(dispatch_get_main_queue()) {
            self.centerMapOnCurrentUser()
        }
    }
    
    // center on the default location previously entered by user, if available
    func centerMapOnCurrentUser() {
        if let currentUserLocations = self.dataManager?.userLocations
            where currentUserLocations.count > 0 {
                let firstLocation = currentUserLocations[0]
                if let latitude = firstLocation.latitude,
                    longitude = firstLocation.longitude {
                        let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
                        let distance = Constants.MapSpanDistanceMeters
                        let region = MKCoordinateRegionMakeWithDistance(coordinate, distance, distance)
                        self.mapView.setRegion(region, animated: true)
                        
                }
        }
    }
}

// MARK: - MKMapViewDelegate

extension StudentMapViewController: MKMapViewDelegate {

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var view = mapView.dequeueReusableAnnotationViewWithIdentifier(Constants.StudentLocationAnnotationReuseIdentifier)
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.StudentLocationAnnotationReuseIdentifier)
            view?.canShowCallout = true
        } else {
            view?.annotation = annotation
        }
        
        if let studentAnnotation = annotation as? StudentAnnotation {
            if let urlString = studentAnnotation.student.mediaUrl,
                _ = NSURL(string: urlString) {
                    let detailButton = UIButton(type: UIButtonType.DetailDisclosure)
                    _ = UIImageView(image: detailButton.imageForState(UIControlState.Highlighted))
                    view?.rightCalloutAccessoryView = detailButton
            }
        }
        return view
    }
    
    // open the URL for the tapped Student Location pin if it is valid
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // TODO: verify URL and network connectivity before sending to Safari
        if let studentAnnotation = view.annotation as? StudentAnnotation,
            urlString = studentAnnotation.student.mediaUrl {
                self.sendToUrlString(urlString)
        }
    }
}

// MARK: - Extension StudentLocation, MKAnnotation

// StudentAnnotation
// wrap StudentInformation with Annotation for display on map
class StudentAnnotation: NSObject, MKAnnotation {
    
    let student: StudentInformation
    
    init?(student: StudentInformation) {
        self.student = student
        super.init()
        if student.latitude == nil || student.longitude == nil {
            return nil
        }
    }

    @objc var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: CLLocationDegrees(student.latitude!), longitude: CLLocationDegrees(student.longitude!))
    }
    
    var title: String? {
        return student.fullname
    }
    
    var subtitle: String? {
        return student.mediaUrl
    }
    
}
