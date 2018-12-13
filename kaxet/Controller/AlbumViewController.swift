//
//  AlbumViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 26/11/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class AlbumViewController: UIViewController {
    let apiServices = RestAPIServices()
    
    let apiUrl = APPURL.BaseURL
    let hostUrl = APPURL.Domain
    
    private var userid: String = ""
    private var accessToken: String = ""
    private var loadAlbumsErr: Bool = false
    private var albums: NSArray = []
    private var currentPage: Int = 1
    private var maxPages: Int = 1
    private var albumForSegue: NSDictionary = [:]
    private var refreshControl: UIRefreshControl!
    private var keyboardActive: Bool = false
    
    @IBOutlet weak var albumSearchText: UITextField!
    @IBOutlet weak var searchIconView: UIView!
    @IBOutlet weak var searchIconImage: UIImageView!
    @IBOutlet weak var albumListTableView: UITableView!
    @IBOutlet weak var btnPrevPage: UIButton!
    @IBOutlet weak var btnNextPage: UIButton!
    @IBOutlet weak var albumPageControl: UIPageControl!
    @IBOutlet var noDataView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        accessToken = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Token)!
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
        
        albumSearchText.delegate = self
        
        albumListTableView.delegate = self
        albumListTableView.dataSource = self
        albumListTableView.register(UINib(nibName: "AlbumTableViewCell", bundle: nil), forCellReuseIdentifier: "albumCell")
        configureAlbumTableView()
        
        addTapGesture()
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        albumListTableView.addSubview(refreshControl)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture(gesture:)))
        swipeLeft.direction = .left
        albumListTableView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture(gesture:)))
        swipeRight.direction = .right
        albumListTableView.addGestureRecognizer(swipeRight)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        keyboardActive = false
        resetPageNavigation()
        getAlbumsBySearchText(page: 1, isInit: true)
    }
    
    @objc func refresh(_ sender: Any) {
        //  your code to refresh tableView
        keyboardActive = false
        resetPageNavigation()
        getAlbumsBySearchText(page: 1, isInit: true)
    }
    
    func resetPageNavigation() {
        self.currentPage = 1
        btnNextPage.isHidden = true
        btnPrevPage.isHidden = true
        self.albumPageControl.isHidden = true
        self.albumPageControl.currentPage = 0
    }
    
    func configureAlbumTableView() {
        //genreSongsTableView.rowHeight = UITableViewAutomaticDimension
        //genreSongsTableView.estimatedRowHeight = 70
        albumListTableView.rowHeight = 60
        albumListTableView.separatorStyle = .none
        albumListTableView.tableFooterView = UIView(frame: CGRect.zero)
        
    }
    
    func getAlbumsBySearchText(page: Int, isInit: Bool) {
        
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            DispatchQueue.main.async {
                let searchString = self.albumSearchText.text

                //Send HTTP request to perform Get Top Songs
                let restUrl = self.apiUrl + "/albumln/aggreportln?page=\(page)"
                
                let postString = ["status": "STSACT", "albumname": searchString!] as NSDictionary
                
                self.apiServices.executePostRequestWithToken(urlToExecute: restUrl, bodyDict: postString, completion: { (jsonResponse, error) in
                    //code
                    
                    DispatchQueue.main.async {
                        dismissProgressHud()
                        self.refreshControl.endRefreshing()
                    }
                    
                    if error != nil {
                        print("error= \(String(describing: error))")
                        DispatchQueue.main.async {
                            ToastMessageView.shared.long(self.view, txt_msg: "Server Error. Please try again later.")
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
                            self.albums = dataResult
                            let resultNPages = responseDict["npage"] as! Int
                            self.maxPages = resultNPages
                            
                            if self.albums.count > 0 {
                                DispatchQueue.main.async {
                                    if isInit {
                                        
                                        switch resultNPages {
                                        case _ where resultNPages > 1:
                                            self.btnNextPage.isHidden = false
                                            self.albumPageControl.isHidden = false
                                            self.albumPageControl.numberOfPages = resultNPages
                                        default:
                                            self.btnNextPage.isHidden = true
                                            self.albumPageControl.isHidden = true
                                        }
                                        
                                        //self.genreSongsPageControl.isHidden = !(resultNPages > 1)
                                        self.albumListTableView.backgroundView = nil
                                    }
                                    self.albumListTableView.reloadData()
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.albumPageControl.isHidden = true
                                    self.btnPrevPage.isHidden = true
                                    self.btnNextPage.isHidden = true
                                    self.albumListTableView.backgroundView = self.noDataView
                                    
                                    self.albumListTableView.reloadData()
                                }
                            }
                            
                        }
                        
                    } else {
                        let message = responseDict["message"] as? String
                        DispatchQueue.main.async {
                            self.albumPageControl.isHidden = true
                            self.btnPrevPage.isHidden = true
                            self.btnNextPage.isHidden = true
                            //self.genreSongsTableView.backgroundView = self.noDataView
                            self.albumListTableView.reloadData()
                        }
                        //ToastMessageView.shared.long(self.view, txt_msg: message!)
                        print(message!)
                        if let expToken = responseDict["errcode"] as? String {
                            if expToken == "exp-token" {
                                self.loadAlbumsErr = true
                                logout(presentingVc: self)
                            }
                        }
                    }
                })
            }
        }
    }
    
    func addTapGesture() {
        
        searchIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSearchIcon(_:))))
        searchIconImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSearchIcon(_:))))
        
        let tapOnTableview: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapRemoveKeyboard(_:)))
        tapOnTableview.cancelsTouchesInView = false
        self.albumListTableView.addGestureRecognizer(tapOnTableview)
        
    }
    
    @objc func tapRemoveKeyboard(_ sender: UITapGestureRecognizer) {
        //keyboardActive = false
        albumSearchText.resignFirstResponder()
        
    }
    
    @objc func tapSearchIcon(_ sender: UITapGestureRecognizer) {
        
        getAlbumsBySearchText(page: 1, isInit: true)
        albumSearchText.endEditing(true)
        
    }
    
    /*
    // MARK: - Navigation
    */
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
        case "goToAlbumSong":
            // Create a new variable to store the instance of ArtistAlbumViewController
            let destinationVC = segue.destination as! AlbumSongViewController
            destinationVC.initData(data: albumForSegue)
        default:
            break
        }
    }
 

    @IBAction func btnPrevPagePressed(_ sender: UIButton) {
        self.currentPage -= 1
        
        getAlbumsBySearchText(page: self.currentPage, isInit: false)
        albumPageControl.currentPage = self.currentPage - 1
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
        
        getAlbumsBySearchText(page: self.currentPage, isInit: false)
        albumPageControl.currentPage = self.currentPage - 1
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
                    getAlbumsBySearchText(page: self.currentPage, isInit: false)
                    albumPageControl.currentPage = self.currentPage - 1
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
                    getAlbumsBySearchText(page: self.currentPage, isInit: false)
                    albumPageControl.currentPage = self.currentPage - 1
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
}

