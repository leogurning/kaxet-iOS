//
//  SearchViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 22/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class SearchViewController: UIViewController {
    
    let apiServices = RestAPIServices()
    
    let apiUrl = APPURL.BaseURL
    let hostUrl = APPURL.Domain
    
    var accessToken: String = ""
    var userid: String = ""
    
    private var userPlaylist: NSArray = []
    private var playlistNPages: Int = 0
    var songDataForSegue: NSDictionary = [:]
    private var loadUserPlaylistDone: Bool = false
    private var loadSongDone: Bool = false
    private var loadUserPlaylistErr: Bool = false
    
    private var resultSongs: NSMutableArray = []
    private var currentPage: Int = 1
    private var maxPages: Int = 1
    /*
    var miniPlayerVc: MiniPlayerViewController?
    var miniPlayerView: UIView?
    */
    @IBOutlet weak var recentSearchTableView: UITableView!
    @IBOutlet weak var searchResultTableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchIconView: UIView!
    @IBOutlet weak var searchIconImage: UIImageView!
    @IBOutlet weak var clearRecentSearch: UIButton!
    @IBOutlet weak var recentSearchTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var resultSongsPageControl: UIPageControl!
    
    @IBOutlet weak var btnPrevPage: UIButton!
    @IBOutlet weak var btnNextPage: UIButton!
    @IBOutlet var noDataView: UIView!
    
    private var searchStringArray: [String] = []
    private var saveSearchText: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        accessToken = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Token)!
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
        
        searchTextField.delegate = self
        
        searchResultTableView.delegate = self
        searchResultTableView.dataSource = self
        searchResultTableView.register(UINib(nibName: "SongListTableViewCell", bundle: nil), forCellReuseIdentifier: "SongListCell")
        
        recentSearchTableView.delegate = self
        recentSearchTableView.dataSource = self
        
        recentSearchTableView.isHidden = true
        
        configureRecentSearchTableView()
        activateSearchResultTable()
        
        initiateSearchView()
        addTapGesture()
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture(gesture:)))
        swipeLeft.direction = .left
        searchResultTableView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture(gesture:)))
        swipeRight.direction = .right
        searchResultTableView.addGestureRecognizer(swipeRight)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {

        if let searchArray = UserDefaults.standard.object(forKey: "recentSearch") as? [String] {
            self.searchStringArray = searchArray
        }
        self.resultSongs.removeAllObjects()
        searchResultTableView.reloadData()
        initiateSearchView()
        resetPageNavigation()
    }
    
    func resetPageNavigation() {
        self.currentPage = 1
        btnNextPage.isHidden = true
        btnPrevPage.isHidden = true
        self.resultSongsPageControl.isHidden = true
        self.resultSongsPageControl.currentPage = 0
    }
    
    @IBAction func clearRecentSearch(_ sender: UIButton) {
        removeRecentSearch()
        //searchTextField.endEditing(true)
        activateSearchResultTable()
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
                    resultSongsPageControl.currentPage = self.currentPage - 1
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
                    resultSongsPageControl.currentPage = self.currentPage - 1
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
    @IBAction func btnPrevPagePressed(_ sender: UIButton) {
        self.currentPage -= 1
        showProgressHud()
        self.loadUserPlaylistDone = true
        self.loadSongDone = false
        getSongsBySearchText(page: self.currentPage, isInit: false)
        resultSongsPageControl.currentPage = self.currentPage - 1
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
        resultSongsPageControl.currentPage = self.currentPage - 1
        switch self.currentPage {
        case _ where self.currentPage < self.maxPages:
            break
        default:
            btnNextPage.isHidden = true
        }
        btnPrevPage.isHidden = false
        
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
 
    
    func initiateSearchView() {
        self.searchTextField.text = ""
        self.searchTextFieldEndEditing(saveInd: false)
        self.clearDisplay()
    }
    
    func removeRecentSearch() {
        self.searchStringArray.removeAll()
        UserDefaults.standard.removeObject(forKey: "recentSearch")
    }
    
    func activateSearchResultTable() {
        configureSearchResultTableView()
        self.recentSearchTableView.isHidden = true
        self.searchResultTableView.isHidden = false
    }
    
    func activateRecentSearchTable() {
        self.recentSearchTableView.isHidden = false
        //self.searchResultTableView.isHidden = true
        DispatchQueue.main.async {
            self.setRecentSearchTableHeight()
        }
    }
    
    func clearDisplay() {
        self.recentSearchTableView.isHidden = true
        //self.searchResultTableView.isHidden = true
    }
    
    func configureRecentSearchTableView() {
        self.recentSearchTableView.estimatedRowHeight = 40
        self.recentSearchTableView.rowHeight = UITableView.automaticDimension
    }
    
    func configureSearchResultTableView() {
        //genreSongsTableView.rowHeight = UITableViewAutomaticDimension
        //genreSongsTableView.estimatedRowHeight = 70
        searchResultTableView.rowHeight = 60
        searchResultTableView.separatorStyle = .none
        searchResultTableView.tableFooterView = UIView(frame: CGRect.zero)
        
    }
    
    func setRecentSearchTableHeight() {
        
        let noOfItem = self.searchStringArray.count
        let actualHeight = 40 * noOfItem
        
        recentSearchTableHeightConstraint.constant = 41 + CGFloat(actualHeight) + 5
        self.view.layoutIfNeeded()
    }
    
    func searchTextFieldEndEditing(saveInd: Bool) {
        
        saveSearchText = saveInd
        searchTextField.endEditing(true)
        
    }
    
    func addTapGesture() {
        
        searchResultTableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapRemoveRecentSearchTableView(_:))))
        searchIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSearchIconView(_:))))
        searchIconImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSearchIconView(_:))))
        
        //view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapRemoveKeyboard(_:))))
    }
    
    @objc func tapRemoveKeyboard(_ sender: UITapGestureRecognizer) {
        
        self.searchTextField.resignFirstResponder()
        self.recentSearchTableView.isHidden = true

    }
    
    @objc func tapRemoveRecentSearchTableView(_ sender: UITapGestureRecognizer) {
        
        self.searchTextFieldEndEditing(saveInd: false)
        self.recentSearchTableView.isHidden = true
        
    }
    
    @objc func tapSearchIconView(_ sender: UITapGestureRecognizer) {
        
        guard let searchText = self.searchTextField.text else {
            DispatchQueue.main.async {
                ToastMessageView.shared.long(self.view, txt_msg: "Please input the search text!")
            }
            
            return
        }
        saveToRecentSearch(text: searchText)
    }
    
    func getSongsBySearchText(page: Int, isInit: Bool) {
        
        //showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            DispatchQueue.main.async {
                let searchString = self.searchTextField.text
            
            //Send HTTP request to perform Get Top Songs
            let restUrl = self.apiUrl + "/songln/aggreportln2/\(self.userid)?page=\(page)"
            
            let postString = ["status": "STSACT", "songpublish": "Y", "songname": searchString!] as NSDictionary
            
            self.apiServices.executePostRequestWithToken(urlToExecute: restUrl, bodyDict: postString, completion: { (jsonResponse, error) in
                //code
                
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
                    //print("Successfully populated !")
                    if let dataResult = responseDict["data"] as? NSMutableArray {
                        self.resultSongs = dataResult
                        let resultNPages = responseDict["npage"] as! Int
                        self.maxPages = resultNPages
                
                        if self.resultSongs.count > 0 {
                            DispatchQueue.main.async {
                                if isInit {
                                    
                                    switch resultNPages {
                                    case _ where resultNPages > 1:
                                        self.btnNextPage.isHidden = false
                                        self.resultSongsPageControl.isHidden = false
                                        self.resultSongsPageControl.numberOfPages = resultNPages
                                    default:
                                        self.btnNextPage.isHidden = true
                                        self.resultSongsPageControl.isHidden = true
                                    }
                                    
                                    //self.genreSongsPageControl.isHidden = !(resultNPages > 1)
                                    self.searchResultTableView.backgroundView = nil
                                }
                                self.searchResultTableView.reloadData()
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.resultSongsPageControl.isHidden = true
                                self.btnPrevPage.isHidden = true
                                self.btnNextPage.isHidden = true
                                self.searchResultTableView.backgroundView = self.noDataView
                                
                                self.searchResultTableView.reloadData()
                            }
                        }
                        
                    }
                    self.loadSongDone = true
                    self.closeProgressHud()
                } else {
                    let message = responseDict["message"] as? String
                    DispatchQueue.main.async {
                        self.resultSongsPageControl.isHidden = true
                        self.btnPrevPage.isHidden = true
                        self.btnNextPage.isHidden = true
                        //self.genreSongsTableView.backgroundView = self.noDataView
                        self.searchResultTableView.reloadData()
                    }
                    //ToastMessageView.shared.long(self.view, txt_msg: message!)
                    print(message!)
                    self.loadSongDone = true
                    self.closeProgressHud()
                }
            })
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
                        self.configureSearchResultTableView()
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

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         if tableView == searchResultTableView {
            return self.resultSongs.count
         } else if tableView == recentSearchTableView {
            return self.searchStringArray.count
         } else {
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == searchResultTableView {
            guard let searchresulttablecell = tableView.dequeueReusableCell(withIdentifier: "SongListCell", for: indexPath) as? SongListTableViewCell else {
                return UITableViewCell()
            }
            guard let songData = self.resultSongs[indexPath.row] as? NSDictionary else {
                return UITableViewCell()
            }
            
            searchresulttablecell.initData(data: songData)
            
            let pcsFlag = songData["pcsflag"] as? String
            searchresulttablecell.playOrBuyTapAction = {
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
            
            searchresulttablecell.addToPlaylistTapAction = {
                // implement your logic here, e.g. call preformSegue()
                self.addToPlaylist(data: songData)
            }
            
            searchresulttablecell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapTableSongCell(_:))))
            
            return searchresulttablecell
            
        } else if tableView == recentSearchTableView {
            guard let recentsearchtablecell = tableView.dequeueReusableCell(withIdentifier: "recentSearchCell", for: indexPath) as? RecentSearchTableViewCell else {
                return UITableViewCell()
            }
            recentsearchtablecell.searchHistoryItem.text = self.searchStringArray[indexPath.row]
            
            return recentsearchtablecell
            
        } else {
            return UITableViewCell()
        }
        
    }
    
    @objc func tapTableSongCell(_ sender: UITapGestureRecognizer) {
        
        let location = sender.location(in: self.searchResultTableView)
        let indexPath = self.searchResultTableView.indexPathForRow(at: location)
        searchTextField.resignFirstResponder()
        if let index = indexPath {
            let selectedSong = resultSongs[index.row] as? NSDictionary
            
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == searchResultTableView {
            
        } else if tableView == recentSearchTableView {
            let searchItem = self.searchStringArray[indexPath.row] as String
            searchTextField.text = searchItem
        }
        
    }

}

