//
//  ViewController.swift
//  typs
//
//  Created by Monte Thakkar on 7/4/16.
//  Copyright © 2016 Monte Thakkar. All rights reserved.
//

import UIKit
import CoreLocation
import MBProgressHUD
import RealmSwift
import Realm
import AudioToolbox
import SnapKit

//used to check if either history or settings tab was opened
var didOpenSecondaryView: Bool?

class ViewController: UIViewController, LocationServiceDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    // instance of Realm object
    let realmObject = try! Realm()
    
    //restaurants returned from yelp search (Yelp Business model class array)
    var nearbyBusinesses: [YelpBusiness]! = [YelpBusiness]()
    
    //min distance of restuarants from current location
    var minDistance: String?
    
    //Yelp Business model class variable (restaurant at current location)
    var business: YelpBusiness?
    
    //variable to check if the location failed (no current location available)
    var locationError: Bool? = false
    
    //tip percent variables
    var isTaxEnabled: Bool = false
    var tipPercent: Int = 20
    let tipPercentMax: Int = 30
    let tipPercentMin: Int = 10
    var tipPercentTapStart: Int = 20
    
    //check & bill amount variables
    var totalBillAmount: Float = 0
    var totalCheckAmount: Float = 0
    
    //tip label position variables
    var tipLabelCenter: CGFloat = 220
    var tipLabelCenterMax: CGFloat = 0
    var tipLabelCenterMin: CGFloat = 0
    var tipLabelCenterStart: CGFloat = 0
    
    //split bill variables
    var splitBillMode: Bool = false
    var partySize: Int?
    var currentPartySize: Int?
    
    //Variables for controlsView actions
    var firstTouchForTaxView: Bool = true
    var firstTouchForTipView: Bool = true
    var firstTouchForPartySizeView: Bool = true
    
    //party size dictionaries with values as names of images to display
    var partySizeDictionary: [Int:String] = [1: "pika", 2: "two", 3: "three", 4: "four", 5: "five", 6: "six", 7: "seven", 8: "eight", 9: "nine"]
    var selectedPartySizeDescriptionDictionary: [Int:String] = [1: "I am here for you!", 2: "Is it a date?", 3: "Who's the third wheel?", 4: "Like a pack of friends", 5: "The five horsemen", 6: "1..2..3..4..5..6", 7: "Seven 11", 8: "Eight sounds fun", 9: "That's too many"]
    
    //Main UIView
    @IBOutlet var mainView: UIView!
    
    //Views
    @IBOutlet weak var welcomeView: UIView!
    
    //Controls View -> Tip, tax, party size, total check amount views
    @IBOutlet weak var controlsView: UIView!
    
    //Views within controlsView
    @IBOutlet weak var taxView: UIView!
    @IBOutlet weak var partySizeView: UIView!
    @IBOutlet weak var tipView: UIView!
    @IBOutlet weak var buttonTaxView: UIView!
    @IBOutlet weak var totalCheckAmountView: UIView!
    
    //Outlets within controlsView
    @IBOutlet weak var taxLabel: UILabel!
    @IBOutlet weak var partySizeImageView: UIImageView!
    @IBOutlet weak var partySizeDescriptionLabel: UILabel!
    @IBOutlet weak var tipAmountLabel: UILabel!
    @IBOutlet weak var tipPercentLabel: UILabel!
    @IBOutlet weak var TipNameLabel: UILabel!
    @IBOutlet weak var totalCheckAmountLabel: UILabel!
    @IBOutlet weak var eachPersonCheckAmountLabel: UILabel!
    
    //Gesture recognizers for controlsView
    @IBOutlet var setTipAmountPanGesture: UIPanGestureRecognizer!
    @IBOutlet var tipViewTapGesture: UITapGestureRecognizer!
    
    //Outlets
    @IBOutlet weak var totalBillAmountTextField: UITextField!
    @IBOutlet weak var welcomeViewRestaurantImageView: UIImageView!
    @IBOutlet weak var welcomeViewRestaurantNameLabel: UILabel!
    @IBOutlet weak var restaurantImageView: UIImageView!
    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var resultsCountLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var checkSavedMessageLabel: UILabel!
    @IBOutlet weak var loggerView: UIView!
    @IBOutlet weak var enableLocationView: UIView!
    @IBOutlet weak var yelpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Delegate for billAmountInput textField
        totalBillAmountTextField.delegate = self
        
        // Delegate for tipAmount Pan gesture
        setTipAmountPanGesture.delegate = self
        
        // Delegate for tipView Tap gesture
        tipViewTapGesture.delegate = self
        
        // Delegate for LocationService
        LocationService.sharedInstance.delegate = self
        
        //Update location from LocationService
        LocationService.sharedInstance.startUpdatingLocation()
        
        //handle settings; get and set settings or initialize and save new settings object
        handleSettingsFromRealmDB()
        
