import XCTest
#if DEBUG
import GameCore
import GameApplication

final class RelocationUITests: XCTestCase {
    @MainActor func testLongPressRelocatesAndCameraGesturesKeepIdentity() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launch()
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
    @MainActor func testCatalogAutomaticallyEntersImmediateDragMode() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launch()
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
        let app = XCUIApplication(); app.launch()
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 20))
        app.buttons["developerTools"].tap(); app.buttons["scenario-early"].tap()
        app.buttons["developerTools"].tap()
        XCTAssertTrue(app.buttons["scenario-early"].isSelected)
        XCTAssertFalse(app.buttons["scenario-late"].isSelected)
        XCTAssertTrue(app.staticTexts["developerStateDescription"].exists)
        capture("scenario-selection", app: app)
        app.buttons["Done"].tap()
        let goals = app.buttons["toggleGoals"]
        XCTAssertEqual(goals.value as? String, "Collapsed")
        XCTAssertTrue(goals.label.contains("Chapters"))
        goals.tap()
        XCTAssertTrue(app.descendants(matching: .any)["goalProgress"].firstMatch.exists)
        XCTAssertEqual(goals.value as? String, "Expanded")
        app.buttons["openJourney"].tap()
        XCTAssertTrue(app.navigationBars["Stone Age journey"].waitForExistence(timeout: 5))
        capture("chapters", app: app)
        app.buttons["Done"].tap()
        goals.tap()
        XCTAssertEqual(goals.value as? String, "Collapsed")
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
        app.launch()
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
        let app = XCUIApplication(); app.launch()
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
        app.launch()
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
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"; app.launch()
        let next = app.staticTexts["nextStepSummary"]
        XCTAssertTrue(next.waitForExistence(timeout: 20))
        XCTAssertTrue(next.label.localizedCaseInsensitiveContains("gathering shelter"), next.label)
        XCTAssertEqual(app.buttons["toggleGoals"].value as? String, "Collapsed")
        capture("fresh-next-step", app: app)
        app.buttons["toggleGoals"].tap()
        XCTAssertTrue(app.staticTexts["nextStepExplanation"].label.contains("Drag"))
        app.buttons["nextStepAction"].tap()
        XCTAssertTrue(app.buttons["build-gatheringShelter"].waitForExistence(timeout: 5))
        app.buttons["build-gatheringShelter"].tap()
        let indicator = app.descendants(matching: .any)["dragModeIndicator"].firstMatch
        XCTAssertTrue(indicator.waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["toggleGoals"].value as? String, "Collapsed")
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
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS[c] %@", "woodcutter"), object: next)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 45), .completed)
        capture("first-building-complete", app: app)
    }

    @MainActor func testGuidanceResearchNavigationDoesNotPurchase() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launch()
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 20))
        app.buttons["developerTools"].tap(); app.buttons["scenario-early"].tap()
        let next = app.staticTexts["nextStepSummary"]
        XCTAssertTrue(next.label.contains("Oral Tradition"), next.label)
        app.buttons["toggleGoals"].tap(); app.buttons["openJourney"].tap()
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

    @MainActor private func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
        // Optional live capture window: XCTest attachments are misframed on some simulator runtimes.
        if ProcessInfo.processInfo.environment["CIVILIZATION_QA_CAPTURE"] == "1" {
            FileHandle.standardOutput.write(Data(("CIVILIZATION_QA_CAPTURE " + name + "\n").utf8))
            Thread.sleep(forTimeInterval: 6)
        }
    }

}
#endif
