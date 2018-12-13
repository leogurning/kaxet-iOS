//
//  AlbumTableViewCell.swift
//  kaxet
//
//  Created by LEONARD GURNING on 25/11/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class AlbumTableViewCell: UITableViewCell {

    @IBOutlet weak var albumImage: KxCustomImageView!
    @IBOutlet weak var arrowImage: UIImageView!
    @IBOutlet weak var albumTopLabel: UILabel!
    @IBOutlet weak var albumBottomLabel: UILabel!
    
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var separatorViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumBottomLabelBottomConstraint: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        albumImage.layer.cornerRadius = 5
        albumImage.clipsToBounds = true
        arrowImage.isHidden = true
        separatorViewLeadingConstraint.constant = albumImage.bounds.width + 24
        layoutIfNeeded()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