extension SearchViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        //print(self.searchStringArray[0])
        self.searchTextField.text = ""
        if self.searchStringArray.count > 0 {
            recentSearchTableView.reloadData()
            activateRecentSearchTable()
        }
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        //print("TextField did end editing method called\(String(describing: textField.text))")
        if self.saveSearchText {
            guard let searchText = textField.text else {
                return
            }
            let noOfItem = self.searchStringArray.count
            if searchText == "" {
                //No Action if the search Text is blank
            } else {
                if self.searchStringArray.contains(searchText) {
                    //No Action if the text is already in the recent Search Array
                } else {
                    //Append the search text to the recent Search Array
                    self.searchStringArray.append(searchText)
                }
                
                if noOfItem < 10 {
                    //No Action if the count of recent Search Array still below 10
                } else {
                    self.searchStringArray.remove(at: 0)
                }
                UserDefaults.standard.set(self.searchStringArray, forKey: "recentSearch")
            }
            
            activateSearchResultTable()
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        //textField.resignFirstResponder()  //if desired
        guard let searchText = textField.text else {
            return true
        }
        saveToRecentSearch(text: searchText)
        return true
    }
    
    func saveToRecentSearch(text: String) {
        //action events
        searchTextFieldEndEditing(saveInd: true)
        
        if text == "" {
            //No Action
            DispatchQueue.main.async {
                ToastMessageView.shared.long(self.view, txt_msg: "Please input the search text!")
            }
            
        } else {
            self.loadUserPlaylistDone = false
            self.loadSongDone = false
            showProgressHud()
            DispatchQueue.global(qos: .userInteractive).async {
                self.getUserPlaylistData(page: 1)
            }
        }
        
        /*
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            self.getUserPlaylistData(page: 1)
        }
        */
    }
}

extension SearchViewController: BuySongViewControllerDelegate {
    func refreshData(_ song: Any?) {
        showProgressHud()
        DispatchQueue.main.asyncAfter(deadline: .now() + APPCONSTANT.refreshDelay) { // change 3 to desired number of seconds
            self.loadUserPlaylistDone = false
            self.loadSongDone = false
            self.resetPageNavigation()
            DispatchQueue.global(qos: .userInteractive).async {
                //  your code to refresh tableView
                self.getUserPlaylistData(page: 1)
            }
        }
        
        
    }
    
    
}
