//
//  CoreDataViewController.swift
//  ios-virtual-tourist
//
//  Created by Idelfonso Gutierrez Jr. on 6/10/17.
//  Copyright © 2017 Idelfonso Gutierrez Jr. All rights reserved.
//

import UIKit
import CoreData

class CoreDataViewController: UICollectionViewController {

    // MARK: Properties
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
            collectionView?.reloadData()
        }
    }
    
    // MARK: Initializers
    
    init(fetchedResultsController fc : NSFetchedResultsController<NSFetchRequestResult>) {
        fetchedResultsController = fc
    }
    
    // Implemented because of the way Swift interfaces with an Objective C
    // protocol called NSArchiving. It's not relevant.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension CoreDataViewController {
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try  fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
}

extension CoreDataViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //tableView.beginUpdates()
        //TODO: Research whats is this use for
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        let set = IndexSet(integer: sectionIndex)
        
        switch (type) {
        case .insert:
            collectionView?.insertSections(set)
            break
        case .delete:
            collectionView?.deleteSections(set)
            break
        default:
            // irrelevant in our case
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch(type) {
        case .insert:
            collectionView?.insertItems(at: [indexPath!])
        case .delete:
            collectionView?.deleteItems(at: [indexPath!])
        case .update:
            collectionView?.reloadItems(at: [indexPath!])
        case .move:
            collectionView?.deleteItems(at: [indexPath!])
            collectionView?.insertItems(at: [indexPath!])
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView?.endInteractiveMovement()
    }
}
