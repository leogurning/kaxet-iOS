//
//  BuySongViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 14/11/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import WebKit

protocol BuySongViewControllerDelegate{
    func refreshData(_ song: Any?)
}

class BuySongViewController: UIViewController {
    
    var delegate : BuySongViewControllerDelegate?
    
    let apiServices = RestAPIServices()
    
    let apiUrl = APPURL.BaseURL
    let hostUrl = APPURL.Domain
    private var userid: String = ""
    private var isPulsa: String = ""
    private var isGopay: String = ""
    private var isCash: String = ""
    var songData: NSDictionary = [:]
    private var purchaseId: String = ""
    
    @IBOutlet weak var webView: UIView!
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var popUpView: UIView!
    @IBOutlet weak var albumImage: KxCustomImageView!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var songPriceLabel: UILabel!
    @IBOutlet weak var songPriceConfirmLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    lazy var pmtWebView: WKWebView = {
        //let cv = WKWebView(frame: self.webView.frame)
        let cv = WKWebView()
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.uiDelegate = self
        cv.navigationDelegate = self
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
        
        mainView.layer.cornerRadius = 10
        mainView.clipsToBounds = true
        
        popUpView.layer.cornerRadius = 10
        popUpView.clipsToBounds = true
        
        songTitleLabel.text = songData["songname"] as? String
        artistNameLabel.text = songData["artist"] as? String
        let songPrice = songData["songprice"] as? Double
        let songPriceText = convertToCurrency(amount: songPrice!)
        
        songPriceLabel.text = songPriceText
        songPriceConfirmLabel.text = songPriceText + " ?"
        
        let albumImagePath = songData["albumphoto"] as? String
        self.albumImage.loadImageUsingUrlString(urlString: albumImagePath)
        self.albumImage.layer.cornerRadius = 5
        self.albumImage.clipsToBounds = true
        /*
        if let albumImageURL = URL(string: albumImagePath!) {
            DispatchQueue.global().async {
                let dataImage = try? Data(contentsOf: albumImageURL)
                if let data = dataImage {
                    let albumImage = UIImage(data: data)
                    DispatchQueue.main.async {
                        self.albumImage.image = albumImage
                        self.albumImage.layer.cornerRadius = 5
                        self.albumImage.clipsToBounds = true
                    }
                }
            }
        }
        */
        checkPaymentMtd()
        addTapGestureRecognizer()
        
        self.webView.addSubview(self.pmtWebView)
        setupWebViewLayout()
        webView.isHidden = true
    
        let webViewKeyPathsToObserve = ["loading", "estimatedProgress"]
        for keyPath in webViewKeyPathsToObserve {
            self.pmtWebView.addObserver(self, forKeyPath: keyPath, options: .new, context: nil)
        }
        
    }
    
