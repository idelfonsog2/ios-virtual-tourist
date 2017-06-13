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
import CoreData

class TravelLocationMapsViewController: CoreDataViewController, MKMapViewDelegate, UINavigationControllerDelegate {

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
        
        // Create teh stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        //Create the fetch Request 
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        let latitudeDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fr.sortDescriptors = [latitudeDescriptor]

        //Create the fetch results controller 
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        
        //Add edit button to the navigaton bar
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
    
    private func bboxString(latitude: Double, longitude: Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        if  latitude != 0 &&  longitude != 0 {
            let minimumLon = max(longitude - Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.0)
            let minimumLat = max(latitude - Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.0)
            let maximumLon = min(longitude + Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.1)
            let maximumLat = min(latitude + Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        } else {
            return "0,0,0,0"
        }
    }

    // MARK: - IBActions
    @IBAction func dropPinButton(_ sender: UILongPressGestureRecognizer) {
        
        if sender.state == .began {
            let touchpoint: CGPoint = sender.location(in: self.mapView)
            let coord = self.mapView.convert(touchpoint, toCoordinateFrom: mapView)
            
            let pointAnnotation = MKPointAnnotation()
            pointAnnotation.coordinate = coord
            UserDefaults.standard.set(coord.latitude, forKey: kLastLatitude)
            UserDefaults.standard.set(coord.longitude, forKey: kLastLongitude)
            print(coord.latitude)
            print(coord.longitude)

            //TODO: Make travelLocation inherits from a fetched
            let pin = Pin(latitude: coord.latitude, longitude: coord.longitude, context: fetchedResultsController!.managedObjectContext)
            
            let bbox = bboxString(latitude: coord.latitude, longitude: coord.longitude)
            FIClient().photoSearchFor(bbox: bbox, completionHandler: { (response, success) in
                if !success {
                    //TODO: Display Error
                } else {
                    // TODO: Create Pin object with
                }
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



