//
//  Photo+CoreDataClass.swift
//  ios-virtual-tourist
//
//  Created by Idelfonso Gutierrez Jr. on 6/13/17.
//  Copyright © 2017 Idelfonso Gutierrez Jr. All rights reserved.
//

import Foundation
import CoreData


public class Photo: NSManagedObject {

    convenience init(url: String, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: entity, insertInto: context)
            self.url = url
        } else {
            fatalError("Unable to find entity name")
        }
    }
}
