//
//  WeightTracker
//
//  Created by Chirag Gupta on 22/06/2025.
//

import HealthKit

class HealthManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
    
    // Request authorization to read/write weight data
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }
        
        let writeTypes: Set<HKSampleType> = [weightType]
        let readTypes: Set<HKObjectType> = [weightType]
        
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
            completion(success, error)
        }
    }
    
    // Save weight to HealthKit
    func saveWeight(_ weight: Double, completion: @escaping (Bool, Error?) -> Void) {
        let weightQuantity = HKQuantity(unit: HKUnit.gramUnit(with: .kilo), doubleValue: weight)
        let weightSample = HKQuantitySample(
            type: weightType,
            quantity: weightQuantity,
            start: Date(),
            end: Date()
        )
        
        healthStore.save(weightSample) { success, error in
            completion(success, error)
        }
    }
    
    // Fetch recent weight entries
    func fetchRecentWeights(completion: @escaping ([WeightEntry]) -> Void) {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: weightType,
            predicate: nil,
            limit: 10,
            sortDescriptors: [sortDescriptor]
        ) { query, samples, error in
            guard let samples = samples as? [HKQuantitySample] else {
                completion([])
                return
            }
            
            let weights = samples.map { sample in
                WeightEntry(
                    date: sample.startDate,
                    weight: sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                )
            }
            
            completion(weights)
        }
        
        healthStore.execute(query)
    }
    
    // Fetch weekly averages (Monday-Sunday weeks)
    func fetchWeeklyAverages(completion: @escaping (Double?, Double?) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        
        // Get start of this week (Monday)
        let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let adjustedThisWeekStart = calendar.date(byAdding: .day, value: calendar.firstWeekday == 1 ? 1 : 0, to: thisWeekStart) ?? thisWeekStart
        
        // Get start of last week
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: adjustedThisWeekStart) ?? adjustedThisWeekStart
        
        // Fetch this week
        fetchWeeklyAverage(from: adjustedThisWeekStart, to: now) { thisWeekAvg in
            // Fetch last week
            self.fetchWeeklyAverage(from: lastWeekStart, to: adjustedThisWeekStart) { lastWeekAvg in
                completion(thisWeekAvg, lastWeekAvg)
            }
        }
    }
    
    private func fetchWeeklyAverage(from startDate: Date, to endDate: Date, completion: @escaping (Double?) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: weightType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { query, samples, error in
            guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                completion(nil)
                return
            }
            
            let weights = samples.map { $0.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo)) }
            let average = weights.reduce(0, +) / Double(weights.count)
            completion(average)
        }
        
        healthStore.execute(query)
    }
}
