//
//  SettingsViewController.swift
//  
//
//  Created by Monte with Pillow on 7/9/16.
//
//

import UIKit
import RealmSwift
import Realm
import AudioToolbox

var settingsCancelled: Bool?

class SettingsViewController: UIViewController {
    
    // instance of Realm object
    let realmObject = try! Realm()

    var isTaxEnabled: Bool?
    var partySize: Int?
    var tipPercent: Int?
    var currentPartySize: Int?
    
    var tipPercentTapStart: Int?
    var tipPercentMax = 30
    var tipPercentMin = 10
    var partySizeTapStart: Int?
    var partySizeMax = 9
    var partySizeMin = 1
    var partySizeFontSize: CGFloat?
    
    @IBOutlet weak var taxIncludedView: UIView!
    
    @IBOutlet weak var tipPercentLabel: UILabel!
    @IBOutlet weak var partySizeLabel: UILabel!
    @IBOutlet weak var taxIncludedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        didOpenSecondaryView = true
    }
    
    override func viewWillAppear(animated: Bool) {
        //Customize the navigation bar title and color
        let navigationBar = self.navigationController?.navigationBar
        
        //make navigation bar transparent
        navigationBar!.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationBar!.shadowImage = UIImage()
        navigationBar!.translucent = true
        
        //set navigation bar title with color
        navigationItem.title = "settings"
        navigationBar!.titleTextAttributes = [NSForegroundColorAttributeName : UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)]
        
        let settings = realmObject.objects(Settings)
        self.tipPercent = (settings.first?.tipPercent)!
        self.isTaxEnabled = (settings.first?.isTaxEnabled)!
        self.partySize = (settings.first?.partySize)!
        
        tipPercentLabel.text = String(tipPercent!) + " %"
        partySizeLabel.text = String(partySize!)
        
        partySizeFontSize = CGFloat(50 * partySize!)
        self.partySizeLabel.font = self.partySizeLabel.font.fontWithSize(partySizeFontSize!)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        taxIncludedView.superview!.setNeedsLayout()
        taxIncludedView.superview!.layoutIfNeeded()
        
        // Now modify bottomView's frame here
        
        setTaxIncludeView()
    }
    
    @IBAction func cancelBarButtonPressed(sender: AnyObject) {
        settingsCancelled = true
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func saveSettings(sender: AnyObject) {
        
        //save settings Object for persistence
        let settings = realmObject.objects(Settings.self)
        try! realmObject.write {
            settings.first?.setValue(isTaxEnabled, forKeyPath: "isTaxEnabled")
            settings.first?.setValue(partySize, forKeyPath: "partySize")
            settings.first?.setValue(partySize, forKeyPath: "currentPartySize")
            settings.first?.setValue(tipPercent, forKeyPath: "tipPercent")
            print("Settings updated")
            settingsCancelled = false
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    
    @IBAction func tipPercentViewPanGesture(sender: UIPanGestureRecognizer) {
    
        let translation: CGPoint = sender.translationInView(self.view)
        
        if (sender.state == UIGestureRecognizerState.Began) {
            
            self.tipPercentTapStart = self.tipPercent;
            // AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            
        } else if (sender.state == UIGestureRecognizerState.Changed) {
            
            //set the tipAmountLabel text based on pan gesture
            self.tipPercent = (self.tipPercentTapStart! - Int(translation.y / 15))
            if (self.tipPercent > self.tipPercentMax) {
                self.tipPercent = self.tipPercentMax;
            } else if (self.tipPercent < self.tipPercentMin) {
                self.tipPercent = self.tipPercentMin;
            }
            tipPercentLabel.text = String(tipPercent!) + " %"
        }
        
    }
    
    @IBAction func partySizeViewPanGesture(sender: UIPanGestureRecognizer) {
        
        let translation: CGPoint = sender.translationInView(self.view)
        
        if (sender.state == UIGestureRecognizerState.Began) {
            
            self.partySizeTapStart = self.partySize;
            // AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            
        } else if (sender.state == UIGestureRecognizerState.Changed) {
            
            //set the tipAmountLabel text based on pan gesture
            self.partySize = (self.partySizeTapStart! + Int(translation.y / 20))
            if (self.partySize > self.partySizeMax) {
                self.partySize = self.partySizeMax;
            } else if (self.partySize < self.partySizeMin) {
                self.partySize = self.partySizeMin;
            }
            partySizeLabel.text = String(partySize!)
            
            partySizeFontSize = CGFloat(50 * partySize!)
            self.partySizeLabel.font = self.partySizeLabel.font.fontWithSize(partySizeFontSize!)
        }
        
    }
    
    @IBAction func taxIncludedTapGesture(sender: UITapGestureRecognizer) {
        
        if (isTaxEnabled == true) {
            UIView.animateWithDuration(0.5, animations: {
                self.taxIncludedView.layer.position.x = self.taxIncludedView.layer.position.x - 120
                }, completion: {
                    (value: Bool) in
                    self.taxIncludedView.backgroundColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)
                    self.taxIncludedView.layer.cornerRadius = 0
                    self.taxIncludedLabel.text = "off"
                    self.isTaxEnabled = false
            })
        } else {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            UIView.animateWithDuration(0.5, animations: {
                self.taxIncludedView.layer.position.x = self.taxIncludedView.layer.position.x + 120
                }, completion: {
                    (value: Bool) in
                    self.taxIncludedView.backgroundColor = UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)
                    self.taxIncludedView.layer.cornerRadius = 30
                    self.taxIncludedLabel.text = "on"
                    self.isTaxEnabled = true
            })
        }
    }
    
    func setTaxIncludeView() {
        if (isTaxEnabled == true) {
            self.taxIncludedView.layer.position.x = self.taxIncludedView.layer.position.x + 120
            self.taxIncludedView.backgroundColor = UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: 1)
            self.taxIncludedView.layer.cornerRadius = 30
            self.taxIncludedLabel.text = "on"
        } else {
            self.taxIncludedView.layer.position.x = self.taxIncludedView.layer.position.x
            self.taxIncludedView.backgroundColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)
            self.taxIncludedView.layer.cornerRadius = 0
            self.taxIncludedLabel.text = "off"
        }
    }
    
}
