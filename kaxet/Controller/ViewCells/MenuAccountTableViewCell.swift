//
//  MenuAccountTableViewCell.swift
//  kaxet
//
//  Created by LEONARD GURNING on 04/12/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class MenuAccountTableViewCell: UITableViewCell {

    @IBOutlet weak var menuAccountIconImage: UIImageView!
    @IBOutlet weak var menuAccountLabel: UILabel!
    @IBOutlet weak var menuAccountArrowImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
