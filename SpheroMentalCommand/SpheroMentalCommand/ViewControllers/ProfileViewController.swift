//
//  ProfileViewController.swift
//  Sphero Mental Command
//
//  Created by Viet Anh on 4/4/15.
//  Copyright © 2015 Viet Anh. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {

    @IBOutlet var tableView : UITableView!
    @IBOutlet var mainView : UIView!
    @IBOutlet var signalView: SignalQualityView!
    @IBOutlet var spheroStatusButton: UIButton!
    var currentIndex : Int = -1
    
    var removeViewAction : (() -> (Void))?
    var listProfile : [String]! = [String]()
    
    let engineWidget: MentalEngineWidget = MentalEngineWidget.shareInstance() as! MentalEngineWidget
    var selectHeadsetVC : SelectHeadsetViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainView.clipsToBounds = true
        mainView.layer.cornerRadius = 5
        spheroStatusButton.layer.cornerRadius = 10
        
        NotificationCenter.default.addObserver(self, selector: #selector(notificationReceived(notification:)), name: NSNotification.Name(rawValue: "userAddedNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationReceived(notification:)), name: NSNotification.Name(rawValue: "userRemovedNotification"), object: nil)
        
        engineWidget.signalDelegate = self
        
        if engineWidget.isHeadsetConnected() == false{
            self.signalView.getSignalChanels(valueSignalAF3: 0, af4Channel: 0, t7Channel: 0, t8Channel: 0, pzChannel: 0)
            self.presentSelectHeadset(mode: 1)
        }
    }
    
    @objc func notificationReceived(notification : NSNotification)
    {
        if(notification.name.rawValue == "userRemovedNotification"){
            self.presentSelectHeadset(mode: 1)
        }
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
        self.presentSelectHeadset(mode: 1)
    }
    
    @IBAction func openSelectSphero(_: AnyObject!){
        RKRobotDiscoveryAgent.startDiscovery()
        self.presentSelectHeadset(mode: 2)
    }
    
    override  func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        engineWidget.signalDelegate = self
        
        if engineWidget.isHeadsetConnected() == false{
            self.signalView.getSignalChanels(valueSignalAF3: 0, af4Channel: 0, t7Channel: 0, t8Channel: 0, pzChannel: 0)
        }
        
        if(engineWidget.currentRobot != nil){
            spheroStatusButton.backgroundColor = UIColor(hex: 0x45FF77)
        }else{
            spheroStatusButton.backgroundColor = UIColor(hex: 0xEB005D)
        }
        
        if let profiles = engineWidget.getlistProfile() as? [String]{
            listProfile = profiles
            self.tableView .reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func gotoTrainView(isNewProfile: Bool, name: String?){
        let storyBoard : UIStoryboard!
        if UIDevice.current.userInterfaceIdiom == .pad{
            storyBoard  = UIStoryboard(name: "Main_iPad", bundle: nil)
        } else {
            storyBoard  = UIStoryboard(name: "Main_iPhone", bundle: nil)
        }
        
        if let trainViewController = storyBoard.instantiateViewController(withIdentifier: "TrainViewController") as? TrainViewController{
            trainViewController.isNewUser = isNewProfile
            trainViewController.profileName = name!
            self.navigationController?.pushViewController(trainViewController, animated: true)
        }
    }
}

extension ProfileViewController{
    
    func onSpheroStatusUpdated() {
        if(engineWidget.currentRobot == nil){
            spheroStatusButton.backgroundColor = UIColor(hex: 0xEB005D)
        } else {
            spheroStatusButton.backgroundColor = UIColor(hex: 0x45FF77)
        }
    }
}

extension ProfileViewController : MentalEngineWidgetDelegate{
    func onHeadsetConnected(_ headsetID: Int32) {
        if selectHeadsetVC != nil{
            selectHeadsetVC!.dismiss(animated: true, completion: nil)
        }
    }
    
