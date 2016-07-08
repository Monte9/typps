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

class ViewController: UIViewController, LocationServiceDelegate, UITextFieldDelegate {
    
    var nearbyBusinesses: [YelpBusiness]! = [YelpBusiness]()
    var minDistance: String?
    
    var currencyFormatter: NSNumberFormatter?
    
    @IBOutlet weak var totalBillAmountTextField: UITextField!
    @IBOutlet weak var taxHintLabel: UILabel!
    @IBOutlet weak var tipAmountLabel: UILabel!
    
    //Views
    @IBOutlet weak var welcomeView: UIView!
    @IBOutlet weak var taxView: UIView!
    @IBOutlet weak var tipView: UIView!
    
    var isTaxEnabled: Bool = false
    var tipPercent: Int = 20
    let tipPercentMax: Int = 30
    let tipPercentMin: Int = 10
    var tipPercentTapStart: Int = 20
    
    var tipLabelCenter: CGFloat = 220
    var tipLabelCenterMax: CGFloat = 0
    var tipLabelCenterMin: CGFloat = 0
    var tipLabelCenterStart: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        taxHintLabel.text = "(off)"
        tipAmountLabel.text = String(tipPercent) + " %"
        
        totalBillAmountTextField.delegate = self
        
        // Delegate for LocationService
        LocationService.sharedInstance.delegate = self
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
        
        //set totalBillAmountPlaceholder
        totalBillAmountTextField.text = "$"
        welcomeView.hidden = false
        
    }
    
    @IBAction func textFieldDidChange(sender: AnyObject) {
        if (totalBillAmountTextField.text == "") {
            totalBillAmountTextField.text = "$"
            welcomeView.hidden = false
        }
        
        if (totalBillAmountTextField.text == "$") {
            welcomeView.hidden = false
        }
        
        if (totalBillAmountTextField.text != "$") {
            welcomeView.hidden = true
        }
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
            self.tipPercent = (self.tipPercentTapStart + Int(translation.x / 10))
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
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true);
        return false;
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    @IBAction func getMyLocationButton(sender: AnyObject) {
        print("Getting my location now..")
        LocationService.sharedInstance.startUpdatingLocation()
    }
    
    func tracingLocation(currentLocation: CLLocation) {
        print(currentLocation.coordinate.latitude)
        print(currentLocation.coordinate.longitude)
        startYelpSearch("food", latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
        LocationService.sharedInstance.stopUpdatingLocation()
    }
    
    func tracingLocationDidFailWithError(error: NSError) {
        print("Location produced error: \(error)")
    }
    
    func startYelpSearch(term: String, latitude: NSNumber?, longitude: NSNumber?) {
        print("starting yelp search now..")
        
        //Example of Yelp search with more search options specified
        YelpBusiness.searchWithTerm("", latitude: latitude, longitude: longitude, sort: .Distance, categories: [], deals: false, offset: nil, limit: 5) { (businesses: [YelpBusiness]!, error: NSError!) -> Void in
            
            if (businesses != nil) {
                self.minDistance = businesses.first?.distance

                print("Got results")
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
            
            for business in self.nearbyBusinesses {
                print(business.name!)
                print(business.address!)
                print(business.distance)
                print(business.latitude)
                print(business.longitude)
            }
            print(self.nearbyBusinesses.count)
        }
    }
    
}

