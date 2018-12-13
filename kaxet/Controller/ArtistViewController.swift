//
//  ArtistViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 22/11/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class ArtistViewController: UIViewController {
    
    let apiServices = RestAPIServices()
    
    let apiUrl = APPURL.BaseURL
    let hostUrl = APPURL.Domain
    
    private var userid: String = ""
    private var accessToken: String = ""
    private var loadArtistsErr: Bool = false
    private var artists: NSArray = []
    private var currentPage: Int = 1
    private var maxPages: Int = 1
    private var artistForSegue: NSDictionary = [:]
    private var refreshControl: UIRefreshControl!
    private var keyboardActive: Bool = false
    
    @IBOutlet var noDataView: UIView!
    @IBOutlet weak var artistCollectionView: UICollectionView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchIconView: UIView!
    @IBOutlet weak var searchIconImage: UIImageView!
    @IBOutlet weak var btnPrevPage: UIButton!
    @IBOutlet weak var btnNextPage: UIButton!
    @IBOutlet weak var artistPageControl: UIPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        accessToken = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Token)!
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
        
        artistCollectionView.delegate = self
        artistCollectionView.dataSource = self
        searchTextField.delegate = self
        
        searchIconView.clipsToBounds = true
        searchIconImage.clipsToBounds = true
        addTapGesture()
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        artistCollectionView.addSubview(refreshControl)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture(gesture:)))
        swipeLeft.direction = .left
        artistCollectionView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture(gesture:)))
        swipeRight.direction = .right
        artistCollectionView.addGestureRecognizer(swipeRight)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        keyboardActive = false
        resetPageNavigation()
        getArtistsBySearchText(page: 1, isInit: true)
    }
    /*
    // MARK: - Navigation
     */
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        switch segue.identifier {
        case "goToArtistAlbum":
            // Create a new variable to store the instance of ArtistAlbumViewController
            let destinationVC = segue.destination as! ArtistAlbumViewController
            destinationVC.initData(data: artistForSegue)
        default:
            break
        }
    }
 
    @objc func refresh(_ sender: Any) {
        //  your code to refresh tableView
        keyboardActive = false
        getArtistsBySearchText(page: 1, isInit: true)
        resetPageNavigation()
    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        
        if self.maxPages > 1 {
            if gesture.direction == UISwipeGestureRecognizer.Direction.right {
                //print("Swipe Right")
                
                let activePage = self.currentPage - 1
                
                switch activePage {
                case _ where activePage >= 1:
                    self.currentPage = activePage
                    getArtistsBySearchText(page: self.currentPage, isInit: false)
                    artistPageControl.currentPage = self.currentPage - 1
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
                    getArtistsBySearchText(page: self.currentPage, isInit: false)
                    artistPageControl.currentPage = self.currentPage - 1
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
    
    func resetPageNavigation() {
        self.currentPage = 1
        btnNextPage.isHidden = true
        btnPrevPage.isHidden = true
        self.artistPageControl.isHidden = true
        self.artistPageControl.currentPage = 0
    }
    
    @IBAction func btnPrevPagePressed(_ sender: UIButton) {
        self.currentPage -= 1
        
        getArtistsBySearchText(page: self.currentPage, isInit: false)
        artistPageControl.currentPage = self.currentPage - 1
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
        
        getArtistsBySearchText(page: self.currentPage, isInit: false)
        artistPageControl.currentPage = self.currentPage - 1
        switch self.currentPage {
        case _ where self.currentPage < self.maxPages:
            break
        default:
            btnNextPage.isHidden = true
        }
        btnPrevPage.isHidden = false
        
    }
    
    func getArtistsBySearchText(page: Int, isInit: Bool) {
        
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            DispatchQueue.main.async {
                let searchString = self.searchTextField.text
                
                //Send HTTP request to perform Get Top Songs
                let restUrl = self.apiUrl + "/artistln/reportln?page=\(page)"
                
                let postString = ["status": "STSACT", "artistname": searchString!] as NSDictionary
                
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
                            self.artists = dataResult
                            let resultNPages = responseDict["npage"] as! Int
                            self.maxPages = resultNPages
                            
                            if self.artists.count > 0 {
                                DispatchQueue.main.async {
                                    if isInit {
                                        
                                        switch resultNPages {
                                        case _ where resultNPages > 1:
                                            self.btnNextPage.isHidden = false
                                            self.artistPageControl.isHidden = false
                                            self.artistPageControl.numberOfPages = resultNPages
                                        default:
                                            self.btnNextPage.isHidden = true
                                            self.artistPageControl.isHidden = true
                                        }
                                        
                                        //self.genreSongsPageControl.isHidden = !(resultNPages > 1)
                                        self.artistCollectionView.backgroundView = nil
                                    }
                                    self.artistCollectionView.reloadData()
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.artistPageControl.isHidden = true
                                    self.btnPrevPage.isHidden = true
                                    self.btnNextPage.isHidden = true
                                    self.artistCollectionView.backgroundView = self.noDataView
                                    
                                    self.artistCollectionView.reloadData()
                                }
                            }
                            
                        }
                        
                    } else {
                        let message = responseDict["message"] as? String
                        DispatchQueue.main.async {
                            self.artistPageControl.isHidden = true
                            self.btnPrevPage.isHidden = true
                            self.btnNextPage.isHidden = true
                            //self.genreSongsTableView.backgroundView = self.noDataView
                            self.artistCollectionView.reloadData()
                        }
                        //ToastMessageView.shared.long(self.view, txt_msg: message!)
                        print(message!)
                        if let expToken = responseDict["errcode"] as? String {
                            if expToken == "exp-token" {
                                self.loadArtistsErr = true
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
        self.artistCollectionView.addGestureRecognizer(tapOnTableview)
    }
    
    @objc func tapRemoveKeyboard(_ sender: UITapGestureRecognizer) {
        //keyboardActive = false
        searchTextField.resignFirstResponder()
        
    }
    
    @objc func tapSearchIcon(_ sender: UITapGestureRecognizer) {
        
        getArtistsBySearchText(page: 1, isInit: true)
        searchTextField.endEditing(true)
        
    }
}

extension ArtistViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return artists.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let artistCell = collectionView.dequeueReusableCell(withReuseIdentifier: "artistCell", for: indexPath) as? ArtistCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let artist = artists[indexPath.row] as? NSDictionary
        let artistImagePath = artist!["artistphotopath"] as? String
        artistCell.artistImage.loadImageUsingUrlString(urlString: artistImagePath)
        artistCell.artistNameLabel.text = artist!["artistname"] as? String
        
        return artistCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if keyboardActive {
            self.searchTextField.resignFirstResponder()
            keyboardActive = false
        } else {
            artistForSegue = artists[indexPath.row] as! NSDictionary
            //print("Artist selected: \(String(describing: artist!["artistname"]))")
            performSegue(withIdentifier: "goToArtistAlbum", sender: self)
        }
        
    }
}

extension ArtistViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let bounds = collectionView.bounds

        return CGSize(width: bounds.width/2, height: 187)
        //return CGSize(width: 158, height: 158)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return 0
    }
}

extension ArtistViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.keyboardActive = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        getArtistsBySearchText(page: 1, isInit: true)
        self.keyboardActive = false
        textField.endEditing(true)
        return true
    }
}
