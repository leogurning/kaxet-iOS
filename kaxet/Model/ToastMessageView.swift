//
//  ToastMessageView.swift
//  kaxet
//
//  Created by LEONARD GURNING on 07/11/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import Foundation
import UIKit

open class ToastMessageView: UILabel {
    
    var overlayView = UIView()
    var backView = UIView()
    var lbl = UILabel()
    
    class var shared: ToastMessageView {
        struct Static {
            static let instance: ToastMessageView = ToastMessageView()
        }
        return Static.instance
    }
    
    func setup(_ view: UIView,txt_msg:String)
    {
        let white = UIColor ( red: 1/255, green: 0/255, blue:0/255, alpha: 0.0 )
        
        backView.frame = CGRect(x: 0, y: 0, width: view.frame.width , height: view.frame.height)
        backView.center = view.center
        backView.backgroundColor = white
        view.addSubview(backView)
        
        overlayView.frame = CGRect(x: 0, y: 0, width: view.frame.width - 60  , height: 50)
        overlayView.center = CGPoint(x: view.bounds.width / 2, y: view.bounds.height - 30)
        overlayView.backgroundColor = UIColor(hex: 0x2f2f31, alpha:1)
        overlayView.clipsToBounds = true
        overlayView.layer.cornerRadius = 10
        overlayView.alpha = 0
        
        let customWhite = UIColor(hex: 0xe1e1e1, alpha:1)
        lbl.frame = CGRect(x: 0, y: 0, width: overlayView.frame.width, height: 50)
        lbl.numberOfLines = 0
        lbl.textColor = customWhite
        lbl.center = overlayView.center
        lbl.text = txt_msg
        lbl.textAlignment = .center
        lbl.center = CGPoint(x: overlayView.bounds.width / 2, y: overlayView.bounds.height / 2)
        lbl.font = UIFont(name: "TrebuchetMS", size: 12)
        overlayView.addSubview(lbl)
        
        view.addSubview(overlayView)
    }
    
    open func short(_ view: UIView,txt_msg:String) {
        self.setup(view,txt_msg: txt_msg)
        //Animation
        UIView.animate(withDuration: 0.5, animations: {
            self.overlayView.alpha = 1
        }) { (true) in
            UIView.animate(withDuration: 3, animations: {
                self.overlayView.alpha = 0
            }) { (true) in
                UIView.animate(withDuration: 0.5, animations: {
                    DispatchQueue.main.async(execute: {
                        self.overlayView.alpha = 0
                        self.lbl.removeFromSuperview()
                        self.overlayView.removeFromSuperview()
                        self.backView.removeFromSuperview()
                    })
                })
            }
        }
    }
    
    open func long(_ view: UIView,txt_msg:String) {
        self.setup(view,txt_msg: txt_msg)
        //Animation
        UIView.animate(withDuration: 0.5, animations: {
            self.overlayView.alpha = 1
        }) { (true) in
            UIView.animate(withDuration: 5, animations: {
                self.overlayView.alpha = 0
            }) { (true) in
                UIView.animate(withDuration: 0.5, animations: {
                    DispatchQueue.main.async(execute: {
                        self.overlayView.alpha = 0
                        self.lbl.removeFromSuperview()
                        self.overlayView.removeFromSuperview()
                        self.backView.removeFromSuperview()
                    })
                })
            }
        }
    }
}
