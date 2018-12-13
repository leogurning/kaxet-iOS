//
//  PlaylistViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 02/12/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class PlaylistViewController: UIViewController {

    let apiServices = RestAPIServices()
    let apiUrl = APPURL.BaseURL
    let hostUrl = APPURL.Domain
    
    var accessToken: String = ""
    var userid: String = ""
    
    private var playlistForSegue:NSDictionary = [:]
    
    private var songData: NSDictionary = [:]
    private var playlistData: NSArray = []
    private var playlistPages: Int = 0
    private var currentPage: Int = 1
    private var refreshControl: UIRefreshControl!
    
    @IBOutlet weak var buttonAddView: UIView!
    @IBOutlet weak var addPlaylistView: UIView!
    @IBOutlet weak var playlistTableView: UITableView!
    @IBOutlet weak var btnPrevPage: UIButton!
    @IBOutlet weak var btnNextPage: UIButton!
    @IBOutlet weak var playlistPageControl: UIPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        accessToken = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Token)!
        
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
        playlistTableView.delegate = self
        playlistTableView.dataSource = self
        configurePlaylistTableView()
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        playlistTableView.addSubview(refreshControl)
        
        addTapGesture()
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture(gesture:)))
        swipeLeft.direction = .left
        playlistTableView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture(gesture:)))
        swipeRight.direction = .right
        playlistTableView.addGestureRecognizer(swipeRight)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        resetPageNavigation()
        self.getUserPlaylistData(page: 1, isInit: true)
    }

    @objc func refresh(_ sender: Any) {
        //  your code to refresh tableView
        resetPageNavigation()
        self.getUserPlaylistData(page: 1, isInit: true)

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
    /*
    // MARK: - Navigation
     */
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "goToAddUserPlaylist" {
            let destinationVC = segue.destination as! AddUserPlaylistViewController
            destinationVC.delegate = self
        }
        
        switch segue.identifier {
        case "goToAddUserPlaylist":
            let destinationVC = segue.destination as! AddUserPlaylistViewController
            destinationVC.delegate = self
        case "goToPlaylistSong":
            let destinationVC = segue.destination as! PlaylistSongViewController
            destinationVC.initData(data: playlistForSegue)
        default:
            break
        }
    }
 
    
    func resetPageNavigation() {
        self.currentPage = 1
        btnNextPage.isHidden = true
        btnPrevPage.isHidden = true
        self.playlistPageControl.isHidden = true
        self.playlistPageControl.currentPage = 0
    }
    
    func configurePlaylistTableView() {
        //genreSongsTableView.rowHeight = UITableViewAutomaticDimension
        //genreSongsTableView.estimatedRowHeight = 70
        playlistTableView.rowHeight = 85
        playlistTableView.separatorStyle = .none
        playlistTableView.tableFooterView = UIView(frame: CGRect.zero)
        
    }
    
    func addTapGesture() {
        
        addPlaylistView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapAddplaylistView(_:))))
        buttonAddView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapAddplaylistView(_:))))
        
    }
    
    @objc func tapAddplaylistView(_ sender: UITapGestureRecognizer) {
        
        self.performSegue(withIdentifier: "goToAddUserPlaylist", sender: self)
        
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
                        self.refreshControl.endRefreshing()
                        ToastMessageView.shared.long(self.view, txt_msg: "Server Error or Disconnected. Please try again later.")
                    }
                    
                    return
                }
                
                guard let responseDict = jsonResponse else {
                    print("error= \(String(describing: error))")
                    DispatchQueue.main.async {
                        dismissProgressHud()
                        self.refreshControl.endRefreshing()
                        ToastMessageView.shared.long(self.view, txt_msg: "App Error. Please try again later.")
                    }
                    
                    return
                }
                
                DispatchQueue.main.async {
                    dismissProgressHud()
                    self.refreshControl.endRefreshing()
                }
                
                let success = responseDict["success"] as? Bool
                if success! {
                    self.playlistPages = responseDict["npage"] as! Int
                    
                    if let dataResult = responseDict["data"] as? NSArray {
                        self.playlistData = dataResult
                        let noOfPlaylist = self.playlistData.count
                        
                        if noOfPlaylist > 0 {
                            DispatchQueue.main.async {
                                self.playlistTableView.reloadData()
                                
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
}

extension PlaylistViewController: UITableViewDelegate, UITableViewDataSource {
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
            tablecell.albumImagePl1.loadImageUsingUrlString(urlString: albumImagePath)
            
        case 2:
            let albumImagePath = albumImageList![0] as? String
            tablecell.albumImagePl1.loadImageUsingUrlString(urlString: albumImagePath)
            
            let albumImagePath2 = albumImageList![1] as? String
            tablecell.albumImagePl2.loadImageUsingUrlString(urlString: albumImagePath2)

        case 3:
            let albumImagePath = albumImageList![0] as? String
            tablecell.albumImagePl1.loadImageUsingUrlString(urlString: albumImagePath)
            
            let albumImagePath2 = albumImageList![1] as? String
            tablecell.albumImagePl2.loadImageUsingUrlString(urlString: albumImagePath2)
            
            let albumImagePath3 = albumImageList![2] as? String
            tablecell.albumImagePl3.loadImageUsingUrlString(urlString: albumImagePath3)
            
        case 4:
            let albumImagePath = albumImageList![0] as? String
            tablecell.albumImagePl1.loadImageUsingUrlString(urlString: albumImagePath)
            
            let albumImagePath2 = albumImageList![1] as? String
            tablecell.albumImagePl2.loadImageUsingUrlString(urlString: albumImagePath2)
            
            let albumImagePath3 = albumImageList![2] as? String
            tablecell.albumImagePl3.loadImageUsingUrlString(urlString: albumImagePath3)
            
            let albumImagePath4 = albumImageList![3] as? String
            tablecell.albumImagePl4.loadImageUsingUrlString(urlString: albumImagePath4)
            
        case _ where countAlbumList > 4:
            let albumImagePath = albumImageList![0] as? String
            tablecell.albumImagePl1.loadImageUsingUrlString(urlString: albumImagePath)
            
            let albumImagePath2 = albumImageList![1] as? String
            tablecell.albumImagePl2.loadImageUsingUrlString(urlString: albumImagePath2)
            
            let albumImagePath3 = albumImageList![2] as? String
            tablecell.albumImagePl3.loadImageUsingUrlString(urlString: albumImagePath3)
            
            let albumImagePath4 = albumImageList![3] as? String
            tablecell.albumImagePl4.loadImageUsingUrlString(urlString: albumImagePath4)
            
        default:
            break
        }
        tablecell.playlistNameLabel.text = playlistName!
        tablecell.noOfSongsLabel.text = "\(noOfSongs!) Songs"
        tablecell.selectionStyle = .none
        //tablecell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapUserPlaylistCell(_:))))
        
        return tablecell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedPl = playlistData[indexPath.row] as? NSDictionary
        self.playlistForSegue = selectedPl!
        /*
        let plName = selectedPl!["_id"] as? String
        print("Playlist id: \(plName ?? "No data")")
        */
        performSegue(withIdentifier: "goToPlaylistSong", sender: self)
    }
    
}

extension PlaylistViewController: AddUserPlaylistDelegate {
    func RefreshPlaylist() {
        resetPageNavigation()
        self.getUserPlaylistData(page: 1, isInit: true)
    }
    
    
}
