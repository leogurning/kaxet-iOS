//
//  UpdateProfileViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 05/12/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import TextFieldEffects
import SwiftKeychainWrapper
import PCLBlurEffectAlert
import MobileCoreServices

class UpdateProfileViewController: UIViewController {
    
    let apiServices = RestAPIServices()
    
    let apiUrl = APPURL.BaseURL
    let hostUrl = APPURL.Domain
    let fileTransferUrl = APPURL.BaseFileTransferURL
    
    private var userid: String = ""
    private var accessToken: String = ""
    private var profileName: String = ""
    private var profileEmail: String = ""
    private var profileUserName: String = ""
    private var profilePhoto: String?
    private var profiles: NSArray = []
    private var profile: NSDictionary = [:]
    private var loadProfileErr: Bool = false
    private var inactiveColor: UIColor?
    
    @IBOutlet weak var profileImage: KxCustomImageView!
    @IBOutlet weak var fullNameTextField: HoshiTextField!
    @IBOutlet weak var emailTextField: HoshiTextField!
    @IBOutlet weak var userNameTextField: HoshiTextField!
    @IBOutlet weak var btnUpdateProfile: UIButton!
    
    @IBOutlet weak var profileImageView: UIView!
    @IBOutlet weak var changePhotoView: UIView!
    @IBOutlet weak var uploadProgressView: UIProgressView!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var uploadProgressLabel: UILabel!
    @IBOutlet weak var addPhotoView: UIView!
    @IBOutlet weak var profileDataView: UIView!
    
    @IBOutlet weak var changePhotoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
        profileImage.layer.cornerRadius = 5
        profileImage.clipsToBounds = true
        userNameTextField.isEnabled = false
        
        inactiveColor = fullNameTextField.borderInactiveColor
        
        fullNameTextField.isSelected = true
        fullNameTextField.borderActiveColor = UIColor(hex: 0x333, alpha: 1)
        
        emailTextField.borderActiveColor = inactiveColor
        userNameTextField.borderActiveColor = inactiveColor
        
        fullNameTextField.delegate = self
        emailTextField.delegate = self
        userNameTextField.delegate = self
        
        addTapGesture()
        addTapGestureRecognizer()
        
