//
//  ViewController.swift
//  typps
//
//  Created by Monte with Pillow on 7/4/16.
//  Copyright © 2016 Monte Thakkar. All rights reserved.
//

import UIKit
import CoreLocation
import MBProgressHUD
import RealmSwift
import Realm
import AudioToolbox

var didOpenSecondaryView: Bool?

class ViewController: UIViewController, LocationServiceDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    // instance of Realm object
    let realmObject = try! Realm()
    
    //current formatter for different currencies
    var currencyFormatter: NSNumberFormatter?
    
    //tip percent variables
    var isTaxEnabled: Bool = false
    var tipPercent: Int = 20
    let tipPercentMax: Int = 30
    let tipPercentMin: Int = 10
    var tipPercentTapStart: Int = 20
    
    var totalBillAmount: Float = 0
    var totalCheckAmount: Float = 0
    var checkTotalViewHeight: CGFloat?
    
    var business: YelpBusiness?
    
    //tip label position variables
    var tipLabelCenter: CGFloat = 220
    var tipLabelCenterMax: CGFloat = 0
    var tipLabelCenterMin: CGFloat = 0
    var tipLabelCenterStart: CGFloat = 0
    
    var nearbyBusinesses: [YelpBusiness]! = [YelpBusiness]()
    var minDistance: String?
    
    //split bill variables
    var splitBillMode : Bool = false
    var partySize: Int?
    var currentPartySize: Int?
    var fourPlusPartySize: Int?
    var partySizeDictionary: [Int:String] = [4: "four", 5: "five", 6: "six", 7: "seven", 8: "eight", 9: "nine"]
    
    
    @IBOutlet var mainView: UIView!

    //status bar notification
    let notification = CWStatusBarNotification()
    
    //Outlets
    @IBOutlet weak var totalBillAmountTextField: UITextField!
    @IBOutlet weak var taxHintLabel: UILabel!
    @IBOutlet weak var tipAmountLabel: UILabel!
    @IBOutlet weak var welcomeViewRestaurantImageView: UIImageView!
    @IBOutlet weak var welcomeViewRestaurantNameLabel: UILabel!
    @IBOutlet weak var restaurantImageView: UIImageView!
    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var resultsCountLabel: UILabel!
    @IBOutlet weak var splitTwoImageView: UIImageView!
    @IBOutlet weak var splitThreeImageView: UIImageView!
    @IBOutlet weak var splitFourPlusImageView: UIImageView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var totalBillAmountLabel: UILabel!
    @IBOutlet weak var splitTotalLabel: UILabel!
    @IBOutlet weak var hiddenMessageLabel: UILabel!
    
    //Views
    @IBOutlet weak var welcomeView: UIView!
    @IBOutlet weak var taxView: UIView!
    @IBOutlet weak var tipView: UIView!
    @IBOutlet weak var splitTwoView: UIView!
    @IBOutlet weak var splitThreeView: UIView!
    @IBOutlet weak var splitFourPlusView: UIView!
    @IBOutlet weak var totalCheckAmountView: UIView!
    @IBOutlet weak var splitView: UIView!
    
    
    @IBOutlet weak var yelpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Delegate for billAmountInput textField
        totalBillAmountTextField.delegate = self
        
        // Delegate for LocationService
        LocationService.sharedInstance.delegate = self
        
        //show loading indicator
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
       //print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        //add gesture recognizers for single and double tap
        var singleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.splitFourPlusViewTapped))
        singleTap.numberOfTapsRequired = 1
        self.splitFourPlusView.addGestureRecognizer(singleTap)
        
        var doubleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.splitFourPlusViewDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        self.splitFourPlusView.addGestureRecognizer(doubleTap)
        
        singleTap.requireGestureRecognizerToFail(doubleTap)
        
        singleTap.delegate = self
        doubleTap.delegate = self
        
        
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func viewWillAppear(animated: Bool) {
        
        //Fetch current location and find current restaurant/bar
        LocationService.sharedInstance.startUpdatingLocation()
        
        let settings = realmObject.objects(Settings)
        
        if settings.first == nil {
            let newSettings = Settings()
            newSettings.isTaxEnabled = false
            newSettings.partySize = 1
            newSettings.tipPercent = 20
            newSettings.currentPartySize = 1
            
            //write the settings object to db for persistence
            try! realmObject.write() {
                realmObject.add(newSettings)
                print("Settings created.. check db for details")
            }
        } else {
            print("Found settings")
            
            self.tipPercent = (settings.first?.tipPercent)!
            self.isTaxEnabled = (settings.first?.isTaxEnabled)!
            self.partySize = (settings.first?.partySize)!
            
            if settingsCancelled == true {
                self.currentPartySize = (settings.first?.currentPartySize)!
                setPartySize(currentPartySize!)
            } else {
                self.currentPartySize = (settings.first?.currentPartySize)!
                setPartySize(partySize!)
            }
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        //Customize the navigation bar title and color
        let navigationBar = self.navigationController?.navigationBar
        
        //make navigation bar transparent
        navigationBar!.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationBar!.shadowImage = UIImage()
        navigationBar!.translucent = true
        
        //set navigation bar title with color
        navigationItem.title = "typps"
        navigationBar!.titleTextAttributes = [NSForegroundColorAttributeName : UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)]
        
        //customize status bar notification
        self.notification.notificationLabelBackgroundColor = UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)
        self.notification.notificationLabelTextColor = UIColor.whiteColor()
        self.notification.notificationAnimationInStyle = CWNotificationAnimationStyle.Top
        self.notification.notificationAnimationOutStyle = CWNotificationAnimationStyle.Top
        
        //add rounded edges to restaurantImageView
        restaurantImageView.layer.cornerRadius = 5
        restaurantImageView.clipsToBounds = true
        welcomeViewRestaurantImageView.layer.cornerRadius = 5
        welcomeViewRestaurantImageView.clipsToBounds = true
        
        // add corner radius to saveButton
        saveButton.layer.cornerRadius = 17
        
        if (didOpenSecondaryView == true) {
            if (totalBillAmountTextField.text != "$" && totalBillAmountTextField.text != "") {
                welcomeView.hidden = true
            }
        } else {
            //set totalBillAmountPlaceholder
            totalBillAmountTextField.text = "$"
            welcomeView.hidden = false
        }
        
        
        if let total = self.totalBillAmountTextField.text {
            let index: String.Index = total.startIndex.advancedBy(1)
            if let totalBillAmount = Float(total.substringFromIndex(index)) {
                updateTotalBillAmount(totalBillAmount + (totalBillAmount * Float(tipPercent) / 100 ))
            }
            self.taxHintLabel.text = "(off)"
            self.tipAmountLabel.text = String(tipPercent) + " %"
            setTaxView()
        }
        
        checkTotalViewHeight = totalCheckAmountView.frame.size.height
        hiddenMessageLabel.hidden = true
    }
    
    func setPartySize(partySize: Int) {
        
        splitTwoImageView.image = UIImage(named: "two")
        splitThreeImageView.image = UIImage(named: "three")
        splitFourPlusImageView.image = UIImage(named: "four")
        
        switch partySize {
        case 2:
            splitTwoImageView.image = UIImage(named: "two_selected")
            splitBillMode = true
            currentPartySize = 2
        case 3:
            splitThreeImageView.image = UIImage(named: "three_selected")
            splitBillMode = true
            currentPartySize = 3
        case 4:
            splitFourPlusImageView.image = UIImage(named: "four_selected")
            splitBillMode = true
            currentPartySize = 4
        case 5:
            splitFourPlusImageView.image = UIImage(named: "five_selected")
            splitBillMode = true
            currentPartySize = 5
        case 6:
            splitFourPlusImageView.image = UIImage(named: "six_selected")
            splitBillMode = true
            currentPartySize = 6
        case 7:
            splitFourPlusImageView.image = UIImage(named: "seven_selected")
            splitBillMode = true
            currentPartySize = 7
        case 8:
            splitFourPlusImageView.image = UIImage(named: "eight_selected")
            splitBillMode = true
            currentPartySize = 8
        case 9:
            splitFourPlusImageView.image = UIImage(named: "nine_selected")
            splitBillMode = true
            currentPartySize = 9
        default:
            print("party size is 1")
        }
    }
    
    @IBAction func textFieldDidChange(sender: AnyObject) {
        if (totalBillAmountTextField.text == "") {
            totalBillAmountTextField.text = "$"
            welcomeView.hidden = false
        }
        
        if (totalBillAmountTextField.text == "$") {
            welcomeView.hidden = false
            self.view.endEditing(true)
        }
        
        if (totalBillAmountTextField.text != "$") {
            welcomeView.hidden = true
            
            if let total = self.totalBillAmountTextField.text {
                let index: String.Index = total.startIndex.advancedBy(1)
                
                if let totalBillAmount = Float(total.substringFromIndex(index)) {
                    self.totalBillAmount = totalBillAmount
                    
                    if isTaxEnabled {
                        let tempTotalBillAmount = totalBillAmount + Float(totalBillAmount * 0.0875)
                        
                        updateTotalBillAmount(tempTotalBillAmount + (tempTotalBillAmount * Float(tipPercent) / 100 ))
                    } else {
                        updateTotalBillAmount(totalBillAmount + (totalBillAmount * Float(tipPercent) / 100 ))
                    }
                } else {
                    self.notification.displayNotificationWithMessage("invalid entry!", forDuration: 1.0)
                }
            }
        }
    }
    
    func updateTotalBillAmount(total:Float) {
        self.totalCheckAmount = total
        
        if (currentPartySize > 1) {
            if (checkTotalViewHeight > 50) {
                self.splitTotalLabel.hidden = false
                self.splitTotalLabel.text = "total $\(total)"
                self.totalBillAmountLabel.text = "$\(Float(total / Float(currentPartySize!))) each"
                self.totalBillAmountLabel.font = self.totalBillAmountLabel.font.fontWithSize(CGFloat(40))
            } else {
                self.splitTotalLabel.hidden = true
                self.totalBillAmountLabel.text = "$\(Float(total / Float(currentPartySize!))) each"
                self.totalBillAmountLabel.font = self.totalBillAmountLabel.font.fontWithSize(CGFloat(25))
            }
        } else if (currentPartySize == 1) {
            if (checkTotalViewHeight < 50) {
                self.totalBillAmountLabel.font = self.totalBillAmountLabel.font.fontWithSize(CGFloat(25))
                self.splitTotalLabel.hidden = true
                self.totalBillAmountLabel.text = "total $\(total)"
            } else {
                self.totalBillAmountLabel.font = self.totalBillAmountLabel.font.fontWithSize(CGFloat(40))
                self.splitTotalLabel.hidden = true
                self.totalBillAmountLabel.text = "total $\(total)"
            }
        }
    }
    
    @IBAction func welcomeViewTapped(sender: UITapGestureRecognizer) {
        //hide decimal pad
        self.view.endEditing(true)
    }
    
    @IBAction func tipViewTapped(sender: UITapGestureRecognizer) {
        //hide decimal pad
        self.view.endEditing(true)
    }
    
    
    @IBAction func taxViewTapped(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
        isTaxEnabled = !isTaxEnabled
        
        setTaxView()
    }
    
    func setTaxView() {
        if (isTaxEnabled) {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            taxView.backgroundColor = UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)
            taxHintLabel.text = "(tax included)"
            taxView.layer.cornerRadius = 60
            
            let tempTotalBillAmount = Int(totalBillAmount + Float(totalBillAmount * 0.0875))
            
            updateTotalBillAmount(Float(tempTotalBillAmount + (tempTotalBillAmount * Int(tipPercent) / 100 )))
        } else {
            taxView.backgroundColor = UIColor(red: 117/255, green: 124/255, blue: 121/255, alpha: 1)
            taxHintLabel.text = "(off)"
            taxView.layer.cornerRadius = 0
            updateTotalBillAmount(totalBillAmount + (totalBillAmount * Float(tipPercent) / 100 ))
        }
    }
    
    @IBAction func setTipAmountWithPan(sender: UIPanGestureRecognizer) {
        self.view.endEditing(true)
        
        let translation: CGPoint = sender.translationInView(self.view)
        
        let parentView = sender.view
        tipLabelCenterMax = (parentView?.frame.width)! - 64
        tipLabelCenterMin = 64

        if (sender.state == UIGestureRecognizerState.Began) {
            
            self.tipPercentTapStart = self.tipPercent;
            self.tipLabelCenterStart = self.tipAmountLabel.center.x
            
        } else if (sender.state == UIGestureRecognizerState.Changed) {
            
            //set the tipAmountLabel text based on pan gesture
            self.tipPercent = (self.tipPercentTapStart + Int(translation.x / 7))
            if (self.tipPercent > self.tipPercentMax) {
                self.tipPercent = self.tipPercentMax;
            } else if (self.tipPercent < self.tipPercentMin) {
                self.tipPercent = self.tipPercentMin;
            }
            tipAmountLabel.text = String(tipPercent) + " %"
            
            if isTaxEnabled {
                let tempTotalBillAmount = Int(totalBillAmount + Float(totalBillAmount * 0.0875))
                
                updateTotalBillAmount(Float(tempTotalBillAmount + (tempTotalBillAmount * Int(tipPercent) / 100 )))
            } else {
                updateTotalBillAmount(totalBillAmount + (totalBillAmount * Float(tipPercent) / 100 ))
            }
            
            //set the tipAmountLabel center based on pan gesture
            self.tipLabelCenter = self.tipLabelCenterStart + translation.x
            if (self.tipLabelCenter > self.tipLabelCenterMax) {
                self.tipLabelCenter = self.tipLabelCenterMax;
            } else if (self.tipLabelCenter < self.tipLabelCenterMin) {
                self.tipLabelCenter = self.tipLabelCenterMin;
            }
            self.tipAmountLabel.center.x = self.tipLabelCenter

        }
    }
    
    @IBAction func splitTwoViewTapped(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
        
        let settings = realmObject.objects(Settings)
        
        if settings.first?.currentPartySize == 2 {
            splitTwoImageView.image = UIImage(named: "two")
            splitBillMode = false
            
            //write the currentPartySize to the settings object to db for persistence
            try! realmObject.write() {
                settings.first?.setValue(1, forKeyPath: "currentPartySize")
                print("currentPartySize updated.. check db for details")
            }
            self.currentPartySize = 1
        } else {
            splitThreeImageView.image = UIImage(named: "three")
            splitFourPlusImageView.image = UIImage(named: "four")
            
            splitTwoImageView.image = UIImage(named: "two_selected")
            splitBillMode = true
            
            //write the currentPartySize to the settings object to db for persistence
            try! realmObject.write() {
                settings.first?.setValue(2, forKeyPath: "currentPartySize")
                print("currentPartySize updated.. check db for details")
            }
            self.currentPartySize = 2
        }
        updateTotalBillAmount(totalCheckAmount)
    }
    
    @IBAction func splitThreeViewTapped(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
        
        let settings = realmObject.objects(Settings)
        
        if settings.first?.currentPartySize == 3 {
            splitThreeImageView.image = UIImage(named: "three")
            splitBillMode = false
            
            //write the currentPartySize to the settings object to db for persistence
            try! realmObject.write() {
                settings.first?.setValue(1, forKeyPath: "currentPartySize")
                print("currentPartySize updated.. check db for details")
            }
            self.currentPartySize = 1
        } else {
            splitTwoImageView.image = UIImage(named: "two")
            splitFourPlusImageView.image = UIImage(named: "four")

            splitThreeImageView.image = UIImage(named: "three_selected")
            splitBillMode = false
            
            //write the currentPartySize to the settings object to db for persistence
            try! realmObject.write() {
                settings.first?.setValue(3, forKeyPath: "currentPartySize")
                print("currentPartySize updated.. check db for details")
            }
            
            self.currentPartySize = 3
        }
        updateTotalBillAmount(totalCheckAmount)
    }
    
    @IBAction func splitFourPlusViewTapped(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
        
        if (fourPlusPartySize < 4 || fourPlusPartySize >= 9) {
            fourPlusPartySize = 3
        }
        
        if let size: String = partySizeDictionary[fourPlusPartySize! + 1]! {
            splitThreeImageView.image = UIImage(named: "three")
            splitFourPlusImageView.image = UIImage(named: "four")
            
            fourPlusPartySize = fourPlusPartySize! + 1
            splitFourPlusImageView.image = UIImage(named: size)
            
            let settings = realmObject.objects(Settings)
            
            //write the currentPartySize to the settings object to db for persistence
            try! realmObject.write() {
                settings.first?.setValue(1, forKeyPath: "currentPartySize")
                print("currentPartySize updated.. check db for details")
            }
            currentPartySize = 1
            updateTotalBillAmount(totalCheckAmount)
        }
        
    }
    
    @IBAction func splitFourPlusViewDoubleTap(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
        
        let settings = realmObject.objects(Settings)
        
        if settings.first?.currentPartySize == fourPlusPartySize {
            if let size: String = partySizeDictionary[fourPlusPartySize!]! {
                splitFourPlusImageView.image = UIImage(named: size)
                splitBillMode = true
            }
            
            //write the currentPartySize to the settings object to db for persistence
            try! realmObject.write() {
                settings.first?.setValue(1, forKeyPath: "currentPartySize")
                print("currentPartySize updated.. check db for details")
            }
            
            currentPartySize = 1
            updateTotalBillAmount(totalCheckAmount)
        } else {
            splitTwoImageView.image = UIImage(named: "two")
            splitThreeImageView.image = UIImage(named: "three")
            
            if let size: String = partySizeDictionary[fourPlusPartySize!]! {
                splitFourPlusImageView.image = UIImage(named: size + "_selected")
                splitBillMode = true
            }
            
            //write the currentPartySize to the settings object to db for persistence
            try! realmObject.write() {
                settings.first?.setValue(fourPlusPartySize!, forKeyPath: "currentPartySize")
                print("currentPartySize updated.. check db for details")
            }
            
            self.currentPartySize = fourPlusPartySize!
            updateTotalBillAmount(totalCheckAmount)
        }
    }
    
    @IBAction func saveButtonPressed(sender: AnyObject) {
//        self.notification.displayNotificationWithMessage("Check saved!", forDuration: 2.0)
//        let check = Check()
//        check.restaurantName = restaurantNameLabel.text!
//        check.imageURL = String(business!.imageURL!)
//        check.createdAt = NSDate()
//        check.inputBillAmount = totalBillAmount
//        check.totalTipAmount = tipPercent
//        check.isTaxIncluded = isTaxEnabled
//        check.partySize = partySize!
//        check.finalCheckAmount = totalCheckAmount
//        
//        //write the check object to db for persistence
//        try! realmObject.write() {
//            realmObject.add(check)
//            print("Check saved.. check db for details")
//        }
        
        UIView.animateWithDuration(0.5, animations: {
            self.mainView.backgroundColor = UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)
            self.restaurantImageView.hidden = true
            self.taxView.hidden = true
            self.splitView.hidden = true
            self.hiddenMessageLabel.hidden = false
            self.yelpButton.hidden = true
            self.saveButton.hidden = true
        }) { (true) in
            UIView.animateWithDuration(1.5, animations: {
                self.mainView.backgroundColor = UIColor.whiteColor()
                }, completion: { (true) in
                self.restaurantImageView.hidden = false
                self.taxView.hidden = false
                self.splitView.hidden = false
                self.hiddenMessageLabel.hidden = true
                self.yelpButton.hidden = false
                self.saveButton.hidden = false
            })
        }
        
    }
    
    @IBAction func openRestaurantInYelp(sender: AnyObject) {
        self.notification.displayNotificationWithMessage("coming soon.", forDuration: 1.0)
    }
    
    @IBAction func historyNavigationBarButtonPressed(sender: AnyObject) {
        self.notification.displayNotificationWithMessage("coming soon.", forDuration: 1.0)
    }
    
    func tracingLocation(currentLocation: CLLocation) {
       // print("Starting yelp search with params: [food, \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)]")
        startYelpSearch("food", latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
        LocationService.sharedInstance.stopUpdatingLocation()
    }
    
    func tracingLocationDidFailWithError(error: NSError) {
        print("Location produced error: \(error)")
    }
    
    func startYelpSearch(term: String, latitude: NSNumber?, longitude: NSNumber?) {
        YelpBusiness.searchWithTerm("", latitude: 37.786691, longitude: -122.407758, sort: .Distance, categories: [], deals: false, offset: nil, limit: 5) { (businesses: [YelpBusiness]!, error: NSError!) -> Void in
            
            if (businesses != nil) {
                self.minDistance = businesses.first?.distance
                for business in businesses {
                    if (business.distance <= self.minDistance) {
                        self.nearbyBusinesses.insert(business, atIndex: 0)
                        self.minDistance = business.distance!
                        self.business = business
                    }
                }
            }
            else {
                print("NO DATA RETURNED")
            }
            
            if (self.nearbyBusinesses != nil) {
                
                if (self.nearbyBusinesses.count == 1) {
                    self.resultsCountLabel.hidden = true
                } else {
                    self.resultsCountLabel.text = String("\(self.nearbyBusinesses.count) possible matches")
                }
                
                for business in self.nearbyBusinesses {
                    if let imageURL = business.imageURL {
                        self.restaurantImageView.setImageWithURL(imageURL)
                        self.welcomeViewRestaurantImageView.setImageWithURL(imageURL)
                    }
                    self.restaurantNameLabel.text = business.name
                    self.welcomeViewRestaurantNameLabel.text = business.name
                    print("\(business.name) is \(business.distance) mi away from current location")
                }
                // Hide HUD once network request comes back (must be done on main UI thread)
                MBProgressHUD.hideHUDForView(self.view, animated: true)
            }
        }
    }
    
}

