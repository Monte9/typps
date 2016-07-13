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

class HistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var tableView: UITableView!
    
    
    // instance of Realm object
    let realmObject = try! Realm()
    
    var checks: Results<Check>!
    
    //NSDate formatter
    let formatter = NSDateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .None
        
        didOpenSecondaryView = true
        
        formatter.dateStyle = NSDateFormatterStyle.LongStyle
        formatter.timeStyle = .MediumStyle
    }
    
    override func viewWillAppear(animated: Bool) {
        //Customize the navigation bar title and color
        let navigationBar = self.navigationController?.navigationBar
        
        //set navigation bar color and title
        navigationItem.title = "history"
        navigationBar!.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        navigationBar?.barTintColor = UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarPosition: .Any, barMetrics: .Default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationBar?.translucent = false
        
        //get all checks from realm db and sort by most recent checks
        checks = realmObject.objects(Check)
        checks = checks!.sorted("createdAt", ascending: false)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (checks?.count)!
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CheckCell") as! CheckCell
        let check = checks[indexPath.row]
        cell.restaurantImageView.setImageWithURL(NSURL(string: check.imageURL)!)
        cell.restaurantNameLabel?.text = check.restaurantName
        cell.checkAmountAndPartySizeLabel.text = "$\(check.finalCheckAmount) for \(check.partySize) people"
        cell.dateLabel.text = formatter.stringFromDate(check.createdAt)
        
        return cell
    }
    
    
    
    @IBAction func closeBarButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
}