        hideChangePhotoView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        fullNameTextField.becomeFirstResponder()
        hideChangePhotoView()
        getUserProfile()

    }
    
    @IBAction func btnUpdateProfilePressed(_ sender: UIButton) {
        
        if validationData() {
            updateUserProfile()
        }
        
    }
    
    @IBAction func btnTakePhotoPressed(_ sender: UIButton) {
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera){
            
            let alertController = UIAlertController.init(title: nil, message: "Device has no camera.", preferredStyle: .alert)
            
            let okAction = UIAlertAction.init(title: "OK", style: .default, handler: {(alert: UIAlertAction!) in
            })
            
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            
        }
        else{
            //other action
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self
            myPickerController.sourceType = UIImagePickerController.SourceType.camera
            self.present(myPickerController, animated: true, completion: nil)
        }
        
        /*
        showUploadProgressView()
        uploadProgressLabel.text = "Take Photo"
        */
    }
    
    @IBAction func btnChooseFrLibraryPressed(_ sender: UIButton) {
        
        if !UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            
            let alertController = UIAlertController.init(title: nil, message: "Device has no photo Library.", preferredStyle: .alert)
            
            let okAction = UIAlertAction.init(title: "OK", style: .default, handler: {(alert: UIAlertAction!) in
            })
            
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            
        }
        else{
            //other action
            showProgressHud()
            DispatchQueue.global(qos: .userInteractive).async {
                let myPickerController = UIImagePickerController()
                myPickerController.delegate = self
                myPickerController.sourceType = UIImagePickerController.SourceType.photoLibrary
                DispatchQueue.main.async {
                    self.present(myPickerController, animated: true) {
                        dismissProgressHud()
                    }
                }
            }
            
        }

        /*
        showUploadProgressView()
        uploadProgressLabel.text = "Choose From Library"
        */
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    private func hideChangePhotoView() {
        DispatchQueue.main.async {
            self.changePhotoView.isHidden = true
            self.progressView.isHidden = true
            self.addPhotoView.isHidden = true
        }
        
    }
    
    private func initChangePhotoView() {
        DispatchQueue.main.async {
            self.changePhotoView.isHidden = false
            self.progressView.isHidden = true
            self.addPhotoView.isHidden = false
            self.addPhotoView.layer.cornerRadius = 5
            self.addPhotoView.clipsToBounds = true
            self.changePhotoView.layer.zPosition = 1

        }
    }
    
    private func showUploadProgressView() {
        DispatchQueue.main.async {
            self.changePhotoView.isHidden = false
            self.progressView.isHidden = false
            self.addPhotoView.isHidden = true
            self.progressView.layer.cornerRadius = 5
            self.progressView.clipsToBounds = true
            //self.progressView.transform = self.progressView.transform.scaledBy(x: 1, y: 9)
        }
        
    }
    
    func getUserProfile() {
        loadProfileErr = false
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            DispatchQueue.main.async {
                
                //Send HTTP request to perform Get Top Songs
                let restUrl = self.apiUrl + "/user/\(self.userid)"

                self.apiServices.executeGetRequestWithToken(urlToExecute: restUrl, completion: { (jsonResponse, error) in
                    //code
                    
                    if error != nil {
                        print("error= \(String(describing: error))")
                        self.closeProgressHud()
                        DispatchQueue.main.async {
                            ToastMessageView.shared.long(self.view, txt_msg: "Server Error or Disconnected. Please try again later.")
                        }
                        
                        return
                    }
                    
                    guard let responseDict = jsonResponse else {
                        print("error= \(String(describing: error))")
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
                            self.profiles = dataResult
                            
                            
                            if self.profiles.count > 0 {
                                self.profile = self.profiles[0] as! NSDictionary
                                DispatchQueue.main.async {
                                    self.profileName = self.profile["name"] as! String
                                    self.profileEmail = self.profile["email"] as! String
                                    self.profileUserName = self.profile["username"] as! String
                                    let tempProfilePhoto = self.profile["photopath"] as? String
                                    if let proPhoto = tempProfilePhoto {
                                        self.profilePhoto = proPhoto
                                        self.profileImage.loadImageUsingUrlString(urlString: proPhoto)
                                    }
                                    self.fullNameTextField.text = self.profileName
                                    self.emailTextField.text = self.profileEmail
                                    self.userNameTextField.text = self.profileUserName
                                }
                                
                                
                            } else {
                                DispatchQueue.main.async {
                                    self.fullNameTextField.text = ""
                                    self.emailTextField.text = ""
                                    self.userNameTextField.text = ""
                                }
                            }
                            
                        }
                        self.closeProgressHud()
                    } else {
                        let message = responseDict["message"] as? String
                        
                        DispatchQueue.main.async {
                            self.fullNameTextField.text = ""
                            self.emailTextField.text = ""
                            self.userNameTextField.text = ""
                            ToastMessageView.shared.long(self.view, txt_msg: message!)
                        }
                        
                        print(message!)
                        if let expToken = responseDict["errcode"] as? String {
                            if expToken == "exp-token" {
                                self.loadProfileErr = true
                            }
                        }
                        self.closeProgressHud()
                    }
                })
            }
        }
    }
    
    private func validationData() -> Bool {
        
        var result: Bool = true
        
        if (fullNameTextField.text?.isEmpty)! ||
            (emailTextField.text?.isEmpty)! ||
            (userNameTextField.text?.isEmpty)! {
            
            //Error Alert
            self.failedAlert(title: "Error", message: "All fields is required to fill in !")
            
            result = false
        }
        
        let email = emailTextField.text
        let isEmailAddressValid = isValidEmailAddress(emailAddressString: email!)
        
        if isEmailAddressValid == false {
            //Error Alert
            self.failedAlert(title: "Error", message: "Please ensure that email address format is valid !")
            
            result = false
        }
        
        return result
    }
    
    private func updateUserProfile() {
        self.loadProfileErr = false
        
        let fullName = fullNameTextField.text
        let email = emailTextField.text
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            DispatchQueue.main.async {
                
                //Send HTTP request to perform Get Top Songs
                let restUrl = self.apiUrl + "/user/\(self.userid)"
                
                let postString = ["name": fullName!, "email": email!] as NSDictionary
                
                self.apiServices.executePutRequestWithToken(urlToExecute: restUrl, bodyDict: postString, completion: { (jsonResponse, error) in
                    //code
                    
                    if error != nil {
                        print("error= \(String(describing: error))")
                        self.closeProgressHud()
                        
                        //Error Alert
                        DispatchQueue.main.async {
                            self.failedAlert(title: "Error", message: "Server Error or Disconnected. Please try again later.")
                        }
                        return
                    }
                    
                    guard let responseDict = jsonResponse else {
                        print("error= \(String(describing: error))")
                        self.closeProgressHud()
                        //Error Alert
                        DispatchQueue.main.async {
                            self.failedAlert(title: "Error", message: "App Error. Please try again later.")
                        }
                        return
                    }
                    
                    let success = responseDict["success"] as? Bool
                    let message = responseDict["message"] as? String
                    if success! {
                        //print("Successfully populated !")
                        
                        self.closeProgressHud()
                        DispatchQueue.main.async {
                            self.successAlert(title: "Success", message: message!)
                            
                            let saveCurrentName: Bool = KeychainWrapper.standard.set(fullName!, forKey: APPCONSTANT.Keychains.Name)
                            print("Current Name save result: \(saveCurrentName)")
                            self.getUserProfile()
                        }
                        
                    } else {
                        self.closeProgressHud()
                        print(message!)
                        DispatchQueue.main.async {
                            self.failedAlert(title: "Error", message: message!)
                        }
                        if let expToken = responseDict["errcode"] as? String {
                            if expToken == "exp-token" {
                                self.loadProfileErr = true
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
    
    func updateAlert(title: String, message: String, titleColor: UIColor, closeParent: Bool? = nil) {
        
        hideToolbarView()
        var closeView: Bool = false
        
        if closeParent == nil {
            closeView = false
        } else {
            closeView = closeParent!
        }
        
        DispatchQueue.main.async {
            let kxAlert = PCLBlurEffectAlert.Controller(title: title, message: message, effect: UIBlurEffect(style: .regular), style: .alert)
            
            //myAlert.addImageView(with: UIImage(named: "Kaxet Logo")!)
            
            //myAlert.configure(thin: 10)
            kxAlert.configure(cornerRadius: 5)
            kxAlert.configure(alertViewWidth: 200)
            kxAlert.configure(buttonHeight: 35)
            kxAlert.configure(backgroundColor: UIColor(hex: 0x333, alpha:1))
            
            kxAlert.configure(titleColor: titleColor)
            kxAlert.configure(messageFont: UIFont(name: "TrebuchetMS", size: 14)!, messageColor: UIColor(hex: 0xFCE86C, alpha:1))
            //kxAlert.configure(messageColor: UIColor(hex: 0xFCE86C, alpha:1))
            
            kxAlert.configure(buttonBackgroundColor: UIColor(hex: 0xFCE86C, alpha:0.8))
            
            let okBtn = PCLBlurEffectAlertAction(title: "OK", style: .cancel) { _ in
                
                //print("Close View?: \(closeView)")
                if closeView {
                    DispatchQueue.main.async {
                        self.dismiss(animated: true){
                            self.navigationItem.hidesBackButton = false
                            self.hideChangePhotoView()
                            showToolbarView()
                        }
                    }
                } else {
                    self.navigationItem.hidesBackButton = false
                    self.hideChangePhotoView()
                    showToolbarView()
                }
                
            }
            
            kxAlert.addAction(okBtn)
            //kxAlert.show()
            self.present(kxAlert, animated: true, completion: nil)
        }
        
    }
    
    private func successAlert(title: String, message: String, closeParent: Bool? = nil) {
        updateAlert(title: title, message: message, titleColor: UIColor(hex: 0x27CE49, alpha:1), closeParent: closeParent)
    }
    
    private func failedAlert(title: String, message: String, closeParent: Bool? = nil) {
        updateAlert(title: title, message: message, titleColor: UIColor(hex: 0xFF6F81, alpha:1), closeParent: closeParent)
    }
    
    private func infoAlert(title: String, message: String, closeParent: Bool? = nil) {
        updateAlert(title: title, message: message, titleColor: UIColor(hex: 0x3AFFFC, alpha:1), closeParent: closeParent)
    }
    
    private func addTapGesture() {
        profileImage.isUserInteractionEnabled = true
        profileImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapUploadImage(_:))))
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapRemoveKeyboard(_:))))
        changePhotoLabel.isUserInteractionEnabled = true
        changePhotoLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapUploadImage(_:))))
        
        let tapOnTableview: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapRemoveKeyboard(_:)))
        tapOnTableview.cancelsTouchesInView = false
        self.profileDataView.addGestureRecognizer(tapOnTableview)
    }
    
    @objc func tapRemoveKeyboard(_ sender: UITapGestureRecognizer) {
        
        fullNameTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        userNameTextField.resignFirstResponder()
    }
    
    @objc func tapUploadImage(_ sender: UITapGestureRecognizer) {
        DispatchQueue.main.async {
            self.fullNameTextField.resignFirstResponder()
            self.emailTextField.resignFirstResponder()
            self.userNameTextField.resignFirstResponder()
            
            self.initChangePhotoView()
            hideToolbarView()
            self.navigationItem.hidesBackButton = true
        }
        
    }
    
    func addTapGestureRecognizer() {
        
        let gestureRecognizer = UITapGestureRecognizer(target: self,action: #selector(tapGestureOutsidePopView))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func tapGestureOutsidePopView() {
        
        if progressView.isHidden {
            DispatchQueue.main.async {
                self.hideChangePhotoView()
                showToolbarView()
                self.navigationItem.hidesBackButton = false
            }
            
        }
        
    }
    
    private func uploadProfileImage(fileKey: String, imageUrls: [URL]) {
        
        //showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            DispatchQueue.main.async {
                
                //Send HTTP request to perform Get Top Songs
                let restUrl = self.fileTransferUrl + "/inputfileupload"
                
                let postString = ["uploadpath": APPCONSTANT.ProfilePhotoUploadPath] as NSDictionary
                
                self.apiServices.executeMultipartPostRequestWithToken(delegateVc: self, urlToExecute: restUrl, bodyDict: postString, filePathKey: fileKey, urls: imageUrls, completion: { (jsonResponse, error) in
                    //code
                    if error != nil {
                        print("error= \(String(describing: error))")
                        //self.closeProgressHud()
                        
                        //Error Alert
                        DispatchQueue.main.async {
                            self.failedAlert(title: "Error", message: "Server Error/Disconnected OR TimeOut. Please try again later.")
                        }
                        return
                    }
                    
                    guard let responseDict = jsonResponse else {
                        print("error= \(String(describing: error))")
                        //self.closeProgressHud()
                        //Error Alert
                        DispatchQueue.main.async {
                            self.failedAlert(title: "Error", message: "App Error. Please try again later.")
                        }
                        return
                    }
                    
                    let success = responseDict["success"] as? Bool
                    let message = responseDict["message"] as? String
                    if success! {
                        //print("Successfully populated !")
                        
                        //self.closeProgressHud()
                        let fileInfo = responseDict["filedata"] as? NSDictionary
                        let filepath = fileInfo!["filepath"] as? String
                        let filename = fileInfo!["filename"] as? String
                        //print("Filepath: \(String(describing: filepath))")
                        
                        showProgressHud()
                        DispatchQueue.global(qos: .userInteractive).async {
                            DispatchQueue.main.async {
                                self.uploadProgressLabel.text = "Updating profile data..."
                                //Send HTTP request to perform Get Top Songs
                                let restUrl = self.apiUrl + "/profilephoto/\(self.userid)"
                                
                                let postString = ["photopath": filepath!, "photoname": filename!] as NSDictionary
                                
                                self.apiServices.executePutRequestWithToken(urlToExecute: restUrl, bodyDict: postString, completion: { (jsonResponse, error) in
                                    //code
                                    
                                    if error != nil {
                                        print("error= \(String(describing: error))")
                                        self.closeProgressHud()
                                        
                                        //Error Alert
                                        DispatchQueue.main.async {
                                            self.failedAlert(title: "Error", message: "Server Error or Disconnected. Please try again later.")
                                        }
                                        return
                                    }
                                    
                                    guard let responseDict = jsonResponse else {
                                        print("error= \(String(describing: error))")
                                        self.closeProgressHud()
                                        //Error Alert
                                        DispatchQueue.main.async {
                                            self.failedAlert(title: "Error", message: "App Error. Please try again later.")
                                        }
                                        return
                                    }
                                    
                                    let success = responseDict["success"] as? Bool
                                    let message = responseDict["message"] as? String
                                    if success! {
                                        //print("Successfully populated !")
                                        
                                        self.closeProgressHud()
                                        DispatchQueue.main.async {
                                            self.successAlert(title: "Success", message: message!)
                                            let saveCurrentPhoto: Bool = KeychainWrapper.standard.set(filepath!, forKey: APPCONSTANT.Keychains.UserPhoto)
                                            print("Current photo save result: \(saveCurrentPhoto)")
                                            
                                            self.getUserProfile()
                                        }
                                        
                                    } else {
                                        self.closeProgressHud()
                                        print(message!)
                                        DispatchQueue.main.async {
                                            self.failedAlert(title: "Error", message: message!)
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
                        
                        
                    } else {
                        //self.closeProgressHud()
                        print(message!)
                        DispatchQueue.main.async {
                            self.failedAlert(title: "Error", message: message!)
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
}

extension UpdateProfileViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case fullNameTextField:
            fullNameTextField.borderActiveColor = UIColor(hex: 0x333, alpha: 1)
            emailTextField.borderActiveColor = inactiveColor
            userNameTextField.borderActiveColor = inactiveColor
        case emailTextField:
            fullNameTextField.borderActiveColor = inactiveColor
            emailTextField.borderActiveColor = UIColor(hex: 0x333, alpha: 1)
            userNameTextField.borderActiveColor = inactiveColor
        default:
            fullNameTextField.borderActiveColor = inactiveColor
            emailTextField.borderActiveColor = inactiveColor
            userNameTextField.borderActiveColor = inactiveColor
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
}

extension UpdateProfileViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        return (touch.view === self.changePhotoView)
    }
}


extension UpdateProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        
        let mediaType : CFString = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaType)] as! CFString
        
        if mediaType == kUTTypeImage {
            profileImage.image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage
            //let imageUrl = info[UIImagePickerControllerReferenceURL] as? URL
            
            profileImage.backgroundColor = UIColor.clear
            self.dismiss(animated: true) {
                if let img = self.profileImage.image {
                    self.showUploadProgressView()
                    self.uploadProgressView.progress = 0.0
                    //let path = (NSTemporaryDirectory() as NSString).appendingPathComponent("tempkaxetprofileimage.png")
                    let pathUrl = APPDIR.documentDirPath.appendingPathComponent("tempkaxetprofileimage.jpeg")
                    let imageData: NSData = img.jpegData(compressionQuality: 1)! as NSData
                    //imageData.write(toFile: path as String, atomically: true)
                    imageData.write(to: pathUrl, atomically: true)
                    
                    // once the image is saved we can use the path to create a local fileurl
                    //let contentUrl:URL = URL(fileURLWithPath: path as String)
                    
                    self.uploadProfileImage(fileKey: "fileinputsrc", imageUrls: [pathUrl])
                    
                } else {
                    self.navigationItem.hidesBackButton = false
                }
            }
            
            
        }
        
        
    }
 
}

extension UpdateProfileViewController: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        let uploadProgress: Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        
        DispatchQueue.main.async {
            self.uploadProgressView.progress = uploadProgress
            let progressPercent = Int(uploadProgress * 100)
            self.uploadProgressLabel.text = "\(progressPercent) %"
        }
        
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
