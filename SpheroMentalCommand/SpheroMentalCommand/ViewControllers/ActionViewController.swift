//
//  ActionViewController.swift
//  Sphero Mental Command
//
//  Created by Viet Anh on 4/26/16.
//  Copyright © 2016 Viet Anh. All rights reserved.
//

import UIKit

class ActionViewController: UITableViewController {

    var optionList: [String]?
    
    var selectOptionAt: ((_ index: Int) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if optionList == nil{
            optionList = [String]()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 43
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optionList!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        
        (cell!.viewWithTag(101) as! UILabel).text = optionList![indexPath.row]
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: NSIndexPath) {
        if selectOptionAt != nil{
            selectOptionAt!(indexPath.row)
        }
    }
}
