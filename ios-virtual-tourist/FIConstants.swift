//
//  FIConstants.swift
//  ios-virtual-tourist
//
//  Created by Idelfonso Gutierrez Jr. on 6/9/17.
//  Copyright © 2017 Idelfonso Gutierrez Jr. All rights reserved.
//

import Foundation

struct Flickr {
    
    static let ApiKeyValue = "142b10b740640600f46da4fddf700f48"
    static let scheme       = "https"
    static let host         = "api.flick.com"
    static let path         = "/services/rest"
    
    static let baseUrl = ""
    
    static let SearchBBoxHalfWidth = 1.0
    static let SearchBBoxHalfHeight = 1.0
    static let SearchLatRange = (-90.0, 90.0)
    static let SearchLonRange = (-180.0, 180.0)
}

struct ParameterKeys {
    static let MethodKey    = "method"
    static let API          = "api_key"
    static let Format       = "format"
    static let NonJSONCallBack = "nonjsoncallback"
    static let Query        = "Query"
    static let Latitude     = "latitude"
    static let Longitude    = "longitude"
    static let Bbox         = "bbox"
}

struct ParameterValues {
    static let JSONValue    = "json"
    static let JSONCallBackValue = 1
}

struct Method {
    static let PlacesFind   = "flickr.places.find"
    static let SearchPhotos = "flickr.photos.search"
}

struct ResponseKeys {
    static let Places   = "places"
    static let Place    = "place"
    static let PlaceId  = "place_id"
    static let Status   = "stat"
}
