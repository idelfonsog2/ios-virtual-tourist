//
//  Photo+CoreDataProperties.swift
//  ios-virtual-tourist
//
//  Created by Idelfonso Gutierrez Jr. on 6/14/17.
//  Copyright © 2017 Idelfonso Gutierrez Jr. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var imageData: NSData?
    @NSManaged public var url: String?
    @NSManaged public var pin: Pin?

}
