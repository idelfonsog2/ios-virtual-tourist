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
    let delegate = UIApplication.shared.delegate as! AppDelegate
    var locationManager: CLLocationManager?
    var editButton: UIBarButtonItem?
    var arrayOfPins: [Pin]?
    var annotations: [MKAnnotation]?
    var photoObjectsArray: [Photo]?
    
    // MARK: - IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var longPress: UILongPressGestureRecognizer!
    @IBOutlet var bannerDeleteView: UIView!
    
    // MARK: - App Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Virtual Tourist"
        self.initCoreDataFetchRequest()
        self.setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupMapView()
        self.displaySavedPins()
        self.checkForLastCoordinates()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.mapView.removeAnnotations(annotations!)
        self.arrayOfPins?.removeAll(keepingCapacity: true)
    }
    // MARK: - TravelLoacationMapViewControllers
    
    func initCoreDataFetchRequest() {
        let stack = delegate.stack
        
        //Create the fetch Request
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        let latitudeDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        let longitudeDescriptor = NSSortDescriptor(key: "longitude", ascending: false)
        fr.sortDescriptors = [latitudeDescriptor, longitudeDescriptor]
        
        // Init FetchResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
    }
    
    func setupNavigationBar() {
        //Add edit button to the navigaton bar
        editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editMode))
        self.navigationItem.rightBarButtonItem = editButton
    }
    
    func setupMapView() {
        self.mapView.delegate = self
        self.mapView.showsPointsOfInterest = true
        self.mapView.showsCompass = true
    }
    
    func displaySavedPins() {
        do {
            arrayOfPins = []
            annotations = []
            let array = try! delegate.stack.context.fetch((fetchedResultsController?.fetchRequest)!) as? [Pin]
            for pin in array! {
                arrayOfPins!.append(pin)
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                self.annotations?.append(annotation)
            }
            self.mapView.addAnnotations(annotations!)
        } catch {
            fatalError("Failed to retrive pins")
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
            self.editButton?.title = "DONE"
            //TODO: Show botton banner indicating that its in edit mode
            //self.mapView.frame.origin.y = 60 * -1
            self.bannerDeleteView.frame.origin.y = self.mapView.frame.maxY // size of the banner view
            self.view.addSubview(bannerDeleteView)
        } else {
            self.editButton?.title = "EDIT"
            UserDefaults.standard.set(false, forKey: kEditModeOn)
            //TODO: Hide button banner
            //self.mapView.frame.origin.y = 0
            self.bannerDeleteView.removeFromSuperview()
        }
    }

    func buildPhotoObjectsWithFlickr(_ number: Int, for pin: Pin?, newImagesrRequested: Bool) {
        if pin != nil {
            let bbox = bboxString(latitude: (pin?.latitude)!, longitude: (pin?.longitude)!)
            self.photoObjectsArray = []
            // Create 21 Photo objects with default values
            // Append them to an arr for later to use it to append the urls
            
            FIClient().photoSearchFor(lat: (pin?.latitude)!, lon: (pin?.longitude)!, completionHandler: { (response, success) in
                if !success {
                    
                } else {
                    let placeId = response as! String
                    FIClient().photoSearchFor(bbox: bbox, placeId: nil, thisMany: number, completionHandler: { (response, success) in
                        if !success {
                            print("Error downloading picture")
                        } else {
                            let imageUrlArray = response as? [String]

                            // Create only 21 photos
                            if imageUrlArray!.count > 20 {
                                for index in 0 ..< 21 {
                                    let photoObject = Photo(imageData: nil, url: imageUrlArray![index], context: self.delegate.stack.context)
                                    photoObject.pin = pin
                                    self.photoObjectsArray?.append(photoObject)
                                }
                                NotificationCenter.default.post(Notification(name: Notification.Name(kDownloadImages)))
                            }
                            
                        }
                    })
                }
            })
            
            
        }
    }

    func bboxString(latitude: Double, longitude: Double) -> String {
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

            //Create the pin, it will store it in CoreData
            let pinDropped = Pin(latitude: coord.latitude, longitude: coord.longitude, context: fetchedResultsController!.managedObjectContext)
            self.buildPhotoObjectsWithFlickr(21, for: pinDropped, newImagesrRequested: false)
            UserDefaults.standard.set(true, forKey: kFirstTimePinDropped)
            
            self.arrayOfPins?.append(pinDropped)
            self.mapView.addAnnotation(pointAnnotation)
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
        //Evaluate the state of the navigation button on the right
        let isEditOn = UserDefaults.standard.bool(forKey: kEditModeOn)
        
        let stack = delegate.stack
        var pinSelected: Pin?
        
        //Look for the matching selected pin in the tempArray
        for pinView in arrayOfPins! {
            if pinView.latitude == view.annotation?.coordinate.latitude && pinView.longitude == view.annotation?.coordinate.longitude {
                pinSelected = pinView
            }
        }
        
        // Pass it or delete it
        if let pinEdit = pinSelected {
            if isEditOn {
                // Delete Pin
                Pin.deleteObject(pin: pinEdit, context: stack.context)
                self.mapView.removeAnnotation(view.annotation!)
            } else {
                // View AlbumVC for the pin selected
                let albumVC = storyboard?.instantiateViewController(withIdentifier: "AlbumViewController") as! AlbumViewController
                albumVC.pin = pinEdit
                albumVC.mapRegion = self.mapView.region
                self.navigationController?.pushViewController(albumVC, animated: true)
            }
        }
    }
}



