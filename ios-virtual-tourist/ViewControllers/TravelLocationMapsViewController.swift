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
    let stack = CoreDataStack.coreDataStack()
    var locationManager: CLLocationManager?
    var editButton: UIBarButtonItem?
    var arrayOfPins: [Pin]?
    var annotations: [MKAnnotation]?
    var selectedPin: Pin?
    
    // MARK: - IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var longPress: UILongPressGestureRecognizer!
    @IBOutlet var bannerDeleteView: UIView!
    
    // MARK: - App Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Virtual Tourist"
        self.setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.initCoreDataFetchRequest()
        
        self.setupMapView()
        self.displaySavedPins()
        self.checkForLastCoordinates()
        UserDefaults.standard.set(false, forKey: kEditModeOn)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.mapView.removeAnnotations(annotations!)
        self.arrayOfPins?.removeAll()
        self.annotations?.removeAll()
        self.mapView.removeAnnotations(annotations!)
        UserDefaults.standard.set(false, forKey: kEditModeOn)
    }
    
    // MARK: - TravelLoacationMapViewControllers
    func initCoreDataFetchRequest() {
        
        //Create the fetch Request
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        let latitudeDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        let longitudeDescriptor = NSSortDescriptor(key: "longitude", ascending: false)
        fr.sortDescriptors = [latitudeDescriptor, longitudeDescriptor]
        
        // Init FetchResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func removeSelectedAnnotations() {
        for selected in self.mapView.selectedAnnotations {
            self.mapView.deselectAnnotation(selected, animated: false)
        }
    }
    
    func setupNavigationBar() {
        editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editMode))
        self.navigationItem.rightBarButtonItem = editButton
    }
    
    func setupMapView() {
        self.mapView.delegate = self
        self.mapView.showsPointsOfInterest = true
        self.mapView.showsCompass = true
    }
    
    func displaySavedPins() {
        arrayOfPins = []
        annotations = []
        let array = self.fetchedResultsController?.fetchedObjects as? [Pin]
        for pin in array! {
            arrayOfPins!.append(pin)
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            self.annotations?.append(annotation)
        }
        self.mapView.addAnnotations(annotations!)
    }
    
    func checkForLastCoordinates() {
        
        // record the zoom level
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
        // UI Changes
        if self.editButton?.title != "DONE" {
            UserDefaults.standard.set(true, forKey: kEditModeOn)
            self.editButton?.title = "DONE"

            self.bannerDeleteView.frame.origin.y = self.mapView.frame.maxY
            self.view.addSubview(bannerDeleteView)
        } else {
            self.editButton?.title = "EDIT"
            UserDefaults.standard.set(false, forKey: kEditModeOn)

            self.bannerDeleteView.removeFromSuperview()
        }
    }

    func buildPhotoObjectsWithFlickr(for pin: Pin?) {
        
        // Call Flickr API base on the pin location bounding box
        // @return 21 Photo Managed Objet with a relation to the specific pin
        if pin != nil {
            let bbox = FIClient().bboxString(latitude: (pin?.latitude)!, longitude: (pin?.longitude)!)
            FIClient().photoSearchFor(bbox: bbox, placeId: nil, completionHandler: { (response, success) in
                if !success {
                    print("Error downloading picture")
                } else {
                    let imageUrlArray = response as? [String]
                    DispatchQueue.main.async {
                        if imageUrlArray!.count > 20 {
                            for index in 0 ..< 21 {
                                let photoObject = Photo(imageData: nil, url: imageUrlArray![index], context: self.stack.context)
                                pin!.addToPhotos(photoObject)
                            }
                        }
                    }
                }
            })
        }
    }
    
    
    // MARK: - IBActions
    @IBAction func dropPinButton(_ sender: UILongPressGestureRecognizer) {
        
        switch sender.state {
        case .began:
            let touchpoint: CGPoint = sender.location(in: self.mapView)
            let coord = self.mapView.convert(touchpoint, toCoordinateFrom: mapView)
            
            let pointAnnotation = MKPointAnnotation()
            pointAnnotation.coordinate = coord
            
            //Create the pin, it will store it in CoreData
            let pinDropped = Pin(latitude: coord.latitude, longitude: coord.longitude, context: stack.context)
            do {
                try self.stack.saveContext()
            } catch {
                print("error saving in pin dropped")
            }
            
            self.buildPhotoObjectsWithFlickr(for: pinDropped)
            self.arrayOfPins?.append(pinDropped)
            
            self.mapView.addAnnotation(pointAnnotation)
            
            UserDefaults.standard.set(true, forKey: kFirstTimePinDropped)
        default: break
        }
        
        
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation , reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        UserDefaults.standard.set(self.mapView.region.center.latitude, forKey: kLatitudeRegion)
        UserDefaults.standard.set(self.mapView.region.center.longitude, forKey: kLongitudeRegion)
        UserDefaults.standard.set(self.mapView.region.span.latitudeDelta, forKey: kLastLatitudeDelta)
        UserDefaults.standard.set(self.mapView.region.span.longitudeDelta, forKey: kLastLongitudeDelta)
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        var pinSelected: Pin?
        
        //Evaluate the state of the navigation button on the right
        let isEditOn = UserDefaults.standard.bool(forKey: kEditModeOn)
        
        // Locate the selected Pin
        for pinView in arrayOfPins! {
            if pinView.latitude == view.annotation?.coordinate.latitude && pinView.longitude == view.annotation?.coordinate.longitude {
                pinSelected = pinView
            }
        }
        
        
        // Delete or ViewDetails for the selected Pin base on isEditOn
        if let pinEdit = pinSelected {
            if isEditOn {
                stack.context.delete(pinEdit)
                self.mapView.removeAnnotation(view.annotation!)
                
                do {
                 try self.stack.saveContext()
                } catch {
                    print("error saving")
                }
            } else {
                let albumVC = storyboard?.instantiateViewController(withIdentifier: "AlbumViewController") as! AlbumViewController
                albumVC.pin = pinEdit
                albumVC.mapRegion = self.mapView.region
                self.navigationController?.pushViewController(albumVC, animated: true)
            }
        }
    }
}



