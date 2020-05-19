//
//  TrainActionView.swift
//  Sphero Mental Command
//
//  Created by Viet Anh on 4/5/16.
//  Copyright © 2016 Viet Anh. All rights reserved.
//

import UIKit

protocol TrainActionDelegate{
    func startTraining(action: MentalAction_t)
    func rejectAction()
    func acceptAction()
    func calibrateAction()
    func calibrateDone()
    func deactiveAction(action: MentalAction_t)
    func isActionActive(action: MentalAction_t) -> Bool!
    func openPopUp(sender: AnyObject!, action: MentalAction_t, reTrainAction: @escaping () -> ())
    func isActionTrain(action: MentalAction_t) -> Bool!
    func isInTraining() -> Bool!
}

class TrainActionView: UIView {

    @IBOutlet var trainMainView: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var settingView: UIView!
    @IBOutlet var calibrationView: UIView!
    @IBOutlet var settingTopSpace: NSLayoutConstraint!
    
    private var isSettingOpened = false
    
    @IBOutlet var progressView: UIView!
    @IBOutlet var progressComplete: NSLayoutConstraint!
    @IBOutlet var buttonActionView: UIView!
    @IBOutlet var tutorialLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    
    @IBOutlet var imageLeft: UIImageView!
    @IBOutlet var imageRight: UIImageView!
    @IBOutlet var imageUp: UIImageView!
    @IBOutlet var imageDown: UIImageView!
    @IBOutlet var imageCenter: UIButton!
    
    @IBOutlet var controlImage: UIImageView!
    @IBOutlet var pushStatus: UILabel!
    @IBOutlet var pullStatus: UILabel!
    @IBOutlet var leftStatus: UILabel!
    @IBOutlet var rightStatus: UILabel!
    
    var delegate: TrainActionDelegate!
    var animationTimer: Timer?
    
    var currentAction: MentalAction_t?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        if UIDevice.current.userInterfaceIdiom == .pad{
            self.settingTopSpace.constant = 760
        } else {
            self.settingTopSpace.constant = UIScreen.main.bounds.height * 0.8 * 0.95
        }
        
