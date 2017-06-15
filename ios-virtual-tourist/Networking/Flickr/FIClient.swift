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
            ParameterKeys.NonJSONCallBack: ParameterValues.JSONCallBackValue
        ]
        
        let url = urlFromParams(params: params)
        let request = NSMutableURLRequest(url: url)
        
        VTNetworking().taskForGET(request) { (response, success) in
            if success {
                print(response)
            } else {
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
