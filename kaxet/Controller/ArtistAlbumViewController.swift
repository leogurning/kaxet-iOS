//
//  ArtistAlbumViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 24/11/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class ArtistAlbumViewController: UIViewController {

    let apiServices = RestAPIServices()
    
    let apiUrl = APPURL.BaseURL
    let hostUrl = APPURL.Domain
    
    private var userid: String = ""
    private var accessToken: String = ""
    private var loadAlbumsErr: Bool = false
    private var albums: NSArray = []
    private var currentPage: Int = 1
    private var maxPages: Int = 1
    
    private var navBackImage: UIImage?
    private var navShadowBackImage: UIImage?
    private var navTintColor: UIColor?
    private var refreshControl: UIRefreshControl!
    
    @IBOutlet weak var backMenuView: UIView!
    @IBOutlet weak var artistNameView: UIView!
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var coverArtistImage: KxCustomImageView!
    @IBOutlet weak var artistImage: KxCustomImageView!
    @IBOutlet weak var totalAlbumLabel: UILabel!
    @IBOutlet weak var albumMenuLineView: UIView!
    @IBOutlet weak var aboutMenuLineView: UIView!
    @IBOutlet weak var detailAboutView: UIView!
    @IBOutlet weak var detailAboutLabel: UILabel!
    
    @IBOutlet weak var detailAlbumView: UIView!
    
    @IBOutlet weak var albumListTableView: UITableView!
    @IBOutlet weak var pageNavView: UIView!
    @IBOutlet weak var btnPrevPage: UIButton!
    @IBOutlet weak var btnNextPage: UIButton!
    @IBOutlet weak var albumPageControl: UIPageControl!
    
    private var artist: NSDictionary = [:]
    private var albumForSegue: NSDictionary = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        accessToken = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Token)!
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
        
        albumListTableView.delegate = self
        albumListTableView.dataSource = self
        albumListTableView.register(UINib(nibName: "AlbumTableViewCell", bundle: nil), forCellReuseIdentifier: "albumCell")
        configureAlbumTableView()
        
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
        setOriginalNavBar()
        hideNavBar()
        getAlbumData(page: 1, isInit: true)
        resetPageNavigation()
        setHeaderData()
        showAlbumDetail()
    }
    
    @objc func refresh(_ sender: Any) {
        //  your code to refresh tableView
        getAlbumData(page: 1, isInit: true)
        resetPageNavigation()
        setHeaderData()
        showAlbumDetail()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        resetNavBar()
    }
    
    func initData(data: NSDictionary) {
        self.artist = data
        
    }
    
    func resetPageNavigation() {
        self.currentPage = 1
        btnNextPage.isHidden = true
        btnPrevPage.isHidden = true
        self.albumPageControl.isHidden = true
        self.albumPageControl.currentPage = 0
    }
    
    func setHeaderData() {
        let artistphotopath = artist["artistphotopath"] as? String
        let artistName = artist["artistname"] as? String
        let about = artist["about"] as? String
        coverArtistImage.loadImageUsingUrlString(urlString: artistphotopath)
        coverView.clipsToBounds = true
        artistImage.loadImageUsingUrlString(urlString: artistphotopath)
        artistImage.layer.cornerRadius = 5
        artistImage.clipsToBounds = true
        artistNameLabel.text = artistName
        detailAboutLabel.text = about
        
        artistNameView.layer.cornerRadius = 5
        artistNameView.clipsToBounds = true
        artistNameView.backgroundColor = UIColor(hex: 0x333, alpha: 0.3)
        backMenuView.layer.cornerRadius = 5
        backMenuView.clipsToBounds = true
        backMenuView.backgroundColor = UIColor(hex: 0x333, alpha: 0.3)
    }
    
    func hideNavBar() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        //self.navigationController?.view.backgroundColor = .clear
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    func setOriginalNavBar() {
        navBackImage = self.navigationController?.navigationBar.backgroundImage(for: .default)
        navShadowBackImage = self.navigationController?.navigationBar.shadowImage
        navTintColor = self.navigationController?.navigationBar.tintColor
        
    }
    
    func resetNavBar() {
        self.navigationController?.navigationBar.setBackgroundImage(navBackImage, for: .default)
        self.navigationController?.navigationBar.shadowImage = navShadowBackImage
        self.navigationController?.navigationBar.isTranslucent = false
        //self.navigationController?.view.backgroundColor = .clear
        self.navigationController?.navigationBar.tintColor = navTintColor
    }
    
    func showAboutDetail() {
        detailAboutView.isHidden = false
        aboutMenuLineView.backgroundColor = UIColor(hex: 0xFCE86C, alpha: 1)
        detailAlbumView.isHidden = true
        albumMenuLineView.backgroundColor = UIColor.white
    }
    
    func showAlbumDetail() {
        detailAboutView.isHidden = true
        aboutMenuLineView.backgroundColor = UIColor.white
        detailAlbumView.isHidden = false
        albumMenuLineView.backgroundColor = UIColor(hex: 0xFCE86C, alpha: 1)
    }
    
    func configureAlbumTableView() {
        //genreSongsTableView.rowHeight = UITableViewAutomaticDimension
        //genreSongsTableView.estimatedRowHeight = 70
        albumListTableView.rowHeight = 60
        albumListTableView.separatorStyle = .none
        albumListTableView.tableFooterView = UIView(frame: CGRect.zero)
        
    }
    
    func getAlbumData(page: Int, isInit: Bool) {
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            DispatchQueue.main.async {
                let artistid = self.artist["_id"] as? String
                
                //Send HTTP request to perform Get Top Songs
                let restUrl = self.apiUrl + "/albumln/aggreportln?page=\(page)"
                
                let postString = ["status": "STSACT", "artistid": artistid!] as NSDictionary
                //let postString = ["status": "STSACT"] as NSDictionary
                
                self.apiServices.executePostRequestWithToken(urlToExecute: restUrl, bodyDict: postString, completion: { (jsonResponse, error) in
                    //code
                    
                    DispatchQueue.main.async {
                        dismissProgressHud()
                        self.refreshControl.endRefreshing()
                    }
                    
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
                            self.albums = dataResult
                            let resultNPages = responseDict["npage"] as! Int
                            self.maxPages = resultNPages
                            
                            if self.albums.count > 0 {
                                DispatchQueue.main.async {
                                    if isInit {
                                        if self.albums.count > 1 {
                                            self.totalAlbumLabel.text = "\(self.albums.count) Albums"
                                        } else {
                                            self.totalAlbumLabel.text = "\(self.albums.count) Album"
                                        }
                                        
                                        switch resultNPages {
                                            case _ where resultNPages > 1:
                                                self.btnNextPage.isHidden = false
                                                self.albumPageControl.isHidden = false
                                                self.albumPageControl.numberOfPages = resultNPages
                                            default:
                                                self.btnNextPage.isHidden = true
                                                self.albumPageControl.isHidden = true
                                        }
                                        self.albumListTableView.backgroundView = nil
                                    }
                                    self.albumListTableView.reloadData()
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.albumPageControl.isHidden = true
                                    self.btnPrevPage.isHidden = true
                                    self.btnNextPage.isHidden = true
                                    self.albumListTableView.backgroundView = nil
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
    
    @IBAction func btnAlbumPressed(_ sender: UIButton) {
        showAlbumDetail()
    }
    
    @IBAction func btnAboutPressed(_ sender: UIButton) {
        showAboutDetail()
    }
    
    @IBAction func btnPrevPagePressed(_ sender: UIButton) {
        self.currentPage -= 1
        
        getAlbumData(page: self.currentPage, isInit: false)
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
        
        getAlbumData(page: self.currentPage, isInit: false)
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
                    getAlbumData(page: self.currentPage, isInit: false)
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
                    getAlbumData(page: self.currentPage, isInit: false)
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
 

}

extension ArtistAlbumViewController: UITableViewDelegate, UITableViewDataSource {
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
        let albumYear = albumData["albumyear"] as? String
        let albumImagePath = albumData["albumphotopath"] as? String
        
        albumtablecell.albumTopLabel.text = albumYear
        albumtablecell.albumTopLabel.font = UIFont(name: "TrebuchetMS", size: 12)
        albumtablecell.albumBottomLabel.text = albumName
        albumtablecell.albumBottomLabel.font = UIFont(name: "TrebuchetMS-Bold", size: 17)
        albumtablecell.albumBottomLabelBottomConstraint.constant = 8
        
        albumtablecell.albumImage.loadImageUsingUrlString(urlString: albumImagePath)
        albumtablecell.selectionStyle = .none
        
        return albumtablecell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        albumForSegue = albums[indexPath.row] as! NSDictionary
        //print("Artist selected: \(String(describing: artist!["artistname"]))")
        performSegue(withIdentifier: "goToAlbumSong", sender: self)
        
    }
}
