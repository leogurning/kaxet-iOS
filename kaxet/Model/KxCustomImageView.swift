//
//  KxCustomImageView.swift
//  kaxet
//
//  Created by LEONARD GURNING on 21/11/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

let imageCache = NSCache<NSString, UIImage>()

class KxCustomImageView: UIImageView {
    var imageUrlString: String?
    
    func loadImageUsingUrlString(urlString: String?) {
        
        imageUrlString = urlString
        
        if let imageURL = URL(string: urlString!) {
            
            //image = nil
            image = UIImage(named: "kxlogo")
            
            if let imageFromCache = imageCache.object(forKey: urlString! as NSString) {
                self.image = imageFromCache
                return
            }
            DispatchQueue.global(qos: .default).async {
                let dataImage = try? Data(contentsOf: imageURL)
                if let data = dataImage {
                    let displayImage = UIImage(data: data)
                    DispatchQueue.main.async {
                        if self.imageUrlString == urlString {
                            self.image = displayImage
                        }
                        imageCache.setObject(displayImage!, forKey: urlString! as NSString)
                    }
                }
            }
        }
        
    }

}
