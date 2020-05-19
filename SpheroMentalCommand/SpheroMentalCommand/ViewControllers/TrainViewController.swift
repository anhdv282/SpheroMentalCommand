//
//  TrainViewController.swift
//  Sphero Mental Command
//
//  Created by Viet Anh on 4/4/16.
//  Copyright © 2016 Viet Anh. All rights reserved.
//

import UIKit

class TrainViewController: UIViewController {

    var isNewUser: Bool!
    
    @IBOutlet var trainNeutralView: TrainNeutralView!
    @IBOutlet var trainActionView: TrainActionView!
    @IBOutlet var signalView: SignalQualityView!
    @IBOutlet var profileNameLabel: UILabel!
    @IBOutlet var spheroStatusButton: UIButton!
    
    var isSetLEDColor = false
    var isCalibrating = false
    var isTraining = false

    var robot: RKConvenienceRobot?
    
    var profileName: String = ""
    
    private var dictionaryAction : [String] = ["Neutral", "Push", "Pull", "Left","Right"]
    
    private  var dictionaryMapping : [String:MentalAction_enum] = ["Neutral":Mental_Neutral, "Push":Mental_Push, "Pull":Mental_Pull, "Left":Mental_Left, "Right":Mental_Right]
    
    let engineWidget: MentalEngineWidget = MentalEngineWidget.shareInstance() as! MentalEngineWidget
    var selectHeadsetVC : SelectHeadsetViewController?
    var currentAction: MentalAction_t?
    
    var power : Float = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if (isNewUser == true || !engineWidget.isActionTrained(Mental_Neutral)){
            setTrainNeutral(visible: true)
            trainNeutralView.isHidden = false
            trainActionView.isHidden = true
        }else{
            setTrainNeutral(visible: false)
            trainNeutralView.isHidden = true
            trainActionView.isHidden = false
        }
        
        spheroStatusButton.layer.cornerRadius = 10
        
        profileNameLabel.text = profileName
        self.trainNeutralView.delegate = self
        self.trainActionView.delegate = self
        self.updateActionStatus(trainingAction: Mental_Disappear)
        
        engineWidget.signalDelegate = self
        engineWidget.performanceMatrixDelete = self
        engineWidget.engineDelegate = self
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        engineWidget.signalDelegate = self
        engineWidget.performanceMatrixDelete = self
        engineWidget.engineDelegate = self
        
