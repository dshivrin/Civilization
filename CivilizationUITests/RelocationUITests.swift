import XCTest
#if DEBUG
import GameCore
import GameApplication

final class RelocationUITests: XCTestCase {
    @MainActor private func launchNormal(_ app: XCUIApplication) {
        app.launch()
        let resume = app.buttons["continueGame"]
        XCTAssertTrue(resume.waitForExistence(timeout: 30))
        if resume.isEnabled { resume.tap() } else { app.buttons["newNormalGame"].tap() }
    }

    @MainActor func testGameplayReviewControlsKeepNormalProgressSeparate() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 20))
        let wood = app.descendants(matching: .any).matching(identifier: "resource-wood").firstMatch
        XCTAssertTrue(wood.waitForExistence(timeout: 5))
        let originalWood = wood.label
        app.buttons["developerTools"].tap()
        app.buttons["startGameplayReview"].tap()
        let banner = app.staticTexts["developerModeBanner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 5)); XCTAssertTrue(banner.label.contains("REVIEW COPY"))
        app.buttons["developerTools"].tap()
        let form = app.descendants(matching: .any).matching(identifier: "developerToolsForm").firstMatch
        func reveal(_ element: XCUIElement) {
            for _ in 0..<16 where !element.isHittable {
                let from = form.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
                let to = form.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
                from.press(forDuration: 0.1, thenDragTo: to)
            }
            XCTAssertTrue(element.isHittable)
        }
        let speed = app.buttons["10×"]
        reveal(speed); speed.tap()
        let grant = app.buttons["developerAddResources"]; reveal(grant); grant.tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(banner.label.contains("10×"))
        XCTAssertTrue(wood.label.contains("350"), wood.label)
        capture("isolated-review-copy-controls", app: app)
        app.terminate(); launchNormal(app)
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 20))
        XCTAssertFalse(banner.exists); XCTAssertEqual(wood.label, originalWood)
        app.buttons["developerTools"].tap()
        let resume = app.buttons["startGameplayReview"]
        XCTAssertTrue(resume.label.contains("Resume review copy")); resume.tap()
        XCTAssertTrue(banner.waitForExistence(timeout: 5)); XCTAssertTrue(banner.label.contains("1×"))
        XCTAssertTrue(wood.label.contains("350"), wood.label)
        app.buttons["developerTools"].tap()
        let normal = app.buttons["Return to normal settlement"]; reveal(normal); normal.tap()
        XCTAssertFalse(banner.exists); XCTAssertEqual(wood.label, originalWood)
    }

    @MainActor func testCivicUpgradeResearchRoundTripAndRestart() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        func reveal(_ element: XCUIElement) {
            for _ in 0..<6 where !element.isHittable { app.scrollViews["buildingInspection"].swipeUp() }
            XCTAssertTrue(element.isHittable)
        }
        func inspect() {
            XCTAssertTrue(app.buttons["settlementBuildings"].waitForExistence(timeout: 20))
            app.buttons["settlementBuildings"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            let center = app.descendants(matching: .any).matching(identifier: "inspectBuilding-0").firstMatch
            XCTAssertTrue(center.waitForExistence(timeout: 5)); center.tap()
        }
        inspect()
        let locked = app.buttons["civicPrerequisiteResearch"]
        reveal(locked); XCTAssertTrue(locked.label.contains("Oral Tradition")); locked.tap()
        let oral = app.buttons["research-oralTradition"]
        XCTAssertTrue(oral.waitForExistence(timeout: 5)); XCTAssertTrue(oral.isHittable)
        XCTAssertTrue(app.staticTexts["research-description-oralTradition"].exists)
        oral.tap()
        app.buttons["returnToCivicCenter"].tap()
        let upgrade = app.buttons["upgradeBuilding"]
        reveal(upgrade); XCTAssertTrue(upgrade.isEnabled); upgrade.tap()
        XCTAssertTrue(app.staticTexts["civicLevelName"].label.contains("Gathering Place"))
        reveal(locked); XCTAssertTrue(locked.label.contains("Social Order")); locked.tap()
        XCTAssertTrue(app.buttons["research-socialOrder"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["research-description-socialOrder"].exists)
        app.buttons["closeResearch"].tap() // Done also restores the same inspection.
        XCTAssertTrue(app.staticTexts["civicLevelName"].label.contains("Gathering Place"))
        capture("civic-gathering-place", app: app)
        app.terminate(); launchNormal(app); inspect()
        XCTAssertTrue(app.staticTexts["civicLevelName"].label.contains("Gathering Place"))
        let move = app.buttons["moveBuilding"]; reveal(move); move.tap()
        XCTAssertTrue(app.buttons["cancelRelocation"].waitForExistence(timeout: 5))
        app.buttons["cancelRelocation"].tap()
    }

    @MainActor func testCivicCouncilCircleAndRelocationPersist() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        var earned = try GameEngine(configuration: .bundled(), now: Date().addingTimeInterval(-1080))
        try earned.research("oralTradition"); try earned.upgrade(buildingID: 0)
        earned.advance(to: earned.state.lastUpdated.addingTimeInterval(1080))
        XCTAssertGreaterThanOrEqual(earned.state.resources.knowledge, 50)
        let blockedRoad = try XCTUnwrap(earned.state.discoveredTiles?.sorted { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y }.first {
            abs($0.x - earned.configuration.map.campfire.x) + abs($0.y - earned.configuration.map.campfire.y) == 1 && earned.roadIssue(at: $0) == nil
        })
        try earned.editRoads(at: [blockedRoad], style: .trodden)
        struct Envelope: Encodable { let version = 6; let state: GameState }
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        app.launchEnvironment["CIVILIZATION_UI_EARNED_SAVE"] = try JSONEncoder().encode(Envelope(state: earned.state)).base64EncodedString()
        launchNormal(app)
        func reveal(_ element: XCUIElement) {
            for _ in 0..<6 where !element.isHittable { app.scrollViews["buildingInspection"].swipeUp() }
            XCTAssertTrue(element.isHittable)
        }
        func inspect() {
            XCTAssertTrue(app.buttons["settlementBuildings"].waitForExistence(timeout: 20))
            app.buttons["settlementBuildings"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            let center = app.descendants(matching: .any).matching(identifier: "inspectBuilding-0").firstMatch
            XCTAssertTrue(center.waitForExistence(timeout: 5)); center.tap()
        }
        inspect()
        let research = app.buttons["civicPrerequisiteResearch"]; reveal(research); research.tap()
        let social = app.buttons["research-socialOrder"]
        XCTAssertTrue(social.waitForExistence(timeout: 5)); XCTAssertTrue(social.isEnabled); social.tap()
        app.buttons["returnToCivicCenter"].tap()
        let upgrade = app.buttons["upgradeBuilding"]; reveal(upgrade); upgrade.tap()
        XCTAssertTrue(app.staticTexts["civicLevelName"].label.contains("Council Circle"))
        let move = app.buttons["moveBuilding"]; reveal(move); move.tap()
        let map = app.otherElements["settlementMap"], frame = map.frame
        let config = earned.configuration
        func camera() throws -> (x: Double, y: Double, zoom: Double) {
            let value = map.value as? String ?? ""
            let expression = try NSRegularExpression(pattern: "camera=(-?[0-9.]+),(-?[0-9.]+) zoom=([0-9.]+)")
            let match = try XCTUnwrap(expression.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)))
            let text = value as NSString
            return (try XCTUnwrap(Double(text.substring(with: match.range(at: 1)))),
                    try XCTUnwrap(Double(text.substring(with: match.range(at: 2)))),
                    try XCTUnwrap(Double(text.substring(with: match.range(at: 3)))))
        }
        let initialCamera = try camera()
        func point(_ tile: Tile) -> CGVector {
            let p = MapGeometry.point(for: tile)
            return CGVector(dx: 0.5 + (p.x - initialCamera.x) / initialCamera.zoom / frame.width,
                            dy: 0.5 - (p.y - initialCamera.y) / initialCamera.zoom / frame.height)
        }
        let site = try XCTUnwrap(earned.state.discoveredTiles?.sorted { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y }.first {
            let p = point($0)
            return $0 != config.map.campfire && earned.relocationIssue(buildingID: 0, at: $0) == nil && (0.35...0.55).contains(p.dx) && (0.40...0.66).contains(p.dy)
        })
        map.coordinate(withNormalizedOffset: point(config.map.campfire)).press(forDuration: 0.05, thenDragTo: map.coordinate(withNormalizedOffset: point(site)))
        XCTAssertFalse(app.buttons["cancelRelocation"].exists)
        inspect()
        XCTAssertTrue(app.staticTexts["inspectedBuildingPosition"].label.contains("Tile \(site.x), \(site.y)"), "Expected \(site), actual \(app.staticTexts["inspectedBuildingPosition"].label), frame \(frame), camera \(map.value as? String ?? "")")
        capture("civic-council-circle-moved", app: app)
        app.terminate(); launchNormal(app); inspect()
        XCTAssertTrue(app.staticTexts["civicLevelName"].label.contains("Council Circle"))
        XCTAssertTrue(app.staticTexts["inspectedBuildingPosition"].label.contains("Tile \(site.x), \(site.y)"), "Expected \(site), actual \(app.staticTexts["inspectedBuildingPosition"].label), frame \(frame), camera \(map.value as? String ?? "")")
        app.buttons.matching(identifier: "Close inspection").element(boundBy: 1).tap()
        app.buttons["Center on settlement"].tap()
        let movedPoint = MapGeometry.point(for: site)
        let expectedCamera = String(format: "camera=%.2f,%.2f", movedPoint.x + 80, movedPoint.y + 30)
        let centered = NSPredicate { _, _ in (map.value as? String ?? "").contains(expectedCamera) }
        expectation(for: centered, evaluatedWith: nil); waitForExpectations(timeout: 5)
        let centeredCamera = try camera()
        func movedScreenPoint(_ tile: Tile) -> CGVector {
            let p = MapGeometry.point(for: tile)
            return CGVector(dx: 0.5 + (p.x - centeredCamera.x) / centeredCamera.zoom / frame.width,
                            dy: 0.5 - (p.y - centeredCamera.y) / centeredCamera.zoom / frame.height)
        }
        map.coordinate(withNormalizedOffset: movedScreenPoint(site)).press(forDuration: 0.55, thenDragTo: map.coordinate(withNormalizedOffset: movedScreenPoint(blockedRoad)))
        XCTAssertTrue(app.buttons["cancelRelocation"].waitForExistence(timeout: 5))
        app.buttons["cancelRelocation"].tap()
    }

    @MainActor func testNormalLaunchMenuNewGameAndContinue() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        app.launch()
        XCTAssertTrue(app.buttons["newNormalGame"].waitForExistence(timeout: 30))
        XCTAssertFalse(app.buttons["continueGame"].isEnabled)
        XCTAssertFalse(app.buttons["developerTools"].exists)
        capture("normal-entry-menu", app: app)
        app.buttons["newNormalGame"].tap()
        let map = app.otherElements["settlementMap"]
        XCTAssertTrue(map.waitForExistence(timeout: 30))
        XCTAssertTrue((map.value as? String ?? "").contains("64×48 tiles · 1 buildings · 0 road tiles"))
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["continueGame"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.buttons["continueGame"].isEnabled)
        XCTAssertFalse(map.exists)
        app.buttons["newNormalGame"].tap()
        XCTAssertTrue(app.buttons["openGames"].waitForExistence(timeout: 30))
        app.buttons["openGames"].tap()
        XCTAssertEqual(app.staticTexts["activeGameName"].label, "Settlement 2")
        XCTAssertTrue(app.buttons["resumeGame-legacy"].exists)
        app.buttons["Done"].tap()
        app.terminate(); launchNormal(app)
        XCTAssertTrue(app.buttons["openGames"].waitForExistence(timeout: 30))
        app.buttons["openGames"].tap()
        XCTAssertEqual(app.staticTexts["activeGameName"].label, "Settlement 2")
    }

    @MainActor func testProductionGeographyCloudsExpeditionAndRelaunch() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        app.launchEnvironment["CIVILIZATION_RENDER_METRICS"] = "1"
        launchNormal(app)
        let map = app.otherElements["settlementMap"]
        XCTAssertTrue(map.waitForExistence(timeout:30))
        XCTAssertTrue((map.value as? String ?? "").contains("64×48 tiles · 1 buildings · 0 road tiles"))
        capture("geography-standard-start-cloud-boundary",app:app)
        app.buttons["openExplore"].tap()
        let coverage = app.staticTexts["explorationCoverage"]
        XCTAssertTrue(coverage.waitForExistence(timeout:5))
        let original = coverage.label
        XCTAssertTrue(original.replacingOccurrences(of: ",", with: "").contains("/ 3072"), original)
        app.buttons["startExploration"].tap()
        XCTAssertTrue(app.staticTexts["explorationTimer"].waitForExistence(timeout:5))
        XCTAssertFalse(app.buttons["startExploration"].isEnabled)
        XCTAssertEqual(coverage.label,original)
        app.terminate(); launchNormal(app)
        XCTAssertTrue(app.buttons["openExplore"].waitForExistence(timeout:30))
        app.buttons["openExplore"].tap()
        XCTAssertTrue(app.staticTexts["explorationTimer"].waitForExistence(timeout:5))
        XCTAssertEqual(app.staticTexts["explorationCoverage"].label,original)
        let revealed = NSPredicate { _,_ in app.staticTexts["explorationCoverage"].label != original }
        expectation(for:revealed,evaluatedWith:nil)
        waitForExpectations(timeout:55)
        XCTAssertFalse(app.staticTexts["explorationTimer"].exists)
        let completed = app.staticTexts["explorationCoverage"].label
        capture("geography-expedition-revealed",app:app)
        app.terminate(); launchNormal(app)
        XCTAssertTrue(app.buttons["openExplore"].waitForExistence(timeout:30))
        app.buttons["openExplore"].tap()
        XCTAssertEqual(app.staticTexts["explorationCoverage"].label,completed)
        XCTAssertFalse(app.staticTexts["explorationTimer"].exists)
    }
    @MainActor func testLargeGroupedVillageOverviewResumeAndReturnToOriginalMap() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 20))
        app.buttons["developerTools"].tap()
        let grouped = app.buttons["scenario-grouped"]
        for _ in 0..<3 where !grouped.isHittable { app.collectionViews.firstMatch.swipeUp() }
        XCTAssertTrue(grouped.label.contains("64×48")); grouped.tap()
        XCTAssertTrue(app.buttons["largeMapOverview"].waitForExistence(timeout: 30))
        let map = app.otherElements["settlementMap"]
        XCTAssertTrue(map.waitForExistence(timeout: 10))
        XCTAssertTrue((map.value as? String ?? "").contains("64×48 tiles · 64 buildings · 566 road tiles"))
        func sceneBuildCount() -> String {
            ((map.value as? String ?? "").components(separatedBy: "sceneBuilds=").last ?? "").components(separatedBy: " ").first ?? ""
        }
        let builtScenes = sceneBuildCount()
        Thread.sleep(forTimeInterval: 2.5) // Several ordinary resource ticks must retain one terrain scene.
        XCTAssertEqual(sceneBuildCount(), builtScenes, "Resource ticks constructed unused terrain scenes")
        let initialCamera = map.value as? String ?? ""
        let center = map.coordinate(withNormalizedOffset: CGVector(dx:0.5,dy:0.5))
        center.press(forDuration:0.02, thenDragTo: map.coordinate(withNormalizedOffset: CGVector(dx:0.62,dy:0.6)))
        XCTAssertTrue((map.value as? String ?? "").contains("pan=1 pinch=0"), map.value as? String ?? "")
        XCTAssertNotEqual(map.value as? String, initialCamera)
        app.buttons["largeMapOverview"].tap()
        capture("large-grouped-overview", app: app)
        map.pinch(withScale: 2.5,velocity: 1)
        XCTAssertTrue((map.value as? String ?? "").contains("pinch=1"), map.value as? String ?? "")
        capture("large-grouped-districts", app: app)
        app.buttons["largeMapOverview"].tap()
        app.terminate(); launchNormal(app)
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["largeMapOverview"].exists)
        app.buttons["developerTools"].tap()
        let resume = app.buttons["Resume developer save"]
        for _ in 0..<3 where !resume.isHittable { app.collectionViews.firstMatch.swipeUp() }
        resume.tap()
        XCTAssertTrue(app.buttons["largeMapOverview"].waitForExistence(timeout: 30))
        XCTAssertTrue((app.otherElements["settlementMap"].value as? String ?? "").contains("64×48 tiles · 64 buildings"))
        app.buttons["developerTools"].tap()
        let normal = app.buttons["Return to normal settlement"]
        for _ in 0..<6 where !normal.isHittable { app.collectionViews.firstMatch.swipeUp() }
        normal.tap()
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["largeMapOverview"].exists)
        XCTAssertTrue((app.otherElements["settlementMap"].value as? String ?? "").contains("64×48 tiles · 1 buildings · 0 road tiles"))
        capture("large-grouped-returned-normal", app: app)
    }
    @MainActor func testIndependentGamesCreateSwitchAndResumeAfterRelaunch() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(), libraryID = UUID().uuidString
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = libraryID
        print("S1SAVES_TEST_LIBRARY " + libraryID)
        launchNormal(app)
        XCTAssertTrue(app.buttons["openGames"].waitForExistence(timeout: 20))
        app.buttons["Build"].tap(); app.buttons["buildingCategory-Food and water"].tap()
        app.buttons["build-gatheringShelter"].tap()
        XCTAssertTrue(app.buttons["confirmPlacement"].waitForExistence(timeout: 5))
        app.buttons["confirmPlacement"].tap()
        XCTAssertFalse(app.descendants(matching: .any)["dragModeIndicator"].firstMatch.exists)
        app.buttons["openGames"].tap()
        XCTAssertTrue(app.staticTexts["Original settlement"].waitForExistence(timeout: 5))
        app.textFields["newGameName"].tap(); app.textFields["newGameName"].typeText("Pine village\n")
        app.buttons["createGame"].tap()
        XCTAssertTrue(app.buttons["openGames"].waitForExistence(timeout: 20))
        app.buttons["toggleGoals"].tap()
        XCTAssertTrue(app.staticTexts["nextStepSummary"].label.localizedCaseInsensitiveContains("gathering shelter"))
        app.buttons["openGames"].tap()
        XCTAssertEqual(app.staticTexts["activeGameName"].label, "Pine village")
        app.buttons["resumeGame-legacy"].tap()
        XCTAssertTrue(app.buttons["openGames"].waitForExistence(timeout: 20))
        app.buttons["toggleGoals"].tap()
        let progressed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS[c] %@", "woodcutter"), object: app.staticTexts["nextStepSummary"])
        XCTAssertEqual(XCTWaiter.wait(for: [progressed], timeout: 45), .completed)
        app.buttons["openGames"].tap()
        XCTAssertEqual(app.staticTexts["activeGameName"].label, "Original settlement")
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "resumeGame-")).firstMatch.tap()
        XCTAssertTrue(app.buttons["openGames"].waitForExistence(timeout: 20))
        app.terminate(); launchNormal(app)
        XCTAssertTrue(app.buttons["openGames"].waitForExistence(timeout: 20))
        app.buttons["toggleGoals"].tap()
        XCTAssertTrue(app.staticTexts["nextStepSummary"].label.localizedCaseInsensitiveContains("gathering shelter"))
        app.buttons["openGames"].tap()
        XCTAssertEqual(app.staticTexts["activeGameName"].label, "Pine village")
        XCTAssertTrue(app.buttons["resumeGame-legacy"].exists)
        capture("independent-games", app: app)
    }

    @MainActor func testMissingSelectedSaveOffersExplicitHealthyGameRecovery() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_MISSING_SELECTED_SAVE"] = "1"
        launchNormal(app)
        XCTAssertTrue(app.staticTexts["gameRecoveryError"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["recoverGame-legacy"].exists)
        capture("missing-selected-save-recovery", app: app)
        app.buttons["recoverGame-legacy"].tap()
        XCTAssertTrue(app.buttons["openGames"].waitForExistence(timeout: 20))
        app.buttons["openGames"].tap()
        XCTAssertEqual(app.staticTexts["activeGameName"].label, "Original settlement")
        XCTAssertTrue(app.staticTexts["Unavailable test game"].exists)
        capture("recovered-games", app: app)
    }

    @MainActor func testGamesManagementRequiresLeavingDeveloperScenario() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"; launchNormal(app)
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 20))
        app.buttons["developerTools"].tap(); app.buttons["scenario-early"].tap()
        app.buttons["openGames"].tap()
        XCTAssertTrue(app.staticTexts["gamesDeveloperWarning"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["activeGameName"].label, "Original settlement")
        app.collectionViews.firstMatch.swipeUp()
        XCTAssertTrue(app.buttons["createGame"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["createGame"].isEnabled)
        XCTAssertFalse(app.textFields["newGameName"].isEnabled)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["developerTools"].exists)
    }

    @MainActor func testLongPressRelocatesAndCameraGesturesKeepIdentity() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        launchNormal(app)
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 20))
        app.buttons["developerTools"].tap()
        app.buttons["scenario-early"].tap()
        let map = app.otherElements["settlementMap"]
        XCTAssertTrue(map.waitForExistence(timeout: 10))
        // The fixture uses the same deterministic geography; screen coordinates follow the renderer's projection.
        let config = try GameConfiguration.bundled()
        let engine = try DeveloperScenario.early.makeEngine(configuration: config, now: Date())
        let building = try XCTUnwrap(engine.state.buildings.first { $0.id == 1 })
        let frame = map.frame
        XCTAssertGreaterThan(frame.width, frame.height)
        let scale = frame.width > 1000 ? 1.1 : 0.95
        let camp = MapGeometry.point(for: config.map.campfire)
        let camera = WorldPoint(x: camp.x + 80, y: camp.y + 30)
        func point(_ tile: Tile, roof: Bool) -> CGVector {
            let world = MapGeometry.point(for: tile)
            let anchorY = world.y - 16 + (roof ? 30.0 : 0)
            return CGVector(dx: 0.5 + (world.x - camera.x) / scale / frame.width,
                            dy: 0.5 - (anchorY - camera.y) / scale / frame.height)
        }
        let candidates = (0..<config.map.height).flatMap { y in (0..<config.map.width).map { Tile(x: $0, y: y) } }
        let destination = try XCTUnwrap(candidates.first { tile in
            let screen = point(tile, roof: true)
            return tile != building.origin && engine.relocationIssue(buildingID: building.id, at: tile) == nil &&
                (0.40...0.64).contains(screen.dx) && (0.32...0.68).contains(screen.dy)
        })
        let start = map.coordinate(withNormalizedOffset: point(building.origin, roof: true))
        let end = map.coordinate(withNormalizedOffset: point(destination, roof: true))
        start.press(forDuration: 0.55, thenDragTo: end)
        let position = app.staticTexts["inspectedBuildingPosition"]
        XCTAssertTrue(position.waitForExistence(timeout: 10))
        XCTAssertTrue(position.label.contains("Tile \(destination.x), \(destination.y)"), position.label)
        let screenshot = XCTAttachment(screenshot: app.screenshot()); screenshot.name = "long-press-relocation"; screenshot.lifetime = .keepAlways; add(screenshot)
        app.buttons["Close inspection"].firstMatch.tap()
        // Ordinary movement below the long-press threshold pans; zoom must not relocate another building.
        let center = map.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.press(forDuration: 0.05, thenDragTo: map.coordinate(withNormalizedOffset: CGVector(dx: 0.58, dy: 0.56)))
        map.pinch(withScale: 1.2, velocity: 1)
        app.buttons["Center on settlement"].tap()
        if frame.width > 1000 {
            // iOS18 SwiftUI Menu automation does not expose the picker rows reliably.
            // Exercise the supported map-inspection path after the same camera gestures.
            map.coordinate(withNormalizedOffset: point(destination, roof: true)).tap()
        } else {
            app.buttons["settlementBuildings"].tap()
            app.buttons["inspectBuilding-1"].tap()
        }
        XCTAssertTrue(position.waitForExistence(timeout: 5))
        XCTAssertTrue(position.label.contains("Tile \(destination.x), \(destination.y)"), position.label)
    }
    @MainActor func testInvalidMoveKeepsPreviewAndBottomCancelWhileOutsideDragPans() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"; launchNormal(app)
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 20))
        app.buttons["developerTools"].tap(); app.buttons["scenario-early"].tap()
        let map = app.otherElements["settlementMap"], frame = map.frame
        let config = try GameConfiguration.bundled()
        let engine = try DeveloperScenario.early.makeEngine(configuration: config, now: Date())
        let building = try XCTUnwrap(engine.state.buildings.first { $0.id == 1 })
        let scale = frame.width > 1000 ? 1.1 : 0.95
        let camp = MapGeometry.point(for: config.map.campfire)
        func point(_ tile: Tile, centerOffset: Double = 0) -> CGVector {
            let world = MapGeometry.point(for: tile)
            return CGVector(dx: 0.5 + (world.x - camp.x - 80) / scale / frame.width,
                            dy: 0.5 - (world.y + centerOffset - camp.y - 30) / scale / frame.height)
        }
        app.buttons["openExplore"].tap()
        let start = map.coordinate(withNormalizedOffset: point(building.origin))
        let blocked = map.coordinate(withNormalizedOffset: point(config.map.campfire))
        start.press(forDuration: 0.55, thenDragTo: blocked)
        let cancel = app.buttons["cancelRelocation"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["confirmPlacement"].isEnabled)
        XCTAssertTrue(app.frame.contains(cancel.frame)); XCTAssertGreaterThanOrEqual(cancel.frame.height, 44)
        XCTAssertEqual(cancel.frame.midX, app.frame.midX, accuracy: 2)
        let preview = app.staticTexts["placementTile"].label
        map.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.30))
            .press(forDuration: 0.05, thenDragTo: map.coordinate(withNormalizedOffset: CGVector(dx: 0.60, dy: 0.35)))
        XCTAssertTrue(cancel.exists)
        XCTAssertEqual(app.staticTexts["placementTile"].label, preview)
        capture("invalid-move-kept-preview", app: app)
        cancel.tap(); XCTAssertFalse(cancel.exists)
        app.buttons["Center on settlement"].tap()
        if frame.width > 1000 {
            map.coordinate(withNormalizedOffset: point(building.origin, centerOffset: 14)).tap()
        } else {
            app.buttons["settlementBuildings"].tap(); app.buttons["inspectBuilding-1"].tap()
        }
        XCTAssertTrue(app.staticTexts["inspectedBuildingPosition"].label.contains("Tile \(building.origin.x), \(building.origin.y)"))
        app.buttons["moveBuilding"].tap()
        app.buttons["openExplore"].tap()
        XCTAssertTrue(app.staticTexts["explorationCoverage"].waitForExistence(timeout: 5), "One Explore tap must cancel an editor and reveal exploration")
        XCTAssertFalse(app.buttons["cancelRelocation"].exists)
    }

    @MainActor func testPreviewDragUsesTouchDownFootprintAtBothEdges() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"; launchNormal(app)
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 20))
        app.buttons["developerTools"].tap(); app.buttons["scenario-early"].tap()
        let map = app.otherElements["settlementMap"], frame = map.frame
        let c = try GameConfiguration.bundled(), g = try DeveloperScenario.early.makeEngine(configuration: c, now: Date())
        let b = try XCTUnwrap(g.state.buildings.first { $0.id == 1 })
        let camp = MapGeometry.point(for: c.map.campfire), scale = frame.width > 1000 ? 1.1 : 0.95
        func point(_ tile: Tile) -> CGVector {
            let p = MapGeometry.point(for: tile)
            return CGVector(dx: 0.5 + (p.x - camp.x - 80) / scale / frame.width,
                            dy: 0.5 - (p.y - camp.y - 30) / scale / frame.height)
        }
        map.coordinate(withNormalizedOffset: point(b.origin)).press(forDuration: 0.55, thenDragTo: map.coordinate(withNormalizedOffset: point(c.map.campfire)))
        XCTAssertTrue(app.buttons["cancelRelocation"].waitForExistence(timeout: 5))
        let preview = app.staticTexts["placementTile"].label
        let inner = point(Tile(x: c.map.campfire.x + 1, y: c.map.campfire.y))
        let outer = point(Tile(x: c.map.campfire.x + 2, y: c.map.campfire.y))
        func edge(_ fraction: Double) -> CGVector {
            CGVector(dx: inner.dx + (outer.dx - inner.dx) * fraction, dy: inner.dy + (outer.dy - inner.dy) * fraction)
        }
        map.coordinate(withNormalizedOffset: edge(0.55)).press(forDuration: 0.05, thenDragTo: map.coordinate(withNormalizedOffset: point(Tile(x: c.map.campfire.x - 1, y: c.map.campfire.y + 2))))
        XCTAssertTrue(app.buttons["cancelRelocation"].exists)
        XCTAssertEqual(app.staticTexts["placementTile"].label, preview, "A touch starting outside must pan even if recognition occurs inside")
        app.buttons["Center on settlement"].tap()
        let destination = try XCTUnwrap((0..<24).flatMap { y in (0..<32).map { Tile(x: $0, y: y) } }.first { t in
            let p = point(t)
            return g.relocationIssue(buildingID: b.id, at: t) == nil && p.dx > inner.dx + 0.04 && p.dx < 0.61 && (0.32...0.66).contains(p.dy)
        })
        map.coordinate(withNormalizedOffset: edge(0.45)).press(forDuration: 0.05, thenDragTo: map.coordinate(withNormalizedOffset: point(Tile(x: destination.x + 1, y: destination.y))))
        XCTAssertFalse(app.buttons["cancelRelocation"].exists)
        XCTAssertTrue(app.staticTexts["inspectedBuildingPosition"].label.contains("Tile \(destination.x), \(destination.y)"))
    }

    @MainActor func testCatalogAutomaticallyEntersImmediateDragMode() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); launchNormal(app)
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 20))
        app.buttons["developerTools"].tap(); app.buttons["scenario-early"].tap()
        app.buttons["Build"].tap(); app.buttons["buildingCategory-Settlement"].tap(); app.buttons["build-hut"].tap()
        let indicator = app.descendants(matching: .any)["dragModeIndicator"].firstMatch
        XCTAssertTrue(indicator.waitForExistence(timeout: 5))
        let map = app.otherElements["settlementMap"]
        let frame = map.frame
        XCTAssertGreaterThan(frame.width, frame.height)
        let config = try GameConfiguration.bundled()
        let engine = try DeveloperScenario.early.makeEngine(configuration: config, now: Date())
        let scale = frame.width > 1000 ? 1.1 : 0.95
        let camp = MapGeometry.point(for: config.map.campfire)
        func point(_ tile: Tile) -> CGVector {
            let world = MapGeometry.point(for: tile)
            return CGVector(dx: 0.5 + (world.x - camp.x - 80) / scale / frame.width,
                            dy: 0.5 - (world.y - camp.y - 30) / scale / frame.height)
        }
        let destination = try XCTUnwrap((0..<24).flatMap { y in (0..<32).map { Tile(x: $0, y: y) } }.first {
            let screen = point($0)
            return engine.placementIssue(.hut, at: $0) == nil && (0.45...0.60).contains(screen.dx) && (0.35...0.65).contains(screen.dy)
        })
        // No long hold: catalog selection has already activated dragging. Camera must remain fixed.
        map.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.5)).press(forDuration: 0.05, thenDragTo: map.coordinate(withNormalizedOffset: point(destination)))
        XCTAssertFalse(indicator.exists)
        if frame.width > 1000 {
            var roof = point(destination)
            roof.dy -= 14 / scale / frame.height
            map.coordinate(withNormalizedOffset: roof).tap()
            let position = app.staticTexts["inspectedBuildingPosition"]
            XCTAssertTrue(position.waitForExistence(timeout: 5))
            XCTAssertTrue(position.label.contains("Tile \(destination.x), \(destination.y)"), position.label)
        } else {
            app.buttons["settlementBuildings"].tap()
            let placed = app.buttons["inspectBuilding-5"]
            XCTAssertTrue(placed.waitForExistence(timeout: 5))
            XCTAssertTrue(placed.label.contains("\(destination.x), \(destination.y)"), placed.label)
        }
    }

    @MainActor func testChapterProgressAndScenarioSelection() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); launchNormal(app)
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 20))
        app.buttons["developerTools"].tap(); app.buttons["scenario-early"].tap()
        app.buttons["developerTools"].tap()
        XCTAssertTrue(app.buttons["scenario-early"].isSelected)
        XCTAssertFalse(app.buttons["scenario-late"].isSelected)
        XCTAssertTrue(app.staticTexts["developerStateDescription"].exists)
        capture("scenario-selection", app: app)
        app.buttons["Done"].tap()
        let goals = app.buttons["toggleGoals"]
        XCTAssertEqual(goals.value as? String, "Minimal")
        XCTAssertTrue(goals.label.contains("Chapters"))
        expandGoals(app)
        XCTAssertTrue(app.descendants(matching: .any)["goalProgress"].firstMatch.exists)
        XCTAssertEqual(goals.value as? String, "Expanded")
        app.buttons["openJourney"].tap()
        XCTAssertTrue(app.navigationBars["Stone Age journey"].waitForExistence(timeout: 5))
        capture("chapters", app: app)
        app.buttons["Done"].tap()
        goals.tap()
        XCTAssertEqual(goals.value as? String, "Minimal")
        app.buttons["Build"].tap()
        XCTAssertTrue(app.buttons["buildingCategory-Settlement"].waitForExistence(timeout: 5))
        app.buttons["buildingCategory-Settlement"].tap()
        XCTAssertTrue(app.buttons["build-hut"].isHittable)
        XCTAssertTrue(app.buttons["build-campfire"].exists)
        XCTAssertFalse(app.buttons["build-campfire"].isEnabled)
        capture("building-catalog", app: app)
        app.buttons["buildingCategory-Security"].tap()
        XCTAssertFalse(app.buttons["build-watchtower"].isEnabled)
        capture("locked-buildings", app: app)
        app.buttons["closeBuildingCatalog"].tap()
        app.buttons["openResearch"].tap()
        let readiness = app.buttons["showReadiness"]
        XCTAssertTrue(readiness.waitForExistence(timeout: 5))
        XCTAssertTrue(readiness.label.contains("checks"))
        readiness.tap()
        XCTAssertTrue(app.navigationBars["Stone Age readiness"].waitForExistence(timeout: 5))
        app.navigationBars["Stone Age readiness"].buttons["Done"].tap()
        app.buttons["closeResearch"].tap()
        app.buttons["Build"].tap()
        app.buttons["buildingCategory-Settlement"].tap()
        app.buttons["build-hut"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["dragModeIndicator"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["closeBuildingCatalog"].exists)
    }

    @MainActor func testDenseSettlementArtAndCamera() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_RENDER_METRICS"] = "1"
        launchNormal(app)
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 20))
        app.buttons["developerTools"].tap(); app.buttons["scenario-late"].tap()
        let map = app.otherElements["settlementMap"]
        XCTAssertTrue(map.waitForExistence(timeout: 10))
        XCTAssertGreaterThan(map.frame.width,map.frame.height)
        capture("late-world", app: app)
        map.pinch(withScale: 1.15,velocity: 0.5)
        let center=map.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        center.press(forDuration:0.05,thenDragTo:map.coordinate(withNormalizedOffset:CGVector(dx:0.58,dy:0.55)))
        app.buttons["Center on settlement"].tap()
        app.buttons["Build"].tap()
        app.buttons["buildingCategory-Crafting"].tap()
        XCTAssertTrue(app.buttons["build-toolmaker"].isEnabled)
        capture("crafting-thumbnails", app: app)
        app.buttons["closeBuildingCatalog"].tap()
        app.buttons["openResearch"].tap()
        XCTAssertTrue(app.buttons["pillarFilter-science"].waitForExistence(timeout:5))
        app.buttons["pillarFilter-science"].tap()
        capture("research-icons", app: app)
        app.buttons["closeResearch"].tap()
        XCTAssertTrue(map.exists)
    }

    @MainActor func testCompactDevelopmentCardsExpandAndShowDeficits() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); launchNormal(app)
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 20))
        app.buttons["developerTools"].tap(); app.buttons["scenario-early"].tap()
        let tablet = app.otherElements["settlementMap"].frame.width > 1000
        app.buttons["Build"].tap(); app.buttons["buildingCategory-Settlement"].tap()
        let hut = app.buttons["details-building-hut"]
        XCTAssertTrue(hut.waitForExistence(timeout: 5))
        XCTAssertEqual(hut.value as? String, "Collapsed")
        XCTAssertFalse(app.staticTexts["building-description-hut"].exists)
        XCTAssertEqual(app.buttons["build-hut"].frame.minY, app.buttons["build-campfire"].frame.minY, accuracy: 2)
        capture("compact-buildings", app: app)
        hut.tap()
        XCTAssertEqual(hut.value as? String, "Expanded")
        XCTAssertTrue(app.staticTexts["building-description-hut"].exists)
        capture("expanded-building", app: app)
        hut.tap()
        XCTAssertFalse(app.staticTexts["building-description-hut"].exists)
        app.buttons["closeBuildingCatalog"].tap()
        app.buttons["openResearch"].tap(); app.buttons["pillarFilter-science"].tap()
        let tradition = app.buttons["details-research-oralTradition"]
        XCTAssertTrue(tradition.waitForExistence(timeout: 5))
        XCTAssertEqual(tradition.value as? String, "Collapsed")
        XCTAssertFalse(app.staticTexts["research-description-oralTradition"].exists)
        capture("compact-research", app: app)
        tradition.tap()
        XCTAssertTrue(app.staticTexts["research-description-oralTradition"].exists)
        capture("expanded-research", app: app)
        tradition.tap()
        app.buttons["closeResearch"].tap()
        app.terminate()
        // Fresh, ordinary starting balances in a unique temporary save; never reset user data.
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        launchNormal(app)
        XCTAssertTrue(app.buttons["openResearch"].waitForExistence(timeout: 20))
        app.buttons["openResearch"].tap()
        app.buttons["pillarFilter-militarySecurity"].tap()
        let deficit = app.descendants(matching: .any)["cost-research-fortification-knowledge"].firstMatch
        XCTAssertTrue(deficit.waitForExistence(timeout: 5))
        XCTAssertTrue(deficit.label.contains("missing"), deficit.label)
        XCTAssertFalse(app.buttons["research-fortification"].isEnabled)
        capture("missing-resource", app: app)
        app.buttons["pillarFilter-economy"].tap()
        let wood = app.descendants(matching: .any)["cost-research-hunting-wood"].firstMatch
        let knowledge = app.descendants(matching: .any)["cost-research-hunting-knowledge"].firstMatch
        XCTAssertTrue(wood.label.contains("available"), wood.label)
        XCTAssertTrue(knowledge.label.contains("missing"), knowledge.label)
        let animal = app.buttons["research-animalDomestication"]
        let neighbor = app.buttons[tablet ? "research-leatherworking" : "research-cultivation"]
        XCTAssertEqual(animal.frame.minY, neighbor.frame.minY, accuracy: 2)
        capture("mixed-affordability", app: app)
        app.buttons["pillarFilter-science"].tap()
        app.buttons["research-oralTradition"].tap()
        XCTAssertFalse(app.buttons["research-oralTradition"].isEnabled)
        let paidWood = app.descendants(matching: .any)["cost-research-oralTradition-wood"].firstMatch
        XCTAssertTrue(paidWood.label.contains("90 stored"), paidWood.label)
        XCTAssertTrue(paidWood.label.contains("already paid"), paidWood.label)
        capture("completed-research", app: app)
        app.buttons["closeResearch"].tap()
    }

    @MainActor func testFreshPlayerSeesNextActionAndBuildsWithoutDeveloperTools() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"; launchNormal(app)
        XCTAssertEqual(app.buttons["toggleGoals"].value as? String, "Minimal")
        XCTAssertFalse(app.staticTexts["nextStepSummary"].exists)
        app.buttons["toggleGoals"].tap()
        let next = app.staticTexts["nextStepSummary"]
        XCTAssertTrue(next.waitForExistence(timeout: 20))
        XCTAssertTrue(next.label.localizedCaseInsensitiveContains("gathering shelter"), next.label)
        XCTAssertEqual(app.buttons["toggleGoals"].value as? String, "Compact")
        capture("fresh-next-step", app: app)
        app.buttons["toggleGoals"].tap()
        XCTAssertTrue(app.staticTexts["nextStepExplanation"].label.contains("Drag"))
        app.buttons["nextStepAction"].tap()
        XCTAssertTrue(app.buttons["build-gatheringShelter"].waitForExistence(timeout: 5))
        app.buttons["build-gatheringShelter"].tap()
        let indicator = app.descendants(matching: .any)["dragModeIndicator"].firstMatch
        XCTAssertTrue(indicator.waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["toggleGoals"].value as? String, "Minimal")
        capture("guided-placement", app: app)
        let map = app.otherElements["settlementMap"], frame = map.frame
        let config = try GameConfiguration.bundled()
        let engine = try GameEngine(configuration: config, now: Date())
        let scale = frame.width > 1000 ? 1.1 : 0.95
        let camp = MapGeometry.point(for: config.map.campfire)
        func point(_ tile: Tile) -> CGVector {
            let world = MapGeometry.point(for: tile)
            return CGVector(dx: 0.5 + (world.x - camp.x - 80) / scale / frame.width,
                            dy: 0.5 - (world.y - camp.y - 30) / scale / frame.height)
        }
        let tile = try XCTUnwrap((0..<24).flatMap { y in (0..<32).map { Tile(x: $0, y: y) } }.first {
            let screen = point($0)
            return engine.placementIssue(.gatheringShelter, at: $0) == nil && (0.45...0.60).contains(screen.dx) && (0.35...0.65).contains(screen.dy)
        })
        map.coordinate(withNormalizedOffset: CGVector(dx: 0.42, dy: 0.76)).press(forDuration: 0.05, thenDragTo: map.coordinate(withNormalizedOffset: point(tile)))
        capture("guided-drop-result", app: app)
        XCTAssertFalse(indicator.exists, app.staticTexts["settlementMessage"].label)
        app.buttons["toggleGoals"].tap()
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS[c] %@", "woodcutter"), object: next)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 45), .completed)
        capture("first-building-complete", app: app)
    }

    @MainActor func testGuidanceResearchNavigationDoesNotPurchase() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); launchNormal(app)
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 20))
        app.buttons["developerTools"].tap(); app.buttons["scenario-early"].tap()
        app.buttons["toggleGoals"].tap()
        let next = app.staticTexts["nextStepSummary"]
        XCTAssertTrue(next.label.contains("Oral Tradition"), next.label)
        expandGoals(app); app.buttons["openJourney"].tap()
        XCTAssertTrue(app.navigationBars["Stone Age journey"].waitForExistence(timeout: 5))
        capture("guided-journey", app: app)
        let action = app.scrollViews["journeyContent"].buttons["nextStepAction"]
        XCTAssertTrue(action.isHittable)
        action.tap()
        XCTAssertTrue(app.buttons["research-oralTradition"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["research-oralTradition"].isEnabled)
        capture("guided-research", app: app)
        app.buttons["closeResearch"].tap()
        XCTAssertTrue(next.label.contains("Oral Tradition"), next.label)
    }

    @MainActor func testEarnedStoneAgeCompletionIsClearAndSandboxRemainsAvailable() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.terminate()
        // Earn the fixture with ordinary public commands, not a developer scenario or granted state.
        var game = try GameEngine(configuration: .bundled(), now: Date())
        for _ in 0..<5000 {
            let hint = game.settlementGuidance
            if hint.action == .complete { break }
            if let wait = hint.waitSeconds { game.advance(to: game.state.lastUpdated.addingTimeInterval(min(60, max(1, wait)))); continue }
            switch hint.action {
            case .build(let kind):
                let tile = try XCTUnwrap((0..<24).flatMap { y in (0..<32).map { Tile(x: $0, y: y) } }.first { game.placementIssue(kind, at: $0) == nil })
                try game.build(kind, at: tile)
            case .upgrade(let id): try game.upgrade(buildingID: id)
            case .research(let id): try game.research(id)
            case .recipe(let id, let mode): try game.setProductionMode(buildingID: id, recipeID: mode)
            case .priority(let id, let priority): try game.setWorkerPriority(buildingID: id, priority: priority)
            case .explore: try game.startExploration()
            default: XCTFail("Unusable ordinary action: " + hint.title); return
            }
            game.advance(to: game.state.lastUpdated.addingTimeInterval(60))
        }
        XCTAssertTrue(game.fullStoneAgeRequirementsMet)
        XCTAssertEqual(game.state.stoneAgeCompleted, true)
        XCTAssertNoThrow(try GameEngine(state: game.state, configuration: game.configuration))
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        struct Envelope: Encodable { let version = 6; let state: GameState }
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_EARNED_SAVE"] = try JSONEncoder().encode(Envelope(state: game.state)).base64EncodedString()
        launchNormal(app)
        XCTAssertTrue(app.buttons["toggleGoals"].waitForExistence(timeout: 20))
        app.buttons["toggleGoals"].tap()
        let next = app.staticTexts["nextStepSummary"]
        XCTAssertTrue(next.waitForExistence(timeout: 20))
        XCTAssertEqual(next.label, "Stone Age complete")
        XCTAssertTrue(app.buttons["toggleGoals"].label.contains("7/7"))
        capture("earned-completion", app: app)
        expandGoals(app); app.buttons["openJourney"].tap()
        XCTAssertTrue(app.staticTexts["journeyNextStepTitle"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["journeyNextStepTitle"].label, "Stone Age complete")
        XCTAssertTrue(app.staticTexts["bronzeAgeReadiness"].exists)
        capture("completed-journey", app: app)
        app.navigationBars["Stone Age journey"].buttons["Done"].tap()
        app.buttons["Build"].tap(); app.buttons["buildingCategory-Settlement"].tap()
        XCTAssertTrue(app.buttons["build-hut"].isEnabled)
    }

    @MainActor func testStarterReserveExplainsAndNavigatesToSupplier() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.terminate()
        var game = try GameEngine(configuration: .bundled(), now: Date())
        for _ in 0..<6 {
            let tile = try XCTUnwrap((0..<24).flatMap { y in (0..<32).map { Tile(x: $0, y: y) } }.first { game.placementIssue(.gatheringShelter, at: $0) == nil })
            try game.build(.gatheringShelter, at: tile)
            game.advance(to: game.state.lastUpdated.addingTimeInterval(30))
        }
        XCTAssertEqual(game.state.resources[.wood], 20)
        struct Envelope: Encodable { let version = 6; let state: GameState }
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_EARNED_SAVE"] = try JSONEncoder().encode(Envelope(state: game.state)).base64EncodedString()
        launchNormal(app)
        XCTAssertTrue(app.buttons["Build"].waitForExistence(timeout: 20))
        app.buttons["Build"].tap(); app.buttons["buildingCategory-Food and water"].tap()
        let shelter = app.buttons["build-gatheringShelter"]
        XCTAssertTrue(shelter.waitForExistence(timeout: 5)); XCTAssertFalse(shelter.isEnabled)
        capture("reserve-protected", app: app)
        app.buttons["details-building-gatheringShelter"].tap()
        let reason = app.staticTexts["building-reserve-gatheringShelter"]
        XCTAssertTrue(reason.waitForExistence(timeout: 5)); XCTAssertTrue(reason.label.contains("Woodcutter"))
        capture("reserve-explanation", app: app)
        let supplier = app.buttons["showBootstrapSupplier-gatheringShelter"]
        if !supplier.isHittable { app.scrollViews["buildingCatalog"].swipeUp() }
        supplier.tap()
        let woodcutter = app.buttons["build-woodcutter"]
        XCTAssertTrue(woodcutter.waitForExistence(timeout: 5)); XCTAssertTrue(woodcutter.isEnabled)
        woodcutter.tap()
        XCTAssertTrue(app.descendants(matching: .any)["dragModeIndicator"].firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor func testRoadDrawReplaceEraseAndCancelPreserveBuildingGestures() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication();app.terminate();app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1";launchNormal(app)
        XCTAssertTrue(app.buttons["Build"].waitForExistence(timeout:20))
        openRoads(app)
        XCTAssertTrue(app.buttons["confirmRoadStroke"].waitForExistence(timeout:5))
        let map = app.otherElements["settlementMap"], frame = map.frame
        let c = try GameConfiguration.bundled(),g = try GameEngine(configuration:c,now:Date())
        let camp = MapGeometry.point(for:c.map.campfire),scale = frame.width > 1000 ? 1.1 : 0.95
        func point(_ tile:Tile) -> CGVector {
            let p = MapGeometry.point(for:tile)
            return CGVector(dx:0.5+(p.x-camp.x-80)/scale/frame.width,dy:0.5-(p.y-camp.y-30)/scale/frame.height)
        }
        let visible = (0..<24).flatMap { y in (0..<32).map { Tile(x:$0,y:y) } }.filter {
            let p = point($0);return (0.42...0.60).contains(p.dx) && (0.40...0.67).contains(p.dy) && g.roadIssue(at:$0) == nil
        }
        let pair = try XCTUnwrap(visible.flatMap { a in visible.map { (a,$0) } }.first { a,b in
            let path = RoadGeometry.path(from:a,to:b,width:32,height:24)
            return path.count >= 4 && path.count <= 8 && path.allSatisfy { g.roadIssue(at:$0) == nil }
        })
        let start = map.coordinate(withNormalizedOffset:point(pair.0)),end = map.coordinate(withNormalizedOffset:point(pair.1))
        start.press(forDuration:0.05,thenDragTo:end)
        XCTAssertEqual(app.staticTexts["roadTileCount"].label,"0 roads placed")
        XCTAssertTrue(app.buttons["confirmRoadStroke"].isEnabled)
        XCTAssertTrue(app.buttons["confirmRoadStroke"].isHittable,"Confirm must stay visible without scrolling")
        capture("road-preview",app:app)
        app.buttons["confirmRoadStroke"].tap()
        let count = app.staticTexts["roadTileCount"].label
        XCTAssertNotEqual(count,"0 roads placed")
        capture("road-trodden",app:app)
        app.buttons["roadStyle-stone"].tap();app.buttons["roadMode-replace"].tap()
        start.tap();app.buttons["confirmRoadStroke"].tap()
        XCTAssertEqual(app.staticTexts["roadTileCount"].label,count)
        capture("road-mixed-stone",app:app)
        app.buttons["roadStyle-dirt"].tap();end.tap();app.buttons["confirmRoadStroke"].tap()
        XCTAssertTrue(app.frame.contains(app.buttons["confirmRoadStroke"].frame),"The entire Confirm target must fit inside the screen")
        capture("road-three-styles",app:app)
        app.buttons["roadMode-erase"].tap();start.tap();app.buttons["clearRoadStroke"].tap()
        XCTAssertEqual(app.staticTexts["roadTileCount"].label,count)
        XCTAssertFalse(app.buttons["confirmRoadStroke"].isEnabled)
        start.press(forDuration:0.05,thenDragTo:end);app.buttons["confirmRoadStroke"].tap()
        XCTAssertEqual(app.staticTexts["roadTileCount"].label,"0 roads placed")
        app.buttons["closeRoads"].tap()
        app.buttons["Build"].tap();app.buttons["buildingCategory-Food and water"].tap();app.buttons["build-gatheringShelter"].tap()
        XCTAssertTrue(app.descendants(matching:.any)["dragModeIndicator"].firstMatch.waitForExistence(timeout:5))
    }

    @MainActor func testRoadPinchDiscardsDraftWithoutApplyingIt() throws {
        continueAfterFailure = false;XCUIDevice.shared.orientation = .landscapeRight
        let app = XCUIApplication();app.terminate();app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1";launchNormal(app)
        XCTAssertTrue(app.buttons["Build"].waitForExistence(timeout:20));openRoads(app)
        let map = app.otherElements["settlementMap"]
        map.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.65)).tap()
        XCTAssertNotEqual(app.staticTexts["roadDraftCount"].label,"0 preview tiles")
        app.buttons["toggleRoadDetails"].tap()
        map.pinch(withScale:1.8,velocity:1)
        app.buttons["toggleRoadDetails"].tap()
        XCTAssertEqual(app.staticTexts["roadDraftCount"].label,"0 preview tiles")
        XCTAssertEqual(app.staticTexts["roadTileCount"].label,"0 roads placed")
        app.buttons["closeRoads"].tap();app.buttons["Center on settlement"].tap()
    }

    @MainActor func testRoadJourneyNavigationDiscardsPreview() throws {
        continueAfterFailure = false;XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication();app.terminate();app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1";launchNormal(app)
        XCTAssertTrue(app.buttons["Build"].waitForExistence(timeout:20));openRoads(app)
        app.otherElements["settlementMap"].coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.65)).tap()
        expandGoals(app);app.buttons["openJourney"].tap()
        app.navigationBars["Stone Age journey"].buttons["Done"].tap()
        XCTAssertFalse(app.buttons["confirmRoadStroke"].exists)
        openRoads(app)
        XCTAssertEqual(app.staticTexts["roadDraftCount"].label,"0 preview tiles")
        XCTAssertEqual(app.staticTexts["roadTileCount"].label,"0 roads placed")
    }

    @MainActor func testRoadDenseMixedSurfacesRemainSeparateFromEraProgress() throws {
        continueAfterFailure = false;XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication();app.terminate()
        var g = try GameEngine(configuration:.bundled(),now:Date())
        let styles = RoadStyle.allCases
        let tiles = (0..<24).flatMap { y in (0..<32).map { Tile(x:$0,y:y) } }.filter { g.roadIssue(at:$0) == nil }
        for (index,tile) in tiles.enumerated() { try g.editRoads(at:[tile],style:styles[index % styles.count]) }
        let isolated = try XCTUnwrap(tiles.first { p in RoadGeometry.neighbors(of:p).allSatisfy { n in g.state.roads?.contains { $0.tile == n.tile } == true } })
        try g.editRoads(at:RoadGeometry.neighbors(of:isolated).map(\.tile),style:nil)
        let roads = g.state.roads ?? []
        let masks = Set(roads.map { g.roadMask(at:$0.tile) })
        XCTAssertEqual(masks,Set(UInt8(0)...15))
        XCTAssertFalse(g.fullStoneAgeRequirementsMet)
        print("ROAD_DENSE_FIXTURE tiles=\(roads.count) masks=\(masks.sorted())")
        struct Envelope:Encodable { let version = 6;let state:GameState }
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_EARNED_SAVE"] = try JSONEncoder().encode(Envelope(state:g.state)).base64EncodedString()
        app.launchEnvironment["CIVILIZATION_RENDER_METRICS"] = "1";launchNormal(app)
        XCTAssertTrue(app.buttons["Build"].waitForExistence(timeout:20));openRoads(app)
        XCTAssertEqual(app.staticTexts["roadTileCount"].label,"\(roads.count) roads placed")
        XCTAssertTrue(app.buttons["toggleGoals"].label.contains("0/7"))
        Thread.sleep(forTimeInterval:6)
        capture("road-dense",app:app)
        app.buttons["closeRoads"].tap();app.buttons["Center on settlement"].tap()
    }

    @MainActor func testGoalsThreeStatesKeepExploreAdjacentAndRoadsInsideBuild() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"; launchNormal(app)
        let goals = app.buttons["toggleGoals"], explore = app.buttons["openExplore"]
        XCTAssertTrue(goals.waitForExistence(timeout: 20))
        XCTAssertEqual(goals.value as? String, "Minimal")
        XCTAssertFalse(app.staticTexts["nextStepSummary"].exists)
        for state in ["Minimal", "Compact", "Expanded"] {
            XCTAssertEqual(goals.value as? String, state)
            let aligned = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                abs(goals.frame.minY - explore.frame.minY) <= 2
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [aligned], timeout: 5), .completed)
            let goalFrame = goals.frame, exploreFrame = explore.frame
            print("HUD_FRAME state=\(state) goals=\(goalFrame) explore=\(exploreFrame)")
            XCTAssertEqual(goalFrame.minY, exploreFrame.minY, accuracy: 2)
            XCTAssertLessThanOrEqual(abs(exploreFrame.minX - goalFrame.maxX), 24, "Adjacent controls may expose inset accessibility frames")
            XCTAssertTrue(explore.isHittable)
            capture("goals-" + state.lowercased(), app: app)
            goals.tap()
        }
        XCTAssertEqual(goals.value as? String, "Minimal")
        explore.tap(); XCTAssertTrue(app.staticTexts["explorationCoverage"].waitForExistence(timeout: 5))
        explore.tap(); XCTAssertFalse(app.staticTexts["explorationCoverage"].exists)
        XCTAssertFalse(app.buttons["openRoads"].exists)
        openRoads(app, style: "stone")
        XCTAssertEqual(app.buttons["roadStyle-stone"].value as? String, "Selected")
        app.buttons["roadMode-replace"].tap()
        XCTAssertEqual(app.buttons["roadStyle-stone"].value as? String, "Selected")
        app.buttons["roadMode-draw"].tap()
        app.otherElements["settlementMap"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65)).tap()
        XCTAssertEqual(app.staticTexts["roadDraftCount"].label, "1 preview tiles")
        XCTAssertTrue(app.buttons["undoRoadTile"].isHittable)
        app.buttons["undoRoadTile"].tap()
        XCTAssertEqual(app.staticTexts["roadDraftCount"].label, "0 preview tiles")
        XCTAssertEqual(app.staticTexts["roadTileCount"].label, "0 roads placed")
        XCTAssertTrue(app.buttons["confirmRoadStroke"].exists)
        XCTAssertTrue(app.frame.contains(app.buttons["confirmRoadStroke"].frame))
        XCTAssertGreaterThan(app.buttons["confirmRoadStroke"].frame.width, app.buttons["confirmRoadStroke"].frame.height * 1.35)
        XCTAssertTrue(app.buttons["confirmRoadStroke"].isHittable)
        capture("roads-in-build-and-undo", app: app)
        app.buttons["closeRoads"].tap()
    }

    @MainActor private func expandGoals(_ app: XCUIApplication) {
        let button = app.buttons["toggleGoals"]
        for _ in 0..<2 where button.value as? String != "Expanded" { button.tap() }
        XCTAssertEqual(button.value as? String, "Expanded")
    }
    @MainActor private func openRoads(_ app: XCUIApplication, style: String = "trodden") {
        app.buttons["Build"].tap()
        let roads = app.buttons["buildingCategory-Roads"]
        let categories = app.scrollViews["buildingCategories"]
        if !roads.isHittable && categories.exists { categories.swipeLeft() }
        roads.tap()
        app.buttons["roadCatalog-" + style].tap()
        XCTAssertTrue(app.buttons["confirmRoadStroke"].waitForExistence(timeout: 5))
    }

    @MainActor private func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
        // Optional live capture window: XCTest attachments are misframed on some simulator runtimes.
        if let requested = ProcessInfo.processInfo.environment["CIVILIZATION_QA_CAPTURE"], requested == "1" || requested.split(separator: ",").contains(Substring(name)) {
            FileHandle.standardOutput.write(Data(("CIVILIZATION_QA_CAPTURE " + name + "\n").utf8))
            Thread.sleep(forTimeInterval: 6)
        }
    }

}
#endif


