//
//  ProfileCell.swift
//  SpheroMentalCommand
//
//  Created by Viet Anh on 6/23/15.
//  Copyright © 2015 Viet Anh. All rights reserved.
//

import Foundation

protocol ProfileCellDelegate{
    func handleSwipe(tag : Int)
    func deleteAction(profileName: String)
    func clearSelection()
}

class ProfileCell: UITableViewCell {
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var btClear: UIButton!
    @IBOutlet weak var gestureSwipeLeft : UIGestureRecognizer!
    @IBOutlet weak var gestureSwipeRight : UIGestureRecognizer!
    @IBOutlet weak var horizontalRight: NSLayoutConstraint!

    var delegate : ProfileCellDelegate!

    override func awakeFromNib() {
        super.awakeFromNib()
        let swipeGestureLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft(_:)))
        swipeGestureLeft.direction = UISwipeGestureRecognizer.Direction.left
        self.addGestureRecognizer(swipeGestureLeft)
        
        let swipeGestureRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight(_:)))
        swipeGestureRight.direction = UISwipeGestureRecognizer.Direction.right
        self.addGestureRecognizer(swipeGestureRight)
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func clearAction(_: AnyObject) {
        self.delegate.deleteAction(profileName: self.labelName.text!)
    }
    
    @objc func handleSwipeLeft(_: UISwipeGestureRecognizer) {
//        if self.tag >= 2 {
            self.horizontalRight.constant = 0;
        self.delegate.handleSwipe(tag: self.tag)
            
        UIView.animate(withDuration: 0.5, animations: {
                
                self.layoutIfNeeded()
                
                }, completion: {
                    finish in
            })
//        }
    }
    
    @objc func handleSwipeRight(_: UISwipeGestureRecognizer) {
        self.horizontalRight.constant = -80;
        UIView.animate(withDuration: 0.5, animations: {
            
            self.layoutIfNeeded()
            
        }, completion: {
            finish in
            self.delegate.clearSelection()
        })
    }
    
    func dismissButton() {
        self.horizontalRight.constant = -80;
        UIView.animate(withDuration: 0.0, animations: {
            
            self.layoutIfNeeded()
            
        }, completion: {
            finish in
            
        })
    }
}