//DEBUG ONLY
        //prints the current path for realm db to view it
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        
        //Get navigation bar to cutomize the title and color
        let navigationBar = self.navigationController?.navigationBar
        
        //make navigation bar transparent
        navigationBar!.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationBar!.shadowImage = UIImage()
        navigationBar!.translucent = true
        
        //set navigation bar title with color
        navigationItem.title = "typs"
        navigationBar!.titleTextAttributes = [NSForegroundColorAttributeName : UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)]
        
        
        //add gesture recognizers for single to toggle party size
        let togglePartySizeTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.togglePartySizeTapGesture))
        togglePartySizeTapGesture.numberOfTapsRequired = 1
        self.partySizeView.addGestureRecognizer(togglePartySizeTapGesture)
        togglePartySizeTapGesture.delegate = self
        
        //add gesture recognizers for double tap to select party size
        let selectPartySizeDoubleTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.selectPartySizeDoubleTapGesture))
        selectPartySizeDoubleTapGesture.numberOfTapsRequired = 2
        self.partySizeView.addGestureRecognizer(selectPartySizeDoubleTapGesture)
        selectPartySizeDoubleTapGesture.delegate = self
        
        //allows single and double tap on the same partySizeImageView
        togglePartySizeTapGesture.requireGestureRecognizerToFail(selectPartySizeDoubleTapGesture)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        //remake label constraints to setup the Controls View
        self.remakeLabelConstraintsToSetupControlsView()
        
        //if settings is saved; then get the new settings from the realm object in the db
        getNewSettingsFromDB()
        
        //if settings is saved then set tipPercent, tax and partySize label values appropriately
        if (settingsSaved == true) {
            setupLabelValuesFromSettings()
        } else {
            resetPartySizeLabelAndValues()
        }
        
        //add rounded edges to restaurantImageView
        restaurantImageView.layer.cornerRadius = 5
        restaurantImageView.clipsToBounds = true
        welcomeViewRestaurantImageView.layer.cornerRadius = 5
        welcomeViewRestaurantImageView.clipsToBounds = true
        
        //add corner radius to saveButton
        saveButton.layer.cornerRadius = 17
        
        //show welcomeView based on whether history or settings tab was opened
        if (didOpenSecondaryView == true) {
            if (totalBillAmountTextField.text != "$" && totalBillAmountTextField.text != "") {
                welcomeView.hidden = true
            }
        } else {
            //set totalBillAmountPlaceholder
            totalBillAmountTextField.text = "$"
            welcomeView.hidden = false
        }
        
        //hide the checkSavedMessage label initially
        checkSavedMessageLabel.hidden = true
        
    }
    
    override func viewDidAppear(animated: Bool) {
        //start off new threads to things that would take a long time to execute, 
        //for example doing a webservice call to get extra data for the form above.
        //The good thing is that because the view already exists and is being displayed to the user, 
        //you can show a nice "Waiting" message to the user while you get the data.
    }
    
    func handleSettingsFromRealmDB() {
        
        //fetch settings object from realm db
        let settings = realmObject.objects(Settings)
        
        //check if settings already exists
        if settings.first == nil {
            
            //since settings does not exist.. it is a new user
            //initialize with default values
            self.isTaxEnabled = false
            self.tipPercent = 20
            self.partySize = 1
            self.currentPartySize = 1
            
            //create and initialize new settings object
            let newSettings = Settings()
            newSettings.isTaxEnabled = self.isTaxEnabled
            newSettings.tipPercent = self.tipPercent
            newSettings.partySize = self.partySize!
            newSettings.currentPartySize = self.currentPartySize!
            
            //write the settings object to db for persistence
            try! realmObject.write() {
                realmObject.add(newSettings)
                
                //set settingsSaved flag to set the appropriate values for the labels
                settingsSaved = true

//DEBUG ONLY
                print("New user detected! Created new settings object in Realm with default values")
                debugModeOutput("Created new settings object in Realm with default values in ViewDidLoad()")
            }
        } else {
            //found setttings.. hence get the values and initialize our instance variables for use
            self.isTaxEnabled = (settings.first?.isTaxEnabled)!
            self.tipPercent = (settings.first?.tipPercent)!
            self.partySize = (settings.first?.partySize)!
            self.currentPartySize = partySize
            
            //set settingsSaved flag to set the appropriate values for the labels
            settingsSaved = true
            
//DEBUG ONLY
            debugModeOutput("Found Settings from Realm persistence object in ViewDidLoad()")
        }
    }
    
    func getNewSettingsFromDB() {
        
        //fetch settings object from realm db
        let settings = realmObject.objects(Settings)
        
        if(settingsSaved == true) {
            //found setttings.. hence get the values and initialize our instance variables for use
            self.isTaxEnabled = (settings.first?.isTaxEnabled)!
            self.tipPercent = (settings.first?.tipPercent)!
            self.partySize = (settings.first?.partySize)!
            self.currentPartySize = partySize
            
            //set settingsSaved flag to set the appropriate values for the labels
            settingsSaved = true
            
            //DEBUG ONLY
            debugModeOutput("Get the new saved setting from Realm persistence object in ViewWillAppear()")
        }
    }
    
    func remakeLabelConstraintsToSetupControlsView() {
        let superview = self.view
        
        print("****Setting up label constraints in the controlsView")
        
        //change font size
        self.TipNameLabel.font = self.TipNameLabel.font.fontWithSize(50)
        self.tipPercentLabel.font = self.tipPercentLabel.font.fontWithSize(50)
        self.tipAmountLabel.font = self.tipAmountLabel.font.fontWithSize(50)
        
        //make constraints for labels
        self.tipAmountLabel.snp_remakeConstraints { (make) in
            make.centerX.equalTo(superview).offset(17)
        }
        self.TipNameLabel.snp_remakeConstraints { (make) in
            make.centerX.equalTo(superview).offset(-57.5)
        }
        self.tipPercentLabel.snp_remakeConstraints { (make) in
            make.centerX.equalTo(superview).offset(72)
        }
        
        self.totalCheckAmountLabel.snp_remakeConstraints { (make) in
            make.centerX.equalTo(superview).offset(0)
            make.centerY.equalTo(superview).offset(150)
        }
        self.eachPersonCheckAmountLabel.snp_remakeConstraints { (make) in
            make.centerX.equalTo(superview).offset(0)
            make.centerY.equalTo(superview).offset(150)
        }
        
        //hide eachPersonCheckAmountLabel as party size is still 1
        self.eachPersonCheckAmountLabel.hidden = true
    }
    
    func setupLabelValuesFromSettings() {
        
        print("****Setting up label values from Settings Object")
        
        //set tipAmountLabel text
        tipAmountLabel.text = String(tipPercent)
        
        //set the taxLabel text
        if (isTaxEnabled) {
            self.taxLabel.text = "Tax ON"
            self.taxLabel.textColor = UIColor.whiteColor()
            self.buttonTaxView.backgroundColor = UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha:
                1)
            self.buttonTaxView.layer.cornerRadius = 10
        } else {
            self.taxLabel.text = "Tax OFF"
            self.taxLabel.textColor = UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)
            self.buttonTaxView.backgroundColor = UIColor.whiteColor()
        }
        
        resetPartySizeLabelAndValues()
        
        //updateTotalBillAmount based on the set label values
        updateTotalBillAmount(totalBillAmount * Float(Float(tipPercent)/100) + totalBillAmount)
    }
    
    func resetPartySizeLabelAndValues() {
        
        //set the partySizeImageView image and description from dictionaries
        let partySizeImageName: String = partySizeDictionary[self.partySize!]!
        let selectedPartySizeImageName = partySizeImageName
        self.partySizeImageView.image = UIImage(named: selectedPartySizeImageName)
        let selectedPartySizeDescription: String = selectedPartySizeDescriptionDictionary[self.partySize!]!
        self.partySizeDescriptionLabel.text = "Double tap to confirm party size"
        
        //reset to default totalCheckAmountLabel posititon and deselect the partySizeImageView
        if (splitBillMode == true && partySize != 1) {
            endAnimatingTotalCheckAmountLabel()
        }
        
        //set the splitBillMode flag to false to indicate that partySize is not selected yet
        splitBillMode = false
        
        //set firstTouchForPartySizeView to true to toggle partySize with single tap
        firstTouchForPartySizeView = true
    }
    
    @IBAction func mainViewDismissKeyboard(sender: UITapGestureRecognizer) {
        //tap gesture on the main view to dismiss keyboard if tapped anywhere
        self.view.endEditing(true)
    }
    
    @IBAction func textFieldDidChange(sender: AnyObject) {
        //first point of entry in the app
        
        //gets the user input for the totalBill Amount Input field
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
        
        var finalAmount = total
        
        if (isTaxEnabled) {
            finalAmount = total + (total * 0.0875)
        } else {
            finalAmount = total
        }
        
        finalAmount = ceil(finalAmount)
        
        if(currentPartySize == nil) {
            currentPartySize = partySize
        }
        
        if(finalAmount > 0) {
            self.eachPersonCheckAmountLabel.text = "$\(ceil(finalAmount/Float(currentPartySize!))) each"
            self.totalCheckAmountLabel.text = "total $\(finalAmount)"
        } else {
            self.eachPersonCheckAmountLabel.text = "$ 0 each"
            self.totalCheckAmountLabel.text = "total $0"
        }
        
    }
    
    @IBAction func taxViewTapGesture(sender: UITapGestureRecognizer) {
        //hide decimal pad
        self.view.endEditing(true)
        
        if (firstTouchForTaxView) {
            self.taxLabel.text = "Tax ON"
            self.taxLabel.textColor = UIColor.whiteColor()
            self.buttonTaxView.backgroundColor = UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha:
                1)
            self.buttonTaxView.layer.cornerRadius = 10
            isTaxEnabled = true
            self.updateTotalBillAmount(self.totalCheckAmount)
        } else {
            self.taxLabel.text = "Tax OFF"
            self.taxLabel.textColor = UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)
            self.buttonTaxView.backgroundColor = UIColor.whiteColor()
            isTaxEnabled = false
            self.updateTotalBillAmount(self.totalCheckAmount)
        }
        
        //toggle first touch for tax view
        firstTouchForTaxView = !firstTouchForTaxView
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        let touchLocation = touch.locationInView(self.partySizeView)
        return !CGRectContainsPoint(self.partySizeDescriptionLabel.frame, touchLocation)
    }
    
    @IBAction func togglePartySizeTapGesture(sender: UITapGestureRecognizer) {
        //hide decimal pad
        self.view.endEditing(true)
        
        var nextPartySize = self.currentPartySize! + 1
        
        if (nextPartySize > 9) {
            nextPartySize = 1
        }
        
        let partySizeImageName: String = partySizeDictionary[nextPartySize]!
        self.partySizeImageView.image = UIImage(named: partySizeImageName)
        
        self.partySizeDescriptionLabel.text = "Select Party Size"
        
        //save the partySize
        currentPartySize! = nextPartySize
        
        if (splitBillMode == true && partySize != 1) {
            endAnimatingTotalCheckAmountLabel()
        }
        
        splitBillMode = false
        firstTouchForPartySizeView = false
    }
    
    @IBAction func selectPartySizeDoubleTapGesture(sender: UITapGestureRecognizer) {
        //hide decimal pad
        self.view.endEditing(true)
        
        firstTouchForPartySizeView = true
        
        let partySizeImageName: String = partySizeDictionary[self.currentPartySize!]!
        let selectedPartySizeImageName = partySizeImageName + "_selected"
        
        if (firstTouchForPartySizeView) {
            self.partySizeImageView.image = UIImage(named: selectedPartySizeImageName)
            
            let selectedPartySizeDescription: String = selectedPartySizeDescriptionDictionary[self.currentPartySize!]!
            self.partySizeDescriptionLabel.text = selectedPartySizeDescription
        } else {
            self.partySizeImageView.image = UIImage(named: partySizeImageName)
            
            self.partySizeDescriptionLabel.text = "Select Party Size"
        }
        
        if (splitBillMode == false && currentPartySize! != 1) {
            beginAnimatingTotalCheckAmountLabel()
        }
        
        partySize = currentPartySize
        splitBillMode = true
    }
    
    @IBAction func setTipAmountPanGesture(sender: UIPanGestureRecognizer) {
        //hide decimal pad
        self.view.endEditing(true)
        
        var point = sender.locationInView(view)
        var velocity = sender.velocityInView(view)
        var translation = sender.translationInView(view)
        
        let parentView = sender.view
        tipLabelCenterMax = (parentView?.frame.width)! - 95
        tipLabelCenterMin = 110
        
        var ticks = (parentView?.frame.width)! - 175
        
        if sender.state == UIGestureRecognizerState.Began {
            self.tipPercentTapStart = self.tipPercent;
            
            self.tipLabelCenterStart = self.tipAmountLabel.center.x
            
            if (firstTouchForTipView) {
                beginAnimatingTipView(self.view)
            }
        } else if sender.state == UIGestureRecognizerState.Changed {
            //set the tipAmountLabel text based on pan gesture
            self.tipPercent = (self.tipPercentTapStart + Int(translation.x / 9))
            if (self.tipPercent > self.tipPercentMax) {
                self.tipPercent = self.tipPercentMax;
            } else if (self.tipPercent < self.tipPercentMin) {
                self.tipPercent = self.tipPercentMin;
            }
            firstTouchForTipView = false
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
            firstTouchForTipView = true
        }
        updateTotalBillAmount(totalBillAmount * Float(Float(tipPercent)/100) + totalBillAmount)
    }
    
    @IBAction func tipViewTapGesture(sender: UITapGestureRecognizer) {
        //hide decimal pad
        self.view.endEditing(true)
        
        let superview = self.view
        
        if (firstTouchForTipView) {
            beginAnimatingTipView(superview)
        } else {
            endAnimatingTipView(superview)
        }
        
        firstTouchForTipView = !firstTouchForTipView
    }
    
    func beginAnimatingTipView(superview: UIView) {
        let availableDistance = tipLabelCenterMax - tipLabelCenterMin
        
        let displacement = CGFloat(tipPercent - 20) * (availableDistance/30)
        
        UIView.animateWithDuration(0.3, animations: {
            self.tipAmountLabel.center.x = superview.center.x + CGFloat(displacement)
            self.tipPercentLabel.center.x = superview.frame.width - 30
            self.TipNameLabel.center.x = 50
            
            //change font size
            self.TipNameLabel.transform = CGAffineTransformScale(self.TipNameLabel.transform, self.getTransformScale(50, newFontSize: 65), self.getTransformScale(50.0, newFontSize: 65))
            self.tipPercentLabel.transform = CGAffineTransformScale(self.tipPercentLabel.transform, self.getTransformScale(50, newFontSize: 65), self.getTransformScale(50.0, newFontSize: 65))
            self.tipAmountLabel.transform = CGAffineTransformScale(self.tipAmountLabel.transform, self.getTransformScale(50, newFontSize: 32.5), self.getTransformScale(50.0, newFontSize: 32.5))
        })
    }
    
    func getTransformScale(oldFontSize: Float, newFontSize: Float) -> CGFloat {
        let oldFont = oldFontSize
        let newFont = newFontSize
        
        let labelScale = oldFontSize / newFontSize
        return CGFloat(labelScale)
    }
    
    func endAnimatingTipView(superview: UIView) {
        UIView.animateWithDuration(0.5, animations: {
            //change font size
            self.TipNameLabel.transform = CGAffineTransformScale(self.TipNameLabel.transform, self.getTransformScale(65, newFontSize: 50), self.getTransformScale(65, newFontSize: 50))
            self.tipPercentLabel.transform = CGAffineTransformScale(self.tipPercentLabel.transform, self.getTransformScale(65, newFontSize: 50), self.getTransformScale(65, newFontSize: 50))
            self.tipAmountLabel.transform = CGAffineTransformScale(self.tipAmountLabel.transform, self.getTransformScale(32.5, newFontSize: 50), self.getTransformScale(32.5, newFontSize: 50))
            
            self.tipAmountLabel.center.x = superview.center.x + 17
            self.tipPercentLabel.center.x = superview.center.x + 72
            self.TipNameLabel.center.x = superview.center.x - 57.5
        })
    }
    
    func beginAnimatingTotalCheckAmountLabel() {
        let parentView = self.totalCheckAmountView
        
        UIView.animateWithDuration(0.5, animations: {
            //change font size
            self.totalCheckAmountLabel.transform = CGAffineTransformScale(self.totalCheckAmountLabel.transform, self.getTransformScale(30, newFontSize: 60), self.getTransformScale(30, newFontSize: 60))
            
            self.totalCheckAmountLabel.center.x = 70
            self.totalCheckAmountLabel.center.y = 20
            self.updateTotalBillAmount(self.totalCheckAmount)
            
        }) { (true) in
            self.eachPersonCheckAmountLabel.hidden = false
        }
    }
    
    func endAnimatingTotalCheckAmountLabel() {
        let parentView = self.totalCheckAmountView
        let superview = self.view
        
        UIView.animateWithDuration(0.5, animations: {
            //change font size
            self.totalCheckAmountLabel.transform = CGAffineTransformScale(self.totalCheckAmountLabel.transform, self.getTransformScale(60, newFontSize: 30), self.getTransformScale(60, newFontSize: 30))
            
            self.totalCheckAmountLabel.center.x = (parentView?.frame.width)! / 2
            self.totalCheckAmountLabel.center.y = 40
            
            self.eachPersonCheckAmountLabel.hidden = true
        })
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
        
        if (currentPartySize == partySize) {
            check.partySize = currentPartySize!
        } else {
            check.partySize = 1
        }
        
        var finalAmount = totalCheckAmount
        
        if (isTaxEnabled) {
            finalAmount = totalCheckAmount + (totalCheckAmount * 0.0875)
        } else {
            finalAmount = totalCheckAmount
        }
        check.finalCheckAmount = ceil(finalAmount)
        
        
        //write the check object to db for persistence
        try! realmObject.write() {
            realmObject.add(check)
            print("Check saved.. check db for details")
            checkSavedAnimation()
        }
    }
    
    func checkSavedAnimation() {
        UIView.animateWithDuration(1.0, animations: {
            self.mainView.backgroundColor = UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)
            self.restaurantImageView.hidden = true
            self.yelpButton.hidden = true
            self.saveButton.hidden = true
            self.partySizeDescriptionLabel.hidden = true
            self.partySizeImageView.hidden = true
            self.taxView.hidden = true
        }) { (true) in
            UIView.animateWithDuration(1.0, animations: {
                self.checkSavedMessageLabel.hidden = false
                }, completion: { (true) in
                    UIView.animateWithDuration(1.5, animations: {
                        self.checkSavedMessageLabel.alpha = 0.0
                        }, completion: { (true) in
                            UIView.animateWithDuration(1.0, animations: { 
                                self.mainView.backgroundColor = UIColor.whiteColor()
                                }, completion: { (true) in
                                    self.restaurantImageView.hidden = false
                                    self.yelpButton.hidden = false
                                    self.saveButton.hidden = false
                                    self.taxView.hidden = false
                                    self.partySizeDescriptionLabel.hidden = false
                                    self.partySizeImageView.hidden = false
                            })
                    })
            })
        }
        self.checkSavedMessageLabel.alpha = 1.0
    }
    
    @IBAction func openRestaurantInYelp(sender: AnyObject) {
        notification.displayNotificationWithMessage("coming soon.", forDuration: 1.0)
    }
    
    @IBAction func historyNavigationBarButtonPressed(sender: AnyObject) {
      //  notification.displayNotificationWithMessage("coming soon.", forDuration: 1.0)
    }
    
    @IBAction func launchSettingsToEnableLocation(sender: UITapGestureRecognizer) {
        UIApplication.sharedApplication().openURL(NSURL(string:"prefs:root=LOCATION_SERVICES")!)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func tracingLocation(currentLocation: CLLocation) {
       // print("Starting yelp search with params: [food, \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)]")
        
        //show loading indicator
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        self.enableLocationView.hidden = true
        self.loggerView.hidden = false
        startYelpSearch("food", latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
        LocationService.sharedInstance.stopUpdatingLocation()
    }
    
    func tracingLocationDidFailWithError(error: NSError) {
        print("Location produced error: \(error)")
        self.locationError = true
        self.loggerView.hidden = true
        self.enableLocationView.hidden = false
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
                
                print(self.nearbyBusinesses.count)
                
                for business in self.nearbyBusinesses {
                    if let imageURL = business.imageURL {
                        self.restaurantImageView.setImageWithURL(imageURL)
                        self.welcomeViewRestaurantImageView.setImageWithURL(imageURL)
                    }
                    self.restaurantNameLabel.text = business.name
                    self.welcomeViewRestaurantNameLabel.text = business.name
                    
                    // Hide HUD once network request comes back (must be done on main UI thread)
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                }
            }
        }
    }
    
    func debugModeOutput(origin: String) {
        print()
        print("************DEBUG MODE: \(origin)")
        print("isTaxEnabled: \(isTaxEnabled)")
        print("tipPercent: \(tipPercent)")
        print("partySize: \(partySize)")
        print("currentPartySize: \(currentPartySize)")
        print("END DEBUG MODE************")
        print()
    }
    
}

