//
//  ViewController.swift
//  typps
//
//  Created by Monte with Pillow on 7/4/16.
//  Copyright © 2016 Monte Thakkar. All rights reserved.
//

import UIKit
import CoreLocation
import AudioToolbox
import MBProgressHUD

class ViewController: UIViewController, LocationServiceDelegate, UITextFieldDelegate {
    
    var currencyFormatter: NSNumberFormatter?
    
    //tip percent variables
    var isTaxEnabled: Bool = false
    var tipPercent: Int = 20
    let tipPercentMax: Int = 30
    let tipPercentMin: Int = 10
    var tipPercentTapStart: Int = 20
    
    //tip label position variables
    var tipLabelCenter: CGFloat = 220
    var tipLabelCenterMax: CGFloat = 0
    var tipLabelCenterMin: CGFloat = 0
    var tipLabelCenterStart: CGFloat = 0
    
    var nearbyBusinesses: [YelpBusiness]! = [YelpBusiness]()
    var minDistance: String?
    
    //split bill variables
    var splitBillMode = false
    
    //Outlets
    @IBOutlet weak var totalBillAmountTextField: UITextField!
    @IBOutlet weak var taxHintLabel: UILabel!
    @IBOutlet weak var tipAmountLabel: UILabel!
    @IBOutlet weak var welcomeViewRestaurantImageView: UIImageView!
    @IBOutlet weak var welcomeViewRestaurantNameLabel: UILabel!
    @IBOutlet weak var restaurantImageView: UIImageView!
    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var restaurantDistanceLabel: UILabel!
    @IBOutlet weak var resultsCountLabel: UILabel!
    @IBOutlet weak var splitTwoImageView: UIImageView!
    @IBOutlet weak var splitThreeImageView: UIImageView!
    @IBOutlet weak var splitFourPlusImageView: UIImageView!
    @IBOutlet weak var saveButton: UIButton!
    
    
    //Views
    @IBOutlet weak var welcomeView: UIView!
    @IBOutlet weak var taxView: UIView!
    @IBOutlet weak var tipView: UIView!
    @IBOutlet weak var splitTwoView: UIView!
    @IBOutlet weak var splitThreeView: UIView!
    @IBOutlet weak var splitFourPlusView: UIView!
    
    let notification = CWStatusBarNotification()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        totalBillAmountTextField.delegate = self
        
        // Delegate for LocationService
        LocationService.sharedInstance.delegate = self
        
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        //Fetch current location and find current restaurant/bar
        LocationService.sharedInstance.startUpdatingLocation()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        //Customize the navigation bar title and color
        let navigationBar = self.navigationController?.navigationBar
        
        //make navigation bar transparent
        navigationBar!.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationBar!.shadowImage = UIImage()
        navigationBar!.translucent = true
        
        //set navigation bar title with color
        navigationBar!.titleTextAttributes = [NSForegroundColorAttributeName : UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)]
        navigationItem.title = "typps"
        
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
        
        saveButton.layer.cornerRadius = 17
        
        //set totalBillAmountPlaceholder
        totalBillAmountTextField.text = "$"
        welcomeView.hidden = false
        
        taxHintLabel.text = "(off)"
        tipAmountLabel.text = String(tipPercent) + " %"
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
        
        if (isTaxEnabled) {
            taxView.backgroundColor = UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)
            taxHintLabel.text = "(tax included)"
            taxView.layer.cornerRadius = 60
        } else {
            taxView.backgroundColor = UIColor(red: 117/255, green: 124/255, blue: 121/255, alpha: 1)
            taxHintLabel.text = "(off)"
            taxView.layer.cornerRadius = 0
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
            
           // AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            
        } else if (sender.state == UIGestureRecognizerState.Changed) {
            
            //set the tipAmountLabel text based on pan gesture
            self.tipPercent = (self.tipPercentTapStart + Int(translation.x / 7))
            if (self.tipPercent > self.tipPercentMax) {
                self.tipPercent = self.tipPercentMax;
            } else if (self.tipPercent < self.tipPercentMin) {
                self.tipPercent = self.tipPercentMin;
            }
            tipAmountLabel.text = String(tipPercent) + " %"
            
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
        
        if (splitBillMode) {
            splitTwoImageView.image = UIImage(named: "two")
            splitBillMode = false
        } else {
            splitTwoImageView.image = UIImage(named: "two_selected")
            splitBillMode = true
        }
        
        
    }
    
    @IBAction func splitThreeViewTapped(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
        
        if (splitBillMode) {
            splitThreeImageView.image = UIImage(named: "three")
            splitBillMode = false
        } else {
            splitThreeImageView.image = UIImage(named: "three_selected")
            splitBillMode = true
        }
    }
    
    @IBAction func splitFourPlusViewTapped(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
        
        if (splitBillMode) {
            splitFourPlusImageView.image = UIImage(named: "four")
            splitBillMode = false
        } else {
            splitFourPlusImageView.image = UIImage(named: "four_selected")
            splitBillMode = true
        }
    }
    
    @IBAction func splitFourPlusViewLongTap(sender: UILongPressGestureRecognizer) {
        self.view.endEditing(true)
        splitFourPlusImageView.image = UIImage(named: "six_selected")
    }
    
    @IBAction func saveButtonPressed(sender: AnyObject) {
        self.notification.displayNotificationWithMessage("coming soon.", forDuration: 1.0)
    }
    
    @IBAction func openRestaurantInYelp(sender: AnyObject) {
        self.notification.displayNotificationWithMessage("coming soon.", forDuration: 1.0)
    }
    
    @IBAction func historyNavigationBarButtonPressed(sender: AnyObject) {
        self.notification.displayNotificationWithMessage("coming soon.", forDuration: 1.0)
    }
    
    @IBAction func settingsNavigationBarButtonPressed(sender: AnyObject) {
        self.notification.displayNotificationWithMessage("coming soon.", forDuration: 1.0)
    }
    
    func tracingLocation(currentLocation: CLLocation) {
        print("Starting yelp search with params: [food, \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)]")
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
                    self.restaurantImageView.setImageWithURL(business.imageURL!)
                    self.welcomeViewRestaurantImageView.setImageWithURL(business.imageURL!)
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

