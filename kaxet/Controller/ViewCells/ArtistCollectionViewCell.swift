//
//  ArtistCollectionViewCell.swift
//  kaxet
//
//  Created by LEONARD GURNING on 22/11/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class ArtistCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cellContentView: UIView!
    @IBOutlet weak var artistImage: KxCustomImageView!
    @IBOutlet weak var artistNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.artistImage.layer.cornerRadius = 54
        self.artistImage.clipsToBounds = true
        self.cellContentView.layer.cornerRadius = 5
        self.cellContentView.clipsToBounds = true
        
        self.cellContentView.setGradientBackground(color1: UIColor(hex: 0xE3E3E3, alpha:0.8), color2: UIColor(hex: 0xFCE86C, alpha:0.6))
    }
    
}
