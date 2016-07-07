//
//  ViewController.swift
//  typps
//
//  Created by Monte with Pillow on 7/4/16.
//  Copyright © 2016 Monte Thakkar. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, LocationServiceDelegate, UITextFieldDelegate {
    
    var nearbyBusinesses: [YelpBusiness]! = [YelpBusiness]()
    var minDistance: String?
    
    var currencyFormatter: NSNumberFormatter?
    
    @IBOutlet weak var totalBillAmountTextField: UITextField!
    @IBOutlet weak var taxHintLabel: UILabel!
    
    //Views
    @IBOutlet weak var welcomeView: UIView!
    @IBOutlet weak var taxView: UIView!
    
    var isTaxEnabled: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        taxHintLabel.text = "(off)"
        
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
        print("Change detected")
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
        isTaxEnabled = !isTaxEnabled
        
        if (isTaxEnabled) {
            taxView.backgroundColor = UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)
            taxHintLabel.text = "(tax included)"
        } else {
            taxView.backgroundColor = UIColor(red: 117/255, green: 124/255, blue: 121/255, alpha: 1)
            taxHintLabel.text = "(off)"
        }
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
        YelpBusiness.searchWithTerm("", latitude: 37.8480965, longitude: -122.48114370000002, sort: .Distance, categories: [], deals: false, offset: nil, limit: 5) { (businesses: [YelpBusiness]!, error: NSError!) -> Void in
            
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

