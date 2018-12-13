//
//  AddToPlaylistViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 12/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class AddToPlaylistViewController: UIViewController {

    let apiServices = RestAPIServices()
    let apiUrl = APPURL.BaseURL
    let hostUrl = APPURL.Domain
    
    var accessToken: String = ""
    var userid: String = ""
    
    @IBOutlet weak var popUpView: UIView!
    @IBOutlet weak var userPlaylistTableView: UITableView!
    @IBOutlet weak var playlistPageControl: UIPageControl!
    @IBOutlet weak var btnNextPage: UIButton!
    @IBOutlet weak var btnPrevPage: UIButton!
    
    private var songData: NSDictionary = [:]
    private var playlistData: NSArray = []
    private var playlistPages: Int = 0
    private var currentPage: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        accessToken = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Token)!
        
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
        
        popUpView.layer.cornerRadius = 10
        popUpView.layer.masksToBounds = true
        
        userPlaylistTableView.delegate = self
        userPlaylistTableView.dataSource = self
        
        self.getUserPlaylistData(page: 1, isInit: true)
        btnPrevPage.isHidden = true
        
        
        configureTableView()
        self.userPlaylistTableView.tableFooterView = UIView(frame: CGRect.zero)
        
        addTapGestureRecognizer()
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture(gesture:)))
        swipeLeft.direction = .left
        userPlaylistTableView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture(gesture:)))
        swipeRight.direction = .right
        userPlaylistTableView.addGestureRecognizer(swipeRight)
    }
    
    func initData(song: NSDictionary, playlist: NSArray, npages: Int) {
        self.songData = song
        self.playlistData = playlist
        //self.playlistPages = npages
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "goToAddToPlaylistInit") {
            let destinationVC = segue.destination as! AddToPlaylistInitViewController
            destinationVC.initData(data: songData)
        }
        
    }
    
    @IBAction func btnCancelPressed(_ sender: UIButton) {
        self.dismiss(animated: true){
            showToolbarView()
        }
    }
    
    @IBAction func btnNewPlaylistPressed(_ sender: UIButton) {
        
        DispatchQueue.main.async {
            weak var pvc:UIViewController! = self.presentingViewController
            self.dismiss(animated: true)
            {
                if let nav = pvc as? BaseNavigationController {
                    //IF the presenting vc is base Nav Controller, get the visible Vc
                    nav.visibleViewController?.performSegue(withIdentifier: "goToAddToPlaylistInit", sender: nil)
                } else if let nav = pvc as? StartViewController {
                    let getMiniPlayerObj = nav.children[1] as! MiniPlayerViewController
                    getMiniPlayerObj.performSegue(withIdentifier: "goToAddToPlaylistInit", sender: nil)
                }
                else {
                    pvc.performSegue(withIdentifier: "goToAddToPlaylistInit", sender: nil)
                }
                
            }
            
        }
    }
    
    @IBAction func btnPrevPagePressed(_ sender: UIButton) {
        self.currentPage -= 1
        
        getUserPlaylistData(page: self.currentPage, isInit: false)
        playlistPageControl.currentPage = self.currentPage - 1
        switch self.currentPage {
            case _ where self.currentPage > 1:
                break
            default:
                btnPrevPage.isHidden = true
        }
        btnNextPage.isHidden = false
    }
    
    @IBAction func btnNextPagePressed(_ sender: UIButton) {
        self.currentPage += 1

        getUserPlaylistData(page: self.currentPage, isInit: false)
        playlistPageControl.currentPage = self.currentPage - 1
        switch self.currentPage {
            case _ where self.currentPage < self.playlistPages:
                break
            default:
                btnNextPage.isHidden = true
        }
        btnPrevPage.isHidden = false
    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        
        if self.playlistPages > 1 {
            if gesture.direction == UISwipeGestureRecognizer.Direction.right {
                //print("Swipe Right")
                
                let activePage = self.currentPage - 1
                
                switch activePage {
                case _ where activePage >= 1:
                    self.currentPage = activePage
                    getUserPlaylistData(page: self.currentPage, isInit: false)
                    playlistPageControl.currentPage = self.currentPage - 1
                    if activePage == 1 {
                        btnPrevPage.isHidden = true
                    }
                default:
                    btnPrevPage.isHidden = true
                }
                btnNextPage.isHidden = false
            }
            else if gesture.direction == UISwipeGestureRecognizer.Direction.left {
                //print("Swipe Left")
                
                let activePage = self.currentPage + 1
                
                switch activePage {
                case _ where activePage <= self.playlistPages:
                    self.currentPage = activePage
                    getUserPlaylistData(page: self.currentPage, isInit: false)
                    playlistPageControl.currentPage = self.currentPage - 1
                    if activePage == self.playlistPages {
                        btnNextPage.isHidden = true
                    }
                default:
                    btnNextPage.isHidden = true
                }
                btnPrevPage.isHidden = false
                
            }
        }
        
    }
    
    func configureTableView() {
        //userPlaylistTableView.rowHeight = UITableViewAutomaticDimension
        userPlaylistTableView.rowHeight = 75
        //userPlaylistTableView.estimatedRowHeight = 75
        userPlaylistTableView.separatorStyle = .none
        
    }
    
    func getUserPlaylistData(page: Int, isInit: Bool) {
        
        showProgressHud()
        
        //Send HTTP request to perform Get user playlist
        DispatchQueue.global(qos: .userInteractive).async {
            let restUrl = self.apiUrl + "/userpl/\(self.userid)?page=\(page)"
            
            self.apiServices.executePostRequestWithToken(urlToExecute: restUrl, bodyDict: nil, completion: { (jsonResponse, error) in
                
                if error != nil {
                    print("error= \(String(describing: error))")
                    DispatchQueue.main.async {
                        dismissProgressHud()
                        ToastMessageView.shared.long(self.view, txt_msg: "Server Error or Disconnected. Please try again later.")
                    }
                    
                    return
                }
                
                guard let responseDict = jsonResponse else {
                    print("error= \(String(describing: error))")
                    DispatchQueue.main.async {
                        dismissProgressHud()
                        ToastMessageView.shared.long(self.view, txt_msg: "App Error. Please try again later.")
                    }
                    
                    return
                }
                
                DispatchQueue.main.async {
                    dismissProgressHud()
                }
                
                let success = responseDict["success"] as? Bool
                if success! {
                    self.playlistPages = responseDict["npage"] as! Int
                    
                    if let dataResult = responseDict["data"] as? NSArray {
                        self.playlistData = dataResult
                        let noOfPlaylist = self.playlistData.count
                        
                        if noOfPlaylist > 0 {
                            DispatchQueue.main.async {
                                self.userPlaylistTableView.reloadData()
                                
                                if isInit {
                                    let numberOfPages = self.playlistPages
                                    self.playlistPageControl.numberOfPages = numberOfPages
                                    
                                    switch numberOfPages {
                                    case _ where numberOfPages > 1:
                                        self.btnNextPage.isHidden = false
                                        self.playlistPageControl.isHidden = false
                                    default:
                                        self.btnNextPage.isHidden = true
                                        self.playlistPageControl.isHidden = true
                                    }
                                }
                                
                                
                            }
                        }
                        //print("No Of Playlist: \(String(describing: noOfPlaylist))")
                    }
                    
                } else {
                    let message = responseDict["message"] as? String
                    print(message!)
                }
                
            })
        }
        
    }
    
    func addTapGestureRecognizer() {
        
        let gestureRecognizer = UITapGestureRecognizer(target: self,action: #selector(tapGestureOutsidePopView))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func tapGestureOutsidePopView() {
        self.dismiss(animated: true){
            showToolbarView()
        }
    }
}

