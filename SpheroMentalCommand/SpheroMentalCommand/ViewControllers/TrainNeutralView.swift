//
//  TrainNeutralView.swift
//  Sphero Mental Command
//
//  Created by Viet Anh on 4/4/16.
//  Copyright © 2016 Viet Anh. All rights reserved.
//

import UIKit

protocol TrainNeutralDelegate{
    func neutralStartTraining()
    func neutralRejectAction()
    func neutralAcceptAction()
}

class TrainNeutralView: UIView {

    @IBOutlet var progressView: UIView!
    @IBOutlet var progressComplete: NSLayoutConstraint!
    
    @IBOutlet var buttonActionView: UIView!
    
    @IBOutlet var desciptionLabel: UILabel!
    @IBOutlet var tutorialLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    var delegate: TrainNeutralDelegate!
    
    var animationTimer: Timer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.desciptionLabel.text = "To start using Sphero, you must make a good recording of your mind in neutral state in a neutral state your mind is relaxed and you are not focusing on any thoughts or actions in particular.\n\nWhen you are ready, please tap the train button at the bottom of the screen. If you are not satisfied with the neutral recording, you may record it again."
        self.resetNeutralTraing()
    }
    
    func startTrainingAnimation(){
        animationTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(TrainNeutralView.updateProgress), userInfo: nil, repeats: true)
        animationTimer?.fire()
    }
    
    @objc func updateProgress(){
        self.progressComplete.constant += 13.75
        if self.progressComplete.constant > 220{
            self.progressComplete.constant = 220
            animationTimer?.invalidate()
        }
        self.layoutSubviews()
    }
    
    func resetNeutralTraing(){
        self.progressComplete.constant = 0
        self.progressView.isHidden = false
        self.buttonActionView.isHidden = true
        self.layoutSubviews()
    }
    
    func trainingSuccess(){
        self.progressView.isHidden = true
        self.buttonActionView.isHidden = false
    }
    
    @IBAction func trainAction(_: AnyObject!){
        self.delegate.neutralStartTraining()
    }
    
    @IBAction func rejectAction(_: AnyObject!){
        self.delegate.neutralRejectAction()
    }
    
    @IBAction func acceptAction(_: AnyObject!){
        self.delegate.neutralAcceptAction()
    }
}

class CornerImageView : UIImageView{
    @IBInspectable var cornerRadius: CGFloat = 5 {
        didSet {
            clipsToBounds = true
            layer.cornerRadius = cornerRadius
        }
    }
}

class CornerView : UIView{
    @IBInspectable var cornerRadius: CGFloat = 5 {
        didSet {
            clipsToBounds = true
            layer.cornerRadius = cornerRadius
        }
    }
}

class CornerButton : UIButton{
    @IBInspectable var cornerRadius: CGFloat = 5 {
        didSet {
            clipsToBounds = true
            layer.cornerRadius = cornerRadius
        }
    }
}
