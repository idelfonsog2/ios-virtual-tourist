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
    var arrayOfImageData: [Data]?
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    // MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - App Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initFetchRequestForPhoto()
        self.loadImages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //self.setupNavBar()
        self.loadImages()
    }
    
    // MARK: - AlbumViewController
    
    func loadImages() {
        arrayOfImages = []
        
        do {
            let array = try! delegate.stack.context.fetch((fetchedResultsController?.fetchRequest)!) as? [Photo]
            
            if array?.count != 0 {
                for image in array! {
                    arrayOfImages?.append(image)
                    //TODO: UserDefaults to let de collection view delegate that we have images
                    //apend
                }
            } else {
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

    func getFlickrImagesForPin(_ pinToBeCheck: Pin?) {
        if pinToBeCheck != nil {
            let bbox = bboxString(latitude: (pinToBeCheck?.latitude)!, longitude: (pinToBeCheck?.longitude)!)
            FIClient().photoSearchFor(bbox: bbox, completionHandler: { (response, success) in
                if !success {
                    print("Error downloading picture")
                } else {
                    // TODO: response is an arrary of photo dictionary
                    // get MediumURL
                    let imageUrlArray = response as! [String]
                    for i in  imageUrlArray {
                        self.arrayOfImageData(Data(contentsOf: imageURL!))
                    }
                    
                    //todo: build this in the collectiondelegate
                    if let imageData = try?  {
                        DispatchQueue.main.async {
                            self.setUIEnabled(true)
                            self.photoImageView.image = UIImage(data: imageData)
                            self.photoTitleLabel.text = photoTitle ?? "(Untitled)"
                        }
                    }
                    print(response as! [String])
                    
                    self.getImageDataForUrl(url: )
                }
            })
        }
    }
    
    func goBack() {
        // TODO: Save before leaving ??
        self.navigationController?.popViewController(animated: true)
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
        
        if arrayOfImages?.count != 0 {
            return arrayOfImages!.count
        } else {
            return 0
        }
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: "FlickrImageCollectionViewCell", for: indexPath) as! FlickrImageCollectionViewCell
        
        //TODO: if array == 0, show loading activity indicator
        
        return cell
    }
    
}
