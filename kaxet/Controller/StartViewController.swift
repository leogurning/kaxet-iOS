//
//  StartViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 23/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class StartViewController: UIViewController {

    @IBOutlet weak var coverSpinningView: UIView!
    @IBOutlet weak var fullSpinningProgressView: FullSpinningProgressView!
    @IBOutlet weak var playerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var playerViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var playerViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var playerViewBottomConstraint: NSLayoutConstraint!
    private var userid: String = ""
    fileprivate var isInitProgress: Bool = true
    
    @IBOutlet weak var mainContainerView: UIView!
    @IBOutlet weak var miniPlayerContainerView: UIView!
    @IBOutlet weak var toolbarView: MenuToolbar!
    @IBOutlet weak var toolbarTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
        
        miniPlayerContainerView.isHidden = true
        /*
        playerViewBottomConstraint.constant = 10
        playerViewHeightConstraint.constant = self.mainContainerView.frame.height
        */
        let getVCobj = self.children[0] as! KaxetTabBarViewController
        let getMiniPlayerObj = self.children[1] as! MiniPlayerViewController
        
        getVCobj.setMiniPlayerVc(playerVc: getMiniPlayerObj)
        getVCobj.setMiniPlayerView(playerView: miniPlayerContainerView)
        
        self.toolbarView.setActiveItem(index: 0)
        self.toolbarView.setParentVC(vc: self)
        self.toolbarView.attachCollectionView()
        self.toolbarView.layer.zPosition = -1
        
        coverSpinningView.isHidden = true
        coverSpinningView.layer.cornerRadius = 10
        coverSpinningView.clipsToBounds = true
        fullSpinningProgressView.isHidden = true
        fullSpinningProgressView.layer.cornerRadius = 10
        fullSpinningProgressView.clipsToBounds = true
        
        _ = DownloadService.shared.session
        /*
        session.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) -> Void in
            
            // downloadTasks = [URLSessionDownloadTask]
            print("There are \(downloadTasks.count) download tasks associated with this session.")
            if downloadTasks.count > 0 {
                
                DispatchQueue.main.async {
                    self.coverSpinningView.isHidden = false
                    self.fullSpinningProgressView.isHidden = false
                }
                
            }
            
        }
        */
        if let downloadData = UserDefaults.standard.object(forKey: "downloadInProgress") as? [String:String] {
            print(downloadData)
            self.coverSpinningView.isHidden = false
            self.fullSpinningProgressView.isHidden = false
        
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DownloadService.shared.onProgress = { (progress) in
            
            OperationQueue.main.addOperation {
                print("Task1: \(progress)")
                self.fullSpinningProgressView.shapeLayer.strokeEnd = CGFloat(progress)
                let dprogress = Int(progress * 100)
                self.fullSpinningProgressView.progressCountLabel.text = "\(dprogress) %"
            }
        }

        DownloadService.shared.downloadCompletionHandler = {
            DispatchQueue.main.async {
                if self.coverSpinningView.isHidden {
                    //No action
                } else {
                    self.coverSpinningView.isHidden = true
                }
                
                if self.fullSpinningProgressView.isHidden {
                    //No Action
                } else {
                    self.fullSpinningProgressView.isHidden = true
                }

            }
            
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DownloadService.shared.onProgress = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Get local file path: download task stores tune here; AV player plays it.
        //let documentsDefaultPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let documentsDefaultPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        //print("documentsDefaultPath: \(documentsDefaultPath.path)")
        let documentDirPathdef = documentsDefaultPath.appendingPathComponent("kaxet")
        let documentDirPath = documentDirPathdef.appendingPathComponent(userid)
        print("documentDirPath: \(documentDirPath.path)")
    
        var isDir: ObjCBool = true
        
        let isExist = FileManager.default.fileExists(atPath: documentDirPath.path, isDirectory: &isDir)
        //print("Exist? : \(isExist)")
        
        if !(isExist) {
            do {
                try FileManager.default.createDirectory(atPath: documentDirPath.path, withIntermediateDirectories: true, attributes: nil)
                print("Folder successfully created !")
            }
            catch {
                print("Error creating directory...")
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
