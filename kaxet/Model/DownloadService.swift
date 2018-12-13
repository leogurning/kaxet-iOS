//
//  DownloadService.swift
//  kaxet
//
//  Created by LEONARD GURNING on 04/11/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class DownloadService: NSObject {
    
    var delegate = DownloadServiceManager()
    public static let shared = DownloadService()
    var session: URLSession

    //let configuration = URLSessionConfiguration.default
    var backgroundSessionCompletionHandler: (() -> Void)?
    var downloadCompletionHandler: (() -> Void)?
    
    var downloadTasks = [GenericDownloadTask]()
    var fileManager = FileManager.default
    
    var documentsDefaultPath: URL?
    var documentDirPath: URL?
    var downloadRef = [String:String]()
    
    var userId: String?
    
    typealias ProgressHandler = (Float) -> ()
    
    var onProgress : ProgressHandler? {
        didSet {
            if onProgress != nil {
                //let _ = activate()
                let _ = DownloadService.shared.session
            }
        }
    }
    
    private override init() {
        
        let config = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background")
        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
        session = URLSession(configuration: config, delegate: delegate, delegateQueue: OperationQueue())
        UserDefaults.standard.set(true, forKey: "kaxetDownloadURLSessionValid")
        super.init()
        
        userId = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)
        let documentsDefaultPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let documentDirPathdef = documentsDefaultPath.appendingPathComponent("kaxet")
        documentDirPath = documentDirPathdef.appendingPathComponent(userId!)
 
        //documentDirPath = APPDIR.documentDirPath
        
    }
    
    func activate() -> URLSession {
        let config = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background")
        
        // Warning: If an URLSession still exists from a previous download, it doesn't create a new URLSession object but returns the existing one with the old delegate object attached!
        
        return URLSession(configuration: config, delegate: delegate, delegateQueue: OperationQueue())
    }
    
    func download(request: URLRequest, downloadId: String) -> DownloadTask {
        var task: URLSessionDownloadTask?
        if let isSessionValid = UserDefaults.standard.object(forKey: "kaxetDownloadURLSessionValid") as? Bool {
            if isSessionValid {
                task = DownloadService.shared.session.downloadTask(with: request)
            } else { //If the session is invalidate due to force cancel of background download task, recreate session and associate
                task = activate().downloadTask(with: request)
                UserDefaults.standard.set(true, forKey: "kaxetDownloadURLSessionValid")
                session = activate()
            }
        
        } else {
            task = DownloadService.shared.session.downloadTask(with: request)
        }
    
        let downloadTask = GenericDownloadTask(task: task!, ref: downloadId)
        downloadTasks.append(downloadTask)
        self.downloadRef = [String(task!.taskIdentifier):downloadId]
        UserDefaults.standard.set(self.downloadRef, forKey: "downloadInProgress")
        /*
        self.session.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) -> Void in
            
            print("There are \(downloadTasks.count) download tasks associated with this session.")
            for downloadTask in downloadTasks {
                print("downloadTask.taskIdentifier = \(downloadTask.taskIdentifier)")
            }
        }
        */
        return downloadTask
        
    }
    
}

