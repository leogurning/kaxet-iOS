//
//  PurchaseInfoViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 06/12/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class PurchaseInfoViewController: UIViewController {

    let apiServices = RestAPIServices()
    
    let apiUrl = APPURL.BaseURL
    let hostUrl = APPURL.Domain
    
    private var userid: String = ""
    private var accessToken: String = ""
    private var loadSongDone: Bool = false
    private var loadSongsErr: Bool = false
    private var songs: NSArray = []
    private var currentPage: Int = 1
    private var maxPages: Int = 1
    private var refreshControl: UIRefreshControl!
    private var isCompleted: Bool = true
    
    @IBOutlet weak var completedListView: UIView!
    @IBOutlet weak var pendingListView: UIView!
    @IBOutlet weak var searchSongText: UITextField!
    @IBOutlet weak var searchIconView: UIView!
    @IBOutlet weak var searchIconImage: UIImageView!
    @IBOutlet weak var btnPrevPage: UIButton!
    @IBOutlet weak var btnNextPage: UIButton!
    @IBOutlet weak var songPageControl: UIPageControl!
    @IBOutlet weak var songListTableView: UITableView!
    
    @IBOutlet var noDataView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
        
        searchSongText.delegate = self
        songListTableView.delegate = self
        songListTableView.dataSource = self
        configureSongTableView()
        completedListView.backgroundColor = UIColor(hex: 0xFCE86C, alpha:1)
        
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
        resetPageNavigation()
        getCompletedSongsBySearchText(page: 1, isInit: true)
    }
    
    @IBAction func btnCompletedPressed(_ sender: UIButton) {
        
        completedListView.backgroundColor = UIColor(hex: 0xFCE86C, alpha:1)
        pendingListView.backgroundColor = UIColor.clear
        resetPageNavigation()
        getCompletedSongsBySearchText(page: 1, isInit: true)
    }
    
    @IBAction func btnPendingPressed(_ sender: UIButton) {
        
        completedListView.backgroundColor = UIColor.clear
        pendingListView.backgroundColor = UIColor(hex: 0xFCE86C, alpha:1)
        resetPageNavigation()
        getPendingSongsBySearchText(page: 1, isInit: true)
    }
    
    @objc func refresh(_ sender: Any) {
        //  your code to refresh tableView
        resetPageNavigation()
        if isCompleted {
            getCompletedSongsBySearchText(page: 1, isInit: true)
        } else {
            getPendingSongsBySearchText(page: 1, isInit: true)
        }
    }
    
    @IBAction func btnPrevPagePressed(_ sender: UIButton) {
        self.currentPage -= 1

        if isCompleted {
            getCompletedSongsBySearchText(page: self.currentPage, isInit: false)
        } else {
            getPendingSongsBySearchText(page: self.currentPage, isInit: false)
        }
        
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
        if isCompleted {
            getCompletedSongsBySearchText(page: self.currentPage, isInit: false)
        } else {
            getPendingSongsBySearchText(page: self.currentPage, isInit: false)
        }
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
                    if isCompleted {
                        getCompletedSongsBySearchText(page: self.currentPage, isInit: false)
                    } else {
                        getPendingSongsBySearchText(page: self.currentPage, isInit: false)
                    }
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
                    if isCompleted {
                        getCompletedSongsBySearchText(page: self.currentPage, isInit: false)
                    } else {
                        getPendingSongsBySearchText(page: self.currentPage, isInit: false)
                    }
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

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
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
    
    func getCompletedSongsBySearchText(page: Int, isInit: Bool) {
        loadSongDone = false
        loadSongsErr = false
        isCompleted = true
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            DispatchQueue.main.async {
                let searchString = self.searchSongText.text
                
                //Send HTTP request to perform Get Top Songs
                let restUrl = self.apiUrl + "/songpurchaseagg/\(self.userid)?page=\(page)"
                
                let postString = ["status": "STSAPV", "rptype": "ALL", "songname": searchString!] as NSDictionary
                
                self.apiServices.executePostRequestWithToken(urlToExecute: restUrl, bodyDict: postString, completion: { (jsonResponse, error) in
                    //code
                    
                    if (error != nil) {
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
                            if let expToken = responseDict["errcode"] as? String {
                                if expToken == "exp-token" {
                                    self.loadSongsErr = true
                                }
                            }
                            print(message!)
                            self.loadSongDone = true
                            self.closeProgressHud()
                        }
                        
                    }
                })
            }
        }
    }
    
    func getPendingSongsBySearchText(page: Int, isInit: Bool) {
        loadSongDone = false
        loadSongsErr = false
        isCompleted = false
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            DispatchQueue.main.async {
                let searchString = self.searchSongText.text
                
                //Send HTTP request to perform Get Top Songs
                let restUrl = self.apiUrl + "/pendingsongpurchaseagg/\(self.userid)?page=\(page)"
                
                let postString = ["rptype": "ALL", "songname": searchString!] as NSDictionary
                
                self.apiServices.executePostRequestWithToken(urlToExecute: restUrl, bodyDict: postString, completion: { (jsonResponse, error) in
                    //code
                    
                    if (error != nil) {
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
                            if let expToken = responseDict["errcode"] as? String {
                                if expToken == "exp-token" {
                                    self.loadSongsErr = true
                                }
                            }
                            print(message!)
                            self.loadSongDone = true
                            self.closeProgressHud()
                        }
                        
                    }
                })
            }
        }
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
    
    private func addTapGesture() {
        
        searchIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSearchIconView(_:))))
        searchIconImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSearchIconView(_:))))
        let tapOnTableview: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapRemoveKeyboard(_:)))
        tapOnTableview.cancelsTouchesInView = false
        self.songListTableView.addGestureRecognizer(tapOnTableview)
    }
    
    @objc func tapRemoveKeyboard(_ sender: UITapGestureRecognizer) {
        //keyboardActive = false
        searchSongText.resignFirstResponder()
        
    }
    
    @objc func tapSearchIconView(_ sender: UITapGestureRecognizer) {
        
        if isCompleted {
            resetPageNavigation()
            getCompletedSongsBySearchText(page: 1, isInit: true)
        } else {
            resetPageNavigation()
            getPendingSongsBySearchText(page: 1, isInit: true)
        }
        searchSongText.endEditing(true)
        
    }
    
}

