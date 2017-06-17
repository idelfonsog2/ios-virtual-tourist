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

class AlbumViewController: CoreDataViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    // MARK: - Properties
    var pin: Pin?
    var arrayOfImages: [Photo]?
    var arrayOfData: [Data]?
    var mapRegion: MKCoordinateRegion?
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    // MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - App Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.initFetchRequestForPhoto()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadImages()
        self.loadPreviewMap()
    }
    
    // MARK: - AlbumViewController
    
    func loadPreviewMap() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin!.latitude, longitude: pin!.longitude)
        self.mapView.setRegion(mapRegion!, animated: true)
        self.mapView.addAnnotation(annotation)
    }
    
    func loadImages() {
        arrayOfData = []
        do {
            // Look for images in Database
            let arrayOfPhotosModel = try delegate.stack.context.fetch((fetchedResultsController?.fetchRequest)!) as? [Photo]
            
            if arrayOfPhotosModel?.count != 0 {
                for imageData in arrayOfPhotosModel! {
                    arrayOfData?.append(imageData.imageData as! Data)
                }
            } else {
                // download images from Flickr
                self.getFlickrImagesForPin(self.pin)
            }
        } catch {
            fatalError("Unable to retrieve images")
        }
    }

    
    func initFetchRequestForPhoto()  {
        // Create the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        //Create the fetch request
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let urlDescriptor = NSSortDescriptor(key: "url", ascending: false)
        fr.sortDescriptors = [urlDescriptor]
        
        //Create the fetch results controller
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            fatalError("Unable to performFetch()")
        }
    }

    //FIXME: try to show images as per those already downloaded
    func getFlickrImagesForPin(_ pinToBeCheck: Pin?) {
        if pinToBeCheck != nil {
            let bbox = bboxString(latitude: (pinToBeCheck?.latitude)!, longitude: (pinToBeCheck?.longitude)!)
            
            FIClient().photoSearchFor(bbox: bbox, completionHandler: { (response, success) in
                if !success {
                    print("Error downloading picture")
                } else {
                    let imageUrlArray = response as! [String]
                    for imageURL in  imageUrlArray {
                        do {
                            // Build Photo Model Object, no need to assign it
                            let data = try Data(contentsOf: URL(string: imageURL)!)
                            let photoObject = Photo(imageData: data as NSData, context: self.delegate.stack.context)
                            photoObject.pin = self.pin
                            self.arrayOfData?.append(data)
                        } catch {
                            fatalError("Error appending data element to array")
                        }
                    }
                    
                    //After the imges have been downloaded
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
    
    // MARK: - IBActions
    @IBAction func newCollectionButtonPressed(_ sender: UIButton) {
    }

    // MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        //Carefull with this statement the first condition will be evaluates
        if arrayOfImages != nil{
            return arrayOfImages!.count
        } else {
            return 10
        }
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: "FlickrImageCollectionViewCell", for: indexPath) as! FlickrImageCollectionViewCell
        
        cell.backgroundColor = UIColor.blue
        cell.activityIndicatorImageView.startAnimating()
        
        // DataReloaded to display images when they have finally downloaded
        if arrayOfData != nil && arrayOfData?.count != 0 {
            let photo = self.arrayOfData?[indexPath.row]
            cell.imageView?.image = UIImage(data: photo!)
            cell.activityIndicatorImageView.stopAnimating()
            cell.activityIndicatorImageView.isHidden = true
        }
        
        return cell
    }
    
}
