//
//  MenuLibTableViewCell.swift
//  kaxet
//
//  Created by LEONARD GURNING on 21/11/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class MenuLibTableViewCell: UITableViewCell {
    
    @IBOutlet weak var MenuLibIconImage: UIImageView!
    @IBOutlet weak var MenuLibForwardImage: UIImageView!
    @IBOutlet weak var MenuLibLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
