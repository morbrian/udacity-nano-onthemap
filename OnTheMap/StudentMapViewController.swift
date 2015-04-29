//
//  StudentMapViewController.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/28/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import UIKit
import MapKit

class StudentMapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.mapType = .Satellite
            mapView.delegate = self
        }
    }
    
    var dataManager: StudentDataAccessManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let tabBarController = self.tabBarController as? ManagingTabBarController {
            self.dataManager = tabBarController.dataManager
            println("on load locs are \(self.dataManager?.studentLocationCount)")
            //fetchNextPage()
        }

        if let studentLocations = dataManager?.studentLocations {
            mapView.addAnnotations(studentLocations)
            mapView.showAnnotations(studentLocations, animated: true)
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
        return ""
    }
    
}
