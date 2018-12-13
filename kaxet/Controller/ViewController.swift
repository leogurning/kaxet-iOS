//
//  ViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 16/07/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit
import SwiftKeychainWrapper

class ViewController: UIViewController {
    
    let apiServices = RestAPIServices()
    
    let apiUrl = APPURL.BaseURL
    let hostUrl = APPURL.Domain
    
    @IBOutlet weak var btnEmailSignIn: UIButton!
    @IBOutlet weak var btnFbLogin: FBSDKLoginButton!
    
    @IBOutlet weak var btnLogout: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        btnFbLogin.readPermissions = ["email","public_profile"]
        btnFbLogin.delegate = self
        
        btnEmailSignIn.layer.cornerRadius = 5
        btnEmailSignIn.clipsToBounds = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func btnLogoutPressed(_ sender: UIButton) {
        FBSDKLoginManager().logOut()
    }
    
    private func createFbUser(pUsername: String, pName: String, pEmail: String, pHoto: String?) {
        
        let name = pName
        let email = pEmail
        let username = pUsername
        
        showProgressHud()
        
        //Validate all required fields
        if (name.isEmpty) ||
            (email.isEmpty) ||
            (username.isEmpty) {
            
            self.closeProgressHud()
            //Error Alert
            failedAlert(title: "Error", message: "All fields is required to fill in !", presentingVC: self)
            
            return
        }
        
        let isEmailAddressValid = isValidEmailAddress(emailAddressString: email)
        
        if isEmailAddressValid == false {
            //Error Alert
            self.closeProgressHud()
            failedAlert(title: "Error", message: "Please ensure that email address format is valid !", presentingVC: self)
            
            return
        }

        //Send HTTP request to perform Register
        var fbRegUrl: String?
        
        let urlString = hostUrl + "/checkfblistener/\(username)?name=\(name)&email=\(email)"
        let testUrl = URL(string: urlString)
        if testUrl != nil{
            fbRegUrl = urlString
        }else {
            fbRegUrl = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        }
        
        let registerUrl = URL(string: fbRegUrl!)
        var request = URLRequest(url: registerUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        
        if let profilePhoto = pHoto {
            let postString = ["photopath": profilePhoto] as [String: String]
            
            //convert the postString to JSON as body param
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: postString, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
                self.closeProgressHud()
                //Error Alert
                failedAlert(title: "App Error", message: "Something when wrong...Try again later !", presentingVC: self)
                return
            }
        }
        
        let task = URLSession.shared.dataTask(with: request) {
            (data: Data?, response: URLResponse?, error: Error?) in
            
            if error != nil {
                
                self.closeProgressHud()
                failedAlert(title: "Server Error", message: "Could not successfully perform the request. Please try again later !", presentingVC: self)
                
                print("error= \(String(describing: error))")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                    as? NSDictionary
                
                if let parseJSON = json {
                    let success = parseJSON["success"] as? Bool
                    let message = parseJSON["message"] as? String
                    
                    if success! {
                        
                        //login process here
                        self.doLogin(pUserName: username, pPassword: username)
                        
                    } else {
                        let errorcode = parseJSON["code"] as? String
                        if errorcode == "002" {
                            //login process here
                            self.doLogin(pUserName: username, pPassword: username)
                        } else {
                            //error alert
                            self.closeProgressHud()
                            failedAlert(title: "Result Error", message: message!, presentingVC: self)
                            
                            return
                        }
                    }
                    
                } else {
                    //error alert
                    self.closeProgressHud()
                    failedAlert(title: "Result Error", message: "Result Error..Try again later !", presentingVC: self)
                    
                    return
                }
                
            } catch let error {
                //error alert
                self.closeProgressHud()
                
                print(error.localizedDescription)
                failedAlert(title: "Server Error", message: "Server Error..Try again later !", presentingVC: self)
                
                return
            }
            
        }
        task.resume()
    }
    
    private func doLogin(pUserName: String, pPassword: String) {
        let userName = pUserName
        let password = pPassword
        
        if (userName.isEmpty) || (password.isEmpty){
            //Display alert message
            self.closeProgressHud()
            failedAlert(title: "Error", message: "Missing required fields. Please input both required fields !", presentingVC: self)
            
            return
        }
        
        DispatchQueue.global().async {
            //Send HTTP request to perform Sign In
            let loginUrl = URL(string: self.apiUrl + "/login")
            
            var request = URLRequest(url: loginUrl!)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "content-type")
            
            let postString = ["username": userName, "password": password] as [String: String]
            
            //convert the postString to JSON as body param
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: postString, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
                self.closeProgressHud()
                //Display Error Alert
                failedAlert(title: "App Error", message: "Something when wrong...Try again later !", presentingVC: self)
                
                return
            }
            
