//
//  GlobalVarNFunc.swift
//  kaxet
//
//  Created by LEONARD GURNING on 09/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import Foundation
import SVProgressHUD
import PCLBlurEffectAlert
import SwiftKeychainWrapper
import FBSDKLoginKit
import FBSDKCoreKit

struct APPURL {
    
    private struct CodaDomains {
        static let Dev = "https://sandbox.codapayments.com/airtime"
        static let Prd = "https://airtime.codapayments.com/airtime"
        static let Identifier = "codapayments.com"
    }
    
    private struct Domains {
        static let Dev = "https://kxlistener.herokuapp.com"
        static let Prd = "https://kxlisp-kaxetprd.4b63.pro-ap-southeast-2.openshiftapps.com"
        static let DevFileTransfer = "https://kxfiletrf.herokuapp.com"
        static let PrdFileTransfer = "https://kxfiletrfp-kaxetprd.4b63.pro-ap-southeast-2.openshiftapps.com"
    }
    
    private struct Routes {
        static let Api = "/api"
    }
    
    //static let Domain = Domains.Dev
    static let Domain = Domains.Prd
    //static let DomainFileTransfer = Domains.DevFileTransfer
    static let DomainFileTransfer = Domains.PrdFileTransfer
    private static let Route = Routes.Api
    static let BaseURL = Domain + Route
    static let BaseFileTransferURL = DomainFileTransfer + Route
    
    static let CodaDomain = CodaDomains.Prd
    static let CodaIdentifier = CodaDomains.Identifier
}

struct APPCONT {
    private struct Main {
        static let StartVc = UIApplication.shared.keyWindow?.rootViewController as! StartViewController
        //static let StartVc = UIApplication.getTopMostViewController()
    }
    
    static let MainTabBar = Main.StartVc.children[0] as! KaxetTabBarViewController
    
}

struct APPCONSTANT {
    
    struct Keychains {
        static let Fblogin = "isFblogin"
        static let Token = "token"
        static let Userid = "userid"
        static let Username = "username"
        static let Name = "name"
        static let Usertype = "usertype"
        static let Balance = "balance"
        static let LastLogin = "lastlogin"
        static let UserPhoto = "filepath"
    }
    
    struct PaymentMtd {
        static let Pulsa = "PMTPULSA"
        static let Gopay = "PMTGOPAY"
        static let Cash = "PMTCASH"
    }
    
    struct CodaParams {
        static let ApiKey = "35315a3ccda36e7483e0e6ebabd3fd6a"
        static let CountryCode = 360
        static let CurrencyCode = 360
    }
    static let NoPhoto = "NOPHOTO"
    static let ProfilePhotoUploadPath = "kaxet/images/profiles/"
    static let refreshDelay: Double = 4
}

struct APPDIR {
    
    fileprivate static let userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
    fileprivate static let documentsDefaultPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static let documentDirPathdef = documentsDefaultPath.appendingPathComponent("kaxet")
    static let documentDirPath = documentDirPathdef.appendingPathComponent(userid)
    
}

func isSongFileExist(filename: String) -> Bool {
    
    let destinationURL = APPDIR.documentDirPath.appendingPathComponent(filename)
    
    var isDir: ObjCBool = false
    
    let isExist = FileManager.default.fileExists(atPath: destinationURL.path, isDirectory: &isDir)
    
    return isExist
    
}

func isSongDownloaded(songcode: String?) -> Bool {
    guard let songId = songcode else {
        return false
    }
    let songFilename = songId + ".kx"
    let songDownloaded = isSongFileExist(filename: songFilename)
    return songDownloaded
}

func getSongDownloadedUrl(songcode: String?) -> URL? {
    guard let songId = songcode else {
        return nil
    }
    let songFilename = songId + ".kx"
    let songDownloaded = APPDIR.documentDirPath.appendingPathComponent(songFilename)
    return songDownloaded
}

func showProgressHud() {
    SVProgressHUD.setRingThickness(7)
    SVProgressHUD.setRingRadius(5)
    SVProgressHUD.setForegroundColor(UIColor(hex: 0xFCE86C, alpha:1))
    SVProgressHUD.setDefaultMaskType(.clear)
    SVProgressHUD.setBackgroundColor(UIColor(hex: 0x333, alpha:0.3))
    SVProgressHUD.show()
    //SVProgressHUD.dismiss(withDelay: TimeInterval(exactly: 10)!)
}

