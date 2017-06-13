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
    var arrayOfPins: [Pin]?
    
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
        fr.sortDescriptors = [] // No need for descriptors, but require by NsFRC

        //Create the fetch results controller 
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        
        //Add edit button to the navigaton bar
        editButton = UIBarButtonItem(title: "EDIT", style: .done, target: self, action: #selector(editMode))
        self.navigationItem.rightBarButtonItem = editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupMapView()
        displaySavedPins()
        checkForLastCoordinates()
    }
    
    // MARK: - TravelLoacationMapViewControllers
    func setupMapView() {
        self.mapView.delegate = self
        self.mapView.showsPointsOfInterest = true
        self.mapView.showsCompass = true
    }
    
    func displaySavedPins() {
        do {
            try fetchedResultsController?.performFetch()
            let count = fetchedResultsController!.fetchedObjects!.count
            for pin in 0 ..< count {
                let item = fetchedResultsController?.fetchedObjects?[pin] as! Pin
                arrayOfPins?.append(item)
                print(arrayOfPins?[pin])
            }
        } catch {
            print("Failer to retrive pins")
        }
    }
    
    func checkForLastCoordinates() {
        let latitudeDelta   = UserDefaults.standard.double(forKey: kLastLatitudeDelta)
        let longitudeDelta  = UserDefaults.standard.double(forKey: kLastLongitudeDelta)
        let centerLatitude  = UserDefaults.standard.double(forKey: kLatitudeRegion)
        let centerLongitude = UserDefaults.standard.double(forKey: kLongitudeRegion)


        if latitudeDelta != 0, longitudeDelta != 0 {
            let centerCoordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
            let spanCoordinate = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            let region = MKCoordinateRegion(center: centerCoordinate, span: spanCoordinate)
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
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            //TODO: find the pin in a set of objects
            for item in (fetchedResultsController?.fetchedObjects)! {
                if item.isEqual(annotation) {
                    print("found in core data")
                    pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                    pinView!.pinTintColor = .red
                }
            }
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //TODO: When the user opens the app, open the region where he previously was
        UserDefaults.standard.set(self.mapView.region.center.latitude, forKey: kLatitudeRegion)
        UserDefaults.standard.set(self.mapView.region.center.longitude, forKey: kLongitudeRegion)
        UserDefaults.standard.set(self.mapView.region.span.latitudeDelta, forKey: kLastLatitudeDelta)
        UserDefaults.standard.set(self.mapView.region.span.longitudeDelta, forKey: kLastLongitudeDelta)
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        //Evaluate the state of the navigation button on the right
        let isEditOn = UserDefaults.standard.bool(forKey: kEditModeOn)
        
        if isEditOn {
            //TODO: Remove pin annotation from CoreData no from Map!
            self.mapView.removeAnnotation(view.annotation!)
        } else {
            //TODO: GO to Album view controllers
            let albumVC = storyboard?.instantiateViewController(withIdentifier: "AlbumViewController") as! AlbumViewController
            let coord = view.annotation?.coordinate
  
            // Create Fetch Request
            let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
            let latitudeDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
            let longitudeDescriptor = NSSortDescriptor(key: "longitude", ascending: false)
            fr.sortDescriptors = [latitudeDescriptor, longitudeDescriptor]
            
            
            
            
            // NSPredicate to the rescue!
            let location = view.annotation
            
            for pinView in (fetchedResultsController?.fetchedObjects)! {
                if pinView.isEqual(location) {
                    print("found in core data")
                }
            }
            
            print("not found")
            
            let pin = fetchedResultsController?.fetchedObjects
            
            //let pred = NSPredicate(format: "notebook == %@", argumentArray: [notebook!])
            
            //fr.predicate = pred

            // you want to find the pin store in the sql coredata, for that you create an nsfetchresults
            //albumVC.pin =
            self.navigationController?.pushViewController(albumVC, animated: true)
        }
        
    }
}



