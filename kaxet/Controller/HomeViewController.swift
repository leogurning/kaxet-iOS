//
//  HomeViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 09/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class HomeViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,
    UIScrollViewDelegate {
    
    let apiServices = RestAPIServices()
    
    let apiUrl = APPURL.BaseURL
    let hostUrl = APPURL.Domain
    
    var accessToken: String = ""
    var userid: String = ""
    
    private var banners: NSArray = []
    private var genres: NSArray = []
    private var topSongs: NSArray = []
    private var recentSongs: NSArray = []
    private var userPlaylist: NSArray = []
    private var playlistNPages: Int = 0
    
    var songDataForSegue: NSDictionary = [:]
    private var genreDataForSegue: NSDictionary = [:]
    /*
    var miniPlayerVc: MiniPlayerViewController?
    var miniPlayerView: UIView?
    */
    @IBOutlet weak var bannerCollectionView: UICollectionView!
    @IBOutlet weak var genreCollectionView: UICollectionView!
    @IBOutlet weak var topSongsCollectionView: UICollectionView!
    @IBOutlet weak var recentSongsCollectionView: UICollectionView!
    @IBOutlet weak var mainScrollView: UIScrollView!
    
    @IBOutlet weak var topSongPageControl: UIPageControl!
    @IBOutlet weak var recentSongPageControl: UIPageControl!
    @IBOutlet weak var bannerPageControl: UIPageControl!
    
    @IBOutlet var noDataView: UIView!
    
    private var loadBannersDone: Bool = false
    private var loadGenresDone: Bool = false
    private var loadTopSongsDone: Bool = false
    private var loadRecentSongsDone: Bool = false
    private var loadUserPlaylistDone: Bool = false
    
    private var loadBannersDoneServapErr: Bool = false
    private var loadGenresDoneServapErr: Bool = false
    private var loadTopSongsDoneServapErr: Bool = false
    private var loadRecentSongsDoneServapErr: Bool = false
    private var loadUserPlaylistDoneServapErr: Bool = false
    
    private var loadBannersErr: Bool = false
    private var loadGenresErr: Bool = false
    private var loadTopSongsErr: Bool = false
    private var loadRecentSongsErr: Bool = false
    private var loadUserPlaylistErr: Bool = false
    private var refreshControl: UIRefreshControl!
    private var scrollingTimer = Timer()
    private var rowIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        bannerCollectionView.delegate = self
        bannerCollectionView.dataSource = self
        
        genreCollectionView.delegate = self
        genreCollectionView.dataSource = self
        
        topSongsCollectionView.delegate = self
        topSongsCollectionView.dataSource = self
        topSongsCollectionView.register(UINib(nibName: "HomeSongListCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "HomeSongListCell")
        
        recentSongsCollectionView.delegate = self
        recentSongsCollectionView.dataSource = self
        recentSongsCollectionView.register(UINib(nibName: "HomeSongListCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "HomeSongListCell")
        
        
        accessToken = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Token)!
        
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!

        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        mainScrollView.addSubview(refreshControl)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        initiateLoadingInd()
        initiateServapErrInd()
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            self.getUserPlaylistData(page: 1)
            //self.getTopSongsResult()
            //self.getRecentSongsResult()
            self.getBannerImage()
            //self.getGenreData()
        }
        //self.miniPlayerVc?.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        scrollingTimer.invalidate()
    }
    
    @objc func refresh(_ sender: Any) {
        //  your code to refresh tableView
        initiateLoadingInd()
        initiateServapErrInd()
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            self.getUserPlaylistData(page: 1)
            self.getBannerImage()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    @IBAction func btnSearchBarPressed(_ sender: UIButton) {
        let tabBarController = UIApplication.shared.keyWindow?.rootViewController as! UITabBarController
        tabBarController.selectedIndex = 1
        //self.presentingViewController!.presentingViewController!.dismiss(animated: true, completion: nil)
        
    }
    */
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
            case "goToAddToPlaylistInit":
                // Create a new variable to store the instance of AddToPlaylistInitViewController
                hideToolbarView()
                let destinationVC = segue.destination as! AddToPlaylistInitViewController
                destinationVC.initData(data: songDataForSegue)
            case "goToAddToPlaylist":
                // Create a new variable to store the instance of AddToPlaylistViewController
                hideToolbarView()
                let destinationVC = segue.destination as! AddToPlaylistViewController
                destinationVC.initData(song: songDataForSegue, playlist: userPlaylist, npages: playlistNPages)
            case "goToGenreDetails":
                // Create a new variable to store the instance of GenreSongsViewController
                let destinationVC = segue.destination as! GenreSongsViewController
                destinationVC.initData(data: genreDataForSegue)
                /*
                destinationVC.miniPlayerVc = self.miniPlayerVc
                destinationVC.miniPlayerView = self.miniPlayerView
                */
            case "goToBuySong":
                // Create a new variable to store the instance of BuySongViewController
                hideToolbarView()
                let destinationVC = segue.destination as! BuySongViewController
                destinationVC.delegate = self
                destinationVC.songData = songDataForSegue
            default:
                return
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == bannerCollectionView {
            return banners.count
        } else if collectionView == genreCollectionView {
            return genres.count
        } else if collectionView == topSongsCollectionView {
            
            return topSongs.count
        } else if collectionView == recentSongsCollectionView {
            return recentSongs.count
        } else {
            return 1
        }

    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        switch scrollView {
        case bannerCollectionView:
            //Change the current page
            let witdh = scrollView.frame.width - (scrollView.contentInset.left*2)
            let index = scrollView.contentOffset.x / witdh
            let roundedIndex = round(index)
            bannerPageControl?.currentPage = Int(roundedIndex)
        case topSongsCollectionView:
            //Change the current page
            let witdh = scrollView.frame.width - (scrollView.contentInset.left*2)
            let index = scrollView.contentOffset.x / witdh
            let roundedIndex = round(index)
            topSongPageControl?.currentPage = Int(roundedIndex)
        case recentSongsCollectionView:
            //Change the current page
            let witdh = scrollView.frame.width - (scrollView.contentInset.left*2)
            let index = scrollView.contentOffset.x / witdh
            let roundedIndex = round(index)
            recentSongPageControl?.currentPage = Int(roundedIndex)
        default:
            break
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == bannerCollectionView {
            guard let bannerCell = collectionView.dequeueReusableCell(withReuseIdentifier: "BannerCell", for: indexPath) as? BannerCollectionViewCell else {
                return UICollectionViewCell()
            }
            
            let banner = banners[indexPath.row] as? NSDictionary
            let bannerImagePath = banner!["filepath"] as? String
            /*
            if let bannerImageURL = URL(string: bannerImagePath!) {
                DispatchQueue.global(qos: .userInteractive).async {
                    let dataImage = try? Data(contentsOf: bannerImageURL)
                    if let data = dataImage {
                        let bannerImage = UIImage(data: data)
                        DispatchQueue.main.async {
                            bannerCell.bannerImage.image = bannerImage
                        }
                    }
                }
            }
            */
            bannerCell.bannerImage.loadImageUsingUrlString(urlString: bannerImagePath)
            
            return bannerCell
        } else if collectionView == genreCollectionView {
            guard let genreCell = collectionView.dequeueReusableCell(withReuseIdentifier: "GenreCell", for: indexPath) as? GenreCollectionViewCell else {
                return UICollectionViewCell()
            }
            
            let genre = genres[indexPath.row] as? NSDictionary
            let genreImagePath = genre!["filepath"] as? String
            genreCell.genreNameLabel.text = genre!["value"] as? String
            /*
            if let genreImageURL = URL(string: genreImagePath!) {
                DispatchQueue.global(qos: .userInteractive).async {
                    let dataImage = try? Data(contentsOf: genreImageURL)
                    if let data = dataImage {
                        let genreImage = UIImage(data: data)
                        DispatchQueue.main.async {
                            genreCell.genreImage.image = genreImage
                        }
                    }
                }
            }
            */
            genreCell.genreImage.loadImageUsingUrlString(urlString: genreImagePath)
            genreCell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGenreCell(_:))))
            
            return genreCell
        } else if collectionView == topSongsCollectionView {
            guard let topSongCell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeSongListCell", for: indexPath) as? HomeSongListCollectionViewCell else {
                return UICollectionViewCell()
            }
            
            let topSong = topSongs[indexPath.row] as? NSDictionary
            
            topSongCell.initData(data: topSong!)
            
            let pcsFlag = topSong!["pcsflag"] as? String
            topSongCell.playOrBuyTapAction = {
                if pcsFlag == "Y" {
                    let songcode = topSong!["_id"] as? String
                    let songDownloaded = isSongDownloaded(songcode: songcode)
                    if songDownloaded {
                        let songPathURL = getSongDownloadedUrl(songcode: songcode)
                        self.showMiniPlayer(song: topSong!, songUrl: songPathURL, plistName: nil)
                    } else {
                        self.showMiniPlayer(song: topSong!,songUrl: nil, plistName: nil)
                    }
                    
                } else {
                    self.buySong(data: topSong!)
                }
            }
            
            topSongCell.addToPlaylistTapAction = {
                // implement your logic here, e.g. call preformSegue()
               self.addToPlaylist(data: topSong!)
            }
            
            topSongCell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapTopSongCell(_:))))
            
            return topSongCell
        } else if collectionView == recentSongsCollectionView {
            guard let recentSongCell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeSongListCell", for: indexPath) as? HomeSongListCollectionViewCell else {
                return UICollectionViewCell()
            }
            
            let recentSong = recentSongs[indexPath.row] as? NSDictionary
            recentSongCell.initData(data: recentSong!)
            
            let pcsFlag = recentSong!["pcsflag"] as? String
            recentSongCell.playOrBuyTapAction = {
                if pcsFlag == "Y" {
                    let songcode = recentSong!["_id"] as? String
                    let songDownloaded = isSongDownloaded(songcode: songcode)
                    if songDownloaded {
                        let songPathURL = getSongDownloadedUrl(songcode: songcode)
                        self.showMiniPlayer(song: recentSong!, songUrl: songPathURL, plistName: nil)
                    } else {
                        self.showMiniPlayer(song: recentSong!,songUrl: nil, plistName: nil)
                    }
                    
                } else {
                    self.buySong(data: recentSong!)
                }
            }
            
            recentSongCell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapRecentSongCell(_:))))
            
            recentSongCell.addToPlaylistTapAction = {
                // implement your logic here, e.g. call preformSegue()
                self.addToPlaylist(data: recentSong!)
            }
            
            return recentSongCell
        } else {
            return UICollectionViewCell()
        }
        
        
    }

    
    @objc func tapTopSongCell(_ sender: UITapGestureRecognizer) {
        
        let location = sender.location(in: self.topSongsCollectionView)
        let indexPath = self.topSongsCollectionView.indexPathForItem(at: location)
        
        if let index = indexPath {
            //print("Got clicked on TopSong index: \(index)!")
            let topSong = topSongs[index.row] as? NSDictionary
            /*
            let songId = topSong!["_id"] as? String
            let songPrvwPath = topSong!["songprvwpath"] as? String
            print("Song Id: \(songId!)")
            print("Song Preview: \(songPrvwPath!)")
             */
            let songcode = topSong!["_id"] as? String
            let songDownloaded = isSongDownloaded(songcode: songcode)
            if songDownloaded {
                let songPathURL = getSongDownloadedUrl(songcode: songcode)
                self.showMiniPlayer(song: topSong!, songUrl: songPathURL, plistName: nil)
            } else {
                self.showMiniPlayer(song: topSong!,songUrl: nil, plistName: nil)
            }
 
        }
    }
    
    private func showMiniPlayer(song: NSDictionary, songUrl: URL?, plistName: String?) {
        goShowMiniPlayer(presentingVc: self, song: song, songUrl: songUrl, plistName: plistName)
    }
    
    @objc func tapRecentSongCell(_ sender: UITapGestureRecognizer) {
        
        let location = sender.location(in: self.recentSongsCollectionView)
        let indexPath = self.recentSongsCollectionView.indexPathForItem(at: location)
        
        if let index = indexPath {
            //print("Got clicked on RecentSong index: \(index)!")
            let recentSong = recentSongs[index.row] as? NSDictionary
            
            let songcode = recentSong!["_id"] as? String
            let songDownloaded = isSongDownloaded(songcode: songcode)
            if songDownloaded {
                let songPathURL = getSongDownloadedUrl(songcode: songcode)
                self.showMiniPlayer(song: recentSong!, songUrl: songPathURL, plistName: nil)
            } else {
                self.showMiniPlayer(song: recentSong!,songUrl: nil, plistName: nil)
            }
            
        }
    }
    
    @objc func tapGenreCell(_ sender: UITapGestureRecognizer) {
        
        let location = sender.location(in: self.genreCollectionView)
        let indexPath = self.genreCollectionView.indexPathForItem(at: location)
        
        if let index = indexPath {
            //print("Got clicked on Genre index: \(index)!")
            let genre = genres[index.row] as? NSDictionary
            self.genreDataForSegue = genre!
            
            self.performSegue(withIdentifier: "goToGenreDetails", sender: self)
            /*
            let code = genre!["code"] as? String
            let value = genre!["value"] as? String
            print("Genre Code: \(code!)")
            print("Genre Value: \(value!)")
            */
        }
    }
    
    func getTopSongsResult() {
        
        //Send HTTP request to perform Get Top Songs
        let strUrl = apiUrl + "/songln/topaggreportln2/\(userid)"
        let postString = ["status": "STSACT"] as NSDictionary
        
        apiServices.executePostRequestWithToken(urlToExecute: strUrl, bodyDict: postString) { (jsonResponse, error) in
            
            if error != nil {
                print("error= \(String(describing: error))")
                self.loadTopSongsDone = true
                self.loadTopSongsDoneServapErr = true
                self.closeProgressHud()
                return
            }
            
            guard let responseDict = jsonResponse else {
                print("error= \(String(describing: error))")
                self.loadTopSongsDone = true
                self.loadTopSongsDoneServapErr = true
                self.closeProgressHud()
                return
            }
            
            let success = responseDict["success"] as? Bool
            if success! {
                if let dataResult = responseDict["data"] as? NSArray {
                    self.topSongs = dataResult
                    DispatchQueue.main.async {

                        if self.topSongs.count > 0 {
                            
                            let pages = Int(dataResult.count / 5)
                            self.topSongPageControl.numberOfPages = pages
                            self.topSongPageControl.isHidden = !(pages > 1)
                            self.topSongsCollectionView.reloadData()
                            self.topSongsCollectionView.performBatchUpdates(nil, completion: {
                                (result) in
                                // ready
                                self.loadTopSongsDone = true
                                self.closeProgressHud()
                            })
                        } else {

                            self.topSongsCollectionView.backgroundView = self.noDataView
                            self.topSongPageControl.isHidden = true
                            self.loadTopSongsDone = true
                            self.closeProgressHud()
                        }
                    }
                }
                
            } else {
                let message = responseDict["message"] as? String
                print(message!)
                if let expToken = responseDict["errcode"] as? String {
                    if expToken == "exp-token" {
                        self.loadTopSongsErr = true
                    }
                }
                self.loadTopSongsDone = true
                self.closeProgressHud()
            }
            
        }
    }
    
    func getRecentSongsResult() {
        
        //Send HTTP request to perform Get Recent Songs
        let strUrl = apiUrl + "/songln/recentaggreportln2/\(userid)"
        let postString = ["status": "STSACT"] as NSDictionary
        
        apiServices.executePostRequestWithToken(urlToExecute: strUrl, bodyDict: postString) { (jsonResponse, error) in
            
            if error != nil {
                print("error= \(String(describing: error))")
                self.loadRecentSongsDone = true
                self.loadRecentSongsDoneServapErr = true
                self.closeProgressHud()
                return
            }
            guard let responseDict = jsonResponse else {
                print("error= \(String(describing: error))")
                self.loadRecentSongsDone = true
                self.loadRecentSongsDoneServapErr = true
                self.closeProgressHud()
                return
            }
            
            let success = responseDict["success"] as? Bool
            if success! {
                if let dataResult = responseDict["data"] as? NSArray {
                    self.recentSongs = dataResult
                    /*
                     let song1 = dataResult[0] as? NSDictionary
                     let song2 = dataResult[1] as? NSDictionary
                     let artist1 = song1!["artist"] as? String
                     let artist2 = song2!["artist"] as? String
                     print("RecentArtist1: \(String(describing: artist1)) dan RecentArtist2: \(String(describing: artist2))")
                     */
                    
                    DispatchQueue.main.async {
                        
                        if self.recentSongs.count > 0 {
                            
                            let pages = Int(dataResult.count / 5)
                            self.recentSongPageControl.numberOfPages = pages
                            self.recentSongPageControl.isHidden = !(pages > 1)
                            self.recentSongsCollectionView.reloadData()
                            self.recentSongsCollectionView.performBatchUpdates(nil, completion: { (result) in
                                
                                self.loadRecentSongsDone = true
                                self.closeProgressHud()
                            })
                        } else {
                            
                            self.recentSongsCollectionView.backgroundView = self.noDataView
                            self.recentSongPageControl.isHidden = true
                            self.loadRecentSongsDone = true
                            self.closeProgressHud()
                        }
                    }
                }
                
            } else {
                let message = responseDict["message"] as? String
                print(message!)
                if let expToken = responseDict["errcode"] as? String {
                    if expToken == "exp-token" {
                        self.loadRecentSongsErr = true
                    }
                }
                self.loadRecentSongsDone = true
                self.closeProgressHud()
            }
            
        }
    }
    
    func getUserPlaylistData(page: Int) {
        
        //Send HTTP request to get playlist
        let strUrl = apiUrl + "/userpl/\(userid)?page=\(page)"
        
        apiServices.executePostRequestWithToken(urlToExecute: strUrl, bodyDict: nil) { (jsonResponse, error) in
            
            if error != nil {
                print("error= \(String(describing: error))")
                self.loadUserPlaylistDone = true
                self.loadUserPlaylistDoneServapErr = true
                self.closeProgressHud()
                return
            }
            
            guard let responseDict = jsonResponse else {
                print("error= \(String(describing: error))")
                self.loadUserPlaylistDone = true
                self.loadUserPlaylistDoneServapErr = true
                self.closeProgressHud()
                return
            }
            
            let success = responseDict["success"] as? Bool
            if success! {
                
                self.playlistNPages = responseDict["npage"] as! Int
                if let dataResult = responseDict["data"] as? NSArray {
                    self.userPlaylist = dataResult
                    /*
                    DispatchQueue.main.async {
                        //self.topSongsCollectionView.reloadData()
                        dismissProgressHud()
                    }
                    let noOfPlaylist = self.userPlaylist.count
                    print("No Of Playlist: \(String(describing: noOfPlaylist))")
                    */
                    self.getTopSongsResult()
                    self.getRecentSongsResult()
                    self.getGenreData()
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
    
    func getBannerImage() {
        
        //Send HTTP request to perform Get Banner
        let bannerUrl = hostUrl + "/msconfigbygroup/BANNER"
        
        apiServices.executeGetRequestNoToken(urlToExecute: bannerUrl) { (jsonResponse, error) in
            
            if error != nil {
                print("error= \(String(describing: error))")
                self.loadBannersDone = true
                self.loadBannersDoneServapErr = true
                self.closeProgressHud()
                return
            }
            guard let responseDict = jsonResponse else {
                print("error= \(String(describing: error))")
                self.loadBannersDone = true
                self.loadBannersDoneServapErr = true
                self.closeProgressHud()
                return
            }
            
            let success = responseDict["success"] as? Bool
            if success! {
                if let dataResult = responseDict["data"] as? NSArray {
                    self.banners = dataResult
                    
                    DispatchQueue.main.async {
                        
                        if self.banners.count > 0 {
                            
                            let pages = Int(dataResult.count / 1)
                            self.bannerPageControl.numberOfPages = pages
                            self.bannerPageControl.isHidden = !(pages > 1)
                            self.bannerCollectionView.reloadData()
                            self.bannerCollectionView.performBatchUpdates(nil, completion: { (result) in
                                self.loadBannersDone = true
                                self.closeProgressHud()
                                self.startBannerScrollingTimer()
                            })
                            
                        } else {
                            self.bannerCollectionView.backgroundView = self.noDataView
                            self.loadBannersDone = true
                            self.closeProgressHud()
                        }
                    }
                }
                
            } else {
                let message = responseDict["message"] as? String
                print(message!)
                
                if let expToken = responseDict["errcode"] as? String {
                    if expToken == "exp-token" {
                        self.loadBannersErr = true
                    }
                }
                self.loadBannersDone = true
                self.closeProgressHud()
            }
            
        }
    }
    
    func getGenreData() {
        
        //Send HTTP request to perform Get Genre
        let strUrl = hostUrl + "/msconfigbygroup/GENRE"
        
        apiServices.executeGetRequestNoToken(urlToExecute: strUrl) { (jsonResponse, error) in
            
            if error != nil {
                print("error= \(String(describing: error))")
                self.loadGenresDone = true
                self.loadGenresDoneServapErr = true
                self.closeProgressHud()
                return
            }
            
            guard let responseDict = jsonResponse else {
                print("error= \(String(describing: error))")
                self.loadGenresDone = true
                self.loadGenresDoneServapErr = true
                self.closeProgressHud()
                return
            }
            
            let success = responseDict["success"] as? Bool
            if success! {
                if let dataResult = responseDict["data"] as? NSArray {
                    self.genres = dataResult
                    
                    DispatchQueue.main.async {
                        
                        if self.genres.count > 0 {
                            self.genreCollectionView.reloadData()
                        } else {
                            self.genreCollectionView.backgroundView = self.noDataView
                        }
                    }
                }
                
            } else {
                let message = responseDict["message"] as? String
                print(message!)
                
                if let expToken = responseDict["errcode"] as? String {
                    if expToken == "exp-token" {
                        self.loadGenresErr = true
                    }
                }
            }
            DispatchQueue.main.async {
                self.genreCollectionView.performBatchUpdates(nil, completion: { (result) in
                    self.loadGenresDone = true
                    self.closeProgressHud()
                })
            }
       
        }
    }
    
    private func initiateLoadingInd() {
        loadBannersDone = false
        loadGenresDone = false
        loadTopSongsDone = false
        loadRecentSongsDone = false
        loadUserPlaylistDone = false
    }
    
    private func initiateServapErrInd() {
        loadBannersDoneServapErr = false
        loadGenresDoneServapErr = false
        loadTopSongsDoneServapErr = false
        loadRecentSongsDoneServapErr = false
        loadUserPlaylistDoneServapErr = false
    }
    
    func startBannerScrollingTimer() {
        
        
        
        scrollingTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(updateBannerWithTimer(_ :)), userInfo: nil, repeats: true)
        
    }
    
    @objc func updateBannerWithTimer(_ : Timer){
        //Change the current page
        
        let numberOfBanners: Int = self.banners.count - 1
        if rowIndex < numberOfBanners {
            rowIndex = rowIndex + 1
        } else {
            rowIndex = 0
        }
        
        self.bannerCollectionView.scrollToItem(at: IndexPath(row: rowIndex, section: 0), at: .centeredHorizontally, animated: true)
    }
    
    func closeProgressHud() {

        if ( loadBannersDone && loadGenresDone && loadTopSongsDone && loadRecentSongsDone && loadUserPlaylistDone ) {
            
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                dismissProgressHud()
            }
            
            if ( loadBannersDoneServapErr || loadGenresDoneServapErr || loadTopSongsDoneServapErr || loadRecentSongsDoneServapErr || loadUserPlaylistDoneServapErr ) {
                
                DispatchQueue.main.async {
                    self.refreshControl.endRefreshing()
                    ToastMessageView.shared.long(self.view, txt_msg: "There is Server/App Error or Disconnected. Please try again later.")
                }
                
            }
            
            goToLogout()
        }
        
    }
    
    private func goToLogout() {
        
        if ( loadBannersErr || loadGenresErr || loadTopSongsErr || loadRecentSongsErr || loadUserPlaylistErr ) {
            
            logout(presentingVc: self)
        }
        
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
    
}

extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var cellWidth: CGFloat = 0
        var cellHeight: CGFloat = 0
        
        switch collectionView {
        case bannerCollectionView:
            cellWidth = view.frame.width
            cellHeight = 130
        case genreCollectionView:
            cellWidth = 114
            cellHeight = 114
        case topSongsCollectionView:
            cellWidth = view.frame.width
            cellHeight = 50
        case recentSongsCollectionView:
            cellWidth = view.frame.width
            cellHeight = 50
        default:
            break
        }
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
}

extension HomeViewController: BuySongViewControllerDelegate {
    func refreshData(_ song: Any?) {
        showProgressHud()
        DispatchQueue.main.asyncAfter(deadline: .now() + APPCONSTANT.refreshDelay) { // change 3 to desired number of seconds
            self.initiateLoadingInd()
            self.initiateServapErrInd()
            DispatchQueue.global(qos: .userInteractive).async {
                //  your code to refresh tableView
                self.getUserPlaylistData(page: 1)
                self.getBannerImage()
            }
        }
    }
}
