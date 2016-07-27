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
import SnapKit

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
    var partySizeDictionary: [Int:String] = [1: "pika", 2: "two", 3: "three", 4: "four", 5: "five", 6: "six", 7: "seven", 8: "eight", 9: "nine"]
    var partySizeDescriptionDictionary: [Int:String] = [1: "How was the food?", 2: "Is it a date?", 3: "Who's the third wheel?", 4: "Like a pack of friends", 5: "The five horsemen!", 6: "666", 7: "Seven 11", 8: "Eight sounds fun", 9: "That's too many"]
    var selectedPartySizeDescriptionDictionary: [Int:String] = [1: "I am here for you!", 2: "OMG MOM! It's a date!!", 3: "No comments", 4: "Hope you had a good time!", 5: "Hope you had a good time!", 6: "Hope you had a good time!", 7: "Hope you had a good time!", 8: "Hope you had a good time!", 9: "Hope you had a good time!"]
    
    //Main UIView
    @IBOutlet var mainView: UIView!
    
    //Controls View -> Tip, tax, party size, total check
    @IBOutlet weak var controlsView: UIView!
    
    //Views within controlsView
    @IBOutlet weak var taxView: UIView!
    @IBOutlet weak var partySizeView: UIView!
    @IBOutlet weak var tipView: UIView!
    
    
    //Outlets within controlsView
    @IBOutlet weak var taxLabel: UILabel!
    @IBOutlet weak var partySizeImageView: UIImageView!
    @IBOutlet weak var partySizeDescriptionLabel: UILabel!
    @IBOutlet weak var tipAmountLabel: UILabel!
    @IBOutlet weak var tipPercentLabel: UILabel!
    @IBOutlet weak var TipNameLabel: UILabel!
    
    //Gesture recognizers for controlsView
    @IBOutlet var setTipAmountPanGesture: UIPanGestureRecognizer!
    @IBOutlet var tipViewTapGesture: UITapGestureRecognizer!
    
    
    //Variables for controlsView actions
    var firstTouchForTaxView: Bool = true
    
    
    //Outlets
    @IBOutlet weak var totalBillAmountTextField: UITextField!
    @IBOutlet weak var welcomeViewRestaurantImageView: UIImageView!
    @IBOutlet weak var welcomeViewRestaurantNameLabel: UILabel!
    @IBOutlet weak var restaurantImageView: UIImageView!
    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var resultsCountLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var hiddenMessageLabel: UILabel!
    
    //Views
    @IBOutlet weak var welcomeView: UIView!
    @IBOutlet weak var yelpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Delegate for billAmountInput textField
        totalBillAmountTextField.delegate = self
        
        // Delegate for LocationService
        LocationService.sharedInstance.delegate = self
        
        //show loading indicator
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        //add gesture recognizers for single and double tap
        let togglePartySizeTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.togglePartySizeTapGesture))
        togglePartySizeTapGesture.numberOfTapsRequired = 1
        self.partySizeView.addGestureRecognizer(togglePartySizeTapGesture)
        
        let selectPartySizeDoubleTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.selectPartySizeDoubleTapGesture))
        selectPartySizeDoubleTapGesture.numberOfTapsRequired = 2
        self.partySizeView.addGestureRecognizer(selectPartySizeDoubleTapGesture)
        
        togglePartySizeTapGesture.delegate = self
        selectPartySizeDoubleTapGesture.delegate = self
        setTipAmountPanGesture.delegate = self
        tipViewTapGesture.delegate = self
        
        //single and double tap in partySizeImageView
        togglePartySizeTapGesture.requireGestureRecognizerToFail(selectPartySizeDoubleTapGesture)
        
        //setup labels for the TipView
        self.setupTipViewLabels()
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
            
