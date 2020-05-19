//
//  SelectHeadsetViewController.swift
//  mentalcommands
//
//  Created by Viet Anh on 2/4/16.
//  Copyright © 2016 Viet Anh. All rights reserved.
//

import UIKit

class SelectHeadsetViewController: UIViewController {
    
    @IBOutlet var tableView : UITableView!
    @IBOutlet var popOverView : UIView!
    @IBOutlet var indicatorView : UIActivityIndicatorView!
    
    @IBOutlet var signalView: SignalQualityView!
    @IBOutlet var headsetButton : UIButton!
    @IBOutlet var spheroButton : UIButton!
    
    @IBOutlet var descLabel : UILabel!
    @IBOutlet var contentImage : UIImageView!
    
    @IBOutlet var spheroView : UIView!
    @IBOutlet var spheroConnectButton : UIButton!
    @IBOutlet var spheroStateImage : UIImageView!
    @IBOutlet var spheroStateLabel : UILabel!
    @IBOutlet var spheroStatusButton : UIButton!
    
    var removeViewAction : (() -> (Void))?
    var listDevice : [HeadsetDevice]! = [HeadsetDevice]()
    var device : HeadsetDevice?
    var headsetSelected : (() -> (Void))?
    
    var viewMode : Int = -1
    
    let engineWidget: MentalEngineWidget = MentalEngineWidget.shareInstance() as! MentalEngineWidget
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.popOverView.clipsToBounds = true
        self.popOverView.layer.cornerRadius = 5
        spheroStatusButton.layer.cornerRadius = 10
        self.spheroConnectButton.layer.cornerRadius = 5
        
        engineWidget.listDeviceDelegate = self
        
        self.indicatorView.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(notificationReceived(notification:)), name: NSNotification.Name(rawValue: "userAddedNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationReceived(notification:)), name: NSNotification.Name(rawValue: "userRemovedNotification"), object: nil)
        
        if viewMode == -1{
            self.updateViewMode(mode: 1, force: true)
        } else {
            self.updateViewMode(mode: viewMode, force: true)
        }
        self.updateSpheroState()
    }
    
    func getSignalChanels(valueSignalAF3: Int32, af4Channel valueSignalAF4: Int32, t7Channel valueSignalT7: Int32, t8Channel valueSignalT8: Int32, pzChannel valueSignalPz: Int32) {
        self.signalView.getSignalChanels(valueSignalAF3: valueSignalAF3, af4Channel: valueSignalAF4, t7Channel: valueSignalPz, t8Channel: valueSignalT7, pzChannel: valueSignalT8)
    }
    
    func updateViewMode(mode: Int, force: Bool){
        if mode == viewMode && force == false{
            return
        }
        
        viewMode = mode
        
        if mode == 1{
            spheroButton.addBottomBorderWithColor(color: UIColor.white, borderWidth: 2, preferWidth: spheroConnectButton.bounds.width - 10)
            headsetButton.addBottomBorderWithColor(color: UIColor(hex: 0xEB005D), borderWidth: 2, preferWidth: spheroConnectButton.bounds.width - 10)
            headsetButton.setTitleColor(UIColor(hex: 0xEB005D), for: .normal)
            spheroButton.setTitleColor(UIColor(hex: 0xB2B2B2), for: .normal)
            self .spheroView.isHidden = true
        }else if mode == 2{
            self .spheroView.isHidden = false
            headsetButton.addBottomBorderWithColor(color: UIColor.white, borderWidth: 2, preferWidth: spheroConnectButton.bounds.width - 10)
            spheroButton.addBottomBorderWithColor(color: UIColor(hex: 0xEB005D), borderWidth: 2, preferWidth: spheroConnectButton.bounds.width - 10)
            spheroButton.setTitleColor(UIColor(hex: 0xEB005D), for: .normal)
            headsetButton.setTitleColor(UIColor(hex: 0xB2B2B2), for: .normal)
            self.updateSpheroState()
        }
    }
    