            let task = URLSession.shared.dataTask(with: request) {
                (data: Data?, response: URLResponse?, error: Error?) in
                
                if error != nil {
                    //Display Error Alert
                    self.closeProgressHud()
                    failedAlert(title: "Server Error", message: "Could not successfully perform the request. Please try again later !", presentingVC: self)
                    
                    print("error= \(String(describing: error))")
                    return
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                        as? NSDictionary
                    
                    if let parseJSON = json {
                        let success = parseJSON["success"] as? Bool
                        if success! {
                            let accessToken = parseJSON["token"] as? String
                            let message = parseJSON["message"] as? [String: Any]
                            
                            print("name: \(String(describing: message!["name"]))")
                            
                            let currentUserid = message?["userid"] as? String
                            let currentUsername = message?["username"] as? String
                            let currentName = message?["name"] as? String
                            let currentUsertype = message?["usertype"] as? String
                            let currentUserPhoto = message?["filepath"] as? String
                            //let currentBalance = message?["balance"] as? Double
                            //let currentLastLogin = message?["lastlogin"] as? Date
                            
                            if (accessToken?.isEmpty)! {
                                //Display Error Alert
                                self.closeProgressHud()
                                failedAlert(title: "Server Error", message: "Could not successfully perform the request. Please try again later !", presentingVC: self)
                                
                                return
                            }
                            
                            let isFblogin: Bool = KeychainWrapper.standard.set(true, forKey: APPCONSTANT.Keychains.Fblogin)
                            print("IsFblogin save result: \(isFblogin)")
                            
                            let saveAccessToken: Bool = KeychainWrapper.standard.set(accessToken!, forKey: APPCONSTANT.Keychains.Token)
                            print("AccessToken save result: \(saveAccessToken)")
                            
                            if !(currentUserid?.isEmpty)! {
                                let saveCurrentUserid: Bool = KeychainWrapper.standard.set(currentUserid!, forKey: APPCONSTANT.Keychains.Userid)
                                print("Current UserId save result: \(saveCurrentUserid)")
                            }
                            if !(currentUsername?.isEmpty)! {
                                let saveCurrentUsername: Bool = KeychainWrapper.standard.set(currentUsername!, forKey: APPCONSTANT.Keychains.Username)
                                print("Current Username save result: \(saveCurrentUsername)")
                            }
                            if !(currentName?.isEmpty)! {
                                let saveCurrentName: Bool = KeychainWrapper.standard.set(currentName!, forKey: APPCONSTANT.Keychains.Name)
                                print("Current Name save result: \(saveCurrentName)")
                            }
                            if !(currentUsertype?.isEmpty)! {
                                let saveCurrentUsertype: Bool = KeychainWrapper.standard.set(currentUsertype!, forKey: APPCONSTANT.Keychains.Usertype)
                                print("CurrentUsertype save result: \(saveCurrentUsertype)")
                            }
                            
                            if let userPhoto = currentUserPhoto {
                                let saveCurrentUserPhoto: Bool = KeychainWrapper.standard.set(userPhoto, forKey: APPCONSTANT.Keychains.UserPhoto)
                                print("CurrentUserphoto save result: \(saveCurrentUserPhoto)")
                            } else {
                                let saveCurrentUserPhoto: Bool = KeychainWrapper.standard.set(APPCONSTANT.NoPhoto, forKey: APPCONSTANT.Keychains.UserPhoto)
                                print("CurrentUserphoto save result: \(saveCurrentUserPhoto)")
                            }
                            
                            DispatchQueue.main.async {
                                if let topVC = UIApplication.shared.keyWindow?.rootViewController {
                                    DispatchQueue.main.async {
                                        dismissProgressHud()
                                    }
                                    let mainPage = topVC.storyboard?.instantiateViewController(withIdentifier: "StartViewController") as! StartViewController
                                    let appDelegate = UIApplication.shared.delegate
                                    appDelegate?.window??.rootViewController = mainPage
                                }
                                
                            }
                            
                        } else {
                            let message = parseJSON["message"] as? String
                            self.closeProgressHud()
                            //Display Error Alert
                            failedAlert(title: "Result Error", message: message!, presentingVC: self)
                            
                            return
                        }
                        
                    } else {
                        //Display Error Alert
                        self.closeProgressHud()
                        failedAlert(title: "Server Error", message: "Result Error..Try again later !", presentingVC: self)
                        
                        return
                    }
                    
                } catch let error {
                    self.closeProgressHud()

                    print(error.localizedDescription)
                    //Display Error Alert
                    failedAlert(title: "Server Error", message: "Server Error..Try again later !", presentingVC: self)
                    
                    return
                }
                
            }
            task.resume()
        }
    }
    
    func closeProgressHud() {
        
        DispatchQueue.main.async {
            dismissProgressHud()
            FBSDKLoginManager().logOut()
        }
        
    }

}

extension ViewController: FBSDKLoginButtonDelegate {
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        
        if(error == nil)
        {
            //print("login complete")
            //print(FBSDKAccessToken.current())
            if result.isCancelled {
                print("cancel login")
            } else {
                if (result.token != nil) {
                    // User is logged in, do work such as go to next view controller.
                    //print("Login userid: \(result.token.userID)")
                    //print("Login userid: \(result.token.tokenString)")
                    fetchUserData()
                } else {
                    print("Error! Token is not captured.")
                    DispatchQueue.main.async {
                        ToastMessageView.shared.long(self.view, txt_msg: "Error! Token is not captured. Please try again later.")
                    }
                }
            }
        }
        else{
            print(error.localizedDescription)
            DispatchQueue.main.async {
                ToastMessageView.shared.long(self.view, txt_msg: "Error Facebook Login! Please try again later.")
            }
        }
        
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Did Logout from Facebook")
    }
    
    private func fetchUserData() {
        let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"id, email, name, picture.width(150).height(150)"])
        graphRequest?.start(completionHandler: { (connection, result, error) in
            if error != nil {
                print("Error",error!.localizedDescription)
            }
            else{
                //print(result!)
                let fbData = result! as? [String:Any]
                //create fb user and login here and login
                let name = fbData!["name"] as? String
                let username = fbData!["id"] as? String
                let email = fbData!["email"] as? String
                
                if let imageURL = ((fbData!["picture"] as? [String: Any])?["data"] as? [String: Any])?["url"] as? String {
                    
                    self.createFbUser(pUsername: username!, pName: name!, pEmail: email!, pHoto: imageURL)
                    //let url = URL(string: imageURL)
                    //let data = NSData(contentsOf: url!)
                    //let image = UIImage(data: data! as Data)
                    //self.profileImageView.image = image
                } else {
                    self.createFbUser(pUsername: username!, pName: name!, pEmail: email!, pHoto: nil)
                }

            }
        })
    }
}