/// Compiles in both Debug and Release; exercises ordinary entry without fixture hooks.
final class NormalEntryUITests: XCTestCase {
    @MainActor func testNormalEntryPersistenceWithoutDeveloperHooks() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launch()
        let newGame = app.buttons["newNormalGame"]
        XCTAssertTrue(newGame.waitForExistence(timeout: 30))
        XCTAssertFalse(app.buttons["developerTools"].exists)
        newGame.tap()
        let map = app.otherElements["settlementMap"]
        XCTAssertTrue(map.waitForExistence(timeout: 30))
        XCTAssertTrue((map.value as? String ?? "").contains("64×48 tiles · 1 buildings · 0 road tiles"))
        app.buttons["Build"].tap(); app.buttons["buildingCategory-Food and water"].tap()
        app.buttons["build-gatheringShelter"].tap()
        XCTAssertTrue(app.buttons["confirmPlacement"].waitForExistence(timeout: 5))
        app.buttons["confirmPlacement"].tap()
        app.terminate(); app.launch()
        let resume = app.buttons["continueGame"]
        XCTAssertTrue(resume.waitForExistence(timeout: 30)); XCTAssertTrue(resume.isEnabled)
        XCTAssertFalse(map.exists)
        resume.tap()
        XCTAssertTrue(map.waitForExistence(timeout: 30))
        XCTAssertTrue((map.value as? String ?? "").contains("64×48 tiles · 2 buildings · 0 road tiles"))
        app.buttons["openGames"].tap()
        let selected = app.staticTexts["activeGameName"].label
        app.buttons["Done"].tap()
        app.terminate(); app.launch()
        XCTAssertTrue(newGame.waitForExistence(timeout: 30)); newGame.tap()
        XCTAssertTrue(map.waitForExistence(timeout: 30))
        XCTAssertTrue((map.value as? String ?? "").contains("64×48 tiles · 1 buildings · 0 road tiles"))
        app.buttons["openGames"].tap()
        XCTAssertNotEqual(app.staticTexts["activeGameName"].label, selected)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "resumeGame-")).count >= 1)
    }
}

