//
//  RestAPIServices.swift
//  kaxet
//
//  Created by LEONARD GURNING on 26/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper
import MobileCoreServices

class RestAPIServices {
    
    let accessToken = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Token)
    
    func executePostRequestWithToken(urlToExecute: String, bodyDict: NSDictionary?, completion: @escaping(NSDictionary?, Error?)->Void) {
        
        //Send HTTP request
        let restUrl = URL(string: urlToExecute)
        
        var request = URLRequest(url: restUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue(accessToken!, forHTTPHeaderField: "Authorization")
        
        let postString = bodyDict
        
        if postString != nil {
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: postString!, options: .prettyPrinted)
                
            } catch let error {
                print(error.localizedDescription)
                completion(nil, error)
                return
            }
            
        }
        
        let task = URLSession.shared.dataTask(with: request) {
            (data: Data?, response: URLResponse?, apiError: Error?) in
            
            
            guard let unwrappedData = data else {
                //print(apiError!)
                completion(nil, apiError)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: unwrappedData, options: .mutableContainers)
                    as? NSDictionary
                
                if let parseJSON = json {
                    completion(parseJSON, nil)
                } else {
                    completion(nil, "Unknown App Error. Try again later !" as? Error)
                }
                
            } catch let error {
                
                print(error.localizedDescription)
                completion(nil, error)
                
            }
        }
        task.resume()
    }
    
    func executePostRequestNoToken(urlToExecute: String, bodyDict: NSDictionary?, completion: @escaping(NSDictionary?, Error?)->Void) {
        
        //Send HTTP request
        let restUrl = URL(string: urlToExecute)
        
        var request = URLRequest(url: restUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        
        let postString = bodyDict
        
        if postString != nil {

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: postString!, options: .prettyPrinted)
                
            } catch let error {
                print(error.localizedDescription)
                completion(nil, error)
                return
            }

        }
        
        let task = URLSession.shared.dataTask(with: request) {
            (data: Data?, response: URLResponse?, apiError: Error?) in
            
            
            guard let unwrappedData = data else {
                //print(apiError!)
                completion(nil, apiError)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: unwrappedData, options: .mutableContainers)
                    as? NSDictionary
                
                if let parseJSON = json {
                    completion(parseJSON, nil)
                } else {
                    completion(nil, "Unknown App Error. Try again later !" as? Error)
                }
                
            } catch let error {
                
                print(error.localizedDescription)
                completion(nil, error)
                
            }
        }
        task.resume()
        
    }
    
    func executeGetRequestWithToken(urlToExecute: String, completion: @escaping(NSDictionary?, Error?)->Void) {
        
        //Send HTTP request
        let restUrl = URL(string: urlToExecute)
        
        var request = URLRequest(url: restUrl!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue(accessToken!, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) {
            (data: Data?, response: URLResponse?, apiError: Error?) in
            
            
            guard let unwrappedData = data else {
                //print(apiError!)
                completion(nil, apiError)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: unwrappedData, options: .mutableContainers)
                    as? NSDictionary
                
                if let parseJSON = json {
                    completion(parseJSON, nil)
                } else {
                    completion(nil, "Unknown App Error. Try again later !" as? Error)
                }
                
            } catch let error {
                
                print(error.localizedDescription)
                completion(nil, error)
                
            }
        }
        task.resume()
    }
    
    func executeGetRequestNoToken(urlToExecute: String, completion: @escaping(NSDictionary?, Error?)->Void) {
        
        //Send HTTP request
        let restUrl = URL(string: urlToExecute)
        
        var request = URLRequest(url: restUrl!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        
        let task = URLSession.shared.dataTask(with: request) {
            (data: Data?, response: URLResponse?, apiError: Error?) in
            
            
            guard let unwrappedData = data else {
                //print(apiError!)
                completion(nil, apiError)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: unwrappedData, options: .mutableContainers)
                    as? NSDictionary
                
                if let parseJSON = json {
                    completion(parseJSON, nil)
                } else {
                    completion(nil, "Unknown App Error. Try again later !" as? Error)
                }
                
            } catch let error {
                
                print(error.localizedDescription)
                completion(nil, error)
                
            }
        }
        task.resume()
    }
    
    func executePutRequestWithToken(urlToExecute: String, bodyDict: NSDictionary?, completion: @escaping(NSDictionary?, Error?)->Void) {
        
        //Send HTTP request
        let restUrl = URL(string: urlToExecute)
        
        var request = URLRequest(url: restUrl!)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue(accessToken!, forHTTPHeaderField: "Authorization")
        
        let postString = bodyDict
        
        if postString != nil {
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: postString!, options: .prettyPrinted)
                
            } catch let error {
                print(error.localizedDescription)
                completion(nil, error)
                return
            }
            
        }
        
        let task = URLSession.shared.dataTask(with: request) {
            (data: Data?, response: URLResponse?, apiError: Error?) in
            
            
            guard let unwrappedData = data else {
                //print(apiError!)
                completion(nil, apiError)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: unwrappedData, options: .mutableContainers)
                    as? NSDictionary
                
                if let parseJSON = json {
                    completion(parseJSON, nil)
                } else {
                    completion(nil, "Unknown App Error. Try again later !" as? Error)
                }
                
            } catch let error {
                
                print(error.localizedDescription)
                completion(nil, error)
                
            }
        }
        task.resume()
    }
    
    func executeDeleteRequestWithToken(urlToExecute: String, bodyDict: NSDictionary?, completion: @escaping(NSDictionary?, Error?)->Void) {
        
        //Send HTTP request
        let restUrl = URL(string: urlToExecute)
        
        var request = URLRequest(url: restUrl!)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue(accessToken!, forHTTPHeaderField: "Authorization")
        
        let postString = bodyDict
        
        if postString != nil {
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: postString!, options: .prettyPrinted)
                
            } catch let error {
                print(error.localizedDescription)
                completion(nil, error)
                return
            }
            
        }
        
        let task = URLSession.shared.dataTask(with: request) {
            (data: Data?, response: URLResponse?, apiError: Error?) in
            
            
            guard let unwrappedData = data else {
                //print(apiError!)
                completion(nil, apiError)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: unwrappedData, options: .mutableContainers)
                    as? NSDictionary
                
                if let parseJSON = json {
                    completion(parseJSON, nil)
                } else {
                    completion(nil, "Unknown App Error. Try again later !" as? Error)
                }
                
            } catch let error {
                
                print(error.localizedDescription)
                completion(nil, error)
                
            }
        }
        task.resume()
    }
    
    func executeMultipartPostRequestWithToken(delegateVc: URLSessionDelegate?, urlToExecute: String, bodyDict: NSDictionary?, filePathKey: String, urls: [URL], completion: @escaping(NSDictionary?, Error?)->Void) {
        
        let boundary = generateBoundaryString()
        
        //Send HTTP request
        let restUrl = URL(string: urlToExecute)
        
        var request = URLRequest(url: restUrl!)
        request.httpMethod = "POST"
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.addValue(accessToken!, forHTTPHeaderField: "Authorization")
        
        let postString = bodyDict
        
        if postString != nil {
            
            do {
                request.httpBody = try createBody(with: postString as? [String : String], filePathKey: filePathKey, urls: urls, boundary: boundary)
                
            } catch let error {
                print(error.localizedDescription)
                completion(nil, error)
                return
            }
            
        }
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: delegateVc, delegateQueue: OperationQueue.main)
        //let task = URLSession.shared.dataTask(with: request)
        let task = session.dataTask(with: request)
        {
            (data: Data?, response: URLResponse?, apiError: Error?) in
            
            guard let unwrappedData = data else {
                //print(apiError!)
                completion(nil, apiError)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: unwrappedData, options: .mutableContainers)
                    as? NSDictionary
                
                if let parseJSON = json {
                    completion(parseJSON, nil)
                } else {
                    completion(nil, "Unknown App Error. Try again later !" as? Error)
                }
                
            } catch let error {
                
                print(error.localizedDescription)
                completion(nil, error)
                
            }
        }
        task.resume()
    }
    
    private func createBody(with parameters: [String: String]?, filePathKey: String, urls: [URL], boundary: String) throws -> Data {
        
        var body = Data()
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }
        
        for url in urls {
            //let url = URL(fileURLWithPath: path)
            let filename = url.lastPathComponent
            let data = try Data(contentsOf: url)
            let mimetype = mimeType(for: url)
            print(filename)
            print(mimetype)
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filename)\"\r\n")
            body.append("Content-Type: \(mimetype)\r\n\r\n")
            body.append(data)
            body.append("\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        return body
    }
    
    /// Create boundary string for multipart/form-data request
    ///
    /// - returns:            The boundary string that consists of "Boundary-" followed by a UUID string.
    
    private func generateBoundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
    
    /// Determine mime type on the basis of extension of a file.
    ///
    /// This requires `import MobileCoreServices`.
    ///
    /// - parameter path:         The path of the file for which we are going to determine the mime type.
    ///
    /// - returns:                Returns the mime type if successful. Returns `application/octet-stream` if unable to determine mime type.
    
    private func mimeType(for url: URL) -> String {
        //let url = URL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
}

extension Data {
    
    /// Append string to Data
    ///
    /// Rather than littering my code with calls to `data(using: .utf8)` to convert `String` values to `Data`, this wraps it in a nice convenient little extension to Data. This defaults to converting using UTF-8.
    ///
    /// - parameter string:       The string to be added to the `Data`.
    
    mutating func append(_ string: String, using encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }
}