        self.resetTraining()
    }
    
    func updateSettingView(){
        UIView.animate(withDuration: 0.5) {
            if self.isSettingOpened == true{
                if UIDevice.current.userInterfaceIdiom == .pad{
                    self.settingTopSpace.constant = 25
                } else {
                    self.settingTopSpace.constant = UIScreen.main.bounds.height * 0.8 * 0.04
                }
            }else{
                if UIDevice.current.userInterfaceIdiom == .pad{
                    self.settingTopSpace.constant = 760
                } else {
                    self.settingTopSpace.constant = UIScreen.main.bounds.height * 0.8 * 0.95
                }
            }
            
            self.layoutSubviews()
        }
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
    
    func resetTraining(){
        self.progressComplete.constant = 0
        self.progressView.isHidden = false
        self.buttonActionView.isHidden = true
        
        resetAllSelected()
        self.controlImage.image = UIImage(named: "control_back")
        self.statusLabel.text = "Training with different directions"
        self.tutorialLabel.text = "Click to the direction then click train button to start Training"
        
        self.layoutSubviews()
    }
    
    func trainingSuccess(){
        self.progressView.isHidden = true
        self.buttonActionView.isHidden = false
    }
    
    func resetAllSelected(){
        self.imageCenter.setImage(UIImage(named: "center_back") , for: .normal)
        if self.delegate != nil{
            self.imageUp.image = ((self.delegate.isActionActive(action: Mental_Push) == true) || (self.delegate.isActionTrain(action: Mental_Push) == false)) ? UIImage(named: "arrow_up_u") : UIImage(named: "arrow_up_d")
            self.imageDown.image = (self.delegate.isActionActive(action: Mental_Pull) == true || self.delegate.isActionTrain(action:Mental_Pull) == false) ? UIImage(named: "arrow_down_u") : UIImage(named: "arrow_down_d")
            self.imageLeft.image = (self.delegate.isActionActive(action: Mental_Left) == true || self.delegate.isActionTrain(action: Mental_Left) == false) ? UIImage(named: "arrow_left_u") : UIImage(named: "arrow_left_d")
            self.imageRight.image = (self.delegate.isActionActive(action: Mental_Right) == true || self.delegate.isActionTrain(action: Mental_Right) == false) ? UIImage(named: "arrow_right_u") : UIImage(named: "arrow_right_d")
        }
    }
    
    @IBAction func startTraingAction(_: AnyObject!){
        if currentAction != nil{
            self.delegate.startTraining(action: currentAction!)
        }
    }
    
    @IBAction func neutralTrainAction(_ sender: AnyObject!){
        if self.delegate.isInTraining() == true{
            return
        }
        if self.delegate.isActionTrain(action: Mental_Neutral) == true{
            self.delegate.openPopUp(sender: sender, action: Mental_Neutral, reTrainAction: { () in
                self.currentAction = Mental_Neutral
                self.resetAllSelected()
                self.imageCenter.setImage(UIImage(named: "center_training") , for: .normal)
            })
        } else {
            if currentAction == Mental_Neutral{
                currentAction = nil
                self.imageCenter.setImage(UIImage(named: "center_back") , for: .normal)
            } else {
                currentAction = Mental_Neutral
                resetAllSelected()
                self.imageCenter.setImage(UIImage(named: "center_training") , for: .normal)
            }
        }
    }
    
    @IBAction func upTrainAction(_ sender: AnyObject!){
        if self.delegate.isInTraining() == true{
            return
        }
        if self.delegate.isActionTrain(action: Mental_Push) == true{
            self.delegate.openPopUp(sender: sender, action: Mental_Push, reTrainAction: { () in
                self.currentAction = Mental_Push
                self.resetAllSelected()
                self.imageUp.image = UIImage(named: "arrow_up")
            })
        } else {
            if currentAction == Mental_Push{
                currentAction = nil
                self.imageUp.image = self.delegate.isActionActive(action: Mental_Push) == true ? UIImage(named: "arrow_up_u") : UIImage(named: "arrow_up_d")
            } else {
                currentAction = Mental_Push
                resetAllSelected()
                self.imageUp.image = UIImage(named: "arrow_up")
            }
        }
    }
    
    @IBAction func downTrainAction(_ sender: AnyObject!){
        if self.delegate.isInTraining() == true{
            return
        }
        if self.delegate.isActionTrain(action: Mental_Pull) == true{
            self.delegate.openPopUp(sender: sender, action: Mental_Pull, reTrainAction: { () in
                self.currentAction = Mental_Pull
                self.resetAllSelected()
                self.imageDown.image = UIImage(named: "arrow_down")
            })
        } else {
            if currentAction == Mental_Pull{
                currentAction = nil
                self.imageDown.image = self.delegate.isActionActive(action: Mental_Pull) == true ? UIImage(named: "arrow_down_u") : UIImage(named: "arrow_down_d")
            } else {
                currentAction = Mental_Pull
                resetAllSelected()
                self.imageDown.image = UIImage(named: "arrow_down")
            }
        }
    }
    
    @IBAction func leftTrainAction(_ sender: AnyObject!){
        if self.delegate.isInTraining() == true{
            return
        }
        if self.delegate.isActionTrain(action: Mental_Left) == true{
            self.delegate.openPopUp(sender: sender, action: Mental_Left, reTrainAction: { () in
                self.currentAction = Mental_Left
                self.resetAllSelected()
                self.imageLeft.image = UIImage(named: "arrow_left")
            })
        } else {
            if currentAction == Mental_Left{
                currentAction = nil
                self.imageLeft.image = self.delegate.isActionActive(action: Mental_Left)       == true ? UIImage(named: "arrow_left_u") : UIImage(named: "arrow_left_d")
            } else {
                currentAction = Mental_Left
                resetAllSelected()
                self.imageLeft.image = UIImage(named: "arrow_left")
            }
        }
    }
    
    @IBAction func rightTrainAction(_ sender: AnyObject!){
        if self.delegate.isInTraining() == true{
            return
        }
        if self.delegate.isActionTrain(action: Mental_Right) == true{
            self.delegate.openPopUp(sender: sender, action: Mental_Right, reTrainAction: { () in
                self.currentAction = Mental_Right
                self.resetAllSelected()
                self.imageRight.image = UIImage(named: "arrow_right")
            })
        } else {
            if currentAction == Mental_Right{
                currentAction = nil
                self.imageRight.image = self.delegate.isActionActive(action: Mental_Right) == true ? UIImage(named: "arrow_right_u") : UIImage(named: "arrow_right_d")
            } else {
                currentAction = Mental_Right
                resetAllSelected()
                self.imageRight.image = UIImage(named: "arrow_right")
            }
        }
    }
    
    func onEmoAction(currentAction: MentalAction_t){
        switch currentAction {
        case Mental_Push:
            self.controlImage.image = UIImage(named: "control_push")
            break
        case Mental_Pull:
            self.controlImage.image = UIImage(named: "control_pull")
            break
        case Mental_Left:
            self.controlImage.image = UIImage(named: "control_left")
            break
        case Mental_Right:
            self.controlImage.image = UIImage(named: "control_right")
            break
        default:
            self.controlImage.image = UIImage(named: "control_back")
        }
    }
    
    @IBAction func rejectAction(_: AnyObject!){
        self.delegate.rejectAction()
    }
    
    @IBAction func acceptAction(_: AnyObject!){
        self.delegate.acceptAction()
    }
    
    @IBAction func calibrationAction(_: AnyObject!){
        self.delegate.calibrateAction()
    }
    
    @IBAction func calibrationDone(_: AnyObject!){
        self.delegate.calibrateDone()
    }
    
    @IBAction func settingAction(_: AnyObject!){
        isSettingOpened = !isSettingOpened
        
        self.updateSettingView()
    }
    
    @IBAction func swipeDownGesture(_: AnyObject!){
        isSettingOpened = false
        self.updateSettingView()
    }
    
    @IBAction func swipeUpGesture(_: AnyObject!){
        isSettingOpened = true
        self.updateSettingView()
    }
    
    @IBAction func settingDoneAction(_: AnyObject!){
        isSettingOpened = false
        self.updateSettingView()
    }
}


