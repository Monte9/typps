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

class TableViewHelper {
    class func EmptyMessage(message:String, viewController:HistoryViewController) {
        let messageLabel = UILabel(frame: CGRectMake(0,0,viewController.view.bounds.size.width, viewController.view.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = UIColor.whiteColor()
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = .Center;
        messageLabel.font = UIFont(name: "Avenir-Heavy", size: 30)
        messageLabel.sizeToFit()
        
        viewController.tableView.backgroundView = messageLabel;
        viewController.tableView.separatorStyle = .None;
    }
}

class HistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CheckCellDelegate {

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
        
        settingsSaved = false
        
        //customize status bar notification
        notification.notificationLabelBackgroundColor = UIColor.whiteColor()
        notification.notificationLabelTextColor = UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)
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
        if checks?.count > 0 {
            return checks.count
        } else {
            TableViewHelper.EmptyMessage("Save checks to view them here.", viewController: self)
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CheckCell") as! CheckCell
        let check = checks[indexPath.row]
        cell.restaurantImageView.setImageWithURL(NSURL(string: check.imageURL)!)
        cell.restaurantNameLabel?.text = check.restaurantName
        cell.checkAmountAndPartySizeLabel.text = "$\(check.finalCheckAmount) for \(check.partySize) people"
        cell.dateLabel.text = formatter.stringFromDate(check.createdAt)
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        cell.buttonDelegate = self
        cell.trashView.hidden = check.hideTrashButton
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    //delegate methods for the ArticleCellDelegate
    func deleteCheck (checkCell: CheckCell!) {
        let index = tableView.indexPathForCell(checkCell)
        
        let check = checks[(index?.row)!]
        
        // Delete an object with a transaction
        try! realmObject.write {
            realmObject.delete(check)
        }
        
        notification.displayNotificationWithMessage("check deleted.", forDuration: 1.0)
        
        tableView.reloadData()
    }
    
    func showDeleteCheckButton(checkCell: CheckCell!) {
        let index = tableView.indexPathForCell(checkCell)
        
        let check = checks[(index?.row)!]
        
        let trashButtonFlag = check.hideTrashButton
        
        try! realmObject.write {
            check.setValue(!trashButtonFlag, forKey: "hideTrashButton")
        }
        
        tableView.reloadData()
    }
    
    @IBAction func displayStatsButton(sender: AnyObject) {
        notification.displayNotificationWithMessage("stats coming soon.", forDuration: 1.0)
    }
    
    
    @IBAction func closeBarButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
