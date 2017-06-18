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
    var imageUrlArray: [String]?
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.initFetchRequestForPhoto()
        self.loadPreviewMap()
    }
    
    // MARK: - AlbumViewController
    func initFetchRequestForPhoto()  {
        // Initialize an array of objects for the Photo Entity if any
        do {
            try fetchedResultsController?.performFetch()
            arrayOfImages = try delegate.stack.context.fetch((fetchedResultsController?.fetchRequest)!) as? [Photo]
            
            // When no objects in the Coredata for Entity: Photos
            // Download images url for that pin
            if arrayOfImages?.count == 0 {
                self.getFlickrImagesForPin(self.pin)
            }
        } catch {
            fatalError("Unable to performFetch()")
        }
    }
    
    func loadPreviewMap() {
        // Display the pin coordinates in the top map
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin!.latitude, longitude: pin!.longitude)
        self.mapView.setRegion(mapRegion!, animated: true)
        self.mapView.addAnnotation(annotation)
    }
  

    func getFlickrImagesForPin(_ pinToBeCheck: Pin?) {
        // Gets an aray of 
        if pinToBeCheck != nil {
            let bbox = bboxString(latitude: (pinToBeCheck?.latitude)!, longitude: (pinToBeCheck?.longitude)!)
        
            FIClient().photoSearchFor(bbox: bbox, completionHandler: { (response, success) in
                if !success {
                    print("Error downloading picture")
                } else {
                    // When download has finish save urls and reload collection view
                    self.imageUrlArray = response as? [String]
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
        // Udacity App contains 21 photos
        return 21
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: "FlickrImageCollectionViewCell", for: indexPath) as! FlickrImageCollectionViewCell
        
        cell.backgroundColor = UIColor.blue
        cell.activityIndicatorImageView.startAnimating()
    
        // Use the CoreData to retrieve the images
        if arrayOfImages?.count != 0 {
            let photoObject = arrayOfImages?[indexPath.row]
            cell.imageView?.image = UIImage(data: photoObject?.imageData! as! Data)
            cell.activityIndicatorImageView.stopAnimating()
            cell.activityIndicatorImageView.isHidden = true
        } else {
            // Donwload the images from Flickr
            if let photoURLString = self.imageUrlArray?[indexPath.row] {
                let photoURL = URL(string: photoURLString)!
                do {
                    let data = try Data(contentsOf: photoURL)
                    let photoObject = Photo(imageData: data as NSData, url: photoURLString, context: self.delegate.stack.context)
                    photoObject.pin = self.pin
                    
                    DispatchQueue.main.async {
                        cell.imageView.image = UIImage(data: data)
                        cell.activityIndicatorImageView.stopAnimating()
                        cell.activityIndicatorImageView.isHidden = true
                    }
                } catch {
                   fatalError("Not able to build the data based on the image url")
                }
            }
        }
        
        return cell
    }
    
}
