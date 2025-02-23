//
//  NearbyLocationsView.swift
//  Coursework
//
//  Created by Leon Liao on 23/2/2025.
//

import SwiftUI
import MapKit
import CoreLocation

struct NearbyLocationsView: View {
    @State private var places: [Place] = [] // List of nearby places
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var searchQuery: String = "" // Search query entered by the user

    private let locationManager = CLLocationManager()
    private var locationDelegate = LocationDelegate() // Retain the delegate
    @State private var userLocation: CLLocationCoordinate2D?

    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    TextField("Search places...", text: $searchQuery, onCommit: {
                        searchNearbyPlaces(query: searchQuery)
                    })
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)

                    Button(action: {
                        searchQuery = ""
                        searchNearbyPlaces(query: nil) // Clear search query and fetch nearby places
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing)
                }

                // Loading indicator
                /*if isLoading {
                    ProgressView("Fetching nearby places...")
                        .padding()
                }*/

                // Error message display
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                // List of nearby places
                List(places) { place in
                    PlaceRow(place: place)
                }
            }
            .navigationTitle("Nearby Places")
            .onAppear {
                requestLocationPermission()
            }
        }
    }

    // MARK: - Request Location Permission
    private func requestLocationPermission() {
        if CLLocationManager.locationServicesEnabled() {
            locationDelegate.onUpdate = { location in
                userLocation = location
                searchNearbyPlaces(query: nil) // Fetch nearby places once location is available
            }
            locationManager.delegate = locationDelegate // Assign the retained delegate
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        } else {
            errorMessage = "Location services are disabled. Please enable them in settings."
        }
    }

    // MARK: - Search for Nearby Places
    private func searchNearbyPlaces(query: String?) {
        guard let location = userLocation else {
            errorMessage = "Unable to fetch location. Please allow location access."
            return
        }

        isLoading = true
        errorMessage = nil

        // Create a search request
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query ?? "Restaurant" // Default search query
        request.region = MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )

        // Perform the search
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    //errorMessage = "Failed to fetch places: \(error.localizedDescription)"
                    return
                }

                guard let response = response else {
                    errorMessage = "No places found nearby."
                    return
                }

                // Map search results to Place model
                places = response.mapItems.compactMap { item in
                    Place(
                        name: item.name ?? "Unknown Place",
                        address: item.placemark.title ?? "No address available",
                        coordinate: item.placemark.coordinate
                    )
                }

                if places.isEmpty {
                    errorMessage = "No matching places found."
                }
            }
        }
    }
}

// MARK: - Place Model
struct Place: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Place Row View
struct PlaceRow: View {
    let place: Place

    var body: some View {
        VStack(alignment: .leading) {
            Text(place.name)
                .font(.headline)

            Text(place.address)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Location Delegate Wrapper
class LocationDelegate: NSObject, CLLocationManagerDelegate {
    var onUpdate: ((CLLocationCoordinate2D) -> Void)?

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last?.coordinate {
            onUpdate?(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}
