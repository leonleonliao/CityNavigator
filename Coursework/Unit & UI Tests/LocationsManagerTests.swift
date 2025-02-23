//
//  LocationsManagerTests.swift
//  Coursework
//
//  Created by Leon Liao on 23/2/2025.
//

import XCTest
@testable import CourseworkTests
@testable import Coursework

class LocationsManagerTests: XCTestCase {
    var locationsManager: LocationsManager!

    override func setUpWithError() throws {
        // Initialize LocationsManager with a sample username
        locationsManager = LocationsManager(username: "test_user")
    }

    override func tearDownWithError() throws {
        // Clean up after each test
        locationsManager = nil
    }

    func testAddLocation() throws {
        // Create a sample location
        let sampleLocation = AnnotatedItem(
            name: "Test Location",
            description: "This is a test location.",
            imageName: "test.image",
            coordinate: CLLocationCoordinate2D(latitude: 22.3964, longitude: 114.1095)
        )

        // Add the location
        locationsManager.addLocation(sampleLocation)

        // Assert the location was added
        XCTAssertEqual(locationsManager.savedLocations.count, 1, "Location should be added.")

        // Try adding the same location again
        locationsManager.addLocation(sampleLocation)

        // Assert the duplicate location was not added
        XCTAssertEqual(locationsManager.savedLocations.count, 1, "Duplicate location should not be added.")
    }
}
