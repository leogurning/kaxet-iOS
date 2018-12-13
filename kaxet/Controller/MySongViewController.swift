//
//  MySongViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 28/11/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class MySongViewController: UIViewController {
    
    let apiServices = RestAPIServices()
    
    let apiUrl = APPURL.BaseURL
    let hostUrl = APPURL.Domain
    
    private var userid: String = ""
    private var accessToken: String = ""
    private var loadSongsErr: Bool = false
    private var songs: NSArray = []
    private var currentPage: Int = 1
    private var maxPages: Int = 1
    private var refreshControl: UIRefreshControl!
    private var keyboardActive: Bool = false
    
    private var userPlaylist: NSArray = []
    private var playlistNPages: Int = 0
    var songDataForSegue: NSDictionary = [:]
    private var loadUserPlaylistDone: Bool = false
    private var loadSongDone: Bool = false
    private var loadUserPlaylistErr: Bool = false
    
    @IBOutlet weak var searchIconView: UIView!
    @IBOutlet weak var searchIconImage: UIImageView!
    @IBOutlet weak var songSearchText: UITextField!
    @IBOutlet weak var songListTableView: UITableView!
    @IBOutlet weak var btnPrevPage: UIButton!
    @IBOutlet weak var btnNextPage: UIButton!
    @IBOutlet weak var songPageControl: UIPageControl!
    @IBOutlet var noDataView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        accessToken = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Token)!
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
        
        songSearchText.delegate = self
        songListTableView.delegate = self
        songListTableView.dataSource = self
        songListTableView.register(UINib(nibName: "SongListTableViewCell", bundle: nil), forCellReuseIdentifier: "SongListCell")
        configureSongTableView()
        addTapGesture()
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        songListTableView.addSubview(refreshControl)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture(gesture:)))
        swipeLeft.direction = .left
        songListTableView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture(gesture:)))
        swipeRight.direction = .right
        songListTableView.addGestureRecognizer(swipeRight)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        keyboardActive = false
        resetPageNavigation()
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            self.getUserPlaylistData(page: 1)
        }
    }
    
    @objc func refresh(_ sender: Any) {
        //  your code to refresh tableView
        keyboardActive = false
        resetPageNavigation()
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            self.getUserPlaylistData(page: 1)
        }
    }
    
    @IBAction func btnPrevPagePressed(_ sender: UIButton) {
        
        self.currentPage -= 1
        showProgressHud()
        self.loadUserPlaylistDone = true
        self.loadSongDone = false
        getSongsBySearchText(page: self.currentPage, isInit: false)
        songPageControl.currentPage = self.currentPage - 1
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
        showProgressHud()
        self.loadUserPlaylistDone = true
        self.loadSongDone = false
        getSongsBySearchText(page: self.currentPage, isInit: false)
        songPageControl.currentPage = self.currentPage - 1
        switch self.currentPage {
        case _ where self.currentPage < self.maxPages:
            break
        default:
            btnNextPage.isHidden = true
        }
        btnPrevPage.isHidden = false
    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        
        if self.maxPages > 1 {
            if gesture.direction == UISwipeGestureRecognizer.Direction.right {
                //print("Swipe Right")
                
                let activePage = self.currentPage - 1
                
                switch activePage {
                case _ where activePage >= 1:
                    self.currentPage = activePage
                    showProgressHud()
                    self.loadUserPlaylistDone = true
                    self.loadSongDone = false
                    getSongsBySearchText(page: self.currentPage, isInit: false)
                    songPageControl.currentPage = self.currentPage - 1
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
                case _ where activePage <= self.maxPages:
                    self.currentPage = activePage
                    showProgressHud()
                    self.loadUserPlaylistDone = true
                    self.loadSongDone = false
                    getSongsBySearchText(page: self.currentPage, isInit: false)
                    songPageControl.currentPage = self.currentPage - 1
                    if activePage == self.maxPages {
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
        hideToolbarView()
        switch segue.identifier {
        case "goToAddToPlaylistInit":
            // Create a new variable to store the instance of AddToPlaylistInitViewController
            let destinationVC = segue.destination as! AddToPlaylistInitViewController
            destinationVC.initData(data: songDataForSegue)
        case "goToAddToPlaylist":
            // Create a new variable to store the instance of AddToPlaylistViewController
            let destinationVC = segue.destination as! AddToPlaylistViewController
            destinationVC.initData(song: songDataForSegue, playlist: userPlaylist, npages: playlistNPages)
        case "goToBuySong":
            // Create a new variable to store the instance of BuySongViewController
            let destinationVC = segue.destination as! BuySongViewController
            destinationVC.delegate = self
            destinationVC.songData = songDataForSegue
        default:
            return
        }
    }
 
    
    func resetPageNavigation() {
        self.currentPage = 1
        btnNextPage.isHidden = true
        btnPrevPage.isHidden = true
        self.songPageControl.isHidden = true
        self.songPageControl.currentPage = 0
    }
    
    func configureSongTableView() {
        //genreSongsTableView.rowHeight = UITableViewAutomaticDimension
        //genreSongsTableView.estimatedRowHeight = 70
        songListTableView.rowHeight = 60
        songListTableView.separatorStyle = .none
        songListTableView.tableFooterView = UIView(frame: CGRect.zero)
        
    }
    
    func getSongsBySearchText(page: Int, isInit: Bool) {
        
        //showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            DispatchQueue.main.async {
                let searchString = self.songSearchText.text
                
                //Send HTTP request to perform Get Top Songs
                let restUrl = self.apiUrl + "/songpurchaseagg/\(self.userid)?page=\(page)"
                
                let postString = ["status": "STSAPV", "rptype": "ALL", "songname": searchString!] as NSDictionary
                
                self.apiServices.executePostRequestWithToken(urlToExecute: restUrl, bodyDict: postString, completion: { (jsonResponse, error) in
                    //code
                    
                    if (error != nil) {
                        print("error= \(String(describing: error))")
                        self.loadUserPlaylistDone = true
                        self.loadSongDone = true
                        self.closeProgressHud()
                        DispatchQueue.main.async {
                            ToastMessageView.shared.long(self.view, txt_msg: "Server Error or Disconnected. Please try again later.")
                        }
                        
                        return
                    }
                    
                    guard let responseDict = jsonResponse else {
                        print("error= \(String(describing: error))")
                        self.loadUserPlaylistDone = true
                        self.loadSongDone = true
                        self.closeProgressHud()
                        DispatchQueue.main.async {
                            ToastMessageView.shared.long(self.view, txt_msg: "App Error. Please try again later.")
                        }
                        
                        return
                    }
                    
                    let success = responseDict["success"] as? Bool
                    if success! {
                        //print("Successfully populated !")
                        if let dataResult = responseDict["data"] as? NSArray {
                            self.songs = dataResult
                            let resultNPages = responseDict["npage"] as! Int
                            self.maxPages = resultNPages
                            self.updateSongid()
                            
                            if self.songs.count > 0 {
                                DispatchQueue.main.async {
                                    if isInit {
                                        
                                        switch resultNPages {
                                        case _ where resultNPages > 1:
                                            self.btnNextPage.isHidden = false
                                            self.songPageControl.isHidden = false
                                            self.songPageControl.numberOfPages = resultNPages
                                        default:
                                            self.btnNextPage.isHidden = true
                                            self.songPageControl.isHidden = true
                                        }
                                        
                                        //self.genreSongsPageControl.isHidden = !(resultNPages > 1)
                                        self.songListTableView.backgroundView = nil
                                    }
                                    self.songListTableView.reloadData()
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.songPageControl.isHidden = true
                                    self.btnPrevPage.isHidden = true
                                    self.btnNextPage.isHidden = true
                                    self.songListTableView.backgroundView = self.noDataView
                                    
                                    self.songListTableView.reloadData()
                                }
                            }
                            
                        }
                        self.loadSongDone = true
                        self.closeProgressHud()
                    } else {
                        let message = responseDict["message"] as? String
                        DispatchQueue.main.async {
                            self.songPageControl.isHidden = true
                            self.btnPrevPage.isHidden = true
                            self.btnNextPage.isHidden = true
                            //self.genreSongsTableView.backgroundView = self.noDataView
                            self.songListTableView.reloadData()
                            ToastMessageView.shared.long(self.view, txt_msg: message!)
                        }

                        print(message!)
                        self.loadSongDone = true
                        self.closeProgressHud()
                    }
                })
            }
        }
    }
    
    private func updateSongid() {
        
        if songs.count > 0 {
            for i in 0..<songs.count {
                let songdata = songs[i] as! NSMutableDictionary
                let songid = songdata["songid"] as? String
                let songname = songdata["song"] as? String
                let songfile = songdata["songfile"] as? String
                let songprvw = songdata["songprvw"] as? String
                songdata.setValue(songid, forKey: "_id")
                songdata.setValue(songfile, forKey: "songfilepath")
                songdata.setValue(songprvw, forKey: "songprvwpath")
                songdata.setValue("Y", forKey: "pcsflag")
                songdata.setValue(songname, forKey: "songname")
            }
        }
        
  
        
    }
    func getUserPlaylistData(page: Int) {
        
        self.loadUserPlaylistDone = false
        self.loadSongDone = false
        
        //Send HTTP request to get playlist
        let strUrl = apiUrl + "/userpl/\(userid)?page=\(page)"
        
        apiServices.executePostRequestWithToken(urlToExecute: strUrl, bodyDict: nil) { (jsonResponse, error) in
            
            if error != nil {
                print("error= \(String(describing: error))")
                self.loadUserPlaylistDone = true
                self.loadSongDone = true
                self.closeProgressHud()
                DispatchQueue.main.async {
                    ToastMessageView.shared.long(self.view, txt_msg: "Server Error or Disconnected. Please try again later.")
                }
                
                return
            }
            
            guard let responseDict = jsonResponse else {
                print("error= \(String(describing: error))")
                self.loadUserPlaylistDone = true
                self.loadSongDone = true
                self.closeProgressHud()
                DispatchQueue.main.async {
                    ToastMessageView.shared.long(self.view, txt_msg: "App Error. Please try again later.")
                }
                
                return
            }
            
            let success = responseDict["success"] as? Bool
            if success! {
                
                self.playlistNPages = responseDict["npage"] as! Int
                if let dataResult = responseDict["data"] as? NSArray {
                    self.userPlaylist = dataResult
                    
                    self.getSongsBySearchText(page: 1, isInit: true)
                    DispatchQueue.main.async {
                        self.resetPageNavigation()
                        self.configureSongTableView()
                    }
                    
                }
                
            } else {
                let message = responseDict["message"] as? String
                print(message!)
                if let expToken = responseDict["errcode"] as? String {
                    if expToken == "exp-token" {
                        self.loadUserPlaylistErr = true
                    }
                }
            }
            
            self.loadUserPlaylistDone = true
            self.closeProgressHud()
            
        }
        
    }
    
    func addTapGesture() {
        
        searchIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSearchIconView(_:))))
        searchIconImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSearchIconView(_:))))
        
        let tapOnTableview: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapRemoveKeyboard(_:)))
        tapOnTableview.cancelsTouchesInView = false
        self.songListTableView.addGestureRecognizer(tapOnTableview)
    }
    
    @objc func tapRemoveKeyboard(_ sender: UITapGestureRecognizer) {
        keyboardActive = false
        songSearchText.resignFirstResponder()
        
    }
    
    @objc func tapSearchIconView(_ sender: UITapGestureRecognizer) {
        
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            self.getUserPlaylistData(page: 1)
        }
        songSearchText.endEditing(true)
        
    }
    
    private func showMiniPlayer(song: NSDictionary, songUrl: URL?, plistName: String?) {
        goShowMiniPlayer(presentingVc: self, song: song, songUrl: songUrl, plistName: plistName)
    }
    
    private func addToPlaylist(data: NSDictionary) {
        self.songDataForSegue = data
        
        if self.userPlaylist.count <= 0 {
            self.performSegue(withIdentifier: "goToAddToPlaylistInit", sender: self)
        } else {
            self.performSegue(withIdentifier: "goToAddToPlaylist", sender: self)
        }
    }
    
    private func buySong(data: NSDictionary) {
        self.songDataForSegue = data
        self.performSegue(withIdentifier: "goToBuySong", sender: self)
    }
    
    func closeProgressHud() {
        
        if ( loadUserPlaylistDone && loadSongDone) {
            
            DispatchQueue.main.async {
                dismissProgressHud()
                self.refreshControl.endRefreshing()
            }
            
            goToLogout()
        }
        
    }
    
    private func goToLogout() {
        
        if ( loadUserPlaylistErr ) {
            
            logout(presentingVc: self)
        }
        
    }
}

