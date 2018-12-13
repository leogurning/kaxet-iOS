//
//  FullSpinningProgressView.swift
//  kaxet
//
//  Created by LEONARD GURNING on 29/11/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class FullSpinningProgressView: UIView {
    
    @IBOutlet weak var progressCountLabel: UILabel!
    
    @IBOutlet weak var btnStopDownloading: UIButton!
    
    let shapeLayer = CAShapeLayer()
    private var songData: NSDictionary = [:]
    fileprivate var downloadTask:  DownloadTask?
    fileprivate let session = DownloadService.shared.session
    //var downloadTask:  DownloadTask?
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     
     }
     */
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let _ = DownloadService.shared.session
        initSubviews()
    }
    
    deinit {
        DownloadService.shared.onProgress = nil
        print("Deinit:  Download onProgress")
    }
    
    @IBAction func btnStopDownloadingPressed(_ sender: UIButton) {
        if let stillProgress = downloadTask?.isDownloading {
            if stillProgress {
                DispatchQueue.main.async {
                    self.downloadTask?.cancel()
                    self.downloadTask = nil
                    self.isHidden = true
                    self.superview?.isHidden = true
                    self.shapeLayer.strokeEnd = 0
                    self.progressCountLabel.text = "0"
                    UserDefaults.standard.removeObject(forKey: "downloadInProgress")
                }
            }
        //If it's from background
        } else {
            //UserDefaults.standard.removeObject(forKey: "downloadInProgress")
            self.session.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) -> Void in

                // downloadTasks = [URLSessionDownloadTask]
                print("There are \(downloadTasks.count) download tasks associated with this session.")
                for downloadTask in downloadTasks {
                    
                    if let downloadData = UserDefaults.standard.object(forKey: "downloadInProgress") as? [String:String] {
                        
                        let fileIdentifier = downloadData[String(downloadTask.taskIdentifier)] ?? ""
                        if fileIdentifier != "" {
                            print("downloadTask.taskIdentifier = \(downloadTask.taskIdentifier)")
                            
                            if downloadTask.state == URLSessionTask.State.running {
                                downloadTask.cancel()
                                self.session.invalidateAndCancel()
                                UserDefaults.standard.set(false, forKey: "kaxetDownloadURLSessionValid")
                            }
                            
                            
                            DispatchQueue.main.async {
                                self.isHidden = true
                                self.superview?.isHidden = true
                                self.shapeLayer.strokeEnd = 0
                                self.progressCountLabel.text = "0"
                                UserDefaults.standard.removeObject(forKey: "downloadInProgress")
                                DownloadService.shared.onProgress = nil
                                DownloadService.shared.downloadTasks.removeAll()

                            }
                            break
                        }
                    }
                    
                }
            }
        }
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    func initData(data: NSDictionary) {
        self.songData = data
    }
    
    private func initSubviews() {
        
        guard let mainView = Bundle.main.loadNibNamed("FullSpinningProgressView", owner: self, options: nil)?.first as? UIView else {
            return
        }
        mainView.frame = self.bounds
        self.addSubview(mainView)
        
        // this will change the label's textColor in Storyboard
        // when a UIView's class is set to SpinningView
        
        let center = mainView.center
        let trackLayer = CAShapeLayer()
        
        let circularPath = UIBezierPath(arcCenter: .zero, radius: 60, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        
        trackLayer.path = circularPath.cgPath
        //trackLayer.strokeColor = UIColor.lightGray.cgColor
        trackLayer.strokeColor = CGColor.colorWithHex(hex: 0xd1ffd7, alpha: 1)
        trackLayer.lineWidth = 15
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.position = center
        mainView.layer.addSublayer(trackLayer)
        
        shapeLayer.path = circularPath.cgPath
        shapeLayer.strokeColor = CGColor.colorWithHex(hex: 0x339933, alpha: 1)
        shapeLayer.lineWidth = 15
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.position = center
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        
        shapeLayer.transform = CATransform3DMakeRotation(-CGFloat.pi / 2, 0, 0, 1)
        
        shapeLayer.strokeEnd = 0
        mainView.layer.addSublayer(shapeLayer)
        
    }
    
    func startAnimation() {
        
        shapeLayer.strokeEnd = 0
        progressCountLabel.text = "0"
        
        let progressAnimation = CABasicAnimation(keyPath: "strokeEnd")
        progressAnimation.toValue = 1
        progressAnimation.duration = 2
        progressAnimation.fillMode = CAMediaTimingFillMode.forwards
        progressAnimation.isRemovedOnCompletion = false
        shapeLayer.add(progressAnimation, forKey: "downloadProgress")
        
    }
    func downloadSong(url: URL, songId: String, completion: @escaping (String) -> Void) {
        
        shapeLayer.strokeEnd = 0
        progressCountLabel.text = "0"
        
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        downloadTask = DownloadService.shared.download(request: request, downloadId: songId)
        downloadTask?.completionHandler = { [weak self] in
            print("Result: \($0)")
            DispatchQueue.main.async {
                self?.downloadTask = nil
                self?.shapeLayer.strokeEnd = 0
                self?.progressCountLabel.text = "0"
                self?.isHidden = true
                self?.isHidden = true
                
                completion("finish")
                /*
                 self?.btnStartDownload2.isEnabled = true
                 self?.downloadProgressBar2.setProgress(0.0, animated: false)
                 self?.progressCountLabel2.text = "0"
                 */
            }
            
        }
        
        DownloadService.shared.onProgress = { (progress) in
            OperationQueue.main.addOperation {
                //print("Task1: \(progress)")
                self.shapeLayer.strokeEnd = CGFloat(progress)
                let dprogress = Int(progress * 100)
                self.progressCountLabel.text = "\(dprogress) %"
            }
        }
        /*
         downloadTask?.progressHandler = { [weak self] in
         print("Task1: \($0)")
         self?.shapeLayer.strokeEnd = CGFloat($0)
         let dprogress = Int($0 * 100)
         self?.progressCountLabel.text = "\(dprogress) %"
         
         }
         */
        downloadTask?.isDownloading = true
        downloadTask?.resume()
    }
}
