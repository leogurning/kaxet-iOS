//
//  ChangePasswordViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 06/12/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import TextFieldEffects
import SwiftKeychainWrapper

class ChangePasswordViewController: UIViewController {

    let apiServices = RestAPIServices()
    
    let apiUrl = APPURL.BaseURL
    let hostUrl = APPURL.Domain
    private var userid: String = ""
    private var accessToken: String = ""
    private var loadProfileErr: Bool = false
    
    private var inactiveColor: UIColor?
    
    @IBOutlet weak var currentPasswordTextField: HoshiTextField!
    @IBOutlet weak var newPasswordTextField: HoshiTextField!
    @IBOutlet weak var confirmPasswordTextField: HoshiTextField!
    
    @IBOutlet weak var logoView: UIView!
    @IBOutlet weak var passDataView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
        inactiveColor = currentPasswordTextField.borderInactiveColor
        
        currentPasswordTextField.isSelected = true
        currentPasswordTextField.borderActiveColor = UIColor(hex: 0x333, alpha: 1)
        
        newPasswordTextField.borderActiveColor = inactiveColor
        confirmPasswordTextField.borderActiveColor = inactiveColor
        
        currentPasswordTextField.delegate = self
        newPasswordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        
        addTapGesture()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        currentPasswordTextField.becomeFirstResponder()
    }

    @IBAction func btnUpdatePasswordPressed(_ sender: UIButton) {
        
        if validation() {
            updatePassword()
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
    
    private func addTapGesture() {

        logoView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapRemoveKeyboard(_:))))
        
        let tapOnTableview: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapRemoveKeyboard(_:)))
        tapOnTableview.cancelsTouchesInView = false
        self.passDataView.addGestureRecognizer(tapOnTableview)
    }
    
    @objc func tapRemoveKeyboard(_ sender: UITapGestureRecognizer) {
        
        currentPasswordTextField.resignFirstResponder()
        newPasswordTextField.resignFirstResponder()
        confirmPasswordTextField.resignFirstResponder()
    }
    
    private func initiateTextPasswd() {
        currentPasswordTextField.text = ""
        newPasswordTextField.text = ""
        confirmPasswordTextField.text = ""
    }
    
    private func validation() -> Bool {
        
        var result: Bool = true
        
        if (currentPasswordTextField.text?.isEmpty)! ||
            (newPasswordTextField.text?.isEmpty)! ||
            (confirmPasswordTextField.text?.isEmpty)! {
            
            //Error Alert
            failedAlert(title: "Error", message: "All fields is required to fill in !", presentingVC: self)
            
            result = false
        }
        let newPasswd = newPasswordTextField.text
        let confirmPasswd = confirmPasswordTextField.text
        if (newPasswd != confirmPasswd) {
            //Error Alert
            failedAlert(title: "Error", message: "Confirm password is not matched !", presentingVC: self)
            
            result = false
        }
        
        return result
    }
    
    private func updatePassword() {
        
        self.loadProfileErr = false
        
        let currPasswd = currentPasswordTextField.text
        let newPasswd = newPasswordTextField.text

        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            DispatchQueue.main.async {
                
                //Send HTTP request to perform Get Top Songs
                let restUrl = self.apiUrl + "/password/\(self.userid)"
                
                let postString = ["oldpassword": currPasswd!, "password": newPasswd!] as NSDictionary
                
                self.apiServices.executePutRequestWithToken(urlToExecute: restUrl, bodyDict: postString, completion: { (jsonResponse, error) in
                    //code
                    
                    if error != nil {
                        print("error= \(String(describing: error))")
                        self.closeProgressHud()
                        
                        //Error Alert
                        DispatchQueue.main.async {
                            failedAlert(title: "Error", message: "Server Error or Disconnected. Please try again later.", presentingVC: self)
                        }
                        return
                    }
                    
                    guard let responseDict = jsonResponse else {
                        print("error= \(String(describing: error))")
                        self.closeProgressHud()
                        //Error Alert
                        DispatchQueue.main.async {
                            failedAlert(title: "Error", message: "App Error. Please try again later.", presentingVC: self)
                        }
                        return
                    }
                    
                    let success = responseDict["success"] as? Bool
                    let message = responseDict["message"] as? String
                    if success! {
                        //print("Successfully populated !")
                        
                        self.closeProgressHud()
                        DispatchQueue.main.async {
                            successAlert(title: "Success", message: message!, presentingVC: self)
                            self.initiateTextPasswd()
                            self.currentPasswordTextField.becomeFirstResponder()
                        }
                        
                    } else {
                        self.closeProgressHud()
                        print(message!)
                        DispatchQueue.main.async {
                            failedAlert(title: "Error", message: message!, presentingVC: self)
                            
                            if let expToken = responseDict["errcode"] as? String {
                                if expToken == "exp-token" {
                                    self.loadProfileErr = true
                                }
                            }
                        }
                        
                        
                    }
                })
            }
        }
        
    }
    
    func closeProgressHud() {
        
        DispatchQueue.main.async {
            dismissProgressHud()
            //self.refreshControl.endRefreshing()
        }
        
        goToLogout()
        
    }
    
    private func goToLogout() {
        
        if ( loadProfileErr ) {
            
            logout(presentingVc: self)
        }
        
    }
}

extension ChangePasswordViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case currentPasswordTextField:
            currentPasswordTextField.borderActiveColor = UIColor(hex: 0x333, alpha: 1)
            newPasswordTextField.borderActiveColor = inactiveColor
            confirmPasswordTextField.borderActiveColor = inactiveColor
        case newPasswordTextField:
            currentPasswordTextField.borderActiveColor = inactiveColor
            newPasswordTextField.borderActiveColor = UIColor(hex: 0x333, alpha: 1)
            confirmPasswordTextField.borderActiveColor = inactiveColor
        case confirmPasswordTextField:
            currentPasswordTextField.borderActiveColor = inactiveColor
            newPasswordTextField.borderActiveColor = inactiveColor
            confirmPasswordTextField.borderActiveColor = UIColor(hex: 0x333, alpha: 1)
        default:
            currentPasswordTextField.borderActiveColor = inactiveColor
            currentPasswordTextField.borderActiveColor = inactiveColor
            currentPasswordTextField.borderActiveColor = inactiveColor
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
}
