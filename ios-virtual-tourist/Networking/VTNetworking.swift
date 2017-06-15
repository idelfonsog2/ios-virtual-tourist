//
//  VTNetworking.swift
//  ios-virtual-tourist
//
//  Created by Idelfonso Gutierrez Jr. on 6/9/17.
//  Copyright © 2017 Idelfonso Gutierrez Jr. All rights reserved.
//

import UIKit

class VTNetworking: NSObject {

    let session = URLSession.shared
    
    func taskForGET(_ request: NSMutableURLRequest, completionHandler: @escaping(_ response: AnyObject?, _ success: Bool) -> Void) {
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            guard error == nil else {
                completionHandler("There was an error with your request" as AnyObject, false)
                return
            }
            
            guard let status = (response as? HTTPURLResponse)?.statusCode, status >= 200 && status <= 299 else {
                completionHandler("Status other than 200" as AnyObject, false)
                return
            }
            
            guard let data = data else {
                completionHandler(nil, false)
                return
            }
            
            self.converDataWithCompletionHandler(data: data, completionHandler: { (response, success) in
                completionHandler(response, success)
            })
        }
        
        task.resume()
    }
    
    func converDataWithCompletionHandler(data: Data, completionHandler: @escaping(_ response: AnyObject?, _ succes: Bool) -> Void) {
        
        var parsedResult: AnyObject?
        
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            completionHandler("Could not parse the data as JSON: '\(data)'" as AnyObject, false)
        }
        
        completionHandler(parsedResult, true)
    }
}
