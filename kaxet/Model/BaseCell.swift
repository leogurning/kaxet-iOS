//
//  BaseCell.swift
//  kaxet
//
//  Created by LEONARD GURNING on 23/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class BaseCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //setupViews()
    }
    
    func setupViews() {
        //implement code in inherit class
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