//            if settingsCancelled == true {
//                self.currentPartySize = (settings.first?.currentPartySize)!
//            } else {
//                self.currentPartySize = (settings.first?.currentPartySize)!
//            }
            self.currentPartySize = 1
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
        navigationItem.title = "tyypps"
        navigationBar!.titleTextAttributes = [NSForegroundColorAttributeName : UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)]
        
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
        
        hiddenMessageLabel.hidden = true
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
                    notification.displayNotificationWithMessage("invalid entry!", forDuration: 1.0)
                }
            }
        }
    }
    
    func updateTotalBillAmount(total:Float) {
        self.totalCheckAmount = ceil(total)
        //TO DO
    }
    
    @IBAction func taxViewTapGesture(sender: UITapGestureRecognizer) {
        if (firstTouchForTaxView) {
            self.taxLabel.text = "Tax ON (8.75% tax included in tip)"
        } else {
            self.taxLabel.text = "Tax OFF"
        }
        
        //toggle first touch for tax view
        firstTouchForTaxView = !firstTouchForTaxView
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        let touchLocation = touch.locationInView(self.partySizeView)
        return !CGRectContainsPoint(self.partySizeDescriptionLabel.frame, touchLocation)
    }
    
    @IBAction func togglePartySizeTapGesture(sender: UITapGestureRecognizer) {
        
        var nextPartySize = self.currentPartySize! + 1
        
        if (nextPartySize > 9) {
            nextPartySize = 1
        }
        
        let partySizeImageName: String = partySizeDictionary[nextPartySize]!
        self.partySizeImageView.image = UIImage(named: partySizeImageName)
        
        let partySizeDescription: String = partySizeDescriptionDictionary[nextPartySize]!
        self.partySizeDescriptionLabel.text = partySizeDescription
        
        //save the partySize
        currentPartySize! = nextPartySize
    }
    
    @IBAction func selectPartySizeDoubleTapGesture(sender: UITapGestureRecognizer) {
        let partySizeImageName: String = partySizeDictionary[self.currentPartySize!]!
        let selectedPartySizeImageName = partySizeImageName + "_selected"
        
        if (firstTouchForTaxView) {
            self.partySizeImageView.image = UIImage(named: selectedPartySizeImageName)
            
            let selectedPartySizeDescription: String = selectedPartySizeDescriptionDictionary[self.currentPartySize!]!
            self.partySizeDescriptionLabel.text = selectedPartySizeDescription
        } else {
            self.partySizeImageView.image = UIImage(named: partySizeImageName)
            
            let partySizeDescription: String = partySizeDescriptionDictionary[self.currentPartySize!]!
            self.partySizeDescriptionLabel.text = partySizeDescription
        }
        
        //toggle first touch for tax view
        firstTouchForTaxView = !firstTouchForTaxView
    }
    
    @IBAction func setTipAmountPanGesture(sender: UIPanGestureRecognizer) {
        var point = sender.locationInView(view)
        var velocity = sender.velocityInView(view)
        var translation = sender.translationInView(view)
        
        let parentView = sender.view
        tipLabelCenterMax = (parentView?.frame.width)! - 75
        tipLabelCenterMin = 100
        
        var ticks = (parentView?.frame.width)! - 175
        
        if sender.state == UIGestureRecognizerState.Began {
            self.tipPercentTapStart = self.tipPercent;
            self.tipLabelCenterStart = self.tipAmountLabel.center.x
            beginAnimatingTipView(self.view)
        } else if sender.state == UIGestureRecognizerState.Changed {
            //set the tipAmountLabel text based on pan gesture
            self.tipPercent = (self.tipPercentTapStart + Int(translation.x / 12))
            if (self.tipPercent > self.tipPercentMax) {
                self.tipPercent = self.tipPercentMax;
            } else if (self.tipPercent < self.tipPercentMin) {
                self.tipPercent = self.tipPercentMin;
            }
            
            tipAmountLabel.text = String(tipPercent)
            
            //set the tipAmountLabel center based on pan gesture
            self.tipLabelCenter = self.tipLabelCenterStart + translation.x
            if (self.tipLabelCenter > self.tipLabelCenterMax) {
                self.tipLabelCenter = self.tipLabelCenterMax;
            } else if (self.tipLabelCenter < self.tipLabelCenterMin) {
                self.tipLabelCenter = self.tipLabelCenterMin;
            }
            
            self.tipAmountLabel.center.x = self.tipLabelCenter
            
        } else if sender.state == UIGestureRecognizerState.Ended {
            endAnimatingTipView(self.view)
        }

    }
    
    @IBAction func tipViewTapGesture(sender: UITapGestureRecognizer) {
        let superview = self.view
        
        if (firstTouchForTaxView) {
            
            beginAnimatingTipView(superview)
            
//            self.tipAmountLabel.snp_updateConstraints(closure: { (make) in
//                make.centerX.equalTo(superview)
//                return
//            })
//            
//            self.TipNameLabel.snp_updateConstraints { (make) in
//                make.left.equalTo(superview.snp_left).offset(20)
//                return
//            }
//            self.tipPercentLabel.snp_updateConstraints { (make) in
//                make.right.equalTo(superview.snp_right).offset(-20)
//                return
//            }
        } else {
            endAnimatingTipView(superview)
        
            
//            self.tipAmountLabel.snp_updateConstraints { (make) in
//                make.centerX.equalTo(superview)
//                return
//            }
//            self.TipNameLabel.snp_updateConstraints { (make) in
//                make.left.equalTo(superview.snp_left).offset(100)
//                return
//            }
//            self.tipPercentLabel.snp_updateConstraints { (make) in
//                make.right.equalTo(superview.snp_right).offset(-100)
//                return
//            }
        }
        
        firstTouchForTaxView = !firstTouchForTaxView
    }
    
    func beginAnimatingTipView(superview: UIView) {
        UIView.animateWithDuration(0.3, animations: {
            self.tipAmountLabel.center.x = superview.center.x
            self.tipPercentLabel.center.x = superview.frame.width - 30
            self.TipNameLabel.center.x = 50
        })
    }
    
    func endAnimatingTipView(superview: UIView) {
        UIView.animateWithDuration(0.5, animations: {
            self.tipAmountLabel.center.x = superview.center.x
            self.tipPercentLabel.center.x = superview.center.x + 45
            self.TipNameLabel.center.x = superview.center.x - 60
        })
    }
    
    func setupTipViewLabels() {
        let superview = self.view
        
        self.tipAmountLabel.snp_remakeConstraints { (make) in
            make.centerX.equalTo(superview)
        }
        self.TipNameLabel.snp_remakeConstraints { (make) in
            make.centerX.equalTo(superview).offset(-60)
        }
        self.tipPercentLabel.snp_remakeConstraints { (make) in
            make.centerX.equalTo(superview).offset(45)
        }
    }
    
    
    
    
    
    
    
    
    
    
    @IBAction func welcomeViewTapped(sender: UITapGestureRecognizer) {
        //hide decimal pad
        self.view.endEditing(true)
    }
    
    @IBAction func saveButtonPressed(sender: AnyObject) {
        let check = Check()
        check.restaurantName = restaurantNameLabel.text!
        check.imageURL = String(business!.imageURL!)
        check.createdAt = NSDate()
        check.inputBillAmount = totalBillAmount
        check.totalTipAmount = tipPercent
        check.isTaxIncluded = isTaxEnabled
        check.partySize = currentPartySize!
        check.finalCheckAmount = totalCheckAmount
        
        //write the check object to db for persistence
        try! realmObject.write() {
            realmObject.add(check)
            print("Check saved.. check db for details")
            checkSavedAnimation()
        }
    }
    
    func checkSavedAnimation() {
        UIView.animateWithDuration(0.5, animations: {
            self.mainView.backgroundColor = UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)
            self.restaurantImageView.hidden = true
            self.hiddenMessageLabel.hidden = false
            self.yelpButton.hidden = true
            self.saveButton.hidden = true
        }) { (true) in
            UIView.animateWithDuration(1.5, animations: {
                self.mainView.backgroundColor = UIColor.whiteColor()
                }, completion: { (true) in
                    self.restaurantImageView.hidden = false
                    self.hiddenMessageLabel.hidden = true
                    self.yelpButton.hidden = false
                    self.saveButton.hidden = false
            })
        }
    }
    
    @IBAction func openRestaurantInYelp(sender: AnyObject) {
        notification.displayNotificationWithMessage("coming soon.", forDuration: 1.0)
    }
    
    @IBAction func historyNavigationBarButtonPressed(sender: AnyObject) {
      //  notification.displayNotificationWithMessage("coming soon.", forDuration: 1.0)
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
        YelpBusiness.searchWithTerm("", latitude: latitude, longitude: longitude, sort: .Distance, categories: [], deals: false, offset: nil, limit: 5) { (businesses: [YelpBusiness]!, error: NSError!) -> Void in
            
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

