//
//  SpinningProgressView.swift
//  kaxet
//
//  Created by LEONARD GURNING on 06/11/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class SpinningProgressView: UIView {

    
    @IBOutlet weak var btnCancelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressCountLabel: UILabel!
    
    @IBOutlet weak var btnStopDownloading: UIButton!
    
    private let shapeLayer = CAShapeLayer()
    private var songData: NSDictionary = [:]
    fileprivate var downloadTask:  DownloadTask?

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
        
        guard let stillProgress = downloadTask?.isDownloading else {
            return
        }
        if stillProgress {
            DispatchQueue.main.async {
                self.downloadTask?.cancel()
                self.downloadTask = nil
                self.isHidden = true
            }
        }
    }
    
    func initData(data: NSDictionary) {
        self.songData = data
    }
    
    private func initSubviews() {
        
        guard let mainView = Bundle.main.loadNibNamed("SpinningProgressView", owner: self, options: nil)?.first as? UIView else {
            return
        }
        mainView.frame = self.bounds
        self.addSubview(mainView)
        
        // this will change the label's textColor in Storyboard
        // when a UIView's class is set to SpinningView
        
        let center = mainView.center
        let trackLayer = CAShapeLayer()
        
        let circularPath = UIBezierPath(arcCenter: .zero, radius: 20, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        
        trackLayer.path = circularPath.cgPath
        //trackLayer.strokeColor = UIColor.lightGray.cgColor
        trackLayer.strokeColor = CGColor.colorWithHex(hex: 0xd1ffd7, alpha: 1)
        trackLayer.lineWidth = 5
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.position = center
        mainView.layer.addSublayer(trackLayer)
        
        shapeLayer.path = circularPath.cgPath
        shapeLayer.strokeColor = CGColor.colorWithHex(hex: 0x339933, alpha: 1)
        shapeLayer.lineWidth = 5
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.position = center
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        
        shapeLayer.transform = CATransform3DMakeRotation(-CGFloat.pi / 2, 0, 0, 1)
        
        shapeLayer.strokeEnd = 0
        mainView.layer.addSublayer(shapeLayer)
        existingProgress()
    }
    
    private func existingProgress() {
        
        DownloadService.shared.onProgress = { (progress) in
            OperationQueue.main.addOperation {
                print("Task1: \(progress)")
                self.shapeLayer.strokeEnd = CGFloat(progress)
                let dprogress = Int(progress * 100)
                self.progressCountLabel.text = "\(dprogress) %"
            }
        }
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
                print("Task1: \(progress)")
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
        //btnStartDownload2.isEnabled = false
        downloadTask?.resume()
    }
}
