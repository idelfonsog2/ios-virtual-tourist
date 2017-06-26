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
    static let host         = "api.flickr.com"
    static let path         = "/services/rest"
    
    static let baseUrl = ""
    
    static let SearchBBoxHalfWidth = 0.5
    static let SearchBBoxHalfHeight = 0.5
    static let SearchLatRange = (-90.0, 90.0)
    static let SearchLonRange = (-180.0, 180.0)
}

struct ParameterKeys {
    static let MethodKey    = "method"
    static let API          = "api_key"
    static let Format       = "format"
    static let NonJSONCallBack = "nojsoncallback"
    static let Query        = "Query"
    static let Latitude     = "lat"
    static let Longitude    = "lon"
    static let Bbox         = "bbox"
    static let Extras       = "extras"
    static let PlaceId      = "place_id"
}

struct ParameterValues {
    static let JSONValue    = "json"
    static let UrlM         = "url_m"
    static let JSONCallBackValue = 1
}

struct Method {
    static let PlacesFind   = "flickr.places.find"
    static let SearchPhotos = "flickr.photos.search"
    static let FindByLatLon = "flickr.places.findByLatLon"
}

struct ResponseKeys {
    static let Places   = "places"
    static let Place    = "place"
    static let PlaceId  = "place_id"
    static let Status   = "stat"
    
    static let Photos   = "photos"
    static let Photo    = "photo"
    static let UrlM     = "url_m"
}