/// The harness installs a legitimately earned normal save in a separate app container.
/// No fixture import, developer scenario, clock control or resource grant exists in the app.
final class NormalCompletionUITests: XCTestCase {
    @MainActor func testEarnedNormalCompletionAndRelaunch() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        for _ in 0..<2 {
            app.launch()
            let resume = app.buttons["continueGame"]
            XCTAssertTrue(resume.waitForExistence(timeout: 30)); XCTAssertTrue(resume.isEnabled)
            XCTAssertFalse(app.buttons["developerTools"].exists)
            resume.tap()
            XCTAssertTrue(app.buttons["toggleGoals"].waitForExistence(timeout: 30))
            XCTAssertTrue(app.buttons["toggleGoals"].label.contains("7/7"))
            app.buttons["toggleGoals"].tap()
            XCTAssertEqual(app.staticTexts["nextStepSummary"].label, "Stone Age complete")
            let expand = app.buttons["toggleGoals"]
            for _ in 0..<2 where expand.value as? String != "Expanded" { expand.tap() }
            XCTAssertEqual(expand.value as? String, "Expanded")
            app.buttons["openJourney"].tap()
            XCTAssertTrue(app.staticTexts["bronzeAgeReadiness"].waitForExistence(timeout: 5))
            app.navigationBars["Stone Age journey"].buttons["Done"].tap()
            app.buttons["Build"].tap(); app.buttons["buildingCategory-Settlement"].tap()
            XCTAssertTrue(app.buttons["build-hut"].isEnabled)
            app.terminate()
        }
    }
}
