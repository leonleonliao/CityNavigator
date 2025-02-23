//
//  AccountViewUITests.swift
//  Coursework
//
//  Created by Leon Liao on 23/2/2025.
//

import XCTest
@testable import CourseworkUITests
@testable import Coursework

class AccountViewUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testLoginSuccess() {
        // Navigate to AccountView
        app.tabBars.buttons["Account"].tap()

        // Input valid credentials
        let usernameField = app.textFields["Username"]
        usernameField.tap()
        usernameField.typeText("test_user")

        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")

        // Tap the login button
        app.buttons["Login"].tap()

        // Assert login success message
        XCTAssertTrue(app.staticTexts["Welcome, test_user!"].exists, "Login should succeed with valid credentials.")
    }

    func testLoginFailure() {
        // Navigate to AccountView
        app.tabBars.buttons["Account"].tap()

        // Input invalid credentials
        let usernameField = app.textFields["Username"]
        usernameField.tap()
        usernameField.typeText("invalid_user")

        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("wrong_password")

        // Tap the login button
        app.buttons["Login"].tap()

        // Assert error message
        XCTAssertTrue(app.staticTexts["Invalid username or password."].exists, "Error message should display for invalid credentials.")
    }
}