extension AddToPlaylistViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playlistData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let tablecell = tableView.dequeueReusableCell(withIdentifier: "UserPlaylistPopUpCell", for: indexPath) as? UserPlaylistPopUpTableViewCell else {
            return UITableViewCell()
        }
        let playlist = self.playlistData[indexPath.row] as? NSDictionary
        
        let playlistName = playlist!["playlistname"] as? String
        let noOfSongs = playlist!["noofsongs"] as? Int
        let albumImageList = playlist!["albumdetails"] as? NSArray
        let countAlbumList = albumImageList!.count
        
        //init image
        tablecell.initImage()
        
        switch countAlbumList {
        case 1:
            let albumImagePath = albumImageList![0] as? String
            /*
            if let albumImageURL = URL(string: albumImagePath!) {
                DispatchQueue.global(qos: .userInteractive).async {
                    let dataImage = try? Data(contentsOf: albumImageURL)
                    if let data = dataImage {
                        let albumImage = UIImage(data: data)
                        DispatchQueue.main.async {
                            tablecell.albumImagePl1.image = albumImage
                            //tablecell.albumImagePl1.layer.cornerRadius = 5
                            //tablecell.albumImagePl1.clipsToBounds = true
                        }
                    }
                }
            }
            */
            tablecell.albumImagePl1.loadImageUsingUrlString(urlString: albumImagePath)
            
        case 2:
            let albumImagePath = albumImageList![0] as? String
            tablecell.albumImagePl1.loadImageUsingUrlString(urlString: albumImagePath)
            /*
            if let albumImageURL = URL(string: albumImagePath!) {
                DispatchQueue.global(qos: .userInteractive).async {
                    let dataImage = try? Data(contentsOf: albumImageURL)
                    if let data = dataImage {
                        let albumImage = UIImage(data: data)
                        DispatchQueue.main.async {
                            tablecell.albumImagePl1.image = albumImage
                            //tablecell.albumImagePl1.layer.cornerRadius = 5
                            //tablecell.albumImagePl1.clipsToBounds = true
                        }
                    }
                }
            }
            */
            
            let albumImagePath2 = albumImageList![1] as? String
            tablecell.albumImagePl2.loadImageUsingUrlString(urlString: albumImagePath2)
            /*
            if let albumImageURL2 = URL(string: albumImagePath2!) {
                DispatchQueue.global(qos: .userInteractive).async {
                    let dataImage = try? Data(contentsOf: albumImageURL2)
                    if let data = dataImage {
                        let albumImage = UIImage(data: data)
                        DispatchQueue.main.async {
                            tablecell.albumImagePl2.image = albumImage
                            //tablecell.albumImagePl2.layer.cornerRadius = 5
                            //tablecell.albumImagePl2.clipsToBounds = true
                        }
                    }
                }
            }
            */
        case 3:
            let albumImagePath = albumImageList![0] as? String
            tablecell.albumImagePl1.loadImageUsingUrlString(urlString: albumImagePath)
            /*
            if let albumImageURL = URL(string: albumImagePath!) {
                DispatchQueue.global(qos: .userInteractive).async {
                    let dataImage = try? Data(contentsOf: albumImageURL)
                    if let data = dataImage {
                        let albumImage = UIImage(data: data)
                        DispatchQueue.main.async {
                            tablecell.albumImagePl1.image = albumImage
                            //tablecell.albumImagePl1.layer.cornerRadius = 5
                            //tablecell.albumImagePl1.clipsToBounds = true
                        }
                    }
                }
            }
            */
            let albumImagePath2 = albumImageList![1] as? String
            tablecell.albumImagePl2.loadImageUsingUrlString(urlString: albumImagePath2)
            /*
            if let albumImageURL2 = URL(string: albumImagePath2!) {
                DispatchQueue.global(qos: .userInteractive).async {
                    let dataImage = try? Data(contentsOf: albumImageURL2)
                    if let data = dataImage {
                        let albumImage = UIImage(data: data)
                        DispatchQueue.main.async {
                            tablecell.albumImagePl2.image = albumImage
                            //tablecell.albumImagePl2.layer.cornerRadius = 5
                            //tablecell.albumImagePl2.clipsToBounds = true
                        }
                    }
                }
            }
            */
            let albumImagePath3 = albumImageList![2] as? String
            tablecell.albumImagePl3.loadImageUsingUrlString(urlString: albumImagePath3)
            /*
            if let albumImageURL3 = URL(string: albumImagePath3!) {
                DispatchQueue.global(qos: .userInteractive).async {
                    let dataImage = try? Data(contentsOf: albumImageURL3)
                    if let data = dataImage {
                        let albumImage = UIImage(data: data)
                        DispatchQueue.main.async {
                            tablecell.albumImagePl3.image = albumImage
                            //tablecell.albumImagePl3.layer.cornerRadius = 5
                            //tablecell.albumImagePl3.clipsToBounds = true
                        }
                    }
                }
            }
            */
        case 4:
            let albumImagePath = albumImageList![0] as? String
            tablecell.albumImagePl1.loadImageUsingUrlString(urlString: albumImagePath)
            /*
            if let albumImageURL = URL(string: albumImagePath!) {
                DispatchQueue.global(qos: .userInteractive).async {
                    let dataImage = try? Data(contentsOf: albumImageURL)
                    if let data = dataImage {
                        let albumImage = UIImage(data: data)
                        DispatchQueue.main.async {
                            tablecell.albumImagePl1.image = albumImage
                            //tablecell.albumImagePl1.layer.cornerRadius = 5
                            //tablecell.albumImagePl1.clipsToBounds = true
                        }
                    }
                }
            }
            */
            let albumImagePath2 = albumImageList![1] as? String
            tablecell.albumImagePl2.loadImageUsingUrlString(urlString: albumImagePath2)
            /*
            if let albumImageURL2 = URL(string: albumImagePath2!) {
                DispatchQueue.global(qos: .userInteractive).async {
                    let dataImage = try? Data(contentsOf: albumImageURL2)
                    if let data = dataImage {
                        let albumImage = UIImage(data: data)
                        DispatchQueue.main.async {
                            tablecell.albumImagePl2.image = albumImage
                            //tablecell.albumImagePl2.layer.cornerRadius = 5
                            //tablecell.albumImagePl2.clipsToBounds = true
                        }
                    }
                }
            }
            */
            let albumImagePath3 = albumImageList![2] as? String
            tablecell.albumImagePl3.loadImageUsingUrlString(urlString: albumImagePath3)
            /*
            if let albumImageURL3 = URL(string: albumImagePath3!) {
                DispatchQueue.global(qos: .userInteractive).async {
                    let dataImage = try? Data(contentsOf: albumImageURL3)
                    if let data = dataImage {
                        let albumImage = UIImage(data: data)
                        DispatchQueue.main.async {
                            tablecell.albumImagePl3.image = albumImage
                            //tablecell.albumImagePl3.layer.cornerRadius = 5
                            //tablecell.albumImagePl3.clipsToBounds = true
                        }
                    }
                }
            }
            */
            let albumImagePath4 = albumImageList![3] as? String
            tablecell.albumImagePl4.loadImageUsingUrlString(urlString: albumImagePath4)
            /*
            if let albumImageURL4 = URL(string: albumImagePath4!) {
                DispatchQueue.global(qos: .userInteractive).async {
                    let dataImage = try? Data(contentsOf: albumImageURL4)
                    if let data = dataImage {
                        let albumImage = UIImage(data: data)
                        DispatchQueue.main.async {
                            tablecell.albumImagePl4.image = albumImage
                            //tablecell.albumImagePl4.layer.cornerRadius = 5
                            //tablecell.albumImagePl4.clipsToBounds = true
                        }
                    }
                }
            }
            */
        case _ where countAlbumList > 4:
            let albumImagePath = albumImageList![0] as? String
            tablecell.albumImagePl1.loadImageUsingUrlString(urlString: albumImagePath)
            /*
            if let albumImageURL = URL(string: albumImagePath!) {
                DispatchQueue.global(qos: .userInteractive).async {
                    let dataImage = try? Data(contentsOf: albumImageURL)
                    if let data = dataImage {
                        let albumImage = UIImage(data: data)
                        DispatchQueue.main.async {
                            tablecell.albumImagePl1.image = albumImage
                            //tablecell.albumImagePl1.layer.cornerRadius = 5
                            //tablecell.albumImagePl1.clipsToBounds = true
                        }
                    }
                }
            }
            */
            let albumImagePath2 = albumImageList![1] as? String
            tablecell.albumImagePl2.loadImageUsingUrlString(urlString: albumImagePath2)
            /*
            if let albumImageURL2 = URL(string: albumImagePath2!) {
                DispatchQueue.global(qos: .userInteractive).async {
                    let dataImage = try? Data(contentsOf: albumImageURL2)
                    if let data = dataImage {
                        let albumImage = UIImage(data: data)
                        DispatchQueue.main.async {
                            tablecell.albumImagePl2.image = albumImage
                            //tablecell.albumImagePl2.layer.cornerRadius = 5
                            //tablecell.albumImagePl2.clipsToBounds = true
                        }
                    }
                }
            }
            */
            let albumImagePath3 = albumImageList![2] as? String
            tablecell.albumImagePl3.loadImageUsingUrlString(urlString: albumImagePath3)
            /*
            if let albumImageURL3 = URL(string: albumImagePath3!) {
                DispatchQueue.global(qos: .userInteractive).async {
                    let dataImage = try? Data(contentsOf: albumImageURL3)
                    if let data = dataImage {
                        let albumImage = UIImage(data: data)
                        DispatchQueue.main.async {
                            tablecell.albumImagePl3.image = albumImage
                            //tablecell.albumImagePl3.layer.cornerRadius = 5
                            //tablecell.albumImagePl3.clipsToBounds = true
                        }
                    }
                }
            }
            */
            let albumImagePath4 = albumImageList![3] as? String
            tablecell.albumImagePl4.loadImageUsingUrlString(urlString: albumImagePath4)
            /*
            if let albumImageURL4 = URL(string: albumImagePath4!) {
                DispatchQueue.global(qos: .userInteractive).async {
                    let dataImage = try? Data(contentsOf: albumImageURL4)
                    if let data = dataImage {
                        let albumImage = UIImage(data: data)
                        DispatchQueue.main.async {
                            tablecell.albumImagePl4.image = albumImage
                            //tablecell.albumImagePl4.layer.cornerRadius = 5
                           // tablecell.albumImagePl4.clipsToBounds = true
                        }
                    }
                }
            }
            */
        default:
            break
        }
        tablecell.playlistNameLabel.text = playlistName!
        tablecell.noOfSongsLabel.text = "\(noOfSongs!) Songs"
        
        //tablecell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapUserPlaylistCell(_:))))
        
        return tablecell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /*
        print("Got clicked on Userplaylist index: \(indexPath)!")
        print("Song name: \(String(describing: self.songData["songname"]))")
        */
        let userPlaylist = playlistData[indexPath.row] as? NSDictionary
        let playlistId = userPlaylist!["_id"] as? String
        let playlistName = userPlaylist!["playlistname"] as? String
        
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            //Send HTTP request to perform add song
            let addSongToPlaylistUrl = self.apiUrl + "/playlist/\(playlistId!)"
            
            let postString = ["songid": self.songData["_id"]!, "userid": self.userid] as NSDictionary
            
            self.apiServices.executePostRequestWithToken(urlToExecute: addSongToPlaylistUrl, bodyDict: postString) { (jsonResponse, error) in
                //error
                
                if error != nil {
                    print("error= \(String(describing: error))")
                    DispatchQueue.main.async {
                        dismissProgressHud()
                    }
                    //Display Error Alert
                    failedAlert(title: "Server Error or Disconnected", message: "Could not successfully perform the request. Please try again later !", presentingVC: self)
                    
                    return
                }
                
                guard let responseDict = jsonResponse else {
                    print("error= \(String(describing: error))")
                    DispatchQueue.main.async {
                        dismissProgressHud()
                    }
                    //Display Error Alert
                    failedAlert(title: "App Error", message: "Could not successfully perform the request. Please try again later !", presentingVC: self)
                    
                    return
                }
                
                DispatchQueue.main.async {
                    dismissProgressHud()
                }
                
                let success = responseDict["success"] as? Bool
                let message = responseDict["message"] as? String
                
                if success! {
                    
                    //Success Alert
                    successAlert(title: "Success", message: message! + " \(playlistName!)", presentingVC: self, closeParent: true)
                    
                } else {
                    
                    //Error Alert
                    failedAlert(title: "Result Error", message: message!, presentingVC: self)
                }
            }

        }

    }
    
}

extension AddToPlaylistViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        return (touch.view === self.view)
    }
}
