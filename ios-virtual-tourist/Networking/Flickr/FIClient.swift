//
//  FIClient.swift
//  ios-virtual-tourist
//
//  Created by Idelfonso Gutierrez Jr. on 6/9/17.
//  Copyright © 2017 Idelfonso Gutierrez Jr. All rights reserved.
//

import UIKit

class FIClient: NSObject {

    /*
     @params coordinates for the region of a pin
     @returns array of url images
     */
    func photoSearchFor(bbox: String?, placeId: String?, thisMany: Int, completionHandler: @escaping(_ response: Any?, _ succes: Bool) -> Void) {
        
        // pick a random page!
        let pageLimit = Flickr.PageLimit
        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
        
        var params: [String: Any] = [
            ParameterKeys.API: Flickr.ApiKeyValue,
            ParameterKeys.MethodKey: Method.SearchPhotos,
            ParameterKeys.Format: ParameterValues.JSONValue,
            ParameterKeys.NonJSONCallBack: ParameterValues.JSONCallBackValue,
            ParameterKeys.Extras: ParameterValues.UrlM,
            ParameterKeys.Page: randomPage
        ]
        
        if placeId != nil {
            params[ParameterKeys.PlaceId] = placeId
        } else if bbox != nil {
            params[ParameterKeys.Bbox] = bbox
        }
        
        let url = urlFromParams(params: params)
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "GET"
        
        print(request.url)
        VTNetworking().taskForGET(request) { (response, success) in
            if success {
                
                guard let photosDictionary = response?[ResponseKeys.Photos] as? [String: Any] else {
                    completionHandler("No PHOTOS key found", false)
                    return
                }
                
                guard let photoArrayDictionary = photosDictionary[ResponseKeys.Photo] as? [[String: Any]] else {
                    completionHandler("No PHOTO key found", false)
                    return
                }
                
                
                var arrayOfUrlImages: [String] = []
                
                //let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArrayDictionary.count)))
                
                for index in 0 ..< thisMany {
                    let photo = photoArrayDictionary[index] as [String: AnyObject]
                    guard let imageUrlString = photo[ResponseKeys.UrlM] as? String else {
                        completionHandler("No 'imageURLString found", false)
                        return
                    }
                    
                    arrayOfUrlImages.append(imageUrlString)
                }
                
                // @return array of url strings
                completionHandler(arrayOfUrlImages, true)
                
            }  else  {
                completionHandler(nil, false)
            }
        }
    }
    
    func photoSearchFor(lat: Double, lon: Double, completionHandler: @escaping(_ response: Any?, _ sucess: Bool) -> Void) {
        let params: [String: Any] = [
            ParameterKeys.API: Flickr.ApiKeyValue,
            ParameterKeys.MethodKey: Method.FindByLatLon,
            ParameterKeys.Latitude: lat,
            ParameterKeys.Longitude: lon,
            ParameterKeys.Format: ParameterValues.JSONValue,
            ParameterKeys.NonJSONCallBack: ParameterValues.JSONCallBackValue,
        ]
        
        let url = urlFromParams(params: params)
        let request = NSMutableURLRequest(url: url)
        print(request.url)
        VTNetworking().taskForGET(request) { (response, success) in
            if success {
                guard let photosDictionary = response?[ResponseKeys.Places] as? [String: Any] else {
                    completionHandler("No PlaceS key found", false)
                    return
                }
                
                guard let photoArrayDictionary = photosDictionary[ResponseKeys.Place] as? [[String: Any]] else {
                    completionHandler("No Place key found", false)
                    return
                }
                
                
                
                let firstResponse = photoArrayDictionary[0]
                
                guard let placeId = firstResponse[ResponseKeys.PlaceId] as? String else {
                    completionHandler("No 'imageURLString found", false)
                    return
                }
                
                completionHandler(placeId, true)
                
            }  else  {
                completionHandler(nil, false)
            }
        }
        
    }
    func downloadImage(withURL urlString: String, completionHandler: @escaping(_ response: Any?, _ success: Bool) -> Void) {
        
        let url = URL(string: urlString)!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard error == nil else {
                completionHandler("error retrieving image", false)
                return
            }
            
            guard let data = data else  {
                completionHandler("error retrieving data image", false)
                return
            }
            
            completionHandler(data, true)

        }
        
        task.resume()
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
