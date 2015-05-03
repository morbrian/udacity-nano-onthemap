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
            mapView.addAnnotations(studentLocations)
            mapView.showAnnotations(studentLocations, animated: true)
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
        
        if let studentLocation = annotation as? StudentLocation {
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
        if let studentLocation = view.annotation as? StudentLocation,
            urlString = studentLocation.mediaUrl,
            url = NSURL(string: urlString) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
}

// MARK: - Extension StudentLocation 

extension StudentLocation: MKAnnotation {
    
    @objc var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
    }
    
    var title: String! {
        return fullname
    }
    
    var subtitle: String! {
        return mediaUrl
    }
    
}