extension PurchaseInfoViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let searchresulttablecell = tableView.dequeueReusableCell(withIdentifier: "SongPurchaseInfoCell", for: indexPath) as? PurchaseInfoTableViewCell else {
            return UITableViewCell()
        }
        
        guard let songData = self.songs[indexPath.row] as? NSDictionary else {
            return UITableViewCell()
        }
        
        let songTitle = songData["song"] as? String
        let artistName = songData["artist"] as? String
        let albumImagePath = songData["albumphoto"] as? String
        searchresulttablecell.albumImage.loadImageUsingUrlString(urlString: albumImagePath)
        
        let purchaseDt = songData["purchasedt"] as? String
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        let formateDate = dateFormatterGet.date(from:purchaseDt!)
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "dd-MM-yyyy" // Output Formated
        
        let printedDate = "\(dateFormatterPrint.string(from: formateDate!))"
        
        let songPrice = songData["songprice"] as? Double
        let songPriceText = convertToCurrency(amount: songPrice!)
        
        searchresulttablecell.songTitleLabel.text = songTitle!
        searchresulttablecell.artistNameLabel.text = artistName!
        
        searchresulttablecell.dateLabel.text = printedDate
        searchresulttablecell.priceLabel.text = songPriceText
        
        return searchresulttablecell
        
    }
    
    
}

extension PurchaseInfoViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if isCompleted {
            resetPageNavigation()
            getCompletedSongsBySearchText(page: 1, isInit: true)
        } else {
            resetPageNavigation()
            getPendingSongsBySearchText(page: 1, isInit: true)
        }
        searchSongText.endEditing(true)
        textField.endEditing(true)
        return true
        
    }
}
