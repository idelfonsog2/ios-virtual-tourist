//
//  Pin+CoreDataClass.swift
//  ios-virtual-tourist
//
//  Created by Idelfonso Gutierrez Jr. on 6/13/17.
//  Copyright © 2017 Idelfonso Gutierrez Jr. All rights reserved.
//

import Foundation
import CoreData


public class Pin: NSManagedObject {
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let entityDes = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: entityDes, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Unable to find entity Name")
        }
    }
    
    func deleteObject(pin: Pin, context: NSManagedObjectContext) {
        self.deleteObject(pin: pin, context: context)
    }
}
