//
//  CheckCell.swift
//  typps
//
//  Created by Monte with Pillow on 7/12/16.
//  Copyright © 2016 Monte Thakkar. All rights reserved.
//

import UIKit

//delegate methods for CheckCell
protocol CheckCellDelegate: class {
    func deleteCheck(checkCell: CheckCell!)
}

class CheckCell: UITableViewCell {
    
    @IBOutlet weak var restaurantImageView: UIImageView!
    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var checkAmountAndPartySizeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var trashView: UIView!
    @IBOutlet weak var containerView: UIView!
    
    var hideTrashButton: Bool? = true
    
    var buttonDelegate: CheckCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        restaurantImageView.layer.cornerRadius = 5
        restaurantImageView.clipsToBounds = true
        
        containerView.layer.cornerRadius = 10
        containerView.clipsToBounds = true
        
        let doubleTapToShowDeleteButton: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.showdeleteCheckButton))
        doubleTapToShowDeleteButton.numberOfTapsRequired = 2
        self.containerView.addGestureRecognizer(doubleTapToShowDeleteButton)
        
        let tapGestureForDeleteButton: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.deleteCheckButtonPressed))
        self.trashView.addGestureRecognizer(tapGestureForDeleteButton)
        
        doubleTapToShowDeleteButton.delegate = self
        tapGestureForDeleteButton.delegate = self
        
        trashView.hidden = hideTrashButton!
    }
    
    override func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func showdeleteCheckButton() {
        hideTrashButton = !(hideTrashButton!)
        self.trashView.hidden = hideTrashButton!
    }
    
    func deleteCheckButtonPressed() {
        buttonDelegate?.deleteCheck(self)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    
}
