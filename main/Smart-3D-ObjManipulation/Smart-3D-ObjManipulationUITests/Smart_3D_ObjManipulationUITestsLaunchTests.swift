//
//  Smart_3D_ObjManipulationUITestsLaunchTests.swift
//  Smart-3D-ObjManipulationUITests
//
//  Created by Dionisis Chatzimarkakis on 16/12/24.
//

import XCTest

final class Smart_3D_ObjManipulationUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
