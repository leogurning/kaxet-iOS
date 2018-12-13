//
//  RecentSearchTableViewCell.swift
//  kaxet
//
//  Created by LEONARD GURNING on 16/11/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class RecentSearchTableViewCell: UITableViewCell {

    @IBOutlet weak var searchHistoryItem: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
