//
//  PlaylistSongViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 03/12/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import PCLBlurEffectAlert

class PlaylistSongViewController: UIViewController {

    let apiServices = RestAPIServices()
    
    let apiUrl = APPURL.BaseURL
    let hostUrl = APPURL.Domain
    
    private var playlistData: NSDictionary = [:]
    
    private var userid: String = ""
    private var accessToken: String = ""
    private var loadSongsErr: Bool = false
    private var songs: NSArray = []
    private var currentPage: Int = 1
    private var maxPages: Int = 1
    private var totalcount: Int = 0
    private var refreshControl: UIRefreshControl!
    var songDataForSegue: NSDictionary = [:]
    private var loadSongDone: Bool = false

    @IBOutlet weak var albumImage1: KxCustomImageView!
    @IBOutlet weak var albumImage2: KxCustomImageView!
    @IBOutlet weak var albumImage3: KxCustomImageView!
    @IBOutlet weak var albumImage4: KxCustomImageView!
    
    @IBOutlet weak var albumImage1WidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumImage1HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumImage2WidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumImage2HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumImage3WidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumImage3HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumImage4HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumImage4WidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var playlistNameLabel: UILabel!
    @IBOutlet weak var noOfSongsLabel: UILabel!
    @IBOutlet weak var artistNamesLabel: UILabel!
    
    @IBOutlet weak var albumImageView: UIView!
    
    @IBOutlet weak var songTableView: UITableView!
    @IBOutlet weak var btnPrevPage: UIButton!
    @IBOutlet weak var btnNextPage: UIButton!
    @IBOutlet weak var songPageControl: UIPageControl!
    @IBOutlet weak var btnDeletePlaylist: UIButton!
    
