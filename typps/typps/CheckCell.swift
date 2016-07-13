//
//  CheckCell.swift
//  typps
//
//  Created by Monte with Pillow on 7/12/16.
//  Copyright © 2016 Monte Thakkar. All rights reserved.
//

import UIKit

class CheckCell: UITableViewCell {
    
    @IBOutlet weak var restaurantImageView: UIImageView!
    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var checkAmountAndPartySizeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        restaurantImageView.layer.cornerRadius = 5
        restaurantImageView.clipsToBounds = true
        
        containerView.layer.cornerRadius = 10
        containerView.clipsToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

       
    }

}