extension MySongViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let searchresulttablecell = tableView.dequeueReusableCell(withIdentifier: "SongListCell", for: indexPath) as? SongListTableViewCell else {
            return UITableViewCell()
        }
        
        guard let songData = self.songs[indexPath.row] as? NSDictionary else {
            return UITableViewCell()
        }
        
        searchresulttablecell.initData(data: songData)

        searchresulttablecell.playOrBuyTapAction = {
            
            let songcode = songData["_id"] as? String
            let songDownloaded = isSongDownloaded(songcode: songcode)
            if songDownloaded {
                let songPathURL = getSongDownloadedUrl(songcode: songcode)
                self.showMiniPlayer(song: songData, songUrl: songPathURL, plistName: nil)
            } else {
                self.showMiniPlayer(song: songData,songUrl: nil, plistName: nil)
            }
                          
        }
        
        searchresulttablecell.addToPlaylistTapAction = {
            // implement your logic here, e.g. call preformSegue()
            self.addToPlaylist(data: songData)
        }
        
        searchresulttablecell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapTableSongCell(_:))))
        
        return searchresulttablecell
        
    }
    
    @objc func tapTableSongCell(_ sender: UITapGestureRecognizer) {
        
        let location = sender.location(in: self.songListTableView)
        let indexPath = self.songListTableView.indexPathForRow(at: location)
        
        if keyboardActive {
            self.songSearchText.resignFirstResponder()
            keyboardActive = false
        } else {
            if let index = indexPath {
                let selectedSong = songs[index.row] as? NSDictionary
                
                let songcode = selectedSong!["_id"] as? String
                let songDownloaded = isSongDownloaded(songcode: songcode)
                if songDownloaded {
                    let songPathURL = getSongDownloadedUrl(songcode: songcode)
                    self.showMiniPlayer(song: selectedSong!, songUrl: songPathURL, plistName: nil)
                } else {
                    self.showMiniPlayer(song: selectedSong!,songUrl: nil, plistName: nil)
                }
                
            }
        }
        
    }
    
}

extension MySongViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        keyboardActive = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            self.getUserPlaylistData(page: 1)
        }
        keyboardActive = false
        textField.endEditing(true)
        return true
        
    }
}

extension MySongViewController: BuySongViewControllerDelegate {
    func refreshData(_ song: Any?) {
        //  your code to refresh tableView
        self.keyboardActive = false
        showProgressHud()
        DispatchQueue.main.asyncAfter(deadline: .now() + APPCONSTANT.refreshDelay) {
            
            self.resetPageNavigation()
            DispatchQueue.global(qos: .userInteractive).async {
                self.getUserPlaylistData(page: 1)
            }
        }

    }
    
    
}
