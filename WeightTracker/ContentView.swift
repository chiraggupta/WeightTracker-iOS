//
//  WeightTracker
//
//  Created by Chirag Gupta on 21/06/2025.
//

import SwiftUI
import HealthKit

// MARK: - Content View
struct ContentView: View {
    @StateObject private var healthManager = HealthManager()
    @State private var currentWeight: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var recentWeights: [WeightEntry] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                Text("Weight Tracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Current Weight Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Weight")
                        .font(.headline)
                    
                    HStack {
                        TextField("Enter weight", text: $currentWeight)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("kg")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Save Button
                Button(action: saveWeight) {
                    Text("Save Weight")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(currentWeight.isEmpty)
                
                // Recent Weights List
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Entries")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if recentWeights.isEmpty {
                        Text("No entries yet")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        List(recentWeights) { entry in
                            HStack {
                                Text(entry.date, style: .date)
                                Spacer()
                                Text("\(entry.weight, specifier: "%.1f") kg")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
            .onAppear {
                requestHealthKitPermission()
                loadRecentWeights()
            }
            .alert("Weight Tracker", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Methods
    private func requestHealthKitPermission() {
        healthManager.requestAuthorization { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = "HealthKit authorization failed: \(error.localizedDescription)"
                    showingAlert = true
                } else if !success {
                    alertMessage = "HealthKit access denied. Please enable in Settings."
                    showingAlert = true
                }
            }
        }
    }
    
    private func saveWeight() {
        guard let weight = Double(currentWeight), weight > 0 else {
            alertMessage = "Please enter a valid weight"
            showingAlert = true
            return
        }
        
        healthManager.saveWeight(weight) { success, error in
            DispatchQueue.main.async {
                if success {
                    alertMessage = "Weight saved successfully!"
                    currentWeight = ""
                    loadRecentWeights()
                } else {
                    alertMessage = "Failed to save weight: \(error?.localizedDescription ?? "Unknown error")"
                }
                showingAlert = true
            }
        }
    }
    
    private func loadRecentWeights() {
        healthManager.fetchRecentWeights { weights in
            DispatchQueue.main.async {
                self.recentWeights = weights
            }
        }
    }
}