    func onHeadsetRemoved(_ headsetID: Int32) {
        signalView.onHeadsetRemoved(headsetID: headsetID)
        if engineWidget.isHeadsetConnected() == false{
            self.presentSelectHeadset(mode: 1)
        }
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

extension ProfileViewController : UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if engineWidget.isHeadsetConnected() == false{
            let alert = UIAlertController(title: nil, message: "Please connect headset first!", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if indexPath.row < listProfile.count{
            MBProgressHUD.showAdded(to: self.view, animated: true)
            self.engineWidget.loadProfile(listProfile[indexPath.row], finish: {(result) in
                if result == true{
                    MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                    self.gotoTrainView(isNewProfile: false, name: self.listProfile[indexPath.row])
                }else{
                    MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                    let alert = UIAlertController(title: "Error", message: "Fail to load your profile.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            })
            
        }else if indexPath.row == listProfile.count{
            engineWidget.setGuestProfile()
            self.gotoTrainView(isNewProfile: true, name: "Guest")
        }else{
            let alertController = UIAlertController(title: nil, message: "Enter your profile name", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Add", style: .default, handler: { (alert) in
                let profileName = alertController.textFields![0].text!
                
                let regex = try!  NSRegularExpression(pattern: ".*[^A-Za-z0-9].*", options: .caseInsensitive)
                
                if profileName.lowercased() == "guest"{
                    let alert = UIAlertController(title: "Error", message: "Cant create profile with this name.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }else if regex.firstMatch(in: profileName, options: [], range: NSMakeRange(0, (profileName.count))) != nil {
                    print("could not handle special characters")
                    let alert = UIAlertController(title: "Error", message: "Profile name can not contain special characters.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }else{
                    let result = self.engineWidget.addProfile(profileName)
                    
                    if result{
                        if let profiles = self.engineWidget.getlistProfile() as? [String]{
                            self.listProfile = profiles
                            self.tableView .reloadData()
                        }
                        MBProgressHUD.showAdded(to: self.view, animated: true)
                        
                        
                        self.engineWidget.loadProfile(profileName, finish: {(result) in
                            if result == true{
                                MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                                self.gotoTrainView(isNewProfile: true, name: profileName)
                            }else{
                                MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                                let alert = UIAlertController(title: "Error", message: "Fail to load your profile.", preferredStyle: UIAlertController.Style.alert)
                                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            }
                        })
                    }else{
                        let alert = UIAlertController(title: "Error", message: "Fail to create profile.", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertController.addTextField(configurationHandler: { (textfield) in
            })
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listProfile.count + 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < listProfile.count{
            var cell : ProfileCell! = tableView.dequeueReusableCell(withIdentifier: "ProfileCell") as! ProfileCell
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "ProfileCell") as! ProfileCell
            }

            cell.dismissButton()
            cell.delegate = self
            cell.tag = indexPath.row
            
            cell.labelName.text = listProfile[indexPath.row]
            
            return cell
        }else if indexPath.row == listProfile.count{
            let cell = tableView.dequeueReusableCell(withIdentifier: "GuestCell")!
            
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewCell")!
            
            return cell
        }
    }
}

extension ProfileViewController: ProfileCellDelegate{
    func deleteAction(profileName: String) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        engineWidget.removeProfile(profileName, finish: {(result) in
            if let profiles = self.engineWidget.getlistProfile() as? [String]{
                self.listProfile = profiles
                self.tableView .reloadData()
            }
            self.currentIndex = -1
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
        })
    }
    
    func clearSelection(){
        currentIndex = -1
    }
    
    func handleSwipe(tag: Int) {
        if currentIndex >= 0 {
            var array : [ProfileCell] = self.tableView.visibleCells as! [ProfileCell]
            for i : Int in 0 ..< array.count {
                if currentIndex == array[i].tag {
                    array[i].dismissButton()
                    break
                }
            }
        }
        currentIndex = tag
    }
}
