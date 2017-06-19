//
//  AlbumViewController.swift
//  ios-virtual-tourist
//
//  Created by Idelfonso Gutierrez Jr. on 6/9/17.
//  Copyright © 2017 Idelfonso Gutierrez Jr. All rights reserved.
//

import UIKit
import CoreData
import MapKit

let kEditingPhotos = "editingPhotos"

class AlbumViewController: CoreDataViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    // MARK: - Properties
    var pin: Pin?
    var arrayOfImages: [Photo]?
    var photosToBeDeleted: [Photo]?
    
    var mapRegion: MKCoordinateRegion?
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    // MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    // MARK: - App Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.allowsMultipleSelection = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.initFetchRequestForPhoto()
        self.loadPreviewMap()
        self.photosToBeDeleted = []
        UserDefaults.standard.set(false, forKey: kEditingPhotos)
        self.newCollectionButton.setTitle("New collection", for: .normal)
    }
    
    // MARK: - AlbumViewController
    func initFetchRequestForPhoto()  {
        do {
            // Initialize an array of objects for the Photo Entity if any
            try fetchedResultsController?.performFetch()
            arrayOfImages = try delegate.stack.context.fetch((fetchedResultsController?.fetchRequest)!) as? [Photo]
            
            // IF none, download 21 images from flickr
            if arrayOfImages?.count == 0 {
                self.getFlickrImages(21, for: self.pin)
            } else {
                print("images found for selected pin")
            }
        } catch {
            fatalError("Unable to performFetch()")
        }
    }
    
    func checkStatusOfButton() {
        
    }
    
    func loadPreviewMap() {
        // Display the pin coordinates in the top map
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin!.latitude, longitude: pin!.longitude)
        self.mapView.setRegion(mapRegion!, animated: true)
        self.mapView.addAnnotation(annotation)
    }
  
    func removeSelectedPhotos() {
        let photosSelected =  self.collectionView.indexPathsForSelectedItems
        
        for i in photosSelected! {
            self.arrayOfImages?.remove(at: i.row)
        }
        
        // Delete selected photos
        for photo in photosToBeDeleted! {
            Photo.deletePhoto(photo: photo, context: delegate.stack.context)
        }
        
       
        UserDefaults.standard.set(false, forKey: kEditingPhotos)
    }

    func getFlickrImages(_ number: Int, for pin: Pin?) {
        // Gets an array of
        if pin != nil {
            let bbox = bboxString(latitude: (pin?.latitude)!, longitude: (pin?.longitude)!)
        
            FIClient().photoSearchFor(bbox: bbox, thisMany: number, completionHandler: { (response, success) in
                if !success {
                    print("Error downloading picture")
                } else {
                    // When download has finish save urls and reload collection view
                    let imageUrlArray = response as? [String]
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                    for photoURLString in imageUrlArray! {
                        do {
                            let data = try Data(contentsOf: URL(string: photoURLString)!)
                            let photoObject = Photo(imageData: data as NSData, url: photoURLString, context: self.delegate.stack.context)
                            photoObject.pin = self.pin
                            self.arrayOfImages?.append(photoObject)
                            
                            DispatchQueue.main.async {
                                self.collectionView.reloadData()
                            }
                        } catch {
                            fatalError("asas")
                        }
                    }
                }
            })
        }
    }
    
    
    func bboxString(latitude: Double, longitude: Double) -> String {
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
    @IBAction func newCollectionButtonPressed(_ sender: UIButton) {
        if UserDefaults.standard.bool(forKey: kEditingPhotos) {
            // 1. Remove photos from Coredata
            removeSelectedPhotos()
            // 2. Change the UI
            self.newCollectionButton.setTitle("New Collection", for: .normal)
            self.collectionView.reloadData()
        } else {
            self.getFlickrImages(21, for: self.pin)
        }
    }
    

    // MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        //FIXME: Leave it alone
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Udacity App contains 21 photos
        return arrayOfImages?.count ?? 0
    }
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: "FlickrImageCollectionViewCell", for: indexPath) as! FlickrImageCollectionViewCell
        
        cell.backgroundColor = UIColor.blue
        cell.activityIndicatorImageView.startAnimating()
    
        
        // Use the CoreData to retrieve the images
        if arrayOfImages?.count != 0 {
            if let photoObject = arrayOfImages?[indexPath.row] {
                cell.imageView?.image = UIImage(data: photoObject.imageData! as! Data)
                cell.activityIndicatorImageView.stopAnimating()
                cell.activityIndicatorImageView.isHidden = true
            } else {
                // The photo was deleted, but the space allocated still exist
                // test: remove the allocated space
                self.arrayOfImages?.remove(at: indexPath.row)
            }
            
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            self.newCollectionButton.setTitle("Remove Selected Pictures", for: .normal)
            let cell = self.collectionView.cellForItem(at: indexPath) as! FlickrImageCollectionViewCell
            cell.selectedBackgroundView?.alpha = 0.5
            cell.imageView.alpha = 0.2
            let selectedPhoto = self.arrayOfImages?[indexPath.row]
            self.photosToBeDeleted?.append(selectedPhoto!)
            UserDefaults.standard.set(true, forKey: kEditingPhotos)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = self.collectionView.cellForItem(at: indexPath) as! FlickrImageCollectionViewCell
        cell.selectedBackgroundView?.alpha = 1
        cell.imageView.alpha = 1
        self.photosToBeDeleted?.remove(at: indexPath.row)
        
        // UI: if all photos deselected
        if self.photosToBeDeleted?.count == 0 {
            self.newCollectionButton.setTitle("New collection", for: .normal)
        }
    }
}
