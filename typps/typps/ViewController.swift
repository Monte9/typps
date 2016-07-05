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
        LocationService.sharedInstance.stopUpdatingLocation()
    }
    
    func tracingLocationDidFailWithError(error: NSError) {
        print("Location produced error: \(error)")
    }

}

