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

class TravelLocationMapsViewController: UIViewController, MKMapViewDelegate, UINavigationControllerDelegate {

    // MARK: - Properties
    var locationManager: CLLocationManager?
    var editButton: UIBarButtonItem?
    
    // MARK: - IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var longPress: UILongPressGestureRecognizer!
    
    // MARK: - App Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Virtual Tourist"
        
        editButton = UIBarButtonItem(title: "EDIT", style: .done, target: self, action: #selector(editMode))
        self.navigationItem.rightBarButtonItem = editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupMapView()
        checkForLastCoordinates()
    }
    
    // MARK: - TravelLoacationMapViewControllers
    func setupMapView() {
        self.mapView.delegate = self
        self.mapView.showsPointsOfInterest = true
        self.mapView.showsCompass = true
    }
    
    func checkForLastCoordinates() {
        let latitude = UserDefaults.standard.double(forKey: kLastLatitude)
        let longitude = UserDefaults.standard.double(forKey: kLastLongitude)
        
        if latitude != 0, longitude != 0 {
            let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            var spanCoordinate = MKCoordinateSpan()
            var region = MKCoordinateRegion()
            spanCoordinate.latitudeDelta = 0.5
            spanCoordinate.longitudeDelta = 0.005
            region.center = coord
            region.span = spanCoordinate
            self.mapView.setRegion(region, animated: true)
        }
    }
    
    func editMode() {
        
        if self.editButton?.title != "DONE" {
            UserDefaults.standard.set(true, forKey: kEditModeOn)
            self.editButton?.title = "Done"
            //TODO: Show botton banner indicating that its in edit mode
        } else {
            self.editButton?.title = "EDIT"
            UserDefaults.standard.set(false, forKey: kEditModeOn)
            //TODO: Hide button banner
        }
        
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
            
            UserDefaults.standard.set(coord.latitude, forKey: kLastLatitude)
            UserDefaults.standard.set(coord.longitude, forKey: kLastLongitude)
            print(coord.latitude)
            print(coord.longitude)
            
            geoCoder.reverseGeocodeLocation(location , completionHandler: { (placeMarkArray, error) in
                guard error == nil else {
                    //TODO: Display Alert message
                    return
                }
                
                let locationName = placeMarkArray?.first?.name
                pointAnnotation.title = locationName
                pointAnnotation.subtitle = "testing"

            })
            
            self.mapView.addAnnotation(pointAnnotation)
            print("PointAnnotation Coord: \(pointAnnotation.coordinate)")
        }
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print(self.mapView.region.span)
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        //Evaluate the state of the navigation button on the right
        let isEditOn = UserDefaults.standard.bool(forKey: kEditModeOn)
        
        if isEditOn {
            //TODO: Remove pin annotation
            self.mapView.removeAnnotation(view.annotation!)
        } else {
            //TODO: GO to Album view controllers
        }
        
    }
}