    @IBOutlet var noDataView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        accessToken = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Token)!
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
        
        albumImage1WidthConstraint.constant = albumImageView.frame.width / 2
        albumImage1HeightConstraint.constant = albumImageView.frame.height / 2
        albumImage2WidthConstraint.constant = albumImageView.frame.width / 2
        albumImage2HeightConstraint.constant = albumImageView.frame.height / 2
        albumImage3WidthConstraint.constant = albumImageView.frame.width / 2
        albumImage3HeightConstraint.constant = albumImageView.frame.height / 2
        albumImage4WidthConstraint.constant = albumImageView.frame.width / 2
        albumImage4HeightConstraint.constant = albumImageView.frame.height / 2
        
        albumImageView.layer.cornerRadius = 5
        albumImageView.clipsToBounds = true
        btnDeletePlaylist.backgroundColor = UIColor(hex: 0x333, alpha: 1)
        btnDeletePlaylist.layer.cornerRadius = 5
        btnDeletePlaylist.clipsToBounds = true
        
        songTableView.delegate = self
        songTableView.dataSource = self
        songTableView.register(UINib(nibName: "PlaylistSongListTableViewCell", bundle: nil), forCellReuseIdentifier: "PlaylistSongListCell")
        configureSongTableView()
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        songTableView.addSubview(refreshControl)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture(gesture:)))
        swipeLeft.direction = .left
        songTableView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture(gesture:)))
        swipeRight.direction = .right
        songTableView.addGestureRecognizer(swipeRight)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        resetPageNavigation()
        setHeaderData()
        self.loadSongDone = false
        getSongsInPlaylist(page: 1, isInit: true)
    }
    
    @objc func refresh(_ sender: Any) {
        //  your code to refresh tableView
        resetPageNavigation()
        setHeaderData()
        self.loadSongDone = false
        getSongsInPlaylist(page: 1, isInit: true)
    }
    
    @IBAction func btnPrevPagePressed(_ sender: UIButton) {
        self.currentPage -= 1
    
        self.loadSongDone = false
        getSongsInPlaylist(page: self.currentPage, isInit: false)
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
        
        self.loadSongDone = false
        getSongsInPlaylist(page: self.currentPage, isInit: false)
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

                    self.loadSongDone = false
                    getSongsInPlaylist(page: self.currentPage, isInit: false)
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
                    self.loadSongDone = false
                    getSongsInPlaylist(page: self.currentPage, isInit: false)
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

    @IBAction func btnDeletePlaylistPressed(_ sender: UIButton) {
        
        let playlist = self.playlistData
        let playlistId = playlist["_id"] as? String
        
        kaxetConfirmationAlert(title: "Confirmation", message: "Are you sure to remove this Playlist ?", titleColor: UIColor(hex: 0x3AFFFC, alpha:1), itemId: playlistId!, isPlaylist: true)
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
        
        case "goToBuySong":
            // Create a new variable to store the instance of BuySongViewController
            let destinationVC = segue.destination as! BuySongViewController
            destinationVC.delegate = self
            destinationVC.songData = songDataForSegue
        default:
            break
        }
    }
 

    func initData(data: NSDictionary) {
        self.playlistData = data
    }
    
    private func setHeaderData() {
    
        let playlist = self.playlistData
    
        let playlistName = playlist["playlistname"] as? String
        playlistNameLabel.text = playlistName!

    }
    
    private func initImage() {
        artistNamesLabel.text = ""
        noOfSongsLabel.text = ""
        albumImage1.image = UIImage(named: "kxlogo")
        albumImage2.image = UIImage(named: "kxlogo")
        albumImage3.image = UIImage(named: "kxlogo")
        albumImage4.image = UIImage(named: "kxlogo")
    }
    
    func setAlbumImagePlaylist() {
        
        let totalCount = self.totalcount

        switch totalCount {
        case _ where totalCount > 1:
            noOfSongsLabel.text = "\(totalCount) Songs"
        case _ where totalCount == 1:
            noOfSongsLabel.text = "\(totalCount) Song"
        case _ where totalCount < 1:
            noOfSongsLabel.text = "No Songs"
        default:
            noOfSongsLabel.text = "Error Getting Songs"
        }
        
        let countAlbumList = self.songs.count
        
        switch countAlbumList {
        case 1:
            let songData = self.songs[0] as? NSDictionary
            let artistName = songData!["artist"] as? String
            let albumImagePath = songData!["albumphoto"] as? String
            self.albumImage1.loadImageUsingUrlString(urlString: albumImagePath!)
            artistNamesLabel.text = artistName
            
        case 2:
            let songData = self.songs[0] as? NSDictionary
            let artistName = songData!["artist"] as? String
            let albumImagePath = songData!["albumphoto"] as? String
            self.albumImage1.loadImageUsingUrlString(urlString: albumImagePath)
            
            let songData2 = self.songs[1] as? NSDictionary
            let artistName2 = songData2!["artist"] as? String
            let albumImagePath2 = songData2!["albumphoto"] as? String
            self.albumImage2.loadImageUsingUrlString(urlString: albumImagePath2)
            artistNamesLabel.text = artistName! + ", " + artistName2!
            
        case 3:
            let songData = self.songs[0] as? NSDictionary
            let artistName = songData!["artist"] as? String
            let albumImagePath = songData!["albumphoto"] as? String
            self.albumImage1.loadImageUsingUrlString(urlString: albumImagePath)
            
            let songData2 = self.songs[1] as? NSDictionary
            let artistName2 = songData2!["artist"] as? String
            let albumImagePath2 = songData2!["albumphoto"] as? String
            self.albumImage2.loadImageUsingUrlString(urlString: albumImagePath2)
            
            let songData3 = self.songs[2] as? NSDictionary
            let artistName3 = songData3!["artist"] as? String
            let albumImagePath3 = songData3!["albumphoto"] as? String
            self.albumImage3.loadImageUsingUrlString(urlString: albumImagePath3)
            artistNamesLabel.text = artistName! + ", " + artistName2! + ", " + artistName3!
            
        case 4:
            let songData = self.songs[0] as? NSDictionary
            let artistName = songData!["artist"] as? String
            let albumImagePath = songData!["albumphoto"] as? String
            self.albumImage1.loadImageUsingUrlString(urlString: albumImagePath)
            
            let songData2 = self.songs[1] as? NSDictionary
            let artistName2 = songData2!["artist"] as? String
            let albumImagePath2 = songData2!["albumphoto"] as? String
            self.albumImage2.loadImageUsingUrlString(urlString: albumImagePath2)
            
            let songData3 = self.songs[2] as? NSDictionary
            let artistName3 = songData3!["artist"] as? String
            let albumImagePath3 = songData3!["albumphoto"] as? String
            self.albumImage3.loadImageUsingUrlString(urlString: albumImagePath3)
            
            let songData4 = self.songs[3] as? NSDictionary
            let artistName4 = songData4!["artist"] as? String
            let albumImagePath4 = songData4!["albumphoto"] as? String
            self.albumImage4.loadImageUsingUrlString(urlString: albumImagePath4)
            artistNamesLabel.text = artistName! + ", " + artistName2! + ", " + artistName3! + ", " + artistName4!
            
        case _ where countAlbumList > 4:
            
            let songData = self.songs[Int(arc4random_uniform(UInt32(countAlbumList)))] as? NSDictionary
            let artistName = songData!["artist"] as? String
            let albumImagePath = songData!["albumphoto"] as? String
            self.albumImage1.loadImageUsingUrlString(urlString: albumImagePath)
            
            let songData2 = self.songs[Int(arc4random_uniform(UInt32(countAlbumList)))] as? NSDictionary
            let artistName2 = songData2!["artist"] as? String
            let albumImagePath2 = songData2!["albumphoto"] as? String
            self.albumImage2.loadImageUsingUrlString(urlString: albumImagePath2)
            
            let songData3 = self.songs[Int(arc4random_uniform(UInt32(countAlbumList)))] as? NSDictionary
            let artistName3 = songData3!["artist"] as? String
            let albumImagePath3 = songData3!["albumphoto"] as? String
            self.albumImage3.loadImageUsingUrlString(urlString: albumImagePath3)
            
            let songData4 = self.songs[Int(arc4random_uniform(UInt32(countAlbumList)))] as? NSDictionary
            let artistName4 = songData4!["artist"] as? String
            let albumImagePath4 = songData4!["albumphoto"] as? String
            self.albumImage4.loadImageUsingUrlString(urlString: albumImagePath4)
            artistNamesLabel.text = artistName! + ", " + artistName2! + ", " + artistName3! + ", " + artistName4!
            
        default:
            break
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
        songTableView.rowHeight = 68
        songTableView.separatorStyle = .none
        songTableView.tableFooterView = UIView(frame: CGRect.zero)
        
    }
    
    func getSongsInPlaylist(page: Int, isInit: Bool) {
        
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            DispatchQueue.main.async {
                
                let playlistId = self.playlistData["_id"] as? String
                //Send HTTP request to perform Get Top Songs
                let restUrl = self.apiUrl + "/playlist2/\(playlistId!)?page=\(page)"
                
                let postString = ["listenerid": self.userid] as NSDictionary
                
                self.apiServices.executePostRequestWithToken(urlToExecute: restUrl, bodyDict: postString, completion: { (jsonResponse, error) in
                    //code
                    
                    if error != nil {
                        print("error= \(String(describing: error))")
                        self.loadSongDone = true
                        self.closeProgressHud()
                        DispatchQueue.main.async {
                            ToastMessageView.shared.long(self.view, txt_msg: "Server Error or Disconnected. Please try again later.")
                        }
                        
                        return
                    }
                    
                    guard let responseDict = jsonResponse else {
                        print("error= \(String(describing: error))")
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
                            self.totalcount = responseDict["totalcount"] as! Int
                            self.updateSongid()
                            
                            if self.songs.count > 0 {
                                DispatchQueue.main.async {
                                    if isInit {
                                        self.setAlbumImagePlaylist()
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
                                        self.songTableView.backgroundView = nil
                                    }
                                    self.songTableView.reloadData()
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.songPageControl.isHidden = true
                                    self.btnPrevPage.isHidden = true
                                    self.btnNextPage.isHidden = true
                                    self.songTableView.backgroundView = self.noDataView
                                    
                                    self.songTableView.reloadData()
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
                            self.songTableView.reloadData()
                            ToastMessageView.shared.long(self.view, txt_msg: message!)
                        }
                        
                        print(message!)
                        if let expToken = responseDict["errcode"] as? String {
                            if expToken == "exp-token" {
                                self.loadSongsErr = true
                            }
                        }
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
                let playlistItemId = songdata["_id"] as? String
                songdata.setValue(songid, forKey: "_id")
                songdata.setValue(playlistItemId, forKey: "playlistitemid")
            }
        }
        
    }
    
    private func showMiniPlayer(song: NSDictionary, songUrl: URL?, indexSong: Int?) {
        
        let playlistName = self.playlistData["playlistname"] as? String
        goShowMiniPlayerWithPlaylist(presentingVc: self, song: song, songUrl: songUrl, plistName: playlistName, playlistData: songs, indexSong: indexSong)
    }
    
    private func removeFrPlaylist(data: NSDictionary) {
        //self.songDataForSegue = data
        let playlistItemId = data["playlistitemid"] as? String
        /*
        let songId = data["_id"] as? String
        let songname = data["songname"] as? String
        
        print("PlaylistItemId: \(playlistItemId!)")
        print("SongId: \(songId!)")
        print("Songname: \(songname!)")
        */
        kaxetConfirmationAlert(title: "Confirmation", message: "Are you sure to remove this item ?", titleColor: UIColor(hex: 0x3AFFFC, alpha:1), itemId: playlistItemId!, isPlaylist: false)
        
    }
    
    private func buySong(data: NSDictionary) {
        self.songDataForSegue = data
        self.performSegue(withIdentifier: "goToBuySong", sender: self)
    }
    
    func closeProgressHud() {
        
        if ( loadSongDone) {
            
            DispatchQueue.main.async {
                dismissProgressHud()
                self.refreshControl.endRefreshing()
            }
            
            goToLogout()
        }
        
    }
    
    private func goToLogout() {
        
        if ( loadSongsErr ) {
            
            logout(presentingVc: self)
        }
        
    }
    
    func kaxetConfirmationAlert(title: String, message: String, titleColor: UIColor, itemId: String, isPlaylist: Bool) {
        
        hideToolbarView()
        DispatchQueue.main.async {
            let kxAlert = PCLBlurEffectAlert.Controller(title: title, message: message, effect: UIBlurEffect(style: .regular), style: .alert)
            
            //myAlert.addImageView(with: UIImage(named: "Kaxet Logo")!)
            
            //myAlert.configure(thin: 10)
            kxAlert.configure(cornerRadius: 5)
            kxAlert.configure(alertViewWidth: 200)
            kxAlert.configure(buttonHeight: 35)
            kxAlert.configure(backgroundColor: UIColor(hex: 0x333, alpha:1))
            
            kxAlert.configure(titleColor: titleColor)
            kxAlert.configure(messageFont: UIFont(name: "TrebuchetMS", size: 14)!, messageColor: UIColor(hex: 0xFCE86C, alpha:1))
            //kxAlert.configure(messageColor: UIColor(hex: 0xFCE86C, alpha:1))
            
            kxAlert.configure(buttonBackgroundColor: UIColor(hex: 0xFCE86C, alpha:0.8))
            let okBtn = PCLBlurEffectAlertAction(title: "OK", style: .default) { _ in
                showToolbarView()
                //print("Item Id to be removed: \(itemId)")
                if isPlaylist {
                    self.removeUserPlaylist(item: itemId)
                    
                } else {
                    self.initImage()
                    self.removeFromUserPlaylist(item: itemId)
                }
                
            }
            
            kxAlert.configure(buttonBackgroundColor: UIColor(hex: 0xFCE86C, alpha:0.8))
            let cancelBtn = PCLBlurEffectAlertAction(title: "Cancel", style: .cancel) { _ in
                showToolbarView()
                
            }
            kxAlert.addAction(okBtn)
            kxAlert.addAction(cancelBtn)
            //kxAlert.show()
            self.present(kxAlert, animated: true, completion: nil)
        }
        
    }
    
    private func removeUserPlaylist(item: String) {
        
        let playlistId = item
        
        if (playlistId.isEmpty) {
            //Display alert message
            failedAlert(title: "Error", message: "Missing required fields. Please input the required Playlist Id !", presentingVC: self)
            return
        }
        
        showProgressHud()
        
        DispatchQueue.global(qos: .userInteractive).async {
            //Send HTTP request to perform Add playlist
            let removePlaylistUrl = self.apiUrl + "/deluserplaylist/\(playlistId)"
            //let removePlaylistUrl = self.apiUrl + "/deluserplaylist/"
            
            self.apiServices.executePostRequestWithToken(urlToExecute: removePlaylistUrl, bodyDict: nil, completion: { (jsonResponse, error) in
                
                if error != nil {
                    print("error= \(String(describing: error))")
                    self.closeProgressHud()
                    failedAlert(title: "Server Error or Disconnected", message: "Could not successfully perform the request. Please try again later !", presentingVC: self)
                    return
                }
                
                guard let responseDict = jsonResponse else {
                    print("error= \(String(describing: error))")
                    self.closeProgressHud()
                    failedAlert(title: "App Error", message: "Could not successfully perform the request. Please try again later !", presentingVC: self)
                    return
                }
                
                let success = responseDict["success"] as? Bool
                let message1 = responseDict["message"] as? String
                
                if success! {
                    DispatchQueue.main.async {
                        self.navigationController?.popViewController(animated: true)
                    }
                    
                    
                } else {
                    self.closeProgressHud()
                    //Error Alert
                    failedAlert(title: "Result Error", message: message1!, presentingVC: self)
                    return
                }
            })
            
        }
        
    }
    
    private func removeFromUserPlaylist(item: String) {
        
        let playlistItemId = item
        
        if (playlistItemId.isEmpty) {
            //Display alert message
            failedAlert(title: "Error", message: "Missing required fields. Please input the required Playlist Item Id !", presentingVC: self)
            return
        }
        
        showProgressHud()
        
        DispatchQueue.global(qos: .userInteractive).async {
            //Send HTTP request to perform Add playlist
            let removeSongPlaylistUrl = self.apiUrl + "/delplaylist/\(playlistItemId)"
            let postString = ["userid": self.userid] as NSDictionary
            
            self.apiServices.executePostRequestWithToken(urlToExecute: removeSongPlaylistUrl, bodyDict: postString, completion: { (jsonResponse, error) in
                
                if error != nil {
                    print("error= \(String(describing: error))")
                    self.closeProgressHud()
                    failedAlert(title: "Server Error or Disconnected", message: "Could not successfully perform the request. Please try again later !", presentingVC: self)
                    return
                }
                
                guard let responseDict = jsonResponse else {
                    print("error= \(String(describing: error))")
                    self.closeProgressHud()
                    failedAlert(title: "App Error", message: "Could not successfully perform the request. Please try again later !", presentingVC: self)
                    return
                }
                
                let success = responseDict["success"] as? Bool
                let message1 = responseDict["message"] as? String
                
                if success! {
                    DispatchQueue.main.async {
                        self.resetPageNavigation()
                        self.loadSongDone = false
                        self.getSongsInPlaylist(page: 1, isInit: true)
                        
                    }
                    
                    
                } else {
                    self.closeProgressHud()
                    //Error Alert
                    failedAlert(title: "Result Error", message: message1!, presentingVC: self)
                    return
                }
            })
            
        }
    }
}

extension PlaylistSongViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let searchresulttablecell = tableView.dequeueReusableCell(withIdentifier: "PlaylistSongListCell", for: indexPath) as? PlaylistSongListTableViewCell else {
            return UITableViewCell()
        }
        guard let songData = self.songs[indexPath.row] as? NSDictionary else {
            return UITableViewCell()
        }
        
        searchresulttablecell.initData(data: songData)
        let pcsFlag = songData["pcsflag"] as? String
        
        searchresulttablecell.playOrBuyTapAction = {
            if pcsFlag == "Y" {
                /*
                let page = self.songPageControl.currentPage
                let basePageNo = page * 10
                let idxSong = basePageNo + indexPath.row + 1
                */
                let songcode = songData["_id"] as? String
                let songDownloaded = isSongDownloaded(songcode: songcode)
                if songDownloaded {
                    let songPathURL = getSongDownloadedUrl(songcode: songcode)
                    self.showMiniPlayer(song: songData, songUrl: songPathURL,indexSong: indexPath.row)
                } else {
                    self.showMiniPlayer(song: songData,songUrl: nil, indexSong: indexPath.row)
                }
                
            } else {
                self.buySong(data: songData)
            }
        }
        
        searchresulttablecell.removeFrPlaylistTapAction = {
            // implement your logic here, e.g. call preformSegue()
            self.removeFrPlaylist(data: songData)
        }
        searchresulttablecell.selectionStyle = .none
        
        searchresulttablecell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapTableSongCell(_:))))
        
        return searchresulttablecell
    }
    
    @objc func tapTableSongCell(_ sender: UITapGestureRecognizer) {
        
        let location = sender.location(in: self.songTableView)
        let indexPath = self.songTableView.indexPathForRow(at: location)
        
        if let index = indexPath {
            let selectedSong = songs[index.row] as? NSDictionary
            
            let songcode = selectedSong!["_id"] as? String
            let songDownloaded = isSongDownloaded(songcode: songcode)
            if songDownloaded {
                let songPathURL = getSongDownloadedUrl(songcode: songcode)
                self.showMiniPlayer(song: selectedSong!, songUrl: songPathURL, indexSong: index.row)
            } else {
                self.showMiniPlayer(song: selectedSong!,songUrl: nil, indexSong: index.row)
            }
            
        }
    }
    
}

extension PlaylistSongViewController : BuySongViewControllerDelegate {
    func refreshData(_ song: Any?) {
        showProgressHud()
        DispatchQueue.main.asyncAfter(deadline: .now() + APPCONSTANT.refreshDelay) {
            self.resetPageNavigation()
            self.setHeaderData()
            self.loadSongDone = false
            DispatchQueue.global(qos: .userInteractive).async {
                self.getSongsInPlaylist(page: 1, isInit: true)
            }
        }

    }
    
    
}
