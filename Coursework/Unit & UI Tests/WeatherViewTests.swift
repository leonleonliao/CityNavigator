//
//  WeatherViewTests.swift
//  Coursework
//
//  Created by Leon Liao on 23/2/2025.
//

import XCTest
@testable import CourseworkTests
@testable import Coursework

class WeatherViewTests: XCTestCase {
    var weatherView: WeatherView!
    var locationsManager: LocationsManager!

    override func setUpWithError() throws {
        // Initialize WeatherView and LocationsManager
        locationsManager = LocationsManager(username: "test_user")
        weatherView = WeatherView()
    }

    override func tearDownWithError() throws {
        // Clean up after each test
        weatherView = nil
        locationsManager = nil
    }

    func testWeatherAPIResponseParsing() throws {
        // Mock JSON response
        let mockJSON = """
        {
            "weather": [
                { "description": "clear sky" }
            ],
            "main": {
                "temp": 25.6
            }
        }
        """.data(using: .utf8)!

        // Decode the mock JSON
        let decoder = JSONDecoder()
        let response = try decoder.decode(WeatherResponse.self, from: mockJSON)

        // Assert the response is parsed correctly
        XCTAssertEqual(response.weather.first?.description, "clear sky", "Weather description should match.")
        XCTAssertEqual(response.main.temp, 25.6, "Temperature should match.")
    }

    func testWeatherAPIErrorHandling() {
        // Simulate an invalid JSON response
        let invalidJSON = """
        { "invalid_field": "invalid_value" }
        """.data(using: .utf8)!

        do {
            // Attempt to decode the invalid JSON
            let decoder = JSONDecoder()
            _ = try decoder.decode(WeatherResponse.self, from: invalidJSON)
            XCTFail("Decoding should fail for invalid JSON.")
        } catch {
            // Assert the decoding fails as expected
            XCTAssertTrue(true, "Error handling should catch invalid JSON.")
        }
    }
}