extension TrainActionView : UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return 6
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        if section == 0{
            label.text =  "Adjust Sphero speed:"
        } else {
            label.text = "Change the Threshold for detecting you emotion:"
        }
        
        label.font = UIFont(name: "OpenSans", size: 12)
        
        let size = label.sizeThatFits(CGSize(width: tableView.frame.width - 10, height: 100))
        label.frame = CGRect(x: 5, y: 7, width: size.width, height: size.height)
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: size.height + 10))
        view.backgroundColor = UIColor.clear
        view.addSubview(label)
        
        return view
    }
    
    func tableView(_  tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let label = UILabel()
        if section == 0{
            label.text =  "Adjust Sphero speed:"
        } else {
            label.text = "Change the Threshold for detecting you emotion:"
        }
        
        label.font = UIFont(name: "OpenSans", size: 12)
        
        let size = label.sizeThatFits(CGSize(width: tableView.frame.width - 10, height: 100))
        return size.height + 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SpeedCell") as! SliderSettingCell
            
            cell.setName(name: "Speed", color: 0x45B874, tag: 9)
            if let spheroSpeed = UserDefaults.standard.value(forKey: "speed-sphero") as? NSNumber{
                cell.slider.value = spheroSpeed.floatValue
            }else{
                cell.slider.value = 0.5
                UserDefaults.standard.setValue(0.5, forKey: "speed-sphero")
                UserDefaults.standard.synchronize()
            }
            
            if let label = cell.viewWithTag(110) as? UILabel{
                label.text = String(format: "%0.2f", cell.slider.value)
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell") as! SliderSettingCell
            switch indexPath.row {
            case 0:
                cell.setName(name: "Relaxation", color: 0x45ff77, tag: indexPath.row)
                if let relaxationThred = UserDefaults.standard.value(forKey: "relaxation-thred") as? NSNumber{
                    cell.slider.value = relaxationThred.floatValue
                }else{
                    cell.slider.value = 0.5
                    UserDefaults.standard.setValue(0.5, forKey: "relaxation-thred")
                    UserDefaults.standard.synchronize()
                }
                break
            case 1:
                cell.setName(name: "Boredom", color: 0x7f24ae, tag: indexPath.row)
                if let relaxationThred = UserDefaults.standard.value(forKey: "boredom-thred") as? NSNumber{
                    cell.slider.value = relaxationThred.floatValue
                }else{
                    cell.slider.value = 0.5
                    UserDefaults.standard.setValue(0.5, forKey: "boredom-thred")
                    UserDefaults.standard.synchronize()
                }
                break
            case 2:
                cell.setName(name: "Excitement", color: 0xff6145, tag: indexPath.row)
                if let relaxationThred = UserDefaults.standard.value(forKey: "excitement-thred") as? NSNumber{
                    cell.slider.value = relaxationThred.floatValue
                }else{
                    cell.slider.value = 0.5
                    UserDefaults.standard.setValue(0.5, forKey: "excitement-thred")
                    UserDefaults.standard.synchronize()
                }
                break
            case 3:
                cell.setName(name: "Long Excitement", color: 0xffe645, tag: indexPath.row)
                if let relaxationThred = UserDefaults.standard.value(forKey: "lexcitement-thred") as? NSNumber{
                    cell.slider.value = relaxationThred.floatValue
                }else{
                    cell.slider.value = 0.5
                    UserDefaults.standard.setValue(0.5, forKey: "lexcitement-thred")
                    UserDefaults.standard.synchronize()
                }
                break
            case 4:
                cell.setName(name: "Interest", color: 0x4234f7, tag: indexPath.row)
                if let relaxationThred = UserDefaults.standard.value(forKey: "interest-thred") as? NSNumber{
                    cell.slider.value = relaxationThred.floatValue
                }else{
                    cell.slider.value = 0.5
                    UserDefaults.standard.setValue(0.5, forKey: "interest-thred")
                    UserDefaults.standard.synchronize()
                }
                break
            default:
                cell.setName(name: "Stress", color: 0x40f9ff, tag: indexPath.row)
                if let relaxationThred = UserDefaults.standard.value(forKey: "stress-thred") as? NSNumber{
                    cell.slider.value = relaxationThred.floatValue
                }else{
                    cell.slider.value = 0.5
                    UserDefaults.standard.setValue(0.5, forKey: "stress-thred")
                    UserDefaults.standard.synchronize()
                }
                break
            }
            
            return cell
        }
    }
}

