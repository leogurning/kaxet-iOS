//
//  GenericDownloadTask.swift
//  kaxet
//
//  Created by LEONARD GURNING on 04/11/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import Foundation

class GenericDownloadTask {
    var completionHandler: ((String) -> Void)?
    var progressHandler: ((Float) -> Void)?
    
    private(set) var task: URLSessionDownloadTask
    var taskId: String = ""
    var isDownloading = false
    
    init(task: URLSessionDownloadTask, ref: String) {
        self.task = task
        self.taskId = ref
    }
    
    deinit {
        print("Deinit: \(task.originalRequest?.url?.absoluteString ?? "")")
    }
    
}

extension GenericDownloadTask: DownloadTask {
    
    func resume() {
        task.resume()
        self.isDownloading = true
    }
    
    func suspend() {
        task.suspend()
        self.isDownloading = false
    }
    
    func cancel() {
        task.cancel()
        self.isDownloading = false
    }
}