    func updateSpheroState(){
        
        if  !self.isConnectToShero(){
            RKRobotDiscoveryAgent.startDiscovery()
            self.spheroStateLabel.text = "Sphero’s connection is lost.\nPlease go to setting for configuration!"
            self.spheroStateImage.image = UIImage(named: "disconnectedImage")
            self.spheroConnectButton.setTitle("Go To Setting", for: .normal)
            spheroStatusButton.backgroundColor = UIColor(hex: 0xEB005D)
        } else {
            self.spheroStateLabel.text = "Sphero’s connected!"
            self.spheroStateImage.image = UIImage(named: "connectedImage")
            self.spheroConnectButton.setTitle("Done", for: .normal)
            spheroStatusButton.backgroundColor = UIColor(hex: 0x45FF77)
        }
    }
    
    @IBAction func spheroConnectAction(_: AnyObject!){
        let url = NSURL(string: UIApplication.openSettingsURLString)
        if url != nil && !self.isConnectToShero(){
            UIApplication.shared.openURL(url! as URL)
        }else{
            RKRobotDiscoveryAgent.shared().removeNotificationObserver(self)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func insightViewAction(_: AnyObject!){
        self.updateViewMode(mode: 1, force: false)
    }
    
    @IBAction func dismissAction(_: AnyObject!){
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func spheroViewAction(_ : AnyObject!){
        RKRobotDiscoveryAgent.startDiscovery()
        self.updateViewMode(mode: 2, force: false)
    }

    override  func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        engineWidget.listDeviceDelegate = self
        
        if let devices = engineWidget.getListDevice() as? [HeadsetDevice] {
            listDevice = devices;
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @objc func notificationReceived(notification : NSNotification)
    {
        if(notification.name.rawValue == "userAddedNotification"){
            RKRobotDiscoveryAgent.shared().removeNotificationObserver(self)
            self.dismiss(animated: true, completion: nil)
        }else if(notification.name.rawValue == "userRemovedNotification"){
            let alert = UIAlertController(title: nil, message: "The headset is disconnected", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension SelectHeadsetViewController : UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(listDevice.count > 0){
            device = listDevice[indexPath.row]
            self.indicatorView.startAnimating()
        }
        
        if(device!.type == 0){
            if(engineWidget.connnectDevice(Int32(indexPath.row), type: 0)){
                if self.headsetSelected != nil{
                    self.headsetSelected!()
                }
            }
        }else if(device!.type == 1){
            if(engineWidget.connnectDevice(Int32(indexPath.row), type: 1)){
                if self.headsetSelected != nil{
                    self.headsetSelected!()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listDevice.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HeadsetCell")!
        
        let item = listDevice[indexPath.row]
        
        if let numberLabel = cell.viewWithTag(101) as? UILabel{
            numberLabel.text = String(format: "%d", indexPath.row + 1)
        }
        
        if let typeLabel = cell.viewWithTag(102) as? UILabel{
            typeLabel.text = item.deviceType
        }
        
        if let idLabel = cell.viewWithTag(103) as? UILabel{
            idLabel.text = item.deviceId
        }
        
        return cell
    }
    
    func onSpheroStatusUpdated(){
        self.updateSpheroState()
    }
    
    func isConnectToShero() -> Bool{
        return !(RKRobotDiscoveryAgent.shared().connectedRobots().count <= 0)
    }
}

extension SelectHeadsetViewController : SelectHeadsetDelegate
{
    func reloadListDevice(_ array: [Any]!) {
        if let list = array as? [HeadsetDevice]{
            listDevice = list
            self.tableView.reloadData()
        }
    }
}

extension UIButton{
    func addBottomBorderWithColor(color: UIColor, borderWidth: CGFloat, preferWidth: CGFloat){
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.setValue(1, forKey: "tag")
        
        let enumerator = self.layer.sublayers
        if enumerator != nil{
            for sublayer in enumerator! {
                if sublayer.value(forKey: "tag") != nil && (sublayer.value(forKey: "tag") as AnyObject).intValue == 1{
                    sublayer.removeFromSuperlayer()
                }
            }
        }
        
        var currentWidth = self.frame.width
        if currentWidth < preferWidth{
            currentWidth = preferWidth
        }
        
        border.frame = CGRect(x: 5, y: self.frame.height - borderWidth, width: currentWidth - 10, height: borderWidth)
        self.layer.addSublayer(border)
    }
}
