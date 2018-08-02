//
//  ViewController.swift
//  Steps
//
//  Created by Matt. on 6/27/18.
//  Copyright © 2018 mbenn. All rights reserved.
//
//
//  Acknowledgements:
//
//  Sohil Pandya's blog post for the initial guidance behind acquiring a user's step count.
//  See his post on GitHub here: https://github.com/dwyl/learn-apple-watch-development/issues/43
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    var healthStore = HKHealthStore()
    let todaysDate = Date().toString(dateFormat: "MM/dd/yy")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the text of the date label
        dateLabel.text = todaysDate
        
        // Check to see if the app already has permissions
        if (isAuthorized()) {
            displaySteps()
        } // end if
        
        else {
            // Don't have permission, yet
            handlePermissions()
        } // end else
        
        // Center text within each label
        stepsLabel.textAlignment = NSTextAlignment.center
        dateLabel.textAlignment = NSTextAlignment.center
        
        // Resize font of stepsLabel if it is too large
        stepsLabel.numberOfLines = 1
        stepsLabel.minimumScaleFactor = 0.1
        stepsLabel.adjustsFontSizeToFitWidth = true;
        
    } // end of function viewDidLoad

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    } // end of method didReceiveMemoryWarning
    
    
    func handlePermissions() {
        
        // Access Step Count
        let healthKitTypes: Set = [ HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)! ]
        
        // Check Authorization
        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { (bool, error) in
            
            if error == nil {
                
                // Authorization Successful
                self.displaySteps()
                
            } // end if
            
        } // end of checking authorization
        
    } // end of func handlePermissions
    
    
    func displaySteps() {
        
        getTodaysSteps { (result) in
            DispatchQueue.main.async {
                
                var stepCount = String(Int(result))
                
                // Did not retrieve proper step count
                if (stepCount == "-1") {
                    
                    // If we do not have permissions
                    if (!self.isAuthorized()) {
                        self.stepsLabel.text = "Settings  >  Privacy  >  Health  >  Steps"
                    } // end if
                    
                    // Else, no data to show
                    else {
                        self.stepsLabel.text = "0"
                    } // end else
                    
                    return
                } // end if
                
                if (stepCount.count > 6) {
                    // Add a comma if the user managed to take at least 1,000,000 steps.
                    // He/she also deserves much more than a comma.
                    stepCount.insert(",", at: stepCount.index(stepCount.startIndex, offsetBy: stepCount.count - 6))
                } // end if
                
                if (stepCount.count > 3) {
                    // Add a comma if the user took at least 1,000 steps.
                    stepCount.insert(",", at: stepCount.index(stepCount.startIndex, offsetBy: stepCount.count - 3))
                } // end if
                
                self.stepsLabel.text = String(stepCount)
                
            }
        }
        
    } // end of func displaySteps
    
    
    func getTodaysSteps(completion: @escaping (Double) -> Void) {
        
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
            var resultCount = -1.0
            
            guard let result = result else {
                completion(resultCount)
                return
            }
            
            if let sum = result.sumQuantity() {
                // Get steps (they are of double type)
                resultCount = sum.doubleValue(for: HKUnit.count())
            } // end if
            
            DispatchQueue.main.async {
                completion(resultCount)
            }
            
        } // end of query
        
        healthStore.execute(query)
        
    } // end of func getTodaysSteps
    
    
    func isAuthorized() -> Bool {
        if (self.healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!) == .sharingAuthorized) {
            return true
        }
        else {
            return false
        }
    }
    
    
} // end of class ViewController