extension AlbumViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let albumtablecell = tableView.dequeueReusableCell(withIdentifier: "albumCell", for: indexPath) as? AlbumTableViewCell else {
            return UITableViewCell()
        }
        guard let albumData = self.albums[indexPath.row] as? NSDictionary else {
            return UITableViewCell()
        }
        
        let albumName = albumData["albumname"] as? String
        let artistName = albumData["artist"] as? String
        let albumImagePath = albumData["albumphotopath"] as? String
        
        albumtablecell.albumTopLabel.text = albumName
        albumtablecell.albumTopLabel.font = UIFont(name: "TrebuchetMS-Bold", size: 17)
        albumtablecell.albumBottomLabel.text = artistName
        albumtablecell.albumBottomLabel.font = UIFont(name: "TrebuchetMS", size: 12)
        albumtablecell.albumBottomLabelBottomConstraint.constant = 8
        
        albumtablecell.arrowImage.isHidden = false
        albumtablecell.albumImage.loadImageUsingUrlString(urlString: albumImagePath)
        albumtablecell.selectionStyle = .none
        
        return albumtablecell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if keyboardActive {
            self.albumSearchText.resignFirstResponder()
            keyboardActive = false
        } else {
            albumForSegue = albums[indexPath.row] as! NSDictionary
            //print("Artist selected: \(String(describing: artist!["artistname"]))")
            performSegue(withIdentifier: "goToAlbumSong", sender: self)
        }
        
    }
}

extension AlbumViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        keyboardActive = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        getAlbumsBySearchText(page: 1, isInit: true)
        keyboardActive = false
        textField.endEditing(true)
        return true
        
    }
}
