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
    
    override func updateDisplayFromModel() {
        mapView.removeAnnotations(mapView.annotations)
        if let studentLocations = dataManager?.studentLocations {
            mapView.addAnnotations(studentLocations)
            mapView.showAnnotations(studentLocations, animated: true)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplayFromModel()
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
        return ""
    }
    
}
