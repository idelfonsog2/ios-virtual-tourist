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

let kEditingPhotos  = "editingPhotos"
let kNewImages      = "newImages"

class AlbumViewController: CoreDataViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {

    // MARK: - Properties
    var pin: Pin?
    var photosToBeDeleted: [Photo]?
    var imageUrlArray: [String]?
    var mapRegion: MKCoordinateRegion?
    let delegate = UIApplication.shared.delegate as! AppDelegate
    var blockOperation: [BlockOperation]?
    private var flickrImagesPresent: Bool?
    
    // MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    // MARK: - App Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchedResultsController?.delegate = self
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.allowsMultipleSelection = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.newCollectionButton.setTitle("New collection", for: .normal)
        self.flickrImagesPresent = false
        self.loadData()
        self.loadPreviewMap()
        
        self.photosToBeDeleted = []
        
        UserDefaults.standard.set(false, forKey: kEditingPhotos)
    }
    
    // MARK: - AlbumViewController
    func loadData()  {
        do {
            // Check if Photo objects exits
            try fetchedResultsController?.performFetch()
            let fetchedObject = try delegate.stack.context.fetch((fetchedResultsController?.fetchRequest)!) as? [Photo]
            
            print(fetchedObject?.count)
            
            if fetchedObject?.count == 21 {
                flickrImagesPresent = false
            } else {
                self.getFlickrImages(21, for: self.pin)
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
  

    func getFlickrImages(_ number: Int, for pin: Pin?) {
        // Gets an array of
        if pin != nil {
            let bbox = bboxString(latitude: (pin?.latitude)!, longitude: (pin?.longitude)!)
        
            FIClient().photoSearchFor(bbox: bbox, thisMany: number, completionHandler: { (response, success) in
                if !success {
                    print(response)
                    print("Error downloading picture")
                } else {
                    // When download has finish save urls and reload collection view
                    self.imageUrlArray = response as? [String]
                    
                    for imageURL in self.imageUrlArray! {
                        do {
                            let url = URL(string: imageURL)
                            let data = try Data(contentsOf: url!)
                            // Create Photo object in CoreData
                            let photoObject = Photo(imageData: data as NSData, url: imageURL, context: self.delegate.stack.context)
                            
                            photoObject.pin = self.pin
                        } catch {
                            fatalError("Unable to transfor url to Data object")
                        }
                       
                    }
                    self.loadData()
                    self.flickrImagesPresent = true
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
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
    
    func removeSelectedPhotos() {
        // Remove items from the collection view
        let photosSelected =  self.collectionView.indexPathsForSelectedItems
        
        for index in photosSelected! {
            let x = fetchedResultsController?.object(at: index) as! Photo
            Photo.deletePhoto(photo: x, context: delegate.stack.context)
        }
        
        // Remove items from CoreData fetchedObjects
//        for photo in photosToBeDeleted! {
//
//            Photo.deletePhoto(photo: photo, context: delegate.stack.context)
//        }
        
        // Clear the photosToBeDeletedArray for next deletion iteration
        self.photosToBeDeleted = []
        
        // RELOAD the number of items and DELETE the item
        //self.collectionView.deleteItems(at: photosSelected!)
        
        // The next rendering of the collectionView
        // will be done using the CoraData fetched array
        UserDefaults.standard.set(false, forKey: kEditingPhotos)
    }
    
    // MARK: - IBActions
    @IBAction func newCollectionButtonPressed(_ sender: UIButton) {
        if UserDefaults.standard.bool(forKey: kEditingPhotos) {
            // 1. Remove photos from Coredata
            removeSelectedPhotos()
            // 2. Change the UI
            self.newCollectionButton.setTitle("New Collection", for: .normal)
        } else {
            self.getFlickrImages(21, for: self.pin)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        if let count = fetchedResultsController?.sections?[0].numberOfObjects {
            return count
        }
        return 0
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: "FlickrImageCollectionViewCell", for: indexPath) as! FlickrImageCollectionViewCell
        
        cell.backgroundColor = UIColor.blue
        cell.activityIndicatorImageView.startAnimating()

        // Download images using the url
        
        if self.flickrImagesPresent! {
            
            let photoURLString = imageUrlArray?[indexPath.row]
            
            FIClient().downloadImage(withURL: photoURLString!, completionHandler: {
                (data, success) in
                if !success {
                    cell.activityIndicatorImageView.stopAnimating()
                    cell.activityIndicatorImageView.isHidden = true
                } else {
                    DispatchQueue.main.async {
                        cell.imageView?.image = UIImage(data: data as! Data)
                        cell.activityIndicatorImageView.stopAnimating()
                        cell.activityIndicatorImageView.isHidden = true
                    }
                }
                
            })
        } else {
            let photo = fetchedResultsController?.object(at: indexPath) as! Photo
            cell.imageView?.image = UIImage(data: photo.imageData! as Data)
            cell.activityIndicatorImageView.stopAnimating()
            cell.activityIndicatorImageView.isHidden = true
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            self.newCollectionButton.setTitle("Remove Selected Pictures", for: .normal)
            let cell = self.collectionView.cellForItem(at: indexPath) as! FlickrImageCollectionViewCell
            cell.selectedBackgroundView?.alpha = 0.5
            cell.imageView.alpha = 0.2
//            let photo = fetchedResultsController?.object(at: indexPath)
//            self.photosToBeDeleted?.append(photo as! Photo)
            UserDefaults.standard.set(true, forKey: kEditingPhotos)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = self.collectionView.cellForItem(at: indexPath) as! FlickrImageCollectionViewCell
        cell.selectedBackgroundView?.alpha = 1
        cell.imageView.alpha = 1
//        self.photosToBeDeleted?.remove(at: indexPath.row - 1)
        
        // UI: if all photos deselected
        if self.photosToBeDeleted?.count == 0 {
            UserDefaults.standard.set(false, forKey: kEditingPhotos)
            self.newCollectionButton.setTitle("New collection", for: .normal)
        }
    }
    
    // MARK: - NSFetchedResultsControlleer
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.blockOperation = [BlockOperation]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            // The index path of the changed object (this value is nil for insertions)
            self.blockOperation?.append(BlockOperation(block: { 
                self.collectionView.insertItems(at: [newIndexPath!])
            }))
            break
        case .delete:
            // The destination path for the object for insertions or moves (this value is nil for a deletion).
            self.blockOperation?.append(BlockOperation(block: {
                if let itemsSelected = self.collectionView.indexPathsForSelectedItems {
                    self.collectionView.deleteItems(at: itemsSelected)
                }
            }))
            break
        default:
            print("Nothing")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.collectionView.performBatchUpdates({
            
            for operation in self.blockOperation! {
                operation.start()
            }
        }) { (completed) in
            print("done executing blockOperation whorray")
        }
    }
}


