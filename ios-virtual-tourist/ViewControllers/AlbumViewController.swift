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


class AlbumViewController: CoreDataViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {

    // MARK: - Properties
    var pin: Pin?
    var mapRegion: MKCoordinateRegion?
    let delegate = UIApplication.shared.delegate as! AppDelegate
    var blockOperation: [BlockOperation]? = [BlockOperation]()
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.newCollectionButton.setTitle("New collection", for: .normal)
        
        self.loadPreviewMap()
        UserDefaults.standard.set(false, forKey: kEditingPhotos)
        UserDefaults.standard.set(false, forKey: kImagesSet)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // FLAG: next time pin is tapped -> load images from coreData
        UserDefaults.standard.set(false, forKey: kFirstTimePinDropped)
    }
    
    // MARK: - AlbumViewController
    func initFetchRequestController()  {
        
        //Instantiate FetchRequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.sortDescriptors = [NSSortDescriptor(key: "url", ascending: false), NSSortDescriptor(key: "imageData", ascending: false)]
        let pred = NSPredicate(format: "pin == %@", pin!)
        fr.predicate = pred
        

        // Create FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext:delegate.stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
    }
    
    func loadPreviewMap() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin!.latitude, longitude: pin!.longitude)
        self.mapView.setRegion(mapRegion!, animated: true)
        self.mapView.addAnnotation(annotation)
    }
    

    func deleteSinglePhotos() {
        
        let indexPaths =  self.collectionView.indexPathsForSelectedItems
        
        for index in indexPaths! {
            let photoToBeDeleted = fetchedResultsController?.object(at: index) as! Photo
            delegate.stack.context.delete(photoToBeDeleted)
            self.collectionView.deselectItem(at: index, animated: true)
        }
        
        UserDefaults.standard.set(false, forKey: kEditingPhotos)
        self.newCollectionButton.setTitle("New Collection", for: .normal)
    }
    
    func deleteEntireAlbum() {
        // retrieve the objects as Photo
        let photosAlbum = fetchedResultsController?.fetchedObjects as! [Photo]
        
        //Delete the objects from the SANDBOX
        for photo in photosAlbum {
            //Photo().deletePhoto(photo: photo, context: self.delegate.stack.context)
            self.pin?.removeFromPhotos(photo)
        }
        
        //Commit the objects deleted, if you try to modifying them it can cause an error due that objcets have been deleted
        do {
            try self.delegate.stack.saveContext()
        } catch {
            fatalError("Did not save context when assiging imageData property")
        }
        
        //Set bools
        UserDefaults.standard.set(true, forKey: kNewCollection)
        UserDefaults.standard.set(true, forKey: kFirstTimePinDropped)
        
        // Make request for new images
        let bbox = FIClient().bboxString(latitude: (self.pin?.latitude)!, longitude: (self.pin?.longitude)!)
 
        FIClient().photoSearchFor(bbox: bbox, placeId: nil, completionHandler: { (response, success) in
            if !success {
                print("Error downloading picture")
            } else {
                let imageUrlArray = response as? [String]
                DispatchQueue.main.async {
                    if imageUrlArray!.count > 20 {
                        for index in 0 ..< 21 {
                            let photoObject = Photo(imageData: nil, url: imageUrlArray![index], context: self.delegate.stack.context)
                            photoObject.pin = self.pin
                        }
                    }
                }
                
            }
        })
    }
    
    // MARK: - IBActions
    @IBAction func newCollectionButtonPressed(_ sender: UIButton) {
        /* This buttons changes functionality in order to remove photos
         true:  delete single photos
         false: delete entire album */
        
        if UserDefaults.standard.bool(forKey: kEditingPhotos) {
            self.deleteSinglePhotos()
        } else {
            self.deleteEntireAlbum()
        }
    }
    
    // MARK: - UICollectionViewDelegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return (fetchedResultsController?.sections?.count)!
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = fetchedResultsController?.sections?[0].numberOfObjects {
            return count
        }
        return 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: kReuseFlicrCollectionViewCellIdentifier, for: indexPath) as! FlickrImageCollectionViewCell
        
        cell.activityIndicatorImageView.startAnimating()
        cell.imageView.image = UIImage(named: "placeholderimage")
        

        // Retrieve Flickr or ModelObject Data
        if !UserDefaults.standard.bool(forKey: kFirstTimePinDropped) {
            let photo = fetchedResultsController?.object(at: indexPath) as! Photo
            cell.imageView?.image = UIImage(data: photo.imageData! as Data)
            cell.activityIndicatorImageView.stopAnimating()
            cell.activityIndicatorImageView.isHidden = true
        } else {
            guard let photoObject = fetchedResultsController?.object(at: indexPath) as? Photo else {
                fatalError("Attempt to configure cell without a managed object")
            }
            
            FIClient().downloadImage(withURL: (photoObject.url!), completionHandler: {
                (data, success) in
                if !success {
                    print("Not able to download image from URL in cellForItem")
                } else {
                    
                    DispatchQueue.main.async {
                        photoObject.imageData = data as? NSData
                        cell.imageView?.image = UIImage(data: data as! Data)
                        cell.backgroundColor = UIColor.white
                        cell.activityIndicatorImageView.stopAnimating()
                        cell.activityIndicatorImageView.isHidden = true
                    }
                }
            })
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = self.collectionView.cellForItem(at: indexPath) as! FlickrImageCollectionViewCell
        cell.imageView.alpha = 0.2
        
        self.newCollectionButton.setTitle("Remove Selected Pictures", for: .normal)
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
            //The index path of the changed object (this value is nil for insertions)
            self.blockOperation?.append(BlockOperation(block: {
                    self.collectionView.insertItems(at: [newIndexPath!])
            }))
            break
        case .delete:
            // The destination path for the object for insertions or moves (this value is nil for a deletion)
            // Photos are downloaded in the backgroundContext
            self.blockOperation?.append(BlockOperation(block: {
                self.collectionView.deleteItems(at: [indexPath!])
            }))
            break
            
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.collectionView.performBatchUpdates({
            if let blockOperation = self.blockOperation {
                for operation in blockOperation {
                    operation.start()
                }
            }
        }) { (completed) in
        }
    }
    
}


