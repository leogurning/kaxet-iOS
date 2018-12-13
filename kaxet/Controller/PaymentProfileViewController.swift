//
//  PaymentProfileViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 06/12/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class PaymentProfileViewController: UIViewController {

    private var isPulsa: String = ""
    private var isGopay: String = ""
    private var isCash: String = ""
    
    @IBOutlet weak var pulsaView: UIView!
    @IBOutlet weak var checkmarkPulsaImage: UIImageView!
    @IBOutlet weak var iconPulsaView: UIView!
    @IBOutlet weak var gopayView: UIView!
    @IBOutlet weak var iconGopayView: UIView!
    @IBOutlet weak var checkmarkGopayImage: UIImageView!
    @IBOutlet weak var cashView: UIView!
    @IBOutlet weak var iconCashView: UIView!
    @IBOutlet weak var checkmarkCashImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        checkmarkPulsaImage.isHidden = true
        checkmarkGopayImage.isHidden = true
        checkmarkCashImage.isHidden = true
        iconPulsaView.layer.cornerRadius = 15
        iconPulsaView.clipsToBounds = true
        iconGopayView.layer.cornerRadius = 15
        iconGopayView.clipsToBounds = true
        iconCashView.layer.cornerRadius = 15
        iconCashView.clipsToBounds = true
        addTapGesture()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkPaymentMtd()
        displayCheckmark()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
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
    
    private func displayCheckmark() {
        
        if isPulsa == "Y" {
            checkmarkPulsaImage.isHidden = false
        } else {
            checkmarkPulsaImage.isHidden = true
        }
        
        if isGopay == "Y" {
            checkmarkGopayImage.isHidden = false
        } else {
            checkmarkGopayImage.isHidden = true
        }
        
        if isCash == "Y" {
            checkmarkCashImage.isHidden = false
        } else {
            checkmarkCashImage.isHidden = true
        }
    }
    
    private func addTapGesture() {
        
        pulsaView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(setPulsaPayment(_:))))
        gopayView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(setGopayPayment(_:))))
        cashView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(setCashPayment(_:))))
    }
    
    @objc func setPulsaPayment(_ sender: UITapGestureRecognizer) {
        let savePulsa: Bool = KeychainWrapper.standard.set("Y", forKey: APPCONSTANT.PaymentMtd.Pulsa)
        print("Current Payment pulsa save result: \(savePulsa)")
        let saveGopay: Bool = KeychainWrapper.standard.set("N", forKey: APPCONSTANT.PaymentMtd.Gopay)
        print("Current Payment gopay save result: \(saveGopay)")
        let saveCash: Bool = KeychainWrapper.standard.set("N", forKey: APPCONSTANT.PaymentMtd.Cash)
        print("Current Payment cash save result: \(saveCash)")
        
        checkPaymentMtd()
        displayCheckmark()
    }
    
    @objc func setGopayPayment(_ sender: UITapGestureRecognizer) {
        let savePulsa: Bool = KeychainWrapper.standard.set("N", forKey: APPCONSTANT.PaymentMtd.Pulsa)
        print("Current Payment pulsa save result: \(savePulsa)")
        let saveGopay: Bool = KeychainWrapper.standard.set("Y", forKey: APPCONSTANT.PaymentMtd.Gopay)
        print("Current Payment gopay save result: \(saveGopay)")
        let saveCash: Bool = KeychainWrapper.standard.set("N", forKey: APPCONSTANT.PaymentMtd.Cash)
        print("Current Payment cash save result: \(saveCash)")
        
        checkPaymentMtd()
        displayCheckmark()
    }
    
    @objc func setCashPayment(_ sender: UITapGestureRecognizer) {
        let savePulsa: Bool = KeychainWrapper.standard.set("N", forKey: APPCONSTANT.PaymentMtd.Pulsa)
        print("Current Payment pulsa save result: \(savePulsa)")
        let saveGopay: Bool = KeychainWrapper.standard.set("N", forKey: APPCONSTANT.PaymentMtd.Gopay)
        print("Current Payment gopay save result: \(saveGopay)")
        let saveCash: Bool = KeychainWrapper.standard.set("Y", forKey: APPCONSTANT.PaymentMtd.Cash)
        print("Current Payment cash save result: \(saveCash)")
        
        checkPaymentMtd()
        displayCheckmark()
    }
}