    private func setupWebViewLayout() {
        pmtWebView.topAnchor.constraint(equalTo: webView.topAnchor, constant: 4).isActive = true
        pmtWebView.centerXAnchor.constraint(equalTo: webView.centerXAnchor).isActive = true
        pmtWebView.leftAnchor.constraint(equalTo: webView.leftAnchor, constant: 0).isActive = true
        pmtWebView.rightAnchor.constraint(equalTo: webView.rightAnchor, constant: 0).isActive = true
        pmtWebView.bottomAnchor.constraint(equalTo: webView.bottomAnchor, constant: 0).isActive = true
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let keyPath = keyPath else { return }
        
        switch keyPath {
            
        //case "loading":
            // If you have back and forward buttons, then here is the best time to enable it
            //print("loading")
            
        case "estimatedProgress":
            // If you are using a `UIProgressView`, this is how you update the progress
            //progressView.isHidden = pmtWebView.estimatedProgress == 1
            progressView.progress = Float(pmtWebView.estimatedProgress)
            
        default:
            break
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
    
    private func checkPaymentMtd() {
        
        if let checkPulsa = KeychainWrapper.standard.string(forKey: APPCONSTANT.PaymentMtd.Pulsa) {
            isPulsa = checkPulsa
        } else {
            isPulsa = "N"
        }
        
        if let checkGopay = KeychainWrapper.standard.string(forKey: APPCONSTANT.PaymentMtd.Gopay) {
            isGopay = checkGopay
        } else {
            isGopay = "N"
        }
        
        if let checkCash = KeychainWrapper.standard.string(forKey: APPCONSTANT.PaymentMtd.Cash) {
            isCash = checkCash
        } else {
            isCash = "N"
        }
        
    }
    
    private func addSongPurchase(pPmtMtd: String) {
        
        let labelid = songData["labelid"] as? String// req.body.labelid;
        let songid = songData["_id"] as? String//req.body.songid;
        let artistid = songData["artistid"] as? String//req.body.artistid;
        let albumid = songData["albumid"] as? String//req.body.albumid;
        let songprice = songData["songprice"] as? Double//req.body.songprice;
        let songname = songData["songname"] as? String
        let status = "STSPEND" //status
        let paymentmtd = pPmtMtd//req.body.paymentmtd;
        
        if (labelid?.isEmpty)! ||
            (songid?.isEmpty)! ||
            (artistid?.isEmpty)! ||
            (albumid?.isEmpty)! ||
            (songprice == nil) ||
            (paymentmtd.isEmpty) {
            //Display alert message
            failedAlert(title: "Error", message: "Missing required fields. Please input all required fields !", presentingVC: self)
            return
        }
        
        showProgressHud()
        
        DispatchQueue.global(qos: .userInteractive).async {
            //Send HTTP request to perform Add playlist
            let addPurchaseUrl = self.apiUrl + "/songpurchase/\(self.userid)"
            let postString = ["labelid": labelid!, "songid": songid!, "artistid": artistid!, "albumid": albumid!, "songprice": songprice!, "status": status, "paymentmtd": paymentmtd] as NSDictionary
            
            self.apiServices.executePostRequestWithToken(urlToExecute: addPurchaseUrl, bodyDict: postString, completion: { (jsonResponse, error) in
                
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
                    let orderId = responseDict["orderId"] as? String
                    self.purchaseId = orderId!
                    DispatchQueue.main.async {
                        
                        if paymentmtd == APPCONSTANT.PaymentMtd.Cash {
                            self.closeProgressHud()
                            successAlert(title: "Success", message: "Song Purchase by Cash successfully completed.Order Id: \(orderId!)", presentingVC: self, closeParent: true)
                        } else {
                            
                            let payType = self.getPaymentType(pPmtMtd: pPmtMtd)
                            //ToastMessageView.shared.long(self.view, txt_msg: "Purchase by Pulsa or Gopay. Call Coda API. Order Id: \(orderId!)")
                            // Coda Payment Pages Back End Integration :
                            
                            let urlToExecute = "https://sandbox.codapayments.com/airtime/api/restful/v1.0/Payment/init.json"
                            
                            let postString = [ "initRequest": ["apiKey": APPCONSTANT.CodaParams.ApiKey, "orderId": orderId!, "country": APPCONSTANT.CodaParams.CountryCode, "currency": APPCONSTANT.CodaParams.CurrencyCode, "payType": payType, "items": [["code": songid!, "name": songname!, "price": songprice!, "type": 1]], "profile": ["entry": [["key": "user_id", "value": self.userid],["key": "need_mno_id", "value": "Yes"]]]]] as [String: Any]
                            
                            self.apiServices.executePostRequestNoToken(urlToExecute: urlToExecute, bodyDict: postString as NSDictionary, completion: { (jsonResponse, error) in
                                
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
                                
                                let result = responseDict["initResult"] as? NSDictionary
                                let txnId = result!["txnId"] as? Int64
                                
                                if let transactionCode = txnId {
                                    print("Trx code: \(transactionCode)")
                                    DispatchQueue.main.async {
                                        let urlToExecute = "https://sandbox.codapayments.com/airtime/begin?type=3&txn_id=\(transactionCode)&browser_type=mobile-web"
                                        let restUrl = URL(string: urlToExecute)
                                        let request = URLRequest(url: restUrl!)
                                        // init and load request in webview.
                                        self.pmtWebView.load(request as URLRequest)
                                        //self.webView.sendSubviewToBack(self.pmtWebView)
                                        self.webView.isHidden = false
                                        self.popUpView.isHidden = true
                                        self.closeProgressHud()
                                    }
                                    
                                } else {
                                    DispatchQueue.main.async {
                                        self.closeProgressHud()
                                        //Error Alert
                                        failedAlert(title: "Coda Txn Error", message: "No transaction code...Try again later !", presentingVC: self)
                                        return
                                    }
                                    
                                }
                            })
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
    
    private func deleteSongPurchase(pOrderId: String) {
        
        DispatchQueue.global(qos: .userInteractive).async {
            //Send HTTP request to perform Add playlist
            let deletetUrl = self.apiUrl + "/songpurchase/\(pOrderId)"
            //let postString = ["playlistname": playlistName!] as NSDictionary
            
            self.apiServices.executeDeleteRequestWithToken(urlToExecute: deletetUrl, bodyDict: nil, completion: { (jsonResponse, error) in
                
                if error != nil {
                    print("error= \(String(describing: error))")
                    return
                }
                
                guard let responseDict = jsonResponse else {
                    print("error= \(String(describing: error))")
                    return
                }
                
                let success = responseDict["success"] as? Bool
                let message1 = responseDict["message"] as? String
                
                if success! {
                    DispatchQueue.main.async {
                        //self.closeProgressHud()
                        print("Delete orderId: \(pOrderId) is successful")
                        
                    }
                    
                    
                } else {
                    print("Delete orderId: \(pOrderId) is failed with message: \(message1!)")
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
    
    private func getPaymentType(pPmtMtd: String) -> Int {
        var result = 0
        
        switch pPmtMtd {
        case APPCONSTANT.PaymentMtd.Pulsa:
            result = 1
        case APPCONSTANT.PaymentMtd.Gopay:
            result = 227
        default:
            result = 0
        }
        
        return result
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func btnCancelBuy(_ sender: UIButton) {
        self.dismiss(animated: true){
            showToolbarView()
        }
    }
    
    @IBAction func btnBuySong(_ sender: UIButton) {
        if isPulsa == "Y" {
            //ToastMessageView.shared.long(self.view, txt_msg: "Will perform buying process using Pulsa")
            addSongPurchase(pPmtMtd: APPCONSTANT.PaymentMtd.Pulsa)
        } else {
            if isGopay == "Y" {
                //ToastMessageView.shared.long(self.view, txt_msg: "Will perform buying process using Gopay")
                addSongPurchase(pPmtMtd: APPCONSTANT.PaymentMtd.Gopay)
            } else {
                if isCash == "Y" {
                    //ToastMessageView.shared.long(self.view, txt_msg: "Will perform buying process using Cash")
                    addSongPurchase(pPmtMtd: APPCONSTANT.PaymentMtd.Cash)
                } else {
                    ToastMessageView.shared.long(self.view, txt_msg: "You have not set the Payment Method. Please set it first in the Account - Payment")
                }
            }
        }
        
    }
    
    
}

extension BuySongViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        return (touch.view === self.view)
    }
}

extension BuySongViewController: WKNavigationDelegate, WKUIDelegate {
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        if !(navigationAction.targetFrame?.isMainFrame)! {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            webView.load(navigationAction.request)
        }
        return nil;
        
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(error.localizedDescription)
        DispatchQueue.main.async {
            ToastMessageView.shared.long(self.view, txt_msg: "Error call Coda Payment page. Please try again later")
            self.closeWebView(resfreshParent: true)
        }
        
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        //if navigationAction.navigationType == .linkActivated {}
        
        if let newURL = navigationAction.request.url,
            let host = newURL.host, !host.contains("codapayments.com") && UIApplication.shared.canOpenURL(newURL) {
            let urlString = newURL.absoluteString
            
            if urlString.hasPrefix("gojek://") {
                UIApplication.shared.open(newURL, completionHandler: { (result) in
                    if result {
                        //print(newURL)
                        //print("Redirected to browser. No need to open it locally")
                        decisionHandler(.cancel)
                        self.closeWebView(resfreshParent: true)
                    } else {
                        //print("browser can not open url. Close all.")
                        decisionHandler(.cancel)
                        self.closeWebView(resfreshParent: false)
                    }
                })
            } else {
                if urlString.contains("/gopay/ui/") {
                    //print(urlString)
                    //print("Open gojek")
                    UIApplication.shared.open(newURL, completionHandler: { (result) in
                        if result {
                            //print(newURL)
                            //print("Redirected to browser. No need to open it locally")
                            decisionHandler(.cancel)
                            self.closeWebView(resfreshParent: true)
                        } else {
                            //print("browser can not open url. Close all.")
                            decisionHandler(.cancel)
                            self.closeWebView(resfreshParent: false)
                        }
                    })
                } else {
                    decisionHandler(.cancel)
                    self.closeWebView(resfreshParent: false)
                }
            }
        } else {
            
            let newURL = navigationAction.request.url
            let urlString = newURL!.absoluteString
            //print(urlString)
            if urlString.contains("/airtime/null") || urlString.contains("/airtime/msisdn#none") {
                let orderId = getParameterFrom(url: urlString, param: "OrderId")
                if orderId == nil {
                    self.deleteSongPurchase(pOrderId: self.purchaseId)
                }
                decisionHandler(.cancel)
                self.closeWebView(resfreshParent: false)
                
            } else {
                //print("Open it locally")
                if urlString.contains("/airtime/complete") {
                    let infoByte = getParameterFrom(url: urlString, param: "extInfoByte")
                    if infoByte == nil {
                        self.deleteSongPurchase(pOrderId: self.purchaseId)
                    }
                    decisionHandler(.cancel)
                    self.closeWebView(resfreshParent: true)
                    
                } else {
                    decisionHandler(.allow)
                }
                
            }
            
        }
        

    }
    /*
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Strat to load")
    }
    */
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView.setProgress(0.0, animated: false)
    }
 
    private func closeWebView(resfreshParent: Bool) {
        self.pmtWebView.removeFromSuperview()
        if resfreshParent {
            self.delegate?.refreshData(songData)
        }
        self.dismiss(animated: true){
            showToolbarView()
        }
    }
    
    func getParameterFrom(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }

}