class DownloadServiceManager: NSObject, URLSessionDownloadDelegate, URLSessionDelegate {
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("Going to Finish Event !")
        DispatchQueue.main.async {
            if let completionHandler = DownloadService.shared.backgroundSessionCompletionHandler {
                DownloadService.shared.backgroundSessionCompletionHandler = nil
                completionHandler()
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        guard let httpResponse = downloadTask.response as? HTTPURLResponse,
            (200...299).contains(httpResponse.statusCode) else {
                print ("server error")
                UserDefaults.standard.removeObject(forKey: "downloadInProgress")
                return
        }
        
        var inBackground = false
        var indexDl = 0
        if let downloadData = UserDefaults.standard.object(forKey: "downloadInProgress") as? [String:String] {
            let fileIdentifier = downloadData[String(downloadTask.taskIdentifier)]! as String
            
            var destinationURL: URL?
            
            if let index = DownloadService.shared.downloadTasks.index(where: { $0.task == downloadTask }) {
                inBackground = false
                indexDl = index
                destinationURL = DownloadService.shared.documentDirPath!.appendingPathComponent(fileIdentifier)
            } else {
                inBackground = true
                let documentsDefaultPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let documentDirPathdef = documentsDefaultPath.appendingPathComponent("kaxet")
                let documentDirPath = documentDirPathdef.appendingPathComponent(DownloadService.shared.userId!)
                
                destinationURL = documentDirPath.appendingPathComponent(fileIdentifier)
            }
            
            var isDir: ObjCBool = false
            
            let isExist = FileManager.default.fileExists(atPath: destinationURL!.path, isDirectory: &isDir)
            
            if isExist {
                print("File already exist...")
                try? DownloadService.shared.fileManager.removeItem(at: location)
                if !inBackground {
                    let task = DownloadService.shared.downloadTasks.remove(at: indexDl)
                    task.isDownloading = false
                    task.completionHandler?("File already exist...")
                } else {
                    DownloadService.shared.downloadCompletionHandler?()
                }
                UserDefaults.standard.removeObject(forKey: "downloadInProgress")
            } else {
                
                try? DownloadService.shared.fileManager.removeItem(at: destinationURL!)
                
                do {
                    try DownloadService.shared.fileManager.moveItem(at: location, to: destinationURL!)
                    print("Successfully downloaded !")
                    if !inBackground {
                        let task = DownloadService.shared.downloadTasks.remove(at: indexDl)
                        //task.atLocation = location
                        task.isDownloading = false
                        UserDefaults.standard.removeObject(forKey: "downloadInProgress")
                        task.completionHandler?("Successfully downloaded !")
                    }
                    else {
                        UserDefaults.standard.removeObject(forKey: "downloadInProgress")
                        DownloadService.shared.downloadCompletionHandler?()
                    }
                } catch let error {
                    
                    try? DownloadService.shared.fileManager.removeItem(at: location)
                    print("Could not copy file to disk: \(error.localizedDescription)")
                    UserDefaults.standard.removeObject(forKey: "downloadInProgress")
                    if !inBackground {
                        let task = DownloadService.shared.downloadTasks.remove(at: indexDl)
                        //task.atLocation = location
                        task.isDownloading = false
                        task.completionHandler?("Could not copy file to disk: \(error.localizedDescription)")
                    }
                    else {
                        DownloadService.shared.downloadCompletionHandler?()
                    }
                }
                
            }
            
        }
        
    }
    
    private func calculateProgress(session : URLSession, downloadTask: URLSessionDownloadTask, completionHandler : @escaping (Float) -> ()) {
        
        session.getTasksWithCompletionHandler { (tasks, uploads, downloads) in
            
            guard let task = downloads.first(where: { $0 == downloadTask }) else {
                return completionHandler(0.0)
            }
            
            if task.countOfBytesExpectedToReceive > 0 {
                
                completionHandler(Float(task.countOfBytesReceived) / Float(task.countOfBytesExpectedToReceive))
                
            } else {
                completionHandler(0.0)
            }
            
            //completionHandler(progress.reduce(0.0, +))
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        if totalBytesExpectedToWrite > 0 {
            if let onProgress = DownloadService.shared.onProgress {
                calculateProgress(session: session, downloadTask: downloadTask, completionHandler: onProgress)
            }
            //let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            //debugPrint("Progress \(downloadTask) \(progress)")
            
        }
        /*
         guard let task = downloadTasks.first(where: { $0.task == downloadTask }) else {
            return
         }
         
        let percentageDownloaded = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            task.progressHandler?(percentageDownloaded)
        }
        */
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            if (error as NSError?)?.code == NSURLErrorCancelled {
                print("Task has been cancelled !")
            } else {
                print("Task failed with error: \(error)")
            }
            UserDefaults.standard.removeObject(forKey: "downloadInProgress")
        } else {
            print("Task completed successfully.")
        }
        
    }
}
