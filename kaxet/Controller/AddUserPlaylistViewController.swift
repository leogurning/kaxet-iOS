//
//  AddUserPlaylistViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 03/12/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

protocol AddUserPlaylistDelegate {
    //func RefreshPlaylist(cityName: String)
    func RefreshPlaylist()
}

class AddUserPlaylistViewController: UIViewController {
    
    //Declare the delegate variable here:
    var delegate: AddUserPlaylistDelegate?
    
    let apiServices = RestAPIServices()
    
    let apiUrl = APPURL.BaseURL
    var userid: String = ""
    var accessToken: String = ""
    
    @IBOutlet weak var userPlaylistNameTextfield: UITextField!
    
    @IBOutlet weak var popUpView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        popUpView.layer.cornerRadius = 6
        popUpView.clipsToBounds = true
        
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
        accessToken = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Token)!
        
        addTapGestureRecognizer()
        
    }
    
    @IBAction func btnAddUserplaylistPressed(_ sender: UIButton) {
        addUserPlaylist()
    }
    
    @IBAction func btnCancelPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
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
    
    private func addUserPlaylist() {
        
        let playlistName = userPlaylistNameTextfield.text
    
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
                    DispatchQueue.main.async {
                        //self.closeProgressHud()
                        self.dismiss(animated: true) {
                            self.delegate?.RefreshPlaylist()
                        }
                        
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
    
    private func closeProgressHud() {
        
        DispatchQueue.main.async {
            dismissProgressHud()
        }
        
    }
}

extension AddUserPlaylistViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        return (touch.view === self.view)
    }
}