        if(engineWidget.currentRobot != nil){
            spheroStatusButton.backgroundColor = UIColor(hex: 0x45FF77)
        }else{
            spheroStatusButton.backgroundColor = UIColor(hex: 0xEB005D)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func presentSelectHeadset(mode: Int){
        if selectHeadsetVC != nil{
            selectHeadsetVC?.dismiss(animated: true, completion: nil)
            selectHeadsetVC = nil
        }
        
        let storyBoard : UIStoryboard!
        if UIDevice.current.userInterfaceIdiom == .pad{
            storyBoard  = UIStoryboard(name: "Main_iPad", bundle: nil)
        } else {
            storyBoard  = UIStoryboard(name: "Main_iPhone", bundle: nil)
        }
        selectHeadsetVC = storyBoard.instantiateViewController(withIdentifier: "SelectHeadsetViewController") as? SelectHeadsetViewController
        
        if selectHeadsetVC != nil && !(selectHeadsetVC?.isBeingPresented)!{
            selectHeadsetVC?.viewMode = mode
            self.present(selectHeadsetVC!, animated: true, completion: nil)
        }
    }
    
    @IBAction func openSelectHeadset(_: AnyObject!){
        self.presentSelectHeadset(mode: 0)
    }
    
    @IBAction func openSelectSphero(_: AnyObject!){
        self.presentSelectHeadset(mode: 1)
    }
    
    func setTrainNeutral(visible: Bool){
        if visible == true{
            self.trainNeutralView.isHidden = false
        }else{
            self.trainNeutralView.isHidden = true
        }
    }
    
    func updateActionStatus(trainingAction: MentalAction_t){
        if engineWidget.isActionTrained(Mental_Right){
            if engineWidget.isActionActive(Mental_Right){
                self.trainActionView.rightStatus.text = "Trained"
            } else {
                self.trainActionView.rightStatus.text = "Disable"
            }
        }else{
            self.trainActionView.rightStatus.text = "Untrained"
        }
        
        if engineWidget.isActionTrained(Mental_Left){
            if engineWidget.isActionActive(Mental_Left){
                self.trainActionView.leftStatus.text = "Trained"
            } else {
                self.trainActionView.leftStatus.text = "Disable"
            }
        }else{
            self.trainActionView.leftStatus.text = "Untrained"
        }
        
        if engineWidget.isActionTrained(Mental_Push){
            if engineWidget.isActionActive(Mental_Push){
                self.trainActionView.pushStatus.text = "Trained"
            } else {
                self.trainActionView.pushStatus.text = "Disable"
            }
        }else{
            self.trainActionView.pushStatus.text = "Untrained"
        }
        
        if engineWidget.isActionTrained(Mental_Pull){
            if engineWidget.isActionActive(Mental_Pull){
                self.trainActionView.pullStatus.text = "Trained"
            } else {
                self.trainActionView.pullStatus.text = "Disable"
            }
        }else{
            self.trainActionView.pullStatus.text = "Untrained"
        }
        
        self.trainActionView.resetTraining()
        
        switch trainingAction {
        case Mental_Pull:
            self.trainActionView.pullStatus.text = "Training"
            self.trainActionView.statusLabel.text = "Training with reverse direction"
            self.trainActionView.tutorialLabel.text = "Be relax and focus on moving Sphero reverse"
            self.trainActionView.imageDown.image = UIImage(named: "arrow_down")
            break
        case Mental_Push:
            self.trainActionView.pushStatus.text = "Training"
            self.trainActionView.statusLabel.text = "Training with forward direction"
            self.trainActionView.tutorialLabel.text = "Be relax and focus on moving Sphero forward"
            self.trainActionView.imageUp.image = UIImage(named: "arrow_up")
            break
        case Mental_Left:
            self.trainActionView.leftStatus.text = "Training"
            self.trainActionView.statusLabel.text = "Training with left direction"
            self.trainActionView.tutorialLabel.text = "Be relax and focus on moving Sphero left"
            self.trainActionView.imageLeft.image = UIImage(named: "arrow_left")
            break
        case Mental_Right:
            self.trainActionView.rightStatus.text = "Training"
            self.trainActionView.statusLabel.text = "Training with right direction"
            self.trainActionView.tutorialLabel.text = "Be relax and focus on moving Sphero right"
            self.trainActionView.imageRight.image = UIImage(named: "arrow_right")
            break
        case Mental_Neutral:
            self.trainActionView.statusLabel.text = "Training neutral"
            self.trainActionView.tutorialLabel.text = "Be relax and not focusing on any direction"
            self.trainActionView.imageCenter.setImage(UIImage(named: "center_training"), for: .normal)
            break
        default:
            break
        }
        
        self.view.layoutSubviews()
        
        currentAction = trainingAction
    }
    
    @IBAction func backAction(_: AnyObject!){
        
        if engineWidget.getSelectedHeadsetID() >= 0 {
            
            if profileName.lowercased() != "guest" {
                
                engineWidget.saveProfile(profileName, finish: {
                })
            }
        }
        else {
            let alert = UIAlertController(title: "Error", message: "Please connect headset first!", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    func getTotalActiveAction() -> Int{
        var count = 0
        count += engineWidget.isActionActive(Mental_Neutral) == true ? 1 : 0
        count += engineWidget.isActionActive(Mental_Push) == true ? 1 : 0
        count += engineWidget.isActionActive(Mental_Pull) == true ? 1 : 0
        count += engineWidget.isActionActive(Mental_Left) == true ? 1 : 0
        count += engineWidget.isActionActive(Mental_Right) == true ? 1 : 0
        
        return count
    }
}

extension TrainViewController: UIPopoverPresentationControllerDelegate{
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension TrainViewController{
    
    func onSpheroStatusUpdated() {
        if(engineWidget.currentRobot == nil){
            spheroStatusButton.backgroundColor = UIColor(hex: 0xEB005D)
        } else {
            spheroStatusButton.backgroundColor = UIColor(hex: 0x45FF77)
        }
        
        self.robot = engineWidget.currentRobot
    }
}

extension TrainViewController: TrainActionDelegate{
    func isInTraining() -> Bool! {
        return self.isTraining
    }
    
    func isActionActive(action: MentalAction_t) -> Bool!{
        return  self.engineWidget.isActionActive(action)
    }
    
    func isActionTrain(action: MentalAction_t) -> Bool!{
        return self.engineWidget.isActionTrained(action)
    }
    
    func openPopUp(sender: AnyObject!, action: MentalAction_t, reTrainAction: @escaping () -> ()) {
        var alertController = UIAlertController(title: nil, message: nil, preferredStyle:.actionSheet)
        
        if self.engineWidget.isActionTrained(action){
            if self.engineWidget.isHeadsetConnected(){
                if action != Mental_Neutral{
                    if self.getTotalActiveAction() > 2 {
                        if self.engineWidget.isActionActive(action){
                            alertController.addAction(UIAlertAction(title: "Disable", style:.default, handler: { (actionSheet) in
                                self.engineWidget.setDeActiveAction(action)
                                self.trainActionView.resetTraining()
                                self.updateActionStatus(trainingAction: Mental_Disappear)
                            }))
                        } else {
                            alertController.addAction(UIAlertAction(title: "Enable", style: .default, handler: { (actionSheet) in
                                self.engineWidget.setActiveAction(action)
                                self.trainActionView.resetTraining()
                                self.updateActionStatus(trainingAction: Mental_Disappear)
                            }))
                        }
                    }
                    
                    alertController.addAction(UIAlertAction(title: "Clear", style: .default, handler: { (actionSheet) in
                        MBProgressHUD.showAdded(to: self.view, animated: true)
                        self.engineWidget.clearTrainingData(action)
                        self.trainActionView.resetTraining()
                    }))
                }
                
                alertController.addAction(UIAlertAction(title: "Re-Train", style: .default, handler: { (actionSheet) in
                    reTrainAction()
                }))
                
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (actionSheet) in
                }))
            } else {
                alertController = UIAlertController(title: nil, message: "Please connect headset first!", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            }
            
            if let popoverController = alertController.popoverPresentationController {
                popoverController.sourceView = (sender as! UIButton)
                popoverController.sourceRect = (sender as! UIButton).bounds
            }
            
            present(alertController, animated: true, completion: nil)
        } else {
            return
        }
    }
    
    func deactiveAction(action: MentalAction_t){
        if self.engineWidget.isActionTrained(action){
            if self.engineWidget.isActionActive(action){
                self.engineWidget.setDeActiveAction(action)
            } else {
                self.engineWidget.setActiveAction(action)
            }
        }
    }
    
    func startTraining(action: MentalAction_t) {
        if isTraining == false && engineWidget.isHeadsetConnected(){
            MBProgressHUD.showAdded(to: self.view, animated: true)
            self.trainActionView.resetTraining()
            self.engineWidget.setActiveAction(action)
            self.engineWidget.setTrainingAction(action)
            self.engineWidget.setTrainingControl(Mental_Start)
            self.updateActionStatus(trainingAction: action)
        }
    }
    
    func acceptAction() {
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        self.engineWidget.setTrainingControl(Mental_Accept)
    }
    
    func rejectAction() {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        self.engineWidget.setTrainingControl(Mental_Reject)
    }
    
    func calibrateAction() {
        if engineWidget.currentRobot != nil{
            engineWidget.currentRobot.calibrating(true)
            isCalibrating = true
            self.calibratePerform()
        }
    }
    
    func calibrateDone() {
        if engineWidget.currentRobot != nil{
            isCalibrating = false
            engineWidget.currentRobot.calibrating(false)
        }
    }
    
    @objc func calibratePerform() {
        if engineWidget.currentRobot != nil{
            if !isCalibrating {
                return
            }
            
            var newAngle = engineWidget.currentRobot.currentHeading;
            newAngle -= 5;
            if (newAngle < 0) {
                newAngle = 359
            }
            engineWidget.currentRobot.drive(withHeading: newAngle, andVelocity: 0.0)
            self.perform(#selector(TrainViewController.calibratePerform), with: nil, afterDelay: 0.05)
        }
    }
}

extension TrainViewController: TrainNeutralDelegate{
    func neutralStartTraining() {
        self.trainNeutralView.resetNeutralTraing()
        self.engineWidget.setActiveAction(Mental_Neutral)
        self.engineWidget.setTrainingAction(Mental_Neutral)
        self.engineWidget.setTrainingControl(Mental_Start)
        self.updateActionStatus(trainingAction: Mental_Neutral)
    }
    
    func neutralAcceptAction() {
        self.engineWidget.setTrainingControl(Mental_Accept)
    }
    
    func neutralRejectAction() {
        self.engineWidget.setTrainingControl(Mental_Reject)
    }
}

extension TrainViewController: MentalEngineWidgetDelegate{
    func emoStateUpdate(_ currentAction: MentalAction_t, power currentPower: Float) {
        if engineWidget.currentRobot != nil && self.robot == nil{
            self.robot = engineWidget.currentRobot
        }
        
        power = currentPower
        
        if self.isTraining{
            power = 0.2
        }
        
        if self.isCalibrating{
            return
        }
        
        if let spheroSpeed = UserDefaults.standard.value(forKey: "speed-sphero") as? NSNumber{
            power *= spheroSpeed.floatValue
        }else{
            power *= 0.5
            UserDefaults.standard.setValue(0.5, forKey: "speed-sphero")
            UserDefaults.standard.synchronize()
        }
        
        if power > 0 {
            self.trainActionView.onEmoAction(currentAction: currentAction)
        } else {
            self.trainActionView.onEmoAction(currentAction: Mental_Neutral)
        }
        
        if self.robot != nil {

            if power > 0 && currentAction == Mental_Push {
                self.robot?.drive(withHeading: 0, andVelocity: power)
            }
            else if power > 0 && currentAction == Mental_Pull {
                self.robot?.drive(withHeading: 180, andVelocity: power)
            }
            else if power > 0 && currentAction == Mental_Left {
                self.robot?.drive(withHeading: 270, andVelocity: power)
            } else if power > 0 && currentAction == Mental_Right {
                self.robot?.drive(withHeading: 90, andVelocity: power)
            } else {
                self.robot?.stop()
            }
        }
    }
    
    @objc func resetLEB(){
        isSetLEDColor = false
    }

    func updateValue(_ relaxationScore: Float, _ boredScore: Float, _ exciteScore: Float, _ longExciteScore: Float, _ interestScore: Float, _ stressScore: Float) {
        
        if(engineWidget.currentRobot != nil && self.robot == nil){
            self.robot = engineWidget.currentRobot
        }
        
        var maxValue : Float = 0
        var maxColors = [Float]()
        
        if self.robot != nil && !isSetLEDColor{
            
            
            if let relaxationThred = UserDefaults.standard.value(forKey: "relaxation-thred") as? NSNumber{
                if relaxationScore > relaxationThred.floatValue{
                    if relaxationScore > maxValue{
                        maxValue = relaxationScore
                        maxColors = [69, 255, 119]
                    }
                }
            }
            
            if let thred = UserDefaults.standard.value(forKey: "boredom-thred") as? NSNumber{
                if boredScore > thred.floatValue{
                    if boredScore > maxValue{
                        maxValue = boredScore
                        maxColors = [127, 36, 174]
                    }
                }
            }
            
            if let thred = UserDefaults.standard.value(forKey: "excitement-thred") as? NSNumber{
                if exciteScore > thred.floatValue{
                    if exciteScore > maxValue{
                        maxValue = exciteScore
                        maxColors = [255, 97, 69]
                    }
                }
            }
            
            if let thred = UserDefaults.standard.value(forKey: "lexcitement-thred") as? NSNumber{
                if longExciteScore > thred.floatValue{
                    if longExciteScore > maxValue{
                        maxValue = longExciteScore
                        maxColors = [255, 230, 69]
                    }
                }
            }
            
            if let thred = UserDefaults.standard.value(forKey: "interest-thred") as? NSNumber{
                if interestScore > thred.floatValue{
                    if interestScore > maxValue{
                        maxValue = interestScore
                        maxColors = [66, 52, 247]
                    }
                }
            }
            
            if let thred = UserDefaults.standard.value(forKey: "stress-thred") as? NSNumber{
                if stressScore > thred.floatValue{
                    if stressScore > maxValue{
                        maxValue = stressScore
                        maxColors = [64, 249, 255]
                    }
                }
            }
            
            if maxValue == 0{
                maxColors = [69, 255, 119]
            }
            
            self.robot?.setLEDWithRed(maxColors[0] / 255.0, green: maxColors[1] / 255.0, blue: maxColors[2] / 255.0)
            isSetLEDColor = true
            self.perform(#selector(resetLEB), with: nil, afterDelay: 3)
        }
    }
    
    func onMentalCommandSignatureUpdated(_ headsetID: Int32) {
        
    }
    
    func onMentalCommandTrainingDataErased(_ headsetID: Int32) {
        
        MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
        self.updateActionStatus(trainingAction: Mental_Disappear)
    }
    
    func onMentalCommandTrainingStarted(_ headsetID: Int32) {
        isTraining = true
        MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
        if self.trainNeutralView.isHidden == false{
            self.trainNeutralView.startTrainingAnimation()
        }else{
            self.trainActionView.startTrainingAnimation()
        }
    }
    
    func onMentalCommandTrainingRejected(_ headsetID: Int32) {
        if self.trainNeutralView.isHidden == false{
            self.trainNeutralView.isHidden = true
            self.trainActionView.isHidden = false
        }else{
            self.trainActionView.resetTraining()
        }
        
        MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
        self.updateActionStatus(trainingAction: Mental_Disappear)
    }
    
    func onMentalCommandTrainingCompleted(_ headsetID: Int32) {
        if self.trainNeutralView.isHidden == false{
            self.trainNeutralView.isHidden = true
            self.trainActionView.isHidden = false
        }else{
            self.trainActionView.resetTraining()
        }
        
        MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
        self.updateActionStatus(trainingAction: Mental_Disappear)
    }
    
    func onMentalCommandTrainingSucceeded(_ headsetID: Int32) {
        isTraining = false
        if self.trainNeutralView.isHidden == false{
            self.trainNeutralView.trainingSuccess()
        }else{
            self.trainActionView.tutorialLabel.text = "Do you want to accept this training session"
            switch self.currentAction! {
            case Mental_Neutral:
                self.trainActionView.statusLabel.text = "Training neutral completed"
                break
            case Mental_Push:
                self.trainActionView.statusLabel.text = "Training move forward completed"
                break
            case Mental_Pull:
                self.trainActionView.statusLabel.text = "Training move reverse completed"
                break
            case Mental_Left:
                self.trainActionView.statusLabel.text = "Training move left completed"
                break
            case Mental_Right:
                self.trainActionView.statusLabel.text = "Training move right completed"
                break
            default:
                break
            }
            self.trainActionView.trainingSuccess()
        }
        
        self.view.layoutSubviews()
    }
    
    func onMentalCommandTrainingFailed(_ headsetID: Int32) {
        isTraining = false
        if self.trainNeutralView.isHidden == false{
            let alertControler = UIAlertController(title: nil, message: "Fail to train this action. Do you want to retry?", preferredStyle: .alert)
            alertControler.addAction(UIAlertAction(title: "Retry", style: .cancel, handler: { (alert) in
                self.neutralStartTraining()
            }))
            self.present(alertControler, animated: true, completion: nil)
        }else{
            let alertControler = UIAlertController(title: nil, message: "Fail to train this action.", preferredStyle: .alert)
            alertControler.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (alert) in
            }))
            self.present(alertControler, animated: true, completion: nil)
            self.trainActionView.resetTraining()
        }
        
        self.updateActionStatus(trainingAction: Mental_Disappear)
    }
    
    
    func onHeadsetConnected(_ headsetID: Int32) {
        if selectHeadsetVC != nil{
            selectHeadsetVC!.dismiss(animated: true, completion: nil)
        }
    }
    
    func onHeadsetRemoved(_ headsetID: Int32) {
        signalView.onHeadsetRemoved(headsetID: headsetID)
        self.navigationController?.popViewController(animated: true)
    }
    
    func getSignalChanels(_ valueSignalAF3: Int32, af4Channel valueSignalAF4: Int32, t7Channel valueSignalT7: Int32, t8Channel valueSignalT8: Int32, pzChannel valueSignalPz: Int32) {
        if selectHeadsetVC != nil{
            self.selectHeadsetVC!.getSignalChanels(valueSignalAF3: valueSignalAF3, af4Channel: valueSignalAF4, t7Channel: valueSignalT7, t8Channel: valueSignalT8, pzChannel: valueSignalPz)
        }
        self.signalView.getSignalChanels(valueSignalAF3: valueSignalAF3, af4Channel: valueSignalAF4, t7Channel: valueSignalPz, t8Channel: valueSignalT7, pzChannel: valueSignalT8)
    }
    
    func getBatteryData(_ value: Int32, maxValue: Int32) {
    }
}
