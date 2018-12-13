//
//  LoginViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 05/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import TextFieldEffects

class LoginViewController: UIViewController {

    let apiUrl = APPURL.BaseURL
    private var inactiveColor: UIColor?

    @IBOutlet weak var userNameTextField: HoshiTextField!
    @IBOutlet weak var passwordTextField: HoshiTextField!
    
    @IBOutlet weak var loginInfoView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        passwordTextField.delegate = self
        userNameTextField.delegate = self
        
        inactiveColor = userNameTextField.borderInactiveColor
        
        userNameTextField.isSelected = true
        userNameTextField.borderActiveColor = UIColor(hex: 0x333, alpha: 1)
        
        passwordTextField.borderActiveColor = inactiveColor

        addTapGesture()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        userNameTextField.becomeFirstResponder()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func signInButtonPressed(_ sender: UIButton) {
        
        doLogin()
        
    }
    
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    private func addTapGesture() {
        
        loginInfoView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSearchIconView(_:))))

    }
    
    @objc func tapSearchIconView(_ sender: UITapGestureRecognizer) {
        
        userNameTextField.endEditing(true)
        passwordTextField.endEditing(true)
    }
    
    private func doLogin() {
        let userName = userNameTextField.text
        let password = passwordTextField.text
        
        if (userName?.isEmpty)! || (password?.isEmpty)!{
            //Display alert message
            failedAlert(title: "Error", message: "Missing required fields. Please input both required fields !", presentingVC: self)
            
            return
        }
        
        //Display progress HUD for loading indicator
        showProgressHud()
        
        DispatchQueue.global().async {
            //Send HTTP request to perform Sign In
            let loginUrl = URL(string: self.apiUrl + "/login")
            
            var request = URLRequest(url: loginUrl!)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "content-type")
            
            let postString = ["username": userName!, "password": password!] as [String: String]
            
            //convert the postString to JSON as body param
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: postString, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    dismissProgressHud()
                }
                //Display Error Alert
                failedAlert(title: "App Error", message: "Something when wrong...Try again later !", presentingVC: self)
                
                return
            }
            
            let task = URLSession.shared.dataTask(with: request) {
                (data: Data?, response: URLResponse?, error: Error?) in
                /*
                 DispatchQueue.main.async {
                 //UIApplication.shared.endIgnoringInteractionEvents()
                 dismissProgressHud()
                 }
                 */
                
                if error != nil {
                    //Display Error Alert
                    DispatchQueue.main.async {
                        //UIApplication.shared.endIgnoringInteractionEvents()
                        dismissProgressHud()
                    }
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
                                failedAlert(title: "Server Error", message: "Could not successfully perform the request. Please try again later !", presentingVC: self)
                                
                                return
                            }
                            
                            let isFblogin: Bool = KeychainWrapper.standard.set(false, forKey: APPCONSTANT.Keychains.Fblogin)
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
                                    
                                    self.dismiss(animated: true, completion: {
                                        DispatchQueue.main.async {
                                            //UIApplication.shared.endIgnoringInteractionEvents()
                                            dismissProgressHud()
                                        }
                                        let mainPage = topVC.storyboard?.instantiateViewController(withIdentifier: "StartViewController") as! StartViewController
                                        let appDelegate = UIApplication.shared.delegate
                                        appDelegate?.window??.rootViewController = mainPage
                                    })
                                    
                                    
                                    
                                }
                                
                                
                                /*
                                 weak var pvc:UIViewController! = self.presentingViewController
                                 
                                 UIView.animate(withDuration: 0.75, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                                 self.dismiss(animated: true, completion: {
                                 pvc.performSegue(withIdentifier: "goToHome", sender: nil)
                                 })
                                 }, completion: nil)
                                 */
                            }
                            
                        } else {
                            let message = parseJSON["message"] as? String
                            DispatchQueue.main.async {
                                //UIApplication.shared.endIgnoringInteractionEvents()
                                dismissProgressHud()
                            }
                            //Display Error Alert
                            failedAlert(title: "Result Error", message: message!, presentingVC: self)
                            
                            return
                        }
                        
                    } else {
                        //Display Error Alert
                        DispatchQueue.main.async {
                            //UIApplication.shared.endIgnoringInteractionEvents()
                            dismissProgressHud()
                        }
                        failedAlert(title: "Server Error", message: "Result Error..Try again later !", presentingVC: self)
                        
                        return
                    }
                    
                } catch let error {
                    
                    DispatchQueue.main.async {
                        //UIApplication.shared.endIgnoringInteractionEvents()
                        dismissProgressHud()
                    }
                    
                    print(error.localizedDescription)
                    //Display Error Alert
                    failedAlert(title: "Server Error", message: "Server Error..Try again later !", presentingVC: self)
                    
                    return
                }
                
            }
            task.resume()
        }
    }

}

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case userNameTextField:
            userNameTextField.borderActiveColor = UIColor(hex: 0x333, alpha: 1)
            passwordTextField.borderActiveColor = inactiveColor
        case passwordTextField:
            userNameTextField.borderActiveColor = inactiveColor
            passwordTextField.borderActiveColor = UIColor(hex: 0x333, alpha: 1)

        default:
            userNameTextField.borderActiveColor = inactiveColor
            passwordTextField.borderActiveColor = inactiveColor

        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        doLogin()
        textField.endEditing(true)
        return true
        
    }
}
