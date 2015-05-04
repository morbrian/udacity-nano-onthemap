//
//  StudentMapViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/28/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit
import MapKit

class StudentMapViewController: OnTheMapBaseViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.mapType = .Satellite
            mapView.delegate = self
        }
    }
    
    // MARK: ViewController Lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplayFromModel()
    }
    
    // MARK: Overrides From OnTheMapBaseViewController
    
    override func updateDisplayFromModel() {
        mapView.removeAnnotations(mapView.annotations)
        if let studentLocations = dataManager?.studentLocations {
            let optionalAnnotations = studentLocations.map() { StudentAnnotation(student: $0) }
            let filteredAnnotations = optionalAnnotations.filter() { $0 != nil }
            let studentAnnotations = filteredAnnotations.map() { $0! as StudentAnnotation }
            mapView.addAnnotations(studentAnnotations)
            mapView.showAnnotations(studentAnnotations, animated: true)
        }
    }

    // MARK: MKMapViewDelegate
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var view = mapView.dequeueReusableAnnotationViewWithIdentifier(Constants.StudentLocationAnnotationReuseIdentifier)
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.StudentLocationAnnotationReuseIdentifier)
            view.canShowCallout = true
        } else {
            view.annotation = annotation
        }
        
        if let studentLocation = annotation as? StudentInformation {
            if let urlString = studentLocation.mediaUrl,
                url = NSURL(string: urlString) {
                    var detailButton = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
                    var detailDisclosure = UIImageView(image: detailButton.imageForState(UIControlState.Highlighted))
                    view.rightCalloutAccessoryView = detailButton
                    
            }
        }
        return view
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        if let studentLocation = view.annotation as? StudentInformation,
            urlString = studentLocation.mediaUrl,
            url = NSURL(string: urlString) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
}

// MARK: - Extension StudentLocation 

class StudentAnnotation: NSObject, MKAnnotation {
    
    let student: StudentInformation
    
    init?(student: StudentInformation) {
        self.student = student
        super.init()
        if !(StudentAnnotation.validLatitude(student.latitude) && StudentAnnotation.validLongitude(student.longitude)) {
            return nil
        }
    }
    
    private static func validLatitude(latitude: Float?) -> Bool {
        if let latitude = latitude {
            return latitude <= 90.0 && latitude >= -90.0
        } else {
            return false
        }
    }
    
    private static func validLongitude(longitude: Float?) -> Bool {
        if let longitude = longitude {
            return longitude <= 180.0 && longitude >= -180.0
        } else {
            return false
        }
    }
    
    @objc var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: CLLocationDegrees(student.latitude!), longitude: CLLocationDegrees(student.longitude!))
    }
    
    var title: String! {
        return student.fullname
    }
    
    var subtitle: String! {
        return student.mediaUrl
    }
    
}
