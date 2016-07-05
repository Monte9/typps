//
//  ViewController.swift
//  typps
//
//  Created by Monte with Pillow on 7/4/16.
//  Copyright © 2016 Monte Thakkar. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, LocationServiceDelegate {
    
    var nearbyBusinesses: [YelpBusiness]! = [YelpBusiness]()
    var minDistance: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Delegate for LocationService
        LocationService.sharedInstance.delegate = self
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