func dismissProgressHud() {
    
    SVProgressHUD.dismiss()
    
}

func kaxetAlert(title: String, message: String, titleColor: UIColor, presentingVC: UIViewController, closeParent: Bool? = nil) {
    
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
                    presentingVC.dismiss(animated: true){
                        showToolbarView()
                    }
                }
            }
            
        }
        
        kxAlert.addAction(okBtn)
        //kxAlert.show()
        presentingVC.present(kxAlert, animated: true, completion: nil)
    }
    
}

func successAlert(title: String, message: String, presentingVC: UIViewController, closeParent: Bool? = nil) {
    kaxetAlert(title: title, message: message, titleColor: UIColor(hex: 0x27CE49, alpha:1), presentingVC: presentingVC, closeParent: closeParent)
}

func failedAlert(title: String, message: String, presentingVC: UIViewController, closeParent: Bool? = nil) {
    kaxetAlert(title: title, message: message, titleColor: UIColor(hex: 0xFF6F81, alpha:1), presentingVC: presentingVC, closeParent: closeParent)
}

func infoAlert(title: String, message: String, presentingVC: UIViewController, closeParent: Bool? = nil) {
    kaxetAlert(title: title, message: message, titleColor: UIColor(hex: 0x3AFFFC, alpha:1), presentingVC: presentingVC, closeParent: closeParent)
}


func removeActivityIndicator(activityIndicator: UIActivityIndicatorView) {
    DispatchQueue.main.async {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
}


func logout(presentingVc: UIViewController) {
    
    presentingVc.dismiss(animated: true, completion: nil)
    
    if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
        
        KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.Token)
        KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.Userid)
        KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.Username)
        KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.Name)
        KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.Usertype)
        KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.Fblogin)
        KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.UserPhoto)
        
        KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.PaymentMtd.Pulsa)
        KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.PaymentMtd.Gopay)
        KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.PaymentMtd.Cash)
        
        FBSDKLoginManager().logOut()
        
        let mainPage = rootVC.storyboard?.instantiateViewController(withIdentifier: "MainViewController") as! ViewController
        let appDelegate = UIApplication.shared.delegate
        appDelegate?.window??.rootViewController = mainPage
        
    }
    /*
    if let topVC = UIApplication.getTopMostViewController() {
        
        KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.Token)
        KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.Userid)
        KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.Username)
        KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.Name)
        KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.Usertype)
        
        let mainPage = topVC.storyboard?.instantiateViewController(withIdentifier: "MainViewController") as! ViewController
        let appDelegate = UIApplication.shared.delegate
        appDelegate?.window??.rootViewController = mainPage
        
    }
    */
}

func hideToolbarView() {
    if let topVC = UIApplication.getTopMostViewController() as? StartViewController {
        topVC.toolbarView.isHidden = true
    }
}

func showToolbarView() {
    if let topVC = UIApplication.getTopMostViewController() as? StartViewController {
        topVC.toolbarView.isHidden = false
    }
}

func goShowMiniPlayer(presentingVc: UIViewController, song: NSDictionary, songUrl: URL?, plistName: String?) {
    
    if let topVC = UIApplication.getTopMostViewController() as? StartViewController {
        if let miniPlayerVc = topVC.children[1] as? MiniPlayerViewController {
            miniPlayerVc.activateMiniPlayer()
            miniPlayerVc.stopSong()
            miniPlayerVc.initData(data: song, songUrl: songUrl, plistName: plistName)
            miniPlayerVc.addButtonTapActionClose = {
                topVC.miniPlayerContainerView.isHidden = true
                //Update scroll view - toolbar bottom Constraint to original size
                topVC.toolbarTopConstraint.constant = 8
            }
            miniPlayerVc.showToastError = {
                ToastMessageView.shared.long(presentingVc.view, txt_msg: $0)
            }
            topVC.miniPlayerContainerView.isHidden = false
            
            //Update scroll view - toolbar bottom Constraint to accomodate mini player view controller
            topVC.toolbarTopConstraint.constant = 80
        }
        
    }
    
}

