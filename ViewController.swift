//
//  ViewController.swift
//  Steps
//
//  Created by Matt. on 6/27/18.
//  Copyright © 2018 mbenn. All rights reserved.
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
        
        var interval = DateComponents()
        interval.day = 1
        
        var anchorComponents = Calendar.current.dateComponents([.day, .month, .year], from: now)
        anchorComponents.hour = 0
        let anchorDate = Calendar.current.date(from: anchorComponents)!
        
        let query = HKStatisticsCollectionQuery(quantityType: stepsQuantityType,
                                                quantitySamplePredicate: nil,
                                                options: [.cumulativeSum],
                                                anchorDate: anchorDate,
                                                intervalComponents: interval)
        query.initialResultsHandler = { _, result, error in
            
            var resultCount = -1.0
            
            guard let result = result else {
                completion(resultCount)
                return
            }
            
            result.enumerateStatistics(from: startOfDay, to: now) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    // Get steps (they are of double type)
                    resultCount = sum.doubleValue(for: HKUnit.count())
                }
                
                // Return
                DispatchQueue.main.async {
                    completion(resultCount)
                }
            }
            
        }
        
        query.statisticsUpdateHandler = {
            query, statistics, statisticsCollection, error in
            
            if let sum = statistics?.sumQuantity() {
                let resultCount = sum.doubleValue(for: HKUnit.count())
                DispatchQueue.main.async {
                    completion(resultCount)
                }
            }
            
        }
        
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
