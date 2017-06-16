//
//  FIClient.swift
//  ios-virtual-tourist
//
//  Created by Idelfonso Gutierrez Jr. on 6/9/17.
//  Copyright © 2017 Idelfonso Gutierrez Jr. All rights reserved.
//

import UIKit

class FIClient: NSObject {

    func photoSearchFor(bbox: String, completionHandler: @escaping(_ response: Any?, _ succes: Bool) -> Void) {
        let params: [String: Any] = [
            ParameterKeys.API: Flickr.ApiKeyValue,
            ParameterKeys.MethodKey: Method.SearchPhotos,
            ParameterKeys.Bbox: bbox,
            ParameterKeys.Format: ParameterValues.JSONValue,
            ParameterKeys.NonJSONCallBack: ParameterValues.JSONCallBackValue,
            ParameterKeys.Extras: ParameterValues.UrlM
        ]
        
        let url = urlFromParams(params: params)
        let request = NSMutableURLRequest(url: url)
        
        VTNetworking().taskForGET(request) { (response, success) in
            if success {
                guard let photosDictionary = response?[ResponseKeys.Photos] as? [String: Any] else {
                    print("No PHOTOS key found")
                    completionHandler(nil, false)
                    return
                }
                
                guard let photoArrayDictionary = photosDictionary[ResponseKeys.Photo] as? [[String: Any]] else {
                    print("No PHOTO key found")
                    completionHandler(nil, false)
                    return
                }
                
                
                var arrayOfUrlImages: [String] = []
                for index in 0 ..< 10 {
                    let photo = photoArrayDictionary[index]
                    
                    /* GUARD: Does our photo have a key for 'url_m'? */
                    guard let imageUrlString = photo[ResponseKeys.UrlM] as? String else {
                        completionHandler(nil, false)
                        return
                    }
                    
                    // if an image exists at the url, set the image and title
                    arrayOfUrlImages.append(imageUrlString)
                }
                
                //TODO: return an array of string in the response
                completionHandler(arrayOfUrlImages, true)
                
            }  else  {
                completionHandler(nil, false)
            }
        }
    }
    
    func urlFromParams(params: [String: Any]) -> URL {
        var components = URLComponents()
        components.scheme = Flickr.scheme
        components.host = Flickr.host
        components.path = Flickr.path
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in params {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems?.append(queryItem)
        }
        
        return components.url!
    }
}
