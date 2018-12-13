//
//  UserPlaylistPopUpTableViewCell.swift
//  kaxet
//
//  Created by LEONARD GURNING on 12/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class UserPlaylistPopUpTableViewCell: UITableViewCell {

    @IBOutlet weak var playlistNameLabel: UILabel!
    @IBOutlet weak var noOfSongsLabel: UILabel!

    @IBOutlet weak var albumImagePl1: KxCustomImageView!
    @IBOutlet weak var albumImagePl2: KxCustomImageView!
    @IBOutlet weak var albumImagePl3: KxCustomImageView!
    @IBOutlet weak var albumImagePl4: KxCustomImageView!
    @IBOutlet weak var albumImagesView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        albumImagesView.layer.cornerRadius = 5
        albumImagesView.layer.masksToBounds = true
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func initImage() {
        albumImagePl1.image = UIImage(named: "kxlogo")
        albumImagePl2.image = UIImage(named: "kxlogo")
        albumImagePl3.image = UIImage(named: "kxlogo")
        albumImagePl4.image = UIImage(named: "kxlogo")
    }

}
