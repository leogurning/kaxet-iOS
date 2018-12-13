//
//  AddToPlaylistInitViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 12/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class AddToPlaylistInitViewController: UIViewController {

    let apiServices = RestAPIServices()
    
    let apiUrl = APPURL.BaseURL
    var userid: String = ""
    var accessToken: String = ""
    
    @IBOutlet weak var popUpView: UIView!
    @IBOutlet weak var userPlaylistNameTextField: UITextField!
    private var songData: NSDictionary = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        popUpView.layer.cornerRadius = 10
        popUpView.layer.masksToBounds = true
        
        // Do any additional setup after loading the view.
        /*
         print("Add To Playlist Selected Top Song: ")
        print("SongID: \(self.songData["_id"]!)")
        print("Song Preview: \(self.songData["songprvwpath"]!)")
        print("Song File: \(self.songData["songfilepath"]!)")
         */
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
        accessToken = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Token)!
        
        addTapGestureRecognizer()
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func btnAddUserPlaylistPressed(_ sender: UIButton) {
        
        let playlistName = userPlaylistNameTextField.text
        
        if (playlistName?.isEmpty)! {
            //Display alert message
            failedAlert(title: "Error", message: "Missing required fields. Please input the required Playlist name fields !", presentingVC: self)
            return
        }
        
        showProgressHud()
        
        DispatchQueue.global(qos: .userInteractive).async {
            //Send HTTP request to perform Add playlist
            let addPlaylistUrl = self.apiUrl + "/userplaylist/\(self.userid)"
            let postString = ["playlistname": playlistName!] as NSDictionary
            
            self.apiServices.executePostRequestWithToken(urlToExecute: addPlaylistUrl, bodyDict: postString, completion: { (jsonResponse, error) in
                
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
                    let playlistId = responseDict["playlistid"] as? String
                    
                    //Send HTTP request to perform add song
                    let addSongToPlaylistUrl = self.apiUrl + "/playlist/\(playlistId!)"
                    let postString2 = ["songid": self.songData["_id"]!, "userid": self.userid] as NSDictionary
                    
                    self.apiServices.executePostRequestWithToken(urlToExecute: addSongToPlaylistUrl, bodyDict: postString2, completion: { (jsonResponse, error) in
                        
                        if error != nil {
                            print("error= \(String(describing: error))")
                            self.closeProgressHud()
                            failedAlert(title: "Server Error or Disconnected", message: "Could not successfully perform the request. Please try again later !", presentingVC: self)
                            return
                        }
                        guard let responseDict2 = jsonResponse else {
                            print("error= \(String(describing: error))")
                            self.closeProgressHud()
                            failedAlert(title: "App Error", message: "Could not successfully perform the request. Please try again later !", presentingVC: self)
                            return
                        }
                        
                        self.closeProgressHud()
                        
                        let success = responseDict2["success"] as? Bool
                        let message = responseDict2["message"] as? String
                        
                        if success! {
                            
                            //Success Alert
                            successAlert(title: "Success", message: message!, presentingVC: self, closeParent: true)
                            
                        } else {
                            
                            //Error Alert
                            failedAlert(title: "Result Error", message: message!, presentingVC: self)
                            
                        }
                        
                    })

                } else {
                    self.closeProgressHud()
                    //Error Alert
                    failedAlert(title: "Result Error", message: message1!, presentingVC: self)
                    return
                }
            })
            
        }
        
    }
    
    @IBAction func btnCancelPressed(_ sender: UIButton) {
        
        self.dismiss(animated: true){
            showToolbarView()
        }
    }
    
    func initData(data: NSDictionary) {
            self.songData = data
    }
    
    private func closeProgressHud() {
            
        DispatchQueue.main.async {
            dismissProgressHud()
        }
        
    }
    
    func addTapGestureRecognizer() {
        
        let gestureRecognizer = UITapGestureRecognizer(target: self,action: #selector(tapGestureOutsidePopView))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func tapGestureOutsidePopView() {
        self.dismiss(animated: true){
            showToolbarView()
        }
    }
}

extension AddToPlaylistInitViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        return (touch.view === self.view)
    }
}
