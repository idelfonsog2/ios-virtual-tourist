//
//  TravelLocationMapsViewController.swift
//  ios-virtual-tourist
//
//  Created by Idelfonso Gutierrez Jr. on 6/8/17.
//  Copyright © 2017 Idelfonso Gutierrez Jr. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class TravelLocationMapsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    // MARK: - Properties
    var locationManager = CLLocationManager()
    
    // MARK: - IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var longPress: UILongPressGestureRecognizer!
    
    // MARK: - App Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        startStandardUpdates()
    }
    
    // MARK: - TravelLoacationMapViewControllers
    func setupMapView() {
        self.mapView.delegate = self
        self.mapView.showsPointsOfInterest = true
        self.mapView.showsScale = true
        self.mapView.showsCompass = true
        self.mapView.showsUserLocation = false
    }
    
    func startStandardUpdates() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 500
        locationManager.startUpdatingLocation()
    }

    // MARK: - IBActions
    @IBAction func dropPinButton(_ sender: UILongPressGestureRecognizer) {
        
        if sender.state == .began {
            let geoCoder = CLGeocoder()
            let touchpoint = sender.location(in: self.mapView)
            let coord = self.mapView.convert(touchpoint, toCoordinateFrom: mapView)
            let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            
            
            let pointAnnotation = MKPointAnnotation()
            pointAnnotation.coordinate = coord
            
            geoCoder.reverseGeocodeLocation(location , completionHandler: { (placeMarkArray, error) in
                guard error == nil else {
                    //TODO: Display Alert message
                    return
                }
                
                let locationName = placeMarkArray?.first?.name
                pointAnnotation.title = locationName
                pointAnnotation.subtitle = "testing"
            })
            
            
            print(pointAnnotation.coordinate)
            self.mapView.addAnnotation(pointAnnotation)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            let button = UIButton(type: .detailDisclosure)
            button.tintColor = UIColor.blue
            pinView?.animatesDrop = true
            pinView!.rightCalloutAccessoryView = button
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print(userLocation.coordinate)
    }

}