func goShowMiniPlayerWithPlaylist(presentingVc: UIViewController, song: NSDictionary, songUrl: URL?, plistName: String?, playlistData: NSArray?, indexSong: Int?) {
    
    if let topVC = UIApplication.getTopMostViewController() as? StartViewController {
        if let miniPlayerVc = topVC.children[1] as? MiniPlayerViewController {
            miniPlayerVc.activateMiniPlayer()
            miniPlayerVc.stopSong()
            miniPlayerVc.initDataWithPlaylist(data: song, songUrl: songUrl, plistName: plistName, playlistData: playlistData, indexSong: indexSong)
            miniPlayerVc.addButtonTapActionClose = {
                topVC.miniPlayerContainerView.isHidden = true
                //Update scroll view - toolbar bottom Constraint to original size
                topVC.toolbarTopConstraint.constant = 8
            }
            miniPlayerVc.showToastError = {
                ToastMessageView.shared.long(presentingVc.view, txt_msg: $0)
            }
            topVC.miniPlayerContainerView.isHidden = false
            
            //Update scroll view - toolbar bottom Constraint to accomodate mini player view controller
            topVC.toolbarTopConstraint.constant = 80
        }
        
    }
    
}

func goShowDownload(song: NSDictionary, songUrl: URL, songId: String, completion: @escaping(String)->Void) {
    if let topVC = UIApplication.getTopMostViewController() as? StartViewController {
    
        topVC.fullSpinningProgressView.initData(data: song)
        topVC.coverSpinningView.isHidden = false
        topVC.fullSpinningProgressView.isHidden = false
        //self.progressDownloadView.startAnimation()
        topVC.fullSpinningProgressView.downloadSong(url: songUrl, songId: songId) { _ in
            //code
            topVC.coverSpinningView.isHidden = true
            topVC.fullSpinningProgressView.isHidden = true
            completion("Completed")
        }
    }
}

func isValidEmailAddress(emailAddressString: String) -> Bool {
    
    var returnValue = true
    let emailRegEx = "[A-Z0-9a-z.-_]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,3}"
    
    do {
        let regex = try NSRegularExpression(pattern: emailRegEx)
        let nsString = emailAddressString as NSString
        let results = regex.matches(in: emailAddressString, range: NSRange(location: 0, length: nsString.length))
        
        if results.count == 0
        {
            returnValue = false
        }
        
    } catch let error as NSError {
        print("invalid regex: \(error.localizedDescription)")
        returnValue = false
    }
    
    return  returnValue
}

func convertToCurrency(amount: Double) -> String {
    // Pull apart the components of the user's locale
    var locComps = Locale.components(fromIdentifier: Locale.current.identifier)
    // Set the specific currency code
    locComps[NSLocale.Key.currencyCode.rawValue] = "IDR" // or any other specific currency code
    // Get the updated locale identifier
    let locId = Locale.identifier(fromComponents: locComps)
    // Get the new custom locale
    let loc = Locale(identifier: locId)
    
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .currency
    numberFormatter.locale = loc
    guard let resultText = numberFormatter.string(from: NSNumber(value: amount)) else {
        return "Convert error !"
    }
    
    return resultText
    
}

extension UIColor {
    
    convenience init(hex: Int, alpha: CGFloat) {
        let components = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 00) & 0xff) / 255
        )
        self.init(red: components.R, green: components.G, blue: components.B, alpha: alpha)
        
    }
    
}

extension CGColor {
    
    class func colorWithHex(hex: Int, alpha: CGFloat) -> CGColor {
        
        return UIColor(hex: hex, alpha: alpha).cgColor
        
    }
    
}

extension UIView {
    func addConstraintsWithFormat(format: String, views: UIView...) {
        var viewsDictionary = [String : UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDictionary))
    }
    
    func removeConstraintsWithFormat(format: String, views: UIView...) {
        var viewsDictionary = [String : UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        removeConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDictionary))
    }
    
    func setGradientBackground(color1: UIColor, color2: UIColor) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = [color1.cgColor, color2.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        
        layer.insertSublayer(gradientLayer, at: 0)
    }
}

extension UIApplication {
    class func getTopMostViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return getTopMostViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return getTopMostViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return getTopMostViewController(base: presented)
        }
        return base
    }
}
