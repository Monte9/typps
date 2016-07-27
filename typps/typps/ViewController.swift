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
    
    //tip amount label position variables
    var tipAmountLabelCenter: CGFloat = 220
    var tipAmountLabelCenterMax: CGFloat = 0
    var tipAmountLabelCenterMin: CGFloat = 0
    var tipAmountLabelCenterStart: CGFloat = 0
    
    var nearbyBusinesses: [YelpBusiness]! = [YelpBusiness]()
    var minDistance: String?
    
    //split bill variables
    var splitBillMode : Bool = false
    var partySize: Int?
    var currentPartySize: Int?
    var fourPlusPartySize: Int?
    var partySizeDictionary: [Int:String] = [4: "four", 5: "five", 6: "six", 7: "seven", 8: "eight", 9: "nine"]
    
    let screenWidth = screenSize.width
    let screenHeight = screenSize.height
    
    @IBOutlet var mainView: UIView!

    //Outlets
    @IBOutlet weak var totalBillAmountTextField: UITextField!
    @IBOutlet weak var welcomeViewRestaurantImageView: UIImageView!
    @IBOutlet weak var welcomeViewRestaurantNameLabel: UILabel!
    @IBOutlet weak var restaurantImageView: UIImageView!
    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var resultsCountLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var totalBillAmountLabel: UILabel!
    @IBOutlet weak var splitTotalLabel: UILabel!
    @IBOutlet weak var hiddenMessageLabel: UILabel!
    
    //Tip View
    @IBOutlet weak var tipLabel: UILabel!
    @IBOutlet weak var tipAmountLabel: UILabel!
    @IBOutlet weak var tipPercentLabel: UILabel!
    @IBOutlet var tipPanGesture: UIPanGestureRecognizer!
    @IBOutlet var tipTapGesture: UITapGestureRecognizer!
    var tipLabelOrigin: CGFloat?
    var tipPercentLabelOrigin: CGFloat?
    var tipAmountLabelOrigin: CGFloat?
    
    //Views
    @IBOutlet weak var welcomeView: UIView!
    @IBOutlet weak var totalCheckAmountView: UIView!
    
    @IBOutlet weak var yelpButton: UIButton!
    
    @IBOutlet weak var tipView: UIView!
    
    var firstTouch = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Delegate for billAmountInput textField
        totalBillAmountTextField.delegate = self
        
        // Delegate for LocationService
        LocationService.sharedInstance.delegate = self
        
        //show loading indicator
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        tipPanGesture.delegate = self
        tipTapGesture.delegate = self
        
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
                //setPartySize(currentPartySize!)
            } else {
                self.currentPartySize = (settings.first?.currentPartySize)!
                //setPartySize(partySize!)
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
            setTaxView()
        }
        
        //checkTotalViewHeight = totalCheckAmountView.frame.size.height
        hiddenMessageLabel.hidden = true
        
        self.tipAmountLabel.hidden = false
        self.tipPercentLabel.hidden = false
        self.tipLabel.hidden = false
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tipLabel.superview!.setNeedsLayout()
        tipLabel.superview!.layoutIfNeeded()
        tipPercentLabel.superview?.setNeedsLayout()
        tipPercentLabel.superview?.layoutIfNeeded()
        
        // Now modify bottomView's frame here
        //self.tipAmountLabel.hidden = true
        tipLabelOrigin = self.tipLabel.center.x
        //self.tipLabel.center.x = self.tipLabel.center.x + 27
        tipPercentLabelOrigin = self.tipPercentLabel.center.x
        //self.tipPercentLabel.center.x = self.tipPercentLabel.center.x - 20
        self.tipAmountLabelOrigin = self.tipAmountLabel.center.x
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @IBAction func tipViewTapped(sender: UITapGestureRecognizer) {
        print(firstTouch)
        if (firstTouch) {
            UIView.animateWithDuration(0.5, animations: {
                self.tipLabel.center.x = 50
                self.tipPercentLabel.center.x = self.screenWidth - 37
                }, completion: {
                    (value: Bool) in
                    self.tipAmountLabel.hidden = false
            })
        } else {
            print("herE?")
            UIView.animateWithDuration(0.5, animations: {
                self.tipLabel.center.x = self.tipLabelOrigin!
                self.tipPercentLabel.center.x = self.tipPercentLabelOrigin!
                self.tipAmountLabel.center.x = self.tipAmountLabelOrigin!
                }, completion: {
                    (value: Bool) in
            })
        }
        firstTouch = !firstTouch
    }
    
    @IBAction func setTipAmountPanGesture(sender: UIPanGestureRecognizer) {
        self.view.endEditing(true)
        
        let translation: CGPoint = sender.translationInView(self.view)
        
        tipAmountLabelCenterMax = self.screenWidth - 80
        tipAmountLabelCenterMin = 105
        
        if (sender.state == UIGestureRecognizerState.Began) {
            self.tipPercentTapStart = self.tipPercent;
            self.tipAmountLabelCenterStart = self.tipAmountLabel.center.x
        } else if (sender.state == UIGestureRecognizerState.Changed) {
            
            self.tipLabel.center.x = 50
            self.tipPercentLabel.center.x = self.screenWidth - 37            
            
            //set the tipAmountLabel text based on pan gesture
            self.tipPercent = (self.tipPercentTapStart + Int(translation.x / 10))
            if (self.tipPercent > self.tipPercentMax) {
                self.tipPercent = self.tipPercentMax;
            } else if (self.tipPercent < self.tipPercentMin) {
                self.tipPercent = self.tipPercentMin;
            }
            
            //set the tipAmountLabel center based on pan gesture
            self.tipAmountLabelCenter = self.tipAmountLabelCenterStart + translation.x
            if (self.tipAmountLabelCenter > self.tipAmountLabelCenterMax) {
                self.tipAmountLabelCenter = self.tipAmountLabelCenterMax;
            } else if (self.tipAmountLabelCenter < self.tipAmountLabelCenterMin) {
                self.tipAmountLabelCenter = self.tipAmountLabelCenterMin;
            }
            self.tipAmountLabel.center.x = self.tipAmountLabelCenter
            self.tipAmountLabel.text = String(tipPercent)
//            // Extract attributes
//            let attributes = (tipAmountLabel.attributedText)!.attributesAtIndex(0, effectiveRange: nil)
//            tipAmountLabel.attributedText = NSAttributedString(string: String(tipPercent), attributes: attributes)
        } else if (sender.state == UIGestureRecognizerState.Ended) {
            firstTouch = false
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
                    
                    
                } else {
                    notification.displayNotificationWithMessage("invalid entry!", forDuration: 1.0)
                }
            }
        }
    }
    
    func updateTotalBillAmount(total:Float) {
           }
    
    @IBAction func welcomeViewTapped(sender: UITapGestureRecognizer) {
        //hide decimal pad
        self.view.endEditing(true)
    }
    
    
    @IBAction func taxViewTapped(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
        isTaxEnabled = !isTaxEnabled
        
       // setTaxView()
    }
    
    func setTaxView() {
       
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

