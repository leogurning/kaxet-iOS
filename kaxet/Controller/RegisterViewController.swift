//
//  RegisterViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 05/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {
    
    let hostUrl = APPURL.Domain
    
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        fullNameTextField.delegate = self
        emailTextField.delegate = self
        userNameTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        
        addTapGesture()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        fullNameTextField.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func registerButtonPressed(_ sender: UIButton) {
        
        //Validate all required fields
        if (fullNameTextField.text?.isEmpty)! ||
            (emailTextField.text?.isEmpty)! ||
            (userNameTextField.text?.isEmpty)! ||
            (passwordTextField.text?.isEmpty)! ||
            (confirmPasswordTextField.text?.isEmpty)! {
            
            //Error Alert
            failedAlert(title: "Error", message: "All fields is required to fill in !", presentingVC: self)
            
            return
        }
        
        //Check the password and confirmPassword
        if (passwordTextField.text?.elementsEqual(confirmPasswordTextField.text!))! != true {
            
            //Error Alert
            failedAlert(title: "Error", message: "Please ensure that passwords match !", presentingVC: self)
            
            return
        }
        
        let name = fullNameTextField.text
        let email = emailTextField.text
        let username = userNameTextField.text
        let password = passwordTextField.text
        
        let isEmailAddressValid = isValidEmailAddress(emailAddressString: email!)
        
        if isEmailAddressValid == false {
            //Error Alert
            failedAlert(title: "Error", message: "Please ensure that email address format is valid !", presentingVC: self)
            
            return
        }
        
        /*
        //Create activity indicator
        let myActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        
        //Position in the center
        myActivityIndicator.center = view.center
        
        //If needed you can prevent activity Indicator from hiding when stopAnimating is calling
        myActivityIndicator.hidesWhenStopped = false
        
        //Start myActivityIndicator
        myActivityIndicator.startAnimating()
        
        view.addSubview(myActivityIndicator)
        //This is for disable all input and button while spinning indicator
        UIApplication.shared.beginIgnoringInteractionEvents()
        */
        
        showProgressHud()
        
        //Send HTTP request to perform Register
        let registerUrl = URL(string: hostUrl + "/registerListener")
        
        var request = URLRequest(url: registerUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        
        let postString = ["name": name!, "email": email!, "username": username!, "password": password!] as [String: String]
        
        //convert the postString to JSON as body param
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: postString, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
            DispatchQueue.main.async {
                //This is for re-enable all input and button AFTER spinning indicator
                //UIApplication.shared.endIgnoringInteractionEvents()
                dismissProgressHud()
            }
            //Error Alert
            failedAlert(title: "App Error", message: "Something when wrong...Try again later !", presentingVC: self)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) {
            (data: Data?, response: URLResponse?, error: Error?) in
            
            //removeActivityIndicator(activityIndicator: myActivityIndicator)
            DispatchQueue.main.async {
                //UIApplication.shared.endIgnoringInteractionEvents()
                dismissProgressHud()
            }
            
            if error != nil {
                //self.displayMessage(userMessage: "Could not successfully perform the request. Please try again later !")
                
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
                        
                        //self.displayMessageAndDismiss(userMessage: message!)
                        successAlert(title: "Success", message: message!, presentingVC: self, closeParent: true)
                        
                    } else {
                        
                        //self.displayMessage(userMessage: message!)
                        failedAlert(title: "Result Error", message: message!, presentingVC: self)
                        
                        return
                    }
                    
                } else {
                    //self.displayMessage(userMessage: "Result Error..Try again later !")
                    failedAlert(title: "Result Error", message: "Result Error..Try again later !", presentingVC: self)
                    
                    return
                }
                
            } catch let error {
                //removeActivityIndicator(activityIndicator: myActivityIndicator)
                DispatchQueue.main.async {
                    //UIApplication.shared.endIgnoringInteractionEvents()
                    dismissProgressHud()
                }
                
                print(error.localizedDescription)
                //self.displayMessage(userMessage: "Server Error..Try again later !")
                failedAlert(title: "Server Error", message: "Server Error..Try again later !", presentingVC: self)
                
                return
            }
            
        }
        task.resume()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    /*
    func displayMessageAndDismiss(userMessage: String) -> Void {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Alert", message: userMessage, preferredStyle: .alert)
            
            let OKAction = UIAlertAction(title: "OK", style: .default)
            { (action: UIAlertAction!) in
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
                
            }
            alertController.addAction(OKAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func displayMessage(userMessage: String) -> Void {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Alert", message: userMessage, preferredStyle: .alert)
            
            let OKAction = UIAlertAction(title: "OK", style: .default)
            { (action: UIAlertAction!) in
                //Action when OK is pressed

                
            }
            alertController.addAction(OKAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    */
    
    private func addTapGesture() {
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSearchIconView(_:))))
        
    }
    
    @objc func tapSearchIconView(_ sender: UITapGestureRecognizer) {
        
        userNameTextField.endEditing(true)
        fullNameTextField.endEditing(true)
        emailTextField.endEditing(true)
        userNameTextField.endEditing(true)
        passwordTextField.endEditing(true)
        confirmPasswordTextField.endEditing(true)
    }
}

extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        textField.endEditing(true)
        return true
        
    }
}
