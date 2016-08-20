//
//  AppDelegate.swift
//  typs
//
//  Created by Monte Thakkar on 7/4/16.
//  Copyright © 2016 Monte Thakkar. All rights reserved.
//

import UIKit

//status bar notification
let notification = CWStatusBarNotification()

//used to check if location is enabled and perform referesh of current location
var isLocationEnabled: Bool? = true

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        //customize status bar notification
        notification.notificationLabelBackgroundColor = UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)
        notification.notificationLabelTextColor = UIColor.whiteColor()
        notification.notificationAnimationInStyle = CWNotificationAnimationStyle.Top
        notification.notificationAnimationOutStyle = CWNotificationAnimationStyle.Top

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        
        //Set location enabled flag to true
        //this is used in the case that they disallow location at first
        //but then they turn on location .. this enables the app to referesh and find the current location
        //once the user comes back into the app
        isLocationEnabled = true
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

