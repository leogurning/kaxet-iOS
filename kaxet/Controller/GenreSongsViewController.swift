//
//  GenreSongsViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 20/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class GenreSongsViewController: UIViewController {

    let apiServices = RestAPIServices()
    
    let apiUrl = APPURL.BaseURL
    let hostUrl = APPURL.Domain
    
    var accessToken: String = ""
    var userid: String = ""
    
    private var userPlaylist: NSArray = []
    private var playlistNPages: Int = 0
    var songDataForSegue: NSDictionary = [:]
    private var loadUserPlaylistDone: Bool = false
    private var loadSongDone:Bool = false
    private var loadUserPlaylistErr: Bool = false
    /*
    var miniPlayerVc: MiniPlayerViewController?
    var miniPlayerView: UIView?
    */
    private var genreSongs: NSArray = []
    private var currentPage: Int = 1
    private var maxPages: Int = 1
    private var refreshControl: UIRefreshControl!
    
    @IBOutlet var noDataView: UIView!
    
    @IBOutlet weak var btnPrevPage: UIButton!
    @IBOutlet weak var btnNextPage: UIButton!
    
    @IBOutlet weak var genreSongsTableView: UITableView!
    @IBOutlet weak var genreSongsPageControl: UIPageControl!
    private var genreCode: NSDictionary = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        genreSongsTableView.delegate = self
        genreSongsTableView.dataSource = self
        
        accessToken = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Token)!
        
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
        
        //let code = self.genreCode["code"] as? String
        let value = self.genreCode["value"] as? String
        
        self.title = value!
        btnNextPage.isHidden = true
        btnPrevPage.isHidden = true
        self.genreSongsPageControl.isHidden = true
        
        /*
        print("Genre Code: \(code!)")
        print("Genre Value: \(value!)")
        */
        genreSongsTableView.register(UINib(nibName: "SongListTableViewCell", bundle: nil), forCellReuseIdentifier: "SongListCell")
        /*
        getSongsByGenreResult(page: 1, isInit: true)
        */
        configureTableView()
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        genreSongsTableView.addSubview(refreshControl)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture(gesture:)))
        swipeLeft.direction = .left
        genreSongsTableView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture(gesture:)))
        swipeRight.direction = .right
        genreSongsTableView.addGestureRecognizer(swipeRight)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            self.getUserPlaylistData(page: 1)
        }
        
    }
    
    @objc func refresh(_ sender: Any) {
        //  your code to refresh tableView
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            self.getUserPlaylistData(page: 1)
        }
    }
    
    func initData(data: NSDictionary) {
        self.genreCode = data
    }
    
    func configureTableView() {
        //genreSongsTableView.rowHeight = UITableViewAutomaticDimension
        genreSongsTableView.rowHeight = 60
        //genreSongsTableView.estimatedRowHeight = 70
        genreSongsTableView.separatorStyle = .none
        genreSongsTableView.tableFooterView = UIView(frame: CGRect.zero)

    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    */
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
 
    @IBAction func btnPrevPagePressed(_ sender: UIButton) {
        
        self.currentPage -= 1
        self.loadUserPlaylistDone = true
        self.loadSongDone = false
        showProgressHud()
        getSongsByGenreResult(page: self.currentPage, isInit: false)
        genreSongsPageControl.currentPage = self.currentPage - 1
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
        self.loadUserPlaylistDone = true
        self.loadSongDone = false
        showProgressHud()
        getSongsByGenreResult(page: self.currentPage, isInit: false)
        genreSongsPageControl.currentPage = self.currentPage - 1
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
                    getSongsByGenreResult(page: self.currentPage, isInit: false)
                    genreSongsPageControl.currentPage = self.currentPage - 1
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
                    getSongsByGenreResult(page: self.currentPage, isInit: false)
                    genreSongsPageControl.currentPage = self.currentPage - 1
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
    func getSongsByGenreResult(page: Int, isInit: Bool) {
        
        let code = self.genreCode["code"] as? String
        
        //showProgressHud()
        
        DispatchQueue.global(qos: .userInteractive).async {
            //Send HTTP request to perform Get Top Songs
            let restUrl = self.apiUrl + "/songln/aggreportln2/\(self.userid)?page=\(page)"
            
            let postString = ["status": "STSACT", "songpublish": "Y", "songgenre": code!] as NSDictionary
            
            self.apiServices.executePostRequestWithToken(urlToExecute: restUrl, bodyDict: postString, completion: { (jsonResponse, error) in
                //code
                
                self.loadSongDone = true
                self.closeProgressHud()
                /*
                 DispatchQueue.main.async {
                    dismissProgressHud()
                    self.refreshControl.endRefreshing()
                 }
                */
                if error != nil {
                    print("error= \(String(describing: error))")
                    DispatchQueue.main.async {
                        ToastMessageView.shared.long(self.view, txt_msg: "Server Error or Disconnected. Please try again later.")
                    }
                    
                    return
                }
                guard let responseDict = jsonResponse else {
                    print("error= \(String(describing: error))")
                    DispatchQueue.main.async {
                        ToastMessageView.shared.long(self.view, txt_msg: "App Error. Please try again later.")
                    }
                    
                    return
                }
                
                let success = responseDict["success"] as? Bool
                if success! {
                    //print("Successfully populated !")
                    if let dataResult = responseDict["data"] as? NSArray {
                        self.genreSongs = dataResult
                        let resultNPages = responseDict["npage"] as! Int
                        self.maxPages = resultNPages
                        
                        if self.genreSongs.count > 0 {
                            DispatchQueue.main.async {
                                if isInit {
                                    
                                    switch resultNPages {
                                    case _ where resultNPages > 1:
                                        self.btnNextPage.isHidden = false
                                        self.genreSongsPageControl.isHidden = false
                                        self.genreSongsPageControl.numberOfPages = resultNPages
                                    default:
                                        self.btnNextPage.isHidden = true
                                        self.genreSongsPageControl.isHidden = true
                                    }
                                    
                                    //self.genreSongsPageControl.isHidden = !(resultNPages > 1)
                                    self.genreSongsTableView.backgroundView = nil
                                }
                                
                                self.genreSongsTableView.reloadData()
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.genreSongsPageControl.isHidden = true
                                self.btnPrevPage.isHidden = true
                                self.btnNextPage.isHidden = true
                                self.genreSongsTableView.backgroundView = self.noDataView
                            }
                        }
                        
                    }
                    
                } else {
                    let message = responseDict["message"] as? String
                    DispatchQueue.main.async {
                        self.genreSongsPageControl.isHidden = true
                        self.btnPrevPage.isHidden = true
                        self.btnNextPage.isHidden = true
                        //self.genreSongsTableView.backgroundView = self.noDataView
                        ToastMessageView.shared.long(self.view, txt_msg: message!)
                    }
                    
                    print(message!)
                    
                }
            })
            
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
                    
                    self.getSongsByGenreResult(page: 1, isInit: true)
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

extension GenreSongsViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
 
        return self.genreSongs.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let tablecell = tableView.dequeueReusableCell(withIdentifier: "SongListCell", for: indexPath) as? SongListTableViewCell else {
            return UITableViewCell()
        }
        guard let songData = self.genreSongs[indexPath.row] as? NSDictionary else {
            return UITableViewCell()
        }
        
        tablecell.initData(data: songData)
        
        let pcsFlag = songData["pcsflag"] as? String
        tablecell.playOrBuyTapAction = {
            if pcsFlag == "Y" {
                let songcode = songData["_id"] as? String
                let songDownloaded = isSongDownloaded(songcode: songcode)
                if songDownloaded {
                    let songPathURL = getSongDownloadedUrl(songcode: songcode)
                    self.showMiniPlayer(song: songData, songUrl: songPathURL, plistName: nil)
                } else {
                    self.showMiniPlayer(song: songData,songUrl: nil, plistName: nil)
                }
                
            } else {
                self.buySong(data: songData)
            }
        }
        
        tablecell.addToPlaylistTapAction = {
            // implement your logic here, e.g. call preformSegue()
            self.addToPlaylist(data: songData)
        }
        
        tablecell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapTableSongCell(_:))))
        
        return tablecell
    }
    /*
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //print("Got clicked on Song index: \(indexPath)!")
        let songData = genreSongs[indexPath.row] as? NSDictionary
        /*
        let songTitle = songData!["songname"] as? String
        let songId = songData!["_id"] as? String
        infoAlert(title: "Info", message: "Play Song Id: \(songId!) and Song Title: \(songTitle!)", presentingVC: self)
        */
        let songcode = songData!["_id"] as? String
        let songDownloaded = isSongDownloaded(songcode: songcode)
        if songDownloaded {
            let songPathURL = getSongDownloadedUrl(songcode: songcode)
            self.showMiniPlayer(song: songData!, songUrl: songPathURL, plistName: nil)
        } else {
            self.showMiniPlayer(song: songData!,songUrl: nil, plistName: nil)
        }
        
    }
    */
    @objc func tapTableSongCell(_ sender: UITapGestureRecognizer) {
        
        let location = sender.location(in: self.genreSongsTableView)
        let indexPath = self.genreSongsTableView.indexPathForRow(at: location)
        
        if let index = indexPath {
            let selectedSong = genreSongs[index.row] as? NSDictionary
            
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

extension GenreSongsViewController: BuySongViewControllerDelegate {
    func refreshData(_ song: Any?) {
        showProgressHud()
        DispatchQueue.main.asyncAfter(deadline: .now() + APPCONSTANT.refreshDelay) {
            DispatchQueue.global(qos: .userInteractive).async {
                self.getUserPlaylistData(page: 1)
            }
        }
        
    }
    
    
}
