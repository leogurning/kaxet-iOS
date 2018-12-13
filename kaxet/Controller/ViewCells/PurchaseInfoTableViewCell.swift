//
//  PurchaseInfoTableViewCell.swift
//  kaxet
//
//  Created by LEONARD GURNING on 06/12/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class PurchaseInfoTableViewCell: UITableViewCell {

    @IBOutlet weak var albumImage: KxCustomImageView!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        albumImage.layer.cornerRadius = 5
        albumImage.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
