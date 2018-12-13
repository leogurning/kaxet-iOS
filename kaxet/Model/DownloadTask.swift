//
//  DownloadTask.swift
//  kaxet
//
//  Created by LEONARD GURNING on 04/11/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import Foundation

protocol DownloadTask {
    var completionHandler: ((String) -> Void)? { get set }
    var progressHandler: ((Float) -> Void)? { get set }
    var isDownloading: Bool { get set }
    
    func resume()
    func suspend()
    func cancel()
}
