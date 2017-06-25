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
let kFlickrImages   = "newImages"

class AlbumViewController: CoreDataViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {

    // MARK: - Properties
    var pin: Pin?
    var mapRegion: MKCoordinateRegion?
    let delegate = UIApplication.shared.delegate as! AppDelegate
    var blockOperation: [BlockOperation]? = [BlockOperation]()
    private var flickrImagesPresent: Bool?
    
    // MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    // MARK: - App Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initFetchRequestController()
        self.fetchedResultsController?.delegate = self
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.allowsMultipleSelection = true
        
        //NotificationCenter.default.addObserver(self, selector: #selector(performReload), name: Notification.Name(kFlickrImages) , object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.newCollectionButton.setTitle("New collection", for: .normal)
        
        // Testing bool and UserDefault
        self.loadPreviewMap()
        UserDefaults.standard.set(false, forKey: kEditingPhotos)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // FLAG next time pin is tapped -> load images from coreData
        UserDefaults.standard.set(false, forKey: kFirstTimePinDropped)
    }
    
    // MARK: - AlbumViewController
    func initFetchRequestController()  {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        
        fr.sortDescriptors = [NSSortDescriptor(key: "url", ascending: false), NSSortDescriptor(key: "imageData", ascending: false)]
        
        let pred = NSPredicate(format: "pin == %@", pin!)
        
        fr.predicate = pred
        
        // Create FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext:delegate.stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func performReload() {
        self.collectionView.reloadData()
    }
    
    func loadPreviewMap() {
        // Load small map with coordinates and region
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin!.latitude, longitude: pin!.longitude)
        self.mapView.setRegion(mapRegion!, animated: true)
        self.mapView.addAnnotation(annotation)
    }
  
    
    // MARK: - IBActions
    @IBAction func newCollectionButtonPressed(_ sender: UIButton) {
        if UserDefaults.standard.bool(forKey: kEditingPhotos) {
            
            // Perform DELETE in the photo object (Photo Class)
            // Remove selected items from the collection view
            let photosSelected =  self.collectionView.indexPathsForSelectedItems
            
            for index in photosSelected! {
                let x = fetchedResultsController?.object(at: index) as! Photo
                Photo.deletePhoto(photo: x, context: delegate.stack.context)
            }
            self.newCollectionButton.setTitle("New Collection", for: .normal)
        } else {
            
            // TODO: delete the 21 images
            // TODO: get new set of images
            
            //self.getFlickrImages(21, for: self.pin)
        }
    }
    
    // MARK: - UICollectionViewDelegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        // RETURN the count of the fetched objects from the ModelObject
        if let count = fetchedResultsController?.sections?[0].numberOfObjects {
            return count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: "FlickrImageCollectionViewCell", for: indexPath) as! FlickrImageCollectionViewCell
        
        cell.backgroundColor = UIColor.blue
        cell.activityIndicatorImageView.startAnimating()

        // IF bool has not been set by the Flickr Network call
        //    RETURN CELL, We have object from the entity
        if !UserDefaults.standard.bool(forKey: kFirstTimePinDropped) {
            let photo = fetchedResultsController?.object(at: indexPath) as! Photo
            cell.imageView?.image = UIImage(data: photo.imageData! as Data)
            cell.activityIndicatorImageView.stopAnimating()
            cell.activityIndicatorImageView.isHidden = true
            
        } else {
            // IF the FlickNetwork call succeded  build the cell image,
            // ELSE return the cell with loading effect
            
            if let object = fetchedResultsController?.object(at: indexPath) {
                let photoObject = object as! Photo
                if let photoURLString = photoObject.url {
                    FIClient().downloadImage(withURL: photoURLString, completionHandler: {
                        (data, success) in
                        if !success {
                            cell.activityIndicatorImageView.stopAnimating()
                            cell.activityIndicatorImageView.isHidden = true
                        } else {
                            DispatchQueue.main.async {
                                cell.imageView?.image = UIImage(data: data as! Data)
                                cell.backgroundColor = UIColor.white
                                cell.activityIndicatorImageView.stopAnimating()
                                cell.activityIndicatorImageView.isHidden = true
                            }
                        }
                        
                    })
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            self.newCollectionButton.setTitle("Remove Selected Pictures", for: .normal)
            let cell = self.collectionView.cellForItem(at: indexPath) as! FlickrImageCollectionViewCell
            //cell.selectedBackgroundView?.alpha = 0.5
            cell.imageView.alpha = 0.2
            UserDefaults.standard.set(true, forKey: kEditingPhotos)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = self.collectionView.cellForItem(at: indexPath) as! FlickrImageCollectionViewCell
        cell.selectedBackgroundView?.alpha = 1
        cell.imageView.alpha = 1
        
        // UI: if all photos deselected
        if self.collectionView.indexPathsForSelectedItems?.count == 0 {
            UserDefaults.standard.set(false, forKey: kEditingPhotos)
            self.newCollectionButton.setTitle("New collection", for: .normal)
        }
    }
    
    // MARK: - NSFetchedResultsControlleer
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.blockOperation?.removeAll()
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
            // The destination path for the object for insertions or moves (this value is nil for a deletion)
            self.blockOperation?.append(BlockOperation(block: {
                self.collectionView.deleteItems(at: [indexPath!])
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


