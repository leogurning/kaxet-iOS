//
//  GenreCollectionViewCell.swift
//  kaxet
//
//  Created by LEONARD GURNING on 10/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class GenreCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var genreImage: KxCustomImageView!
    @IBOutlet weak var coverYellowView: UIView!
    @IBOutlet weak var genreNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.coverImage.layer.cornerRadius = 5
        self.coverImage.clipsToBounds = true
        //This is to make circle shape. Use corner radius
        self.coverYellowView.layer.cornerRadius = 30;
    }
}
