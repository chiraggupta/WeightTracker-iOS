//
//  WeightTracker
//
//  Created by Chirag Gupta on 21/06/2025.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject private var healthManager = HealthManager()
    @State private var currentWeight: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var recentWeights: [WeightEntry] = []
    @State private var thisWeekAverage: Double?
    @State private var lastWeekAverage: Double?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                Text("Weight Tracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                
                // Current Weight Input - Large prominent section
                VStack(spacing: 20) {
                    Text("Today's Weight")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 15) {
                        TextField("Enter weight", text: $currentWeight)
                            .keyboardType(.decimalPad)
                            .font(.title)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 15)
                            .padding(.horizontal, 20)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        
                        Text("kg")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: saveWeight) {
                        Text("Save Weight")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(currentWeight.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(currentWeight.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 30)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Weekly Averages
                VStack(spacing: 12) {
                    HStack(spacing: 15) {
                        VStack {
                            Text("This Week")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let avg = thisWeekAverage {
                                Text("\(avg, specifier: "%.1f") kg")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            } else {
                                Text("No data")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        
                        VStack {
                            Text("Last Week")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let avg = lastWeekAverage {
                                Text("\(avg, specifier: "%.1f") kg")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            } else {
                                Text("No data")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Recent Weights List
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Entries")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
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
                            .padding(.vertical, 4)
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarHidden(true)
            .onAppear {
                requestHealthKitPermission()
                loadRecentWeights()
                loadWeeklyAverages()
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
                    loadWeeklyAverages()
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
    
    private func loadWeeklyAverages() {
        healthManager.fetchWeeklyAverages { thisWeek, lastWeek in
            DispatchQueue.main.async {
                self.thisWeekAverage = thisWeek
                self.lastWeekAverage = lastWeek
            }
        }
    }
}
