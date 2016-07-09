//
//  HistoryViewController.swift
//  typps
//
//  Created by Monte with Pillow on 7/9/16.
//  Copyright © 2016 Monte Thakkar. All rights reserved.
//

import UIKit
import RealmSwift
import Realm

class HistoryViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        didOpenSecondaryView = true
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        //Customize the navigation bar title and color
        let navigationBar = self.navigationController?.navigationBar
        
        //make navigation bar transparent
        navigationBar!.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationBar!.shadowImage = UIImage()
        navigationBar!.translucent = true
        
        //set navigation bar title with color
        navigationItem.title = "history"
        navigationBar!.titleTextAttributes = [NSForegroundColorAttributeName : UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)]
    }
    
    @IBAction func closeBarButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
