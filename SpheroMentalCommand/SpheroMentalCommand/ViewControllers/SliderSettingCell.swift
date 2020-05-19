//
//  SliderSettingCell.swift
//  Sphero Mental Command
//
//  Created by Viet Anh on 4/5/16.
//  Copyright © 2016 Viet Anh. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(hex: Int) {
        let components = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 00) & 0xff) / 255
        )
        self.init(red: components.R, green: components.G, blue: components.B, alpha: 1)
    }
}

class SliderSettingCell: UITableViewCell {
    @IBOutlet var settingName: UILabel!
    
    @IBOutlet var slider: UISlider!
    @IBOutlet var sampleView: UIView!
    @IBOutlet var switchEnable : UISwitch!
    
    private var sliderColor: UIColor?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if slider != nil {
            slider.addTarget(self, action: #selector(sliderValueChanged(sender:)), for: .valueChanged)
        }
        if sampleView != nil {
            sampleView.layer.cornerRadius = sampleView.frame.height * 0.5
        }
    }
    
    func setName(name: String!, color: Int!, tag: Int!){
        settingName.text = name
        if sampleView != nil {
            sampleView.backgroundColor = UIColor(hex: color)
        }

        if slider != nil {
            slider.minimumTrackTintColor = UIColor(hex: color)
            slider.minimumValue = 0
            slider.maximumValue = 1
            slider.tag = tag
            slider.setThumbImage(getImageWithColor(color: UIColor(hex: color), radius: 12), for: .normal)
        }
    }
    
    func getImageWithColor(color: UIColor, radius: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: radius, height: radius), false, 0)
        let ctx = UIGraphicsGetCurrentContext()
        ctx!.saveGState()
        
        let rect = CGRect(x: 0, y: 0, width: radius, height: radius)
        ctx!.setFillColor(color.cgColor)
        ctx!.fill(rect)
        
        ctx!.restoreGState()
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return img!
    }
    
    @objc func sliderValueChanged(sender: AnyObject!){
        switch sender.tag {
        case 0:
            UserDefaults.standard.setValue((sender as! UISlider).value, forKey: "relaxation-thred")
            UserDefaults.standard.synchronize()
            break
        case 1:
            UserDefaults.standard.setValue((sender as! UISlider).value, forKey: "boredom-thred")
            UserDefaults.standard.synchronize()
            break
        case 2:
            UserDefaults.standard.setValue((sender as! UISlider).value, forKey: "excitement-thred")
            UserDefaults.standard.synchronize()
            break
        case 3:
            UserDefaults.standard.setValue((sender as! UISlider).value, forKey: "lexcitement-thred")
            UserDefaults.standard.synchronize()
            break
        case 4:
            UserDefaults.standard.setValue((sender as! UISlider).value, forKey: "interest-thred")
            UserDefaults.standard.synchronize()
            break
        case 5:
            UserDefaults.standard.setValue((sender as! UISlider).value, forKey: "stress-thred")
            UserDefaults.standard.synchronize()
            break
        case 9:
            if let label = self.viewWithTag(110) as? UILabel{
                label.text = String(format: "%0.2f", (sender as! UISlider).value)
            }
            UserDefaults.standard.setValue((sender as! UISlider).value, forKey: "speed-sphero")
            UserDefaults.standard.synchronize()
            break
        default:
            break
        }
    }
    
}
