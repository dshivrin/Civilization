import XCTest
#if DEBUG
import GameCore
import GameApplication

final class RelocationUITests: XCTestCase {
    @MainActor func testUI2FoothillIntegratedTraversalAndSaveIsolation() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        let namespace = UUID().uuidString
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = namespace
        print("FOOTHILL harness=v2-explicit-boundary-snapshot namespace=" + namespace)
        launchNormal(app)
        func tap(_ id: String) {
            let b = app.buttons[id]; XCTAssertTrue(b.waitForExistence(timeout: 10), id)
            if !b.isHittable {
                let scroll = app.scrollViews["foundingControls"].exists ? app.scrollViews["foundingControls"] : app.scrollViews.firstMatch
                for _ in 0..<20 {
                    if b.isHittable { break }
                    let below = b.frame.isEmpty || b.frame.midY > scroll.frame.midY
                    scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5,dy: below ? 0.75 : 0.25)).press(forDuration: 0.02,thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5,dy: 0.5)))
                }
            }
            XCTAssertTrue(b.isHittable, id); b.tap()
        }
        func open(_ entry: String) {
            if !app.buttons[entry].isHittable {
                XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 30)); tap("developerTools")
            }
            tap(entry)
            XCTAssertTrue(app.staticTexts["foundingStatus"].waitForExistence(timeout: 20))
        }
        func capture(_ name: String, boundary: Bool = false) {
            let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); a.name = "foothill-" + name; a.lifetime = .keepAlways; add(a)
            var state = app.staticTexts["foundingStatus"].value as? String ?? ""
            if boundary { state += " " + app.staticTexts["foothillTraversal"].label }
            let b = XCTAttachment(string: state); b.name = "foothill-" + name + "-state"; b.lifetime = .keepAlways; add(b); print("FOOTHILL " + name + " " + state)
        }
        func digest() -> String {
            tap("foundingRail-Games"); XCTAssertTrue(app.staticTexts["foundingSaveBytes"].exists)
            let hash = app.staticTexts["foundingSaveBytes"].label
            XCTAssertTrue(hash.contains("sha256=")); return hash
        }
        open("openFoundingReview"); tap("foundingRail-Goals"); tap("foundingGoalAction")
        let original = app.staticTexts["foundingStatus"].value as? String
        let originalHash = digest(); print("FOOTHILL original-before " + originalHash)
        tap("closeFoundingReview")
        open("openFoothillReview"); capture("01-fresh-map")
        tap("foundingRail-Goals"); capture("02-one-tap-goal"); tap("foundingGoalAction"); capture("03-lodge-free-footpath")
        tap("foundingCatalog"); capture("04-catalog"); tap("foundingCatalogAction"); capture("05-legal-hut-plot"); tap("foundingConfirmHut")
        tap("foundingRail-Games"); tap("foundingTools"); tap("foundingAdvance60")
        tap("foundingSuggestPath"); tap("foundingConfirmPath"); capture("06-connected-hut")
        XCTAssertTrue((app.staticTexts["foundingStatus"].value as? String ?? "").contains("active=1"))
        tap("foundingToolsDone"); tap("foundingRail-Explore"); tap("foothillBoundary"); capture("07-terrain-wall-line", boundary: true)
        tap("foothillBuy"); XCTAssertFalse(app.staticTexts["foothillError"].exists); capture("08-purchased-open-gate", boundary: true)
        tap("foothillWalk")
        let audit = app.staticTexts["foothillTraversal"]
        XCTAssertTrue(audit.label.contains("WALKABLE")); XCTAssertTrue(audit.label.contains("gate 1"))
        XCTAssertTrue(NSPredicate(format: "label CONTAINS %@", "probe=20,14 moving=0").evaluate(with: audit) || {
            let e = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "probe=20,14 moving=0"), object: audit)
            return XCTWaiter.wait(for: [e], timeout: 15) == .completed
        }())
        capture("09-actual-traversal-arrived", boundary: true)
        tap("foothillGate"); XCTAssertTrue(audit.label.contains("BLOCKED")); XCTAssertTrue(audit.label.contains("interior reached 0")); capture("10-closed-no-bypass", boundary: true)
        tap("foothillCompare"); capture("11-freestanding-50-vs-36", boundary: true)
        app.scrollViews.firstMatch.swipeDown(); app.scrollViews.firstMatch.swipeDown(); capture("11b-equal-price-costs", boundary: true)
        tap("foothillSlope"); XCTAssertTrue(audit.label.contains("Ordinary slope: WALKABLE"))
        let slopeArrival = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "probe=24,23 moving=0"), object: audit)
        XCTAssertEqual(XCTWaiter.wait(for: [slopeArrival], timeout: 15), .completed); capture("12-walkable-slope", boundary: true)
        tap("foothillExpansion"); XCTAssertTrue(audit.label.contains("Expansion: WALKABLE"))
        let expansionArrival = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "probe=25,27 moving=0"), object: audit)
        XCTAssertEqual(XCTWaiter.wait(for: [expansionArrival], timeout: 15), .completed); capture("13-expansion-room", boundary: true)
        let foothillStatus = app.staticTexts["foundingStatus"].value as? String
        let foothillHash = digest(); print("FOOTHILL paid-after " + foothillHash)
        tap("closeFoundingReview")
        app.terminate(); app.launch(); XCTAssertTrue(app.buttons["continueGame"].waitForExistence(timeout: 30)); tap("continueGame")
        open("openFoothillReview"); XCTAssertEqual(app.staticTexts["foundingStatus"].value as? String, foothillStatus)
        XCTAssertEqual(digest(), foothillHash); tap("foundingMenuDone")
        tap("foundingRail-Explore"); tap("foothillBoundary"); tap("foothillWalk")
        XCTAssertTrue(audit.label.contains("BLOCKED")); XCTAssertTrue(audit.label.contains("interior reached 0")); capture("14-reloaded-paid-closed", boundary: true)
        tap("foundingMenuDone"); tap("foundingRail-Explore"); tap("foundingFogComparison")
        XCTAssertTrue(app.staticTexts["fogAudit"].waitForExistence(timeout: 10)); capture("15-temporary-forest")
        tap("fogBuild"); tap("fogStep"); tap("fogReturn")
        XCTAssertEqual(app.staticTexts["foundingStatus"].value as? String, foothillStatus)
        XCTAssertEqual(digest(), foothillHash); capture("16-foothill-return-retained")
        tap("closeFoundingReview"); open("openFoundingReview")
        XCTAssertEqual(app.staticTexts["foundingStatus"].value as? String, original)
        let finalOriginal = digest(); XCTAssertEqual(finalOriginal, originalHash); print("FOOTHILL original-after " + finalOriginal); capture("17-original-founding-preserved")
        tap("closeFoundingReview")
    }
    @MainActor func testUI2FogComparisonMenusExit() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForNonExistence(timeout: 30))
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 15)); app.buttons["developerTools"].tap()
        XCTAssertTrue(app.buttons["openFoundingReview"].waitForExistence(timeout: 10)); app.buttons["openFoundingReview"].tap()
        XCTAssertTrue(app.staticTexts["foundingStatus"].waitForExistence(timeout: 15))
        let before = app.staticTexts["foundingStatus"].value as? String
        func tap(_ id: String) { XCTAssertTrue(app.buttons[id].waitForExistence(timeout: 5)); app.buttons[id].tap() }
        for target in ["foundingRail-Goals", "foundingCatalog", "foundingRail-Games"] {
            tap("foundingRail-Explore"); tap("foundingFogComparison")
            XCTAssertTrue(app.staticTexts["fogAudit"].exists)
            tap(target)
            XCTAssertFalse(app.staticTexts["fogAudit"].exists, "Founding menus must exit the temporary engine first")
            XCTAssertEqual(app.staticTexts["foundingStatus"].value as? String, before)
            tap(target == "foundingCatalog" ? "foundingCatalogDone" : "foundingMenuDone")
        }
        tap("closeFoundingReview")
    }
    @MainActor func testUI2FogReduceMotion() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForNonExistence(timeout: 30))
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 15)); app.buttons["developerTools"].tap()
        XCTAssertTrue(app.buttons["openFoundingReview"].waitForExistence(timeout: 10)); app.buttons["openFoundingReview"].tap()
        XCTAssertTrue(app.staticTexts["foundingStatus"].waitForExistence(timeout: 15))
        func tap(_ id: String) { XCTAssertTrue(app.buttons[id].waitForExistence(timeout: 5)); app.buttons[id].tap() }
        tap("foundingRail-Explore"); tap("foundingFogComparison")
        let audit = app.staticTexts["fogAudit"]
        func capture(_ name: String) {
            XCTAssertTrue(audit.label.contains("osReduceMotion=1"), audit.label)
            XCTAssertTrue(audit.label.contains("moving=0"), audit.label)
            XCTAssertTrue(audit.label.contains("fade=0"), audit.label)
            XCTAssertTrue(audit.label.contains("hiddenGround=0 hiddenMarkers=0 opaque=1"), audit.label)
            let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); a.name = "fog-motion-reduce-" + name; a.lifetime = .keepAlways; add(a)
            let b = XCTAttachment(string: audit.label); b.name = "fog-motion-reduce-" + name + "-state"; b.lifetime = .keepAlways; add(b)
        }
        capture("covered")
        tap("fogBuild")
        XCTAssertTrue(app.staticTexts["foundingStatus"].label.contains("Wood 80"), "Visible stocks must belong to temporary gameplay")
        tap("fogStep"); tap("fogExpedition"); tap("fogLastCovered"); capture("last-covered")
        tap("fogFirstReveal"); capture("first-revealed-no-fade")
        tap("fogBuild"); tap("fogStep"); tap("fogGameplay"); capture("original-retained-pose")
        let before = audit.label.components(separatedBy: "actor=").last
        tap("fogLook"); capture("blue-braid-retained-pose")
        XCTAssertEqual(audit.label.components(separatedBy: "actor=").last, before)
        tap("fogReturn"); tap("closeFoundingReview")
    }
    @MainActor func testUI2FogMotionIntegrated() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForNonExistence(timeout: 30))
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 15))
        app.buttons["developerTools"].tap()
        XCTAssertTrue(app.buttons["openFoundingReview"].waitForExistence(timeout: 10)); app.buttons["openFoundingReview"].tap()
        XCTAssertTrue(app.staticTexts["foundingStatus"].waitForExistence(timeout: 15))
        let founding = app.staticTexts["foundingStatus"].value as? String
        func tap(_ id: String) { XCTAssertTrue(app.buttons[id].waitForExistence(timeout: 5), id); XCTAssertTrue(app.buttons[id].isHittable, id); app.buttons[id].tap() }
        let audit = app.staticTexts["fogAudit"]
        func value() -> String { audit.label }
        func token(_ key: String) -> String {
            let result = value().split(separator: " ").first { $0.hasPrefix(key + "=") }.map(String.init)
            XCTAssertNotNil(result, key + " missing from " + value()); return result ?? "missing"
        }
        func assertHidden() {
            XCTAssertTrue(value().contains("hiddenGround=0"), value())
            XCTAssertTrue(value().contains("hiddenMarkers=0"), value())
            XCTAssertTrue(value().contains("opaque=1"), value())
            XCTAssertFalse(value().contains("unknown=0 "), value())
        }
        func capture(_ name: String) {
            let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); a.name = "fog-motion-" + name; a.lifetime = .keepAlways; add(a)
            let b = XCTAttachment(string: value()); b.name = "fog-motion-" + name + "-state"; b.lifetime = .keepAlways; add(b)
        }
        func wait(_ text: String) {
            XCTAssertTrue(audit.waitForExistence(timeout: 5))
            let p = NSPredicate { _, _ in value().contains(text) }
            expectation(for: p, evaluatedWith: nil); waitForExpectations(timeout: 8)
        }
        func open() { tap("foundingRail-Explore"); tap("foundingFogComparison"); wait("opaque=1") }
        open()
        let initialKnown = token("known"), camera = token("camera"), zoom = token("zoom")
        assertHidden(); capture("01-organic-covered")
        tap("fogStyle"); capture("02-tiled-covered-matched")
        XCTAssertEqual(token("known"), initialKnown); XCTAssertEqual(token("camera"), camera); XCTAssertEqual(token("zoom"), zoom)
        tap("fogStyle"); assertHidden()
        let map = app.otherElements["onboardingWalkthroughMap"]
        let before = map.value as? String ?? ""
        map.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.35)).press(forDuration: 0.05, thenDragTo: map.coordinate(withNormalizedOffset: CGVector(dx: 0.70, dy: 0.40)))
        map.pinch(withScale: 1.35, velocity: 1)
        XCTAssertNotEqual(map.value as? String ?? "", before)
        capture("03-covered-edge-pan-pinch"); assertHidden()
        // Reopen the identical temporary adapter to restore exact matched framing.
        tap("fogReturn"); open()
        tap("fogBuild")
        XCTAssertTrue(app.staticTexts["foundingStatus"].label.contains("Wood 80"), "Visible stocks must belong to temporary gameplay")
        tap("fogStep")
        tap("fogExpedition"); tap("fogLastCovered")
        let coveredKnown = token("known"), revealCamera = token("camera"), revealZoom = token("zoom")
        capture("04-last-covered"); assertHidden()
        tap("fogFirstReveal"); capture("05-first-revealed-transition"); assertHidden()
        XCTAssertNotEqual(token("known"), coveredKnown)
        XCTAssertEqual(token("camera"), revealCamera); XCTAssertEqual(token("zoom"), revealZoom)
        wait("fade=0"); capture("06-whole-forest-revealed")
        tap("fogStyle"); capture("07-tiled-revealed-matched")
        XCTAssertEqual(token("camera"), revealCamera); XCTAssertEqual(token("zoom"), revealZoom)
        tap("fogStyle")
        tap("fogBuild"); tap("fogStep")
        tap("fogGameplay"); wait("moving=1"); XCTAssertFalse(value().contains("actors=0"), value())
        XCTAssertTrue(["zoom=0.9500", "zoom=1.1000"].contains(token("zoom")), value())
        capture("08-original-moving-gameplay-scale")
        tap("fogStatic"); wait("moving=0")
        let actor = token("actor"), builds = token("builds")
        let joints = token("joints"), facing = token("facing")
        capture("09-original-static")
        tap("fogLook"); wait("look=blue-braid")
        XCTAssertEqual(token("actor"), actor); XCTAssertEqual(token("builds"), builds)
        XCTAssertEqual(token("joints"), joints); XCTAssertEqual(token("facing"), facing)
        capture("10-blue-braid-static-same-anchors")
        tap("fogStatic"); wait("moving=1")
        XCTAssertEqual(token("actor"), actor); XCTAssertEqual(token("builds"), builds)
        capture("11-blue-braid-moving-gameplay-scale")
        // Let genuine renderer time show an existing complete activity sequence in the recording.
        let deadline = Date().addingTimeInterval(18)
        while Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.2)) }
        capture("12-blue-braid-existing-sequence")
        map.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.30)).press(forDuration: 0.05, thenDragTo: map.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.40)))
        map.pinch(withScale: 0.75, velocity: -1)
        assertHidden(); capture("13-revealed-edge-pan-pinch")
        tap("fogReturn")
        XCTAssertEqual(app.staticTexts["foundingStatus"].value as? String, founding)
        tap("foundingCatalog"); XCTAssertTrue(app.buttons["foundingCard-hut"].exists); tap("foundingCatalogDone")
        tap("closeFoundingReview")
    }
    @MainActor func testUI2MenusActionsAndRetainedReturn() throws {
        try menusFlow(largerText: false)
    }
    @MainActor func testUI2MenusLargerText() throws {
        try menusFlow(largerText: true)
    }
    @MainActor private func menusFlow(largerText: Bool) throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        if largerText { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityM"] }
        launchNormal(app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForNonExistence(timeout: 30))
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 15))
        app.buttons["developerTools"].tap(); XCTAssertTrue(app.buttons["openFoundingReview"].waitForExistence(timeout: 10)); app.buttons["openFoundingReview"].tap()
        XCTAssertTrue(app.staticTexts["foundingStatus"].waitForExistence(timeout: 15))
        func capture(_ name: String) {
            let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); a.name = "menus-" + (largerText ? "large-" : "") + name; a.lifetime = .keepAlways; add(a)
        }
        func tap(_ id: String) {
            let b = app.buttons[id]
            if !b.isHittable {
                let scroll = app.scrollViews["foundingControls"].exists ? app.scrollViews["foundingControls"] : app.scrollViews.firstMatch
                for _ in 0..<40 {
                    if b.isHittable { break }
                    let below = b.frame.isEmpty || b.frame.midY > scroll.frame.midY
                    scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: below ? 0.7 : 0.3)).press(forDuration: 0.02,
                        thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
                }
            }
            if !b.isHittable {
                capture("failure-" + id)
                let diagnostic = XCTAttachment(string: app.debugDescription); diagnostic.name = "menus-failure-hierarchy"; diagnostic.lifetime = .keepAlways; add(diagnostic)
            }
            XCTAssertTrue(b.isHittable, id); b.tap()
        }
        func search(_ text: String, submit: Bool = true) {
            let field = app.textFields["foundingSearch"]
            field.tap()
            let old = field.value as? String ?? ""
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: old == "Search buildings" ? 0 : old.count) + text + (submit ? "\n" : ""))
        }
        let goals = app.buttons["foundingRail-Goals"], explore = app.buttons["foundingRail-Explore"], games = app.buttons["foundingRail-Games"]
        for button in [goals, explore, games] {
            XCTAssertGreaterThanOrEqual(button.frame.height, 44); XCTAssertGreaterThanOrEqual(button.frame.width, 44); XCTAssertFalse(button.label.isEmpty)
        }
        XCTAssertLessThan(goals.frame.midY, explore.frame.midY); XCTAssertLessThan(explore.frame.midY, games.frame.midY)
        tap("foundingRail-Goals")
        XCTAssertEqual(app.staticTexts["foundingObjective"].label, "Upgrade Campfire to Founder’s Lodge")
        XCTAssertTrue(app.buttons["foundingGoalAction"].isHittable)
        XCTAssertGreaterThanOrEqual(app.buttons["foundingChapters"].frame.height, 44)
        XCTAssertEqual(app.buttons["foundingChapters"].value as? String, "Collapsed")
        capture("01-one-tap-goals")
        tap("foundingGoalAction")
        tap("foundingCatalog")
        search("Hut", submit: false)
        tap("foundingCatalogDone")
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        tap("foundingCatalog")
        tap("foundingCard-hut")
        XCTAssertEqual(app.buttons["foundingCatalogAction"].label, "Build")
        XCTAssertGreaterThanOrEqual(app.buttons["foundingCatalogAction"].frame.height, 44)
        XCTAssertGreaterThanOrEqual(app.buttons["foundingCatalogAction"].frame.width, 44)
        XCTAssertGreaterThanOrEqual(app.buttons["foundingCatalogAction"].frame.minY, app.frame.minY)
        XCTAssertLessThanOrEqual(app.buttons["foundingCatalogAction"].frame.maxY, app.frame.maxY)
        XCTAssertEqual(app.staticTexts.matching(identifier: "foundingPrice").count, 1)
        XCTAssertGreaterThanOrEqual(app.textFields["foundingSearch"].frame.height, 44)
        let cardSize = app.buttons["foundingCard-hut"].frame.size
        capture("02-build")
        if largerText {
            let grid = app.scrollViews["foundingCatalogGrid"]
            XCTAssertLessThanOrEqual(app.buttons["foundingCard-hut"].frame.maxY, grid.frame.maxY + 2)
            let details = app.scrollViews["foundingInspectorDetails"]
            details.swipeUp(velocity: .slow); capture("14-inspector-output-tail"); details.swipeDown(velocity: .slow)
        }
        tap("foundingCatalogAction")
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        tap("foundingConfirmHut")
        tap("foundingCatalog")
        XCTAssertEqual(app.textFields["foundingSearch"].value as? String, "Hut")
        XCTAssertEqual(app.staticTexts["foundingSelectedName"].label, "Hut")
        XCTAssertEqual(app.buttons["foundingCard-hut"].frame.size, cardSize)
        app.textFields["foundingSearch"].tap()
        tap("foundingCatalogDone")
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        tap("foundingCatalog")
        XCTAssertEqual(app.textFields["foundingSearch"].value as? String, "Hut")
        capture("03-dismiss-return")
        search("Storehouse"); tap("foundingCard-storehouse")
        XCTAssertEqual(app.buttons["foundingCatalogAction"].label, "Build")
        tap("foundingCatalogAction"); tap("foundingConfirmBuilding")
        tap("foundingCatalog")
        search("Gathering shelter"); tap("foundingCard-gatheringShelter")
        XCTAssertEqual(app.buttons["foundingCatalogAction"].label, "Build")
        tap("foundingCatalogAction"); tap("foundingConfirmBuilding")
        tap("foundingCatalog")
        search("Storehouse"); tap("foundingCard-storehouse")
        XCTAssertEqual(app.buttons["foundingCatalogAction"].label, "Find materials")
        capture("04-material-shortfall")
        if largerText {
            let details = app.scrollViews["foundingInspectorDetails"]
            details.swipeUp(velocity: .slow); capture("15-shortfall-output-tail"); details.swipeDown(velocity: .slow)
        }
        tap("foundingCatalogAction")
        XCTAssertEqual(app.staticTexts["foundingRequiredMaterials"].label, "Materials for Storehouse")
        XCTAssertTrue(app.buttons["foundingSource-woodcutter"].exists)
        XCTAssertFalse(app.staticTexts["foundingRequiredTechnology"].exists)
        capture("05-exact-material-route")
        tap("foundingSource-woodcutter")
        XCTAssertEqual(app.staticTexts["foundingSelectedName"].label, "Woodcutter")
        tap("foundingSourceBack")
        XCTAssertEqual(app.staticTexts["foundingRequiredMaterials"].label, "Materials for Storehouse")
        tap("foundingRequirementBack")
        XCTAssertEqual(app.staticTexts["foundingSelectedName"].label, "Storehouse")
        XCTAssertEqual(app.textFields["foundingSearch"].value as? String, "Storehouse")
        search("Toolmaker"); tap("foundingCard-toolmaker")
        XCTAssertEqual(app.buttons["foundingCatalogAction"].label, "Open required research")
        capture("06-research-locked")
        tap("foundingCatalogAction")
        XCTAssertEqual(app.staticTexts["foundingRequiredTechnology"].label, "Oral Tradition")
        capture("07-exact-research-route")
        XCTAssertTrue(app.buttons["foundingResearchSupplier"].exists)
        tap("foundingResearchSupplier")
        XCTAssertEqual(app.staticTexts["foundingSelectedName"].label, "Woodcutter")
        tap("foundingSourceBack")
        XCTAssertEqual(app.staticTexts["foundingRequiredTechnology"].label, "Oral Tradition")
        tap("foundingRequirementBack")
        XCTAssertEqual(app.staticTexts["foundingSelectedName"].label, "Toolmaker")
        XCTAssertEqual(app.textFields["foundingSearch"].value as? String, "Toolmaker")
        search("No matching item")
        XCTAssertTrue(app.staticTexts["foundingNoMatches"].exists)
        XCTAssertEqual(app.staticTexts["foundingSelectedName"].label, "Toolmaker")
        search("")
        tap("foundingCategory-Roads")
        XCTAssertTrue(app.staticTexts["foundingCatalogRoadHelp"].exists)
        capture("08-readable-roads")
        if largerText {
            let help = app.staticTexts["foundingCatalogRoadHelp"]
            let roads = app.scrollViews["foundingRoadInstructions"]
            XCTAssertTrue(help.exists)
            roads.swipeUp(velocity: .slow)
            capture("11-roads-text-tail")
            tap("foundingCatalogRoads")
            XCTAssertTrue(app.staticTexts["foundingRoadHelp"].exists)
            XCTAssertGreaterThanOrEqual(app.buttons["foundingConfirmPath"].frame.height, 44)
            capture("12-roads-map-panel")
            app.scrollViews["foundingControls"].swipeUp(velocity: .slow)
            capture("13-roads-map-panel-tail")
            tap("foundingToolsDone")
            tap("foundingCatalog")
        }
        tap("foundingCatalogDone"); tap("foundingCatalog")
        XCTAssertEqual(app.buttons["foundingCategory-Roads"].value as? String, "Selected")
        tap("foundingCategory-All")
        let grid = app.scrollViews["foundingCatalogGrid"]
        grid.swipeUp(velocity: .slow)
        let savedScroll = grid.value as? String
        tap("foundingCatalogDone"); tap("foundingCatalog")
        XCTAssertEqual(grid.value as? String, savedScroll)
        capture("10-retained-scroll")
        tap("foundingCatalogDone")
        tap("foundingRail-Explore"); tap("foundingExploreMap")
        let map = app.otherElements["onboardingWalkthroughMap"]
        let before = map.value as? String ?? ""
        map.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.45)).press(forDuration: 0.05, thenDragTo: map.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.5)))
        map.pinch(withScale: 1.15, velocity: 1)
        XCTAssertNotEqual(map.value as? String ?? "", before)
        capture("09-map-gestures")
        tap("closeFoundingReview")
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 10))
    }

    @MainActor func testUI2FoundingMapInteractionAndReload() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 30))
        func open() {
            app.buttons["developerTools"].tap()
            XCTAssertTrue(app.buttons["openFoundingReview"].waitForExistence(timeout: 10))
            app.buttons["openFoundingReview"].tap()
            XCTAssertTrue(app.staticTexts["foundingStatus"].waitForExistence(timeout: 15))
            app.buttons["foundingRail-Games"].tap(); app.buttons["foundingTools"].tap()
        }
        open()
        let status = app.staticTexts["foundingStatus"]
        func value() -> String { status.value as? String ?? "" }
        func field(_ key: String) throws -> Int {
            let part = try XCTUnwrap(value().split(separator: " ").first { $0.hasPrefix(key + "=") })
            return try XCTUnwrap(Int(part.dropFirst(key.count + 1)))
        }
        func tap(_ id: String) {
            let b = app.buttons[id]
            let scroll = app.scrollViews["foundingControls"]
            for _ in 0..<60 {
                if b.isHittable { break }
                let below = b.frame.isEmpty || b.frame.midY > scroll.frame.midY
                scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: below ? 0.7 : 0.3)).press(forDuration: 0.02,
                    thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
            }
            XCTAssertTrue(b.isHittable, id); b.tap()
        }
        func capture(_ name: String) {
            let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            a.name = "ui2-" + name; a.lifetime = .keepAlways; add(a)
            print("UI2 " + name + " " + value() + " objective=" + app.staticTexts["foundingObjective"].label)
        }
        let map = app.otherElements["onboardingWalkthroughMap"]
        func mapField(_ key: String) throws -> Double {
            let v = map.value as? String ?? ""
            let part = try XCTUnwrap(v.split(separator: " ").first { $0.hasPrefix(key + "=") }, v)
            return try XCTUnwrap(Double(part.dropFirst(key.count + 1)))
        }
        func tapMapTarget(_ name: String) throws {
            let x = try mapField(name + "X"), y = try mapField(name + "Y")
            XCTAssertGreaterThan(x, 10); XCTAssertGreaterThan(y, 10)
            XCTAssertLessThan(x, map.frame.width - 325); XCTAssertLessThan(y, map.frame.height - 10)
            map.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y)).tap()
        }
        XCTAssertEqual(try field("civic"), 0); XCTAssertEqual(try field("level"), 1)
        XCTAssertEqual(try field("wood"), 100); XCTAssertEqual(try field("stone"), 50)
        XCTAssertEqual(try field("story"), 0); XCTAssertGreaterThanOrEqual(try field("sites"), 2)
        XCTAssertEqual(app.staticTexts["foundingObjective"].label, "Upgrade Campfire to Founder’s Lodge")
        capture("01-campfire")
        tap("foundingUpgrade")
        XCTAssertEqual(try field("civic"), 0); XCTAssertEqual(try field("level"), 2)
        XCTAssertEqual(try field("wood"), 88); XCTAssertEqual(try field("stone"), 46)
        XCTAssertEqual(try field("roads"), 1); XCTAssertEqual(try field("story"), 0)
        XCTAssertEqual(try field("civicHistory"), 2)
        XCTAssertEqual(app.staticTexts["foundingObjective"].label, "Build your first hut")
        capture("02-lodge-free-path")
        try tapMapTarget("civic")
        XCTAssertTrue(app.staticTexts["foundingInspection"].label.contains("Founder’s Lodge"))
        try tapMapTarget("plot0")
        XCTAssertTrue(app.buttons["foundingConfirmHut"].exists)
        try tapMapTarget("plot1"); capture("03-visible-hut-fallback")
        tap("foundingConfirmHut")
        let paidWood = try field("wood")
        tap("foundingAdvance60")
        XCTAssertEqual(try field("active"), 0)
        XCTAssertEqual(app.staticTexts["foundingObjective"].label, "Connect your hut to the Lodge")
        XCTAssertTrue(app.staticTexts["foundingConnectionExplanation"].exists)
        capture("04-disconnected")
        tap("foundingDrawPath")
        let coordinates = map.value as? String ?? ""
        let routeCount = coordinates.split(separator: " ").filter { $0.hasPrefix("route") && $0.contains("X=") }.count
        XCTAssertGreaterThan(routeCount, 0)
        for index in 0..<routeCount { try tapMapTarget("route\(index)") }
        capture("05-route-preview"); tap("foundingConfirmPath")
        XCTAssertEqual(try field("active"), 1)
        XCTAssertEqual(try field("wood"), paidWood)
        XCTAssertEqual(app.staticTexts["foundingObjective"].label, "Founding connected")
        capture("06-connected")
        let history = try field("goals")
        tap("foundingDisconnect")
        XCTAssertEqual(try field("active"), 0); XCTAssertEqual(try field("wood"), paidWood)
        XCTAssertEqual(try field("goals"), history); XCTAssertEqual(try field("story"), 0)
        capture("07-disconnected-retained")
        let saved = value()
        app.terminate(); app.launch()
        let continueButton = app.buttons["continueGame"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 30)); continueButton.tap()
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 30)); open()
        XCTAssertEqual(value(), saved)
        XCTAssertEqual(app.staticTexts["foundingObjective"].label, "Connect your hut to the Lodge")
        capture("08-reloaded")
        tap("foundingSuggestPath"); tap("foundingConfirmPath")
        XCTAssertEqual(try field("active"), 1); capture("09-reconnected")
        tap("closeFoundingReview")
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 10))
    }

    /// Goal5 review starts fresh, delays until Food is depleted, then recovers through existing controls.
    @MainActor func testFirstEraDelayedDepletedRecoveryThroughCraft() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForNonExistence(timeout: 30))
        app.buttons["developerTools"].tap(); app.buttons["openEconomyLab"].tap()
        let status = app.staticTexts["economyLabStatus"]
        XCTAssertTrue(status.waitForExistence(timeout: 15))
        func value() -> String { status.value as? String ?? "" }
        func field(_ key: String) throws -> Int {
            let part = try XCTUnwrap(value().split(separator: " ").first { $0.hasPrefix(key + "=") })
            return try XCTUnwrap(Int(part.dropFirst(key.count + 1)))
        }
        func reveal(_ element: XCUIElement) {
            let scroll = app.scrollViews.firstMatch
            for _ in 0..<60 {
                let frame = element.frame
                let visible = scroll.frame.intersection(app.frame).insetBy(dx: 2, dy: 2)
                // Offscreen SwiftUI buttons can have no AX activation point. Bring
                // their geometric center into the viewport before asking hittability.
                if !frame.isEmpty && frame.midX.isFinite && frame.midY.isFinite && visible.contains(CGPoint(x: frame.midX, y: frame.midY)) && element.isHittable { return }
                let below = frame.isEmpty || !frame.midY.isFinite || frame.midY > visible.midY
                scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: below ? 0.7 : 0.3)).press(forDuration: 0.02,
                    thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
            }
            XCTAssertTrue(element.isHittable, element.identifier)
        }
        func tap(_ id: String) { let button = app.buttons[id]; reveal(button); button.tap() }
        func capture(_ name: String) {
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = name; shot.lifetime = .keepAlways; add(shot)
            print("GOAL5 " + name + " " + value() + " guide=" + app.staticTexts["economyLabGuide"].label)
        }
        func build(_ kind: String) { tap("labBuild-" + kind); tap("labConfirmBuild"); tap("labAdvance60") }
        func realWaitUntil(_ predicate: @escaping () -> Bool, name: String) {
            let began = Date()
            let condition = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in predicate() }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [condition], timeout: 85), .completed)
            print("GOAL5 actual elapsed " + name + " seconds=\(Date().timeIntervalSince(began))")
        }
        tap("labPause")
        XCTAssertEqual(try field("wood"), 32)
        XCTAssertTrue(app.staticTexts["economyLabGuide"].label.contains("Hut"))
        reveal(app.staticTexts["economyLabGuide"]); capture("first-era-fresh-next-action")
        // Explicit review steps represent a 33-minute delayed opening, not wall-clock waiting.
        for _ in 0..<33 { tap("labAdvance60") }
        XCTAssertEqual(try field("food"), 0)
        XCTAssertEqual(try field("wood"), 32)
        reveal(app.staticTexts["economyLabGuide"]); capture("first-era-delayed-food-depleted")
        build("hut")
        XCTAssertFalse(app.buttons["labSurvey"].isEnabled)
        reveal(app.buttons["labSurvey"])
        capture("first-era-survey-blocked-eight-food")
        tap("labRecoverFood"); XCTAssertEqual(try field("food"), 12)
        tap("labRecoverFood"); XCTAssertEqual(try field("food"), 12)
        tap("labSurvey"); XCTAssertEqual(try field("food"), 4)
        reveal(app.staticTexts["labSurveyTimer"]); capture("first-era-survey-paid-wait")
        tap("labPause") // Resume real 1x time for this required wait.
        realWaitUntil({ value().contains("survey=true") }, name: "survey")
        tap("labPause")
        XCTAssertEqual(try field("knowledge"), 6)
        build("woodcutter"); build("gatheringShelter")
        XCTAssertTrue(value().contains("checkpoint=true"))
        XCTAssertTrue(value().contains("foodNet=7.0"))
        tap("labRevealStone")
        build("stoneGatherer")
        // Shelter+hut+woodcutter+gatherer consume the reserve. Stockyard needs18 Wood+6 Stone.
        tap("labStorage-stockyard")
        XCTAssertFalse(app.buttons["labConfirmBuild"].isEnabled)
        XCTAssertTrue(app.staticTexts["labError"].label.contains("18 Wood + 6 Stone"))
        reveal(app.staticTexts["labError"]); capture("first-era-stockyard-blocked-cost")
        app.buttons["Cancel"].tap()
        for _ in 0..<10 { tap("labAdvance60") }
        XCTAssertGreaterThanOrEqual(try field("stone"), 6)
        tap("labStorage-stockyard"); tap("labConfirmBuild"); tap("labAdvance60")
        tap("labStorage-granary"); tap("labConfirmBuild"); tap("labAdvance60")
        XCTAssertEqual(try field("foodCap"), 120); XCTAssertEqual(try field("woodCap"), 120)
        tap("labUnlockCraft")
        XCTAssertFalse(app.buttons["labCraftTool"].isEnabled)
        reveal(app.staticTexts["labCraftProject"]); capture("first-era-craft-blocked-flint-source")
        tap("labMode-flint"); tap("labAdvance60"); tap("labAdvance60")
        tap("labCraftTool")
        XCTAssertEqual(try field("tools"), 0)
        reveal(app.staticTexts["labToolTimer"]); capture("first-era-tool-paid-wait")
        tap("labPause")
        realWaitUntil({ (try? field("tools")) == 1 }, name: "tool-batch")
        tap("labPause")
        for _ in 0..<2 { tap("labCraftTool"); tap("labAdvance60") }
        XCTAssertEqual(try field("tools"), 3)
        tap("labSpendTools")
        XCTAssertTrue(value().contains("improved=true")); XCTAssertTrue(value().contains("woodNet=8.0"))
        XCTAssertEqual(try field("tools"), 0)
        XCTAssertTrue(app.staticTexts["economyLabGuide"].label.contains("3 Tools spent once"))
        reveal(app.staticTexts["labCraftImproved"]); capture("first-era-recovered-post-craft-checkpoint")
        app.buttons["closeEconomyLab"].tap(); app.buttons["openEconomyLab"].tap()
        XCTAssertTrue(status.waitForExistence(timeout: 15)); tap("labPause")
        XCTAssertTrue(value().contains("improved=true")); XCTAssertEqual(try field("tools"), 0)
        XCTAssertEqual(try field("knowledge"), 6)
        reveal(app.staticTexts["economyLabGuide"]); capture("first-era-recovered-reopen")
        app.buttons["closeEconomyLab"].tap(); app.navigationBars["Developer tools"].buttons["Done"].tap()
        let ordinaryMap = app.otherElements["settlementMap"]
        XCTAssertTrue(ordinaryMap.waitForExistence(timeout: 15))
        XCTAssertTrue((ordinaryMap.value as? String ?? "").contains("64×48 tiles · 1 buildings · 0 road tiles"))
    }

    @MainActor func testFirstCraftGatherCraftSpendAndReload() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        func open() {
            XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForNonExistence(timeout: 30))
            app.buttons["developerTools"].tap(); app.buttons["openEconomyLab"].tap()
            XCTAssertTrue(app.staticTexts["economyLabStatus"].waitForExistence(timeout: 15))
        }
        launchNormal(app); open()
        let status = app.staticTexts["economyLabStatus"]
        func value() -> String { status.value as? String ?? "" }
        func field(_ key: String) throws -> Int {
            let part = try XCTUnwrap(value().split(separator: " ").first { $0.hasPrefix(key + "=") })
            return try XCTUnwrap(Int(part.dropFirst(key.count + 1)))
        }
        func reveal(_ element: XCUIElement) {
            let scroll = app.scrollViews.firstMatch
            for _ in 0..<60 where !element.isHittable {
                let below = element.frame.midY > scroll.frame.midY
                scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: below ? 0.7 : 0.3)).press(forDuration: 0.02,
                    thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
            }
            XCTAssertTrue(element.isHittable, element.identifier)
        }
        func tap(_ id: String) {
            let button = app.buttons[id]
            reveal(button); button.tap()
        }
        func capture(_ name: String) {
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = name; shot.lifetime = .keepAlways; add(shot)
        }
        func build(_ kind: String) { tap("labBuild-" + kind); tap("labConfirmBuild"); tap("labAdvance60") }
        tap("labPause")
        XCTAssertFalse(app.buttons["labUnlockCraft"].exists)
        XCTAssertTrue(value().contains("craft=false"))
        build("hut"); tap("labSurvey"); tap("labAdvance60")
        build("woodcutter"); build("gatheringShelter")
        for _ in 0..<9 { tap("labAdvance60") }
        tap("labRevealStone"); build("stoneGatherer")
        tap("labUnlockCraft")
        XCTAssertEqual(try field("flintCap"), 24); XCTAssertEqual(try field("toolsCap"), 24)
        XCTAssertTrue(app.staticTexts["labCraftProject"].exists)
        XCTAssertFalse(app.buttons["labCraftTool"].isEnabled)
        reveal(app.staticTexts["labFlintSource"]); capture("craft-revealed-flint-source")
        reveal(app.staticTexts["labCraftProject"]); capture("craft-source-cost-and-project")
        tap("labMode-flint")
        let stone = try field("stone")
        tap("labAdvance60"); tap("labAdvance60")
        XCTAssertEqual(try field("stone"), stone); XCTAssertEqual(try field("flint"), 8)
        tap("labMode-stone")
        let wood = try field("wood")
        tap("labCraftTool")
        XCTAssertEqual(try field("wood"), wood - 2)
        XCTAssertEqual(try field("flint"), 6)
        XCTAssertEqual(try field("tools"), 0); XCTAssertEqual(try field("batch"), 60)
        tap("labAdvance10")
        reveal(app.staticTexts["labToolTimer"]); capture("craft-paid-real-wait")
        app.buttons["closeEconomyLab"].tap(); app.buttons["openEconomyLab"].tap()
        XCTAssertTrue(status.waitForExistence(timeout: 15)); tap("labPause")
        XCTAssertEqual(try field("flint"), 6); XCTAssertGreaterThan(try field("batch"), 0)
        tap("labAdvance60"); XCTAssertEqual(try field("tools"), 1)
        for count in 2...3 {
            tap("labCraftTool"); tap("labAdvance60")
            XCTAssertEqual(try field("tools"), count)
        }
        capture("craft-three-tools-before-spend")
        tap("labSpendTools")
        XCTAssertEqual(try field("tools"), 0)
        XCTAssertTrue(value().contains("improved=true")); XCTAssertTrue(value().contains("woodNet=8.0"))
        XCTAssertTrue(app.staticTexts["labCraftImproved"].exists)
        reveal(app.staticTexts["labCraftImproved"]); capture("craft-lasting-woodcutter-improvement")
        tap("labStorage-stockyard"); tap("labConfirmBuild"); tap("labAdvance60")
        XCTAssertEqual(try field("flintCap"), 48); XCTAssertEqual(try field("toolsCap"), 48)
        XCTAssertEqual(try field("foodCap"), 60)
        app.terminate() // Retain the same UUID-backed temporary library on relaunch.
        launchNormal(app); open(); tap("labPause")
        XCTAssertTrue(value().contains("improved=true")); XCTAssertTrue(value().contains("woodNet=8.0"))
        XCTAssertEqual(try field("tools"), 0); XCTAssertEqual(try field("flint"), 2)
        XCTAssertEqual(try field("batch"), 0); XCTAssertEqual(try field("flintCap"), 48)
        XCTAssertFalse(app.buttons["labSpendTools"].exists)
        XCTAssertEqual(try field("knowledge"), 6)
        XCTAssertTrue(value().contains("berries=") && value().contains("pending"))
        capture("craft-relaunch-persistent-project")
        app.buttons["closeEconomyLab"].tap(); app.navigationBars["Developer tools"].buttons["Done"].tap()
        XCTAssertTrue(app.otherElements["settlementMap"].exists)
    }


    @MainActor func testStoneStorageRevealCollectSpendAndReload() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        func open() {
            XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForNonExistence(timeout: 30))
            app.buttons["developerTools"].tap(); app.buttons["openEconomyLab"].tap()
            XCTAssertTrue(app.staticTexts["economyLabStatus"].waitForExistence(timeout: 15))
        }
        launchNormal(app); open()
        let status = app.staticTexts["economyLabStatus"]
        func value() -> String { status.value as? String ?? "" }
        func field(_ key: String) throws -> Int {
            let part = try XCTUnwrap(value().split(separator: " ").first { $0.hasPrefix(key + "=") })
            return try XCTUnwrap(Int(part.dropFirst(key.count + 1)))
        }
        func tap(_ id: String) {
            let button = app.buttons[id]
            for _ in 0..<24 where !button.isHittable {
                let scroll = app.scrollViews.firstMatch
                scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8)).press(forDuration: 0.02,
                    thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55)))
            }
            if !button.isHittable { for _ in 0..<24 where !button.isHittable {
                let scroll = app.scrollViews.firstMatch
                scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)).press(forDuration: 0.02,
                    thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6)))
            } }
            if !button.isHittable { capture("stone-unhittable-" + id) }
            XCTAssertTrue(button.isHittable, id); button.tap()
        }
        func capture(_ name: String) {
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = name; shot.lifetime = .keepAlways; add(shot)
        }
        func build(_ kind: String) { tap("labBuild-" + kind); tap("labConfirmBuild"); tap("labAdvance60") }
        tap("labPause")
        XCTAssertFalse(app.buttons["labRevealStone"].exists)
        build("hut"); tap("labSurvey"); tap("labAdvance60")
        build("woodcutter"); build("gatheringShelter")
        XCTAssertTrue(value().contains("checkpoint=true"))
        for _ in 0..<9 { tap("labAdvance60") }
        tap("labRevealStone")
        XCTAssertTrue(value().contains("source=true"))
        XCTAssertTrue(app.staticTexts["labStoneSource"].exists)
        capture("stone-revealed-source")
        build("stoneGatherer")
        for _ in 0..<9 { tap("labAdvance60") }
        XCTAssertEqual(try field("stone"), 40)
        tap("labAdvance60"); XCTAssertEqual(try field("stone"), 40)
        tap("labStorage-granary"); tap("labConfirmBuild")
        XCTAssertEqual(try field("stone"), 36)
        XCTAssertEqual(try field("foodCap"), 60)
        app.buttons["closeEconomyLab"].tap(); app.buttons["openEconomyLab"].tap()
        XCTAssertTrue(status.waitForExistence(timeout: 15)); tap("labPause"); tap("labAdvance60")
        XCTAssertEqual(try field("foodCap"), 120)
        XCTAssertEqual(try field("woodCap"), 60); XCTAssertEqual(try field("stoneCap"), 40)
        capture("stone-granary-food-only")
        tap("labStorage-stockyard"); tap("labConfirmBuild")
        XCTAssertEqual(try field("stone"), 34)
        tap("labAdvance60")
        XCTAssertEqual(try field("foodCap"), 120)
        XCTAssertEqual(try field("woodCap"), 120); XCTAssertEqual(try field("stoneCap"), 100)
        for _ in 0..<14 { tap("labAdvance60") }
        XCTAssertEqual(try field("stone"), 100)
        XCTAssertGreaterThan(try field("wood"), 60)
        XCTAssertGreaterThan(try field("food"), 60)
        capture("stone-stockyard-expanded-caps")
        app.terminate() // Retain the same UUID-backed temporary library on relaunch.
        launchNormal(app); open(); tap("labPause")
        XCTAssertEqual(try field("stone"), 100); XCTAssertEqual(try field("storage"), 2)
        XCTAssertEqual(try field("foodCap"), 120); XCTAssertEqual(try field("woodCap"), 120)
        XCTAssertEqual(try field("knowledge"), 6)
        XCTAssertTrue(value().contains("checkpoint=true"))
        capture("stone-storage-relaunch")
        app.buttons["closeEconomyLab"].tap(); app.navigationBars["Developer tools"].buttons["Done"].tap()
        XCTAssertTrue(app.otherElements["settlementMap"].exists)
    }

    @MainActor func testMapFindsWaitDismissGatherObserveAndReload() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        func open() {
            XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForNonExistence(timeout: 30))
            app.buttons["developerTools"].tap(); app.buttons["openEconomyLab"].tap()
            XCTAssertTrue(app.staticTexts["economyLabStatus"].waitForExistence(timeout: 15))
        }
        launchNormal(app); open()
        let status = app.staticTexts["economyLabStatus"]
        func value() -> String { status.value as? String ?? "" }
        func tap(_ id: String) {
            let button = app.buttons[id]
            for _ in 0..<7 where !button.isHittable { app.scrollViews.firstMatch.swipeUp() }
            if !button.isHittable { for _ in 0..<7 where !button.isHittable { app.scrollViews.firstMatch.swipeDown() } }
            XCTAssertTrue(button.isHittable, id); button.tap()
        }
        func fields(_ text: String, _ name: String) throws -> String {
            let part = try XCTUnwrap(text.split(separator: " ").first { $0.hasPrefix(name + "=") })
            return String(part.dropFirst(name.count + 1))
        }
        let map = app.otherElements["onboardingWalkthroughMap"]
        func inspect(_ id: String) throws {
            let location = try fields(value(), id).split(separator: ",")
            let tile = Tile(x: try XCTUnwrap(Int(location[0])), y: try XCTUnwrap(Int(location[1])))
            let geometry = try XCTUnwrap(map.value as? String)
            let config = try GameConfiguration.riverbendEconomyLab()
            let point = MapGeometry.point(for: tile), civic = MapGeometry.point(for: config.map.campfire)
            let zoom = try XCTUnwrap(Double(fields(geometry, "zoom")))
            let target = map.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
                dx: try XCTUnwrap(Double(fields(geometry, "civicX"))) + (point.x - civic.x) / zoom,
                dy: try XCTUnwrap(Double(fields(geometry, "civicY"))) - (point.y - civic.y) / zoom))
            target.tap()
            XCTAssertTrue(app.staticTexts["labFindTitle"].waitForExistence(timeout: 5))
        }
        func capture(_ name: String) {
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = name; shot.lifetime = .keepAlways; add(shot)
        }
        tap("labBuild-hut"); tap("labConfirmBuild")
        // The Hut is genuinely in progress; no synthetic fixture or reward injection.
        XCTAssertTrue((map.value as? String ?? "").contains("construction=legacy"))
        tap("labPause")
        XCTAssertTrue(value().contains("pending"))
        map.pinch(withScale: 0.65, velocity: -1)
        try inspect("tracks")
        XCTAssertEqual(app.staticTexts["labFindTitle"].label, "Fresh deer tracks", "Nearest marker wins when touch targets overlap after zoom")
        tap("labDismissFind")
        map.pinch(withScale: 1.0 / 0.65, velocity: 1)
        try inspect("berries")
        XCTAssertEqual(app.staticTexts["labFindTitle"].label, "Wild berries")
        capture("map-finds-construction-wait-berries")
        tap("labDismissFind")
        XCTAssertFalse(app.buttons["labResolveFind"].exists)
        XCTAssertTrue(value().contains("pending"))
        app.buttons["closeEconomyLab"].tap(); app.buttons["openEconomyLab"].tap()
        XCTAssertTrue(status.waitForExistence(timeout: 15)); tap("labPause")
        try inspect("berries")
        let food = try XCTUnwrap(Int(fields(value(), "food")))
        tap("labResolveFind")
        XCTAssertEqual(try fields(value(), "food"), String(food + 3))
        XCTAssertTrue(try fields(value(), "berries").hasSuffix("resolved"))
        try inspect("tracks")
        XCTAssertEqual(app.staticTexts["labFindTitle"].label, "Fresh deer tracks")
        let beforeObserve = value()
        capture("map-finds-tracks-observe")
        tap("labResolveFind")
        XCTAssertEqual(try fields(value(), "food"), try fields(beforeObserve, "food"))
        XCTAssertTrue(try fields(value(), "tracks").hasSuffix("resolved"))
        tap("labAdvance60"); tap("labSurvey"); tap("labAdvance60")
        for kind in ["woodcutter", "gatheringShelter"] {
            tap("labBuild-" + kind)
            XCTAssertFalse(app.buttons["labResolveFind"].exists)
            tap("labConfirmBuild"); tap("labAdvance60")
        }
        XCTAssertTrue(value().contains("checkpoint=true"))
        app.terminate() // Retain the same UUID-backed temporary library on relaunch.
        launchNormal(app); open(); tap("labPause")
        XCTAssertTrue(value().contains("checkpoint=true"))
        XCTAssertTrue(try fields(value(), "berries").hasSuffix("resolved"))
        XCTAssertTrue(try fields(value(), "tracks").hasSuffix("resolved"))
        XCTAssertFalse(app.buttons["labResolveFind"].exists)
        capture("map-finds-reloaded-checkpoint")
        app.buttons["closeEconomyLab"].tap(); app.navigationBars["Developer tools"].buttons["Done"].tap()
        XCTAssertTrue(app.otherElements["settlementMap"].exists)
    }

    @MainActor func testEconomyLabGestureRouteAndReload() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForNonExistence(timeout: 30))
        app.buttons["developerTools"].tap(); app.buttons["openEconomyLab"].tap()
        let status = app.staticTexts["economyLabStatus"]
        XCTAssertTrue(status.waitForExistence(timeout: 15))
        func tap(_ id: String) {
            let button = app.buttons[id]
            for _ in 0..<7 where !button.isHittable { app.scrollViews.firstMatch.swipeUp() }
            if !button.isHittable {
                for _ in 0..<7 where !button.isHittable { app.scrollViews.firstMatch.swipeDown() }
            }
            XCTAssertTrue(button.isHittable, id); button.tap()
        }
        func build(_ value: String) {
            tap("labBuild-" + value); tap("labNextSite"); tap("labConfirmBuild"); tap("labAdvance60")
        }
        tap("labPause")
        XCTAssertTrue((status.value as? String ?? "").contains("wood=32"))
        let map = app.otherElements["onboardingWalkthroughMap"]
        tap("labPause") // resume, then verify ticks preserve a player-selected camera
        map.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5)).press(forDuration: 0.05,
            thenDragTo: map.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.6)))
        let camera = try XCTUnwrap(map.value as? String).components(separatedBy: " sceneBuilds=").first
        Thread.sleep(forTimeInterval: 2)
        XCTAssertEqual((map.value as? String)?.components(separatedBy: " sceneBuilds=").first, camera)
        tap("labPause")
        tap("labBuild-hut")
        let location = app.staticTexts["labPlacement"].label
        let numbers = location.split { !($0.isNumber || $0 == "-") }.compactMap { Int($0) }
        let origin = Tile(x: try XCTUnwrap(numbers.first), y: try XCTUnwrap(numbers.dropFirst().first))
        let mapValue = try XCTUnwrap(map.value as? String)
        func field(_ name: String) throws -> Double {
            let part = try XCTUnwrap(mapValue.split(separator: " ").first { $0.hasPrefix(name + "=") })
            return try XCTUnwrap(Double(part.dropFirst(name.count + 1)))
        }
        let config = try GameConfiguration.riverbendEconomyLab()
        let center = config.definition(.hut).footprint.center(at: origin)
        let civic = MapGeometry.point(for: config.map.campfire)
        let zoom = try field("zoom")
        let roof = map.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
            dx: try field("civicX") + (center.x - civic.x) / zoom,
            dy: try field("civicY") - (center.y - civic.y + 55) / zoom))
        roof.tap()
        XCTAssertEqual(app.staticTexts["labPlacement"].label, location, "Preview roof tap retains origin")
        let beforeDragCamera = (map.value as? String)?.components(separatedBy: "camera=").last
        roof.press(forDuration: 0.05, thenDragTo: roof.withOffset(CGVector(dx: 32 / zoom, dy: 16 / zoom)))
        let moved = app.staticTexts["labPlacement"].label.split { !($0.isNumber || $0 == "-") }.compactMap { Int($0) }
        XCTAssertEqual(moved, [origin.x + 1, origin.y])
        XCTAssertEqual((map.value as? String)?.components(separatedBy: "camera=").last, beforeDragCamera)
        tap("labNextSite"); tap("labConfirmBuild"); tap("labAdvance60")
        tap("labSurvey")
        let paid = try XCTUnwrap(status.value as? String)
        XCTAssertTrue(paid.contains("knowledge=0"))
        // Dismiss and reopen the persisted lab in the same independent namespace.
        app.buttons["closeEconomyLab"].tap(); app.buttons["openEconomyLab"].tap()
        XCTAssertTrue(status.waitForExistence(timeout: 15))
        tap("labPause")
        tap("labAdvance60")
        XCTAssertTrue((status.value as? String ?? "").contains("knowledge=6 survey=true"))
        build("woodcutter"); build("gatheringShelter")
        XCTAssertTrue((status.value as? String ?? "").contains("checkpoint=true"))
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); attachment.name = "economy-lab-positive-loop"; attachment.lifetime = .keepAlways; add(attachment)
        tap("labAdvance60")
        XCTAssertTrue((status.value as? String ?? "").contains("woodNet=6.0"))
        app.terminate()
        // Keep the same QA library/lab identity; production save roots are never read.
        // FRESH_SAVE selects the existing UUID directory; it never resets that directory.
        launchNormal(app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForNonExistence(timeout: 30))
        app.buttons["developerTools"].tap(); app.buttons["openEconomyLab"].tap()
        XCTAssertTrue(status.waitForExistence(timeout: 15))
        XCTAssertTrue((status.value as? String ?? "").contains("checkpoint=true"))
        XCTAssertTrue((status.value as? String ?? "").contains("knowledge=6"))
        app.buttons["closeEconomyLab"].tap()
        app.navigationBars["Developer tools"].buttons["Done"].tap()
        XCTAssertTrue(app.otherElements["settlementMap"].exists)
    }

    @MainActor func testVillagerMotionCloseProbe() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForNonExistence(timeout: 30))
        app.buttons["developerTools"].tap(); app.buttons["openNativeVisualReview"].tap()
        XCTAssertTrue(app.buttons["openVillagerMotionReview"].waitForExistence(timeout: 10))
        app.buttons["openVillagerMotionReview"].tap()
        let done = app.buttons["closeVillagerMotionReview"]
        XCTAssertTrue(done.waitForExistence(timeout: 10))
        app.buttons["villagerNextPose"].tap(); app.buttons["villagerPower"].tap()
        print("VILLAGER_CLOSE_BEFORE \(done.value ?? "missing") \(done.frame)")
        done.tap()
        let closed = done.waitForNonExistence(timeout: 10)
        if !closed { print("VILLAGER_CLOSE_AFTER \(done.value ?? "missing") \(done.frame)") }
        XCTAssertTrue(closed)
    }

    @MainActor func testVillagerMotionShortRecording() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForNonExistence(timeout: 30))
        let normal = try XCTUnwrap(app.otherElements["settlementMap"].value as? String)
        app.buttons["developerTools"].tap(); app.buttons["openNativeVisualReview"].tap()
        XCTAssertTrue(app.buttons["openVillagerMotionReview"].waitForExistence(timeout: 10))
        app.buttons["openVillagerMotionReview"].tap()
        let status = app.staticTexts["villagerPoseStatus"]
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        for activity in ["walk", "carry", "gather", "work"] {
            app.buttons["villagerNextPose"].tap()
            let first = try XCTUnwrap(status.value as? String)
            XCTAssertTrue(first.contains("activity=\(activity)"), first)
            Thread.sleep(forTimeInterval: 3)
            let second = try XCTUnwrap(status.value as? String)
            func joints(_ value: String) -> String? { value.split(separator: " ").first { $0.hasPrefix("joints=") }.map(String.init) }
            XCTAssertNotNil(joints(first)); XCTAssertNotEqual(joints(first), joints(second))
            print("VILLAGER_RECORDED_MOTION \(first) → \(second)")
        }
        app.buttons["villagerStatic"].tap()
        let frozen = try XCTUnwrap(status.value as? String)
        Thread.sleep(forTimeInterval: 2)
        XCTAssertEqual(status.value as? String, frozen)
        app.buttons["closeVillagerMotionReview"].tap()
        XCTAssertTrue(app.buttons["closeVillagerMotionReview"].waitForNonExistence(timeout: 10))
        app.buttons["closeNativeVisualReview"].tap()
        XCTAssertTrue(app.buttons["closeNativeVisualReview"].waitForNonExistence(timeout: 10))
        app.navigationBars["Developer tools"].buttons["Done"].tap()
        XCTAssertEqual(try XCTUnwrap(app.otherElements["settlementMap"].value as? String).components(separatedBy: " sceneBuilds=").first,
                       normal.components(separatedBy: " sceneBuilds=").first)
    }

    @MainActor func testVillagerMotionReviewStatesAndStaticFallback() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForNonExistence(timeout: 30))
        let normal = try XCTUnwrap(app.otherElements["settlementMap"].value as? String)
        app.buttons["developerTools"].tap(); app.buttons["openNativeVisualReview"].tap()
        let entry = app.buttons["openVillagerMotionReview"]
        XCTAssertTrue(entry.waitForExistence(timeout: 10))
        let lab = app.descendants(matching: .any).matching(identifier: "nativeVisualReviewMap").firstMatch
        XCTAssertTrue(lab.waitForExistence(timeout: 10))
        let initialLabCamera = try XCTUnwrap(lab.value as? String).components(separatedBy: " sceneBuilds=").first
        lab.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.60)).press(forDuration: 0.05,
            thenDragTo: lab.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.65)))
        let movedLabCamera = try XCTUnwrap(lab.value as? String).components(separatedBy: " sceneBuilds=").first
        XCTAssertNotEqual(movedLabCamera, initialLabCamera)
        entry.tap()
        let status = app.staticTexts["villagerPoseStatus"]
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        func value() -> String { status.value as? String ?? "" }
        func field(_ key: String, in snapshot: String) -> String {
            snapshot.split(separator: " ").first { $0.hasPrefix(key + "=") }.map(String.init) ?? "missing"
        }
        let initial = value(), actorID = field("actorID", in: initial), nodes = field("nodes", in: initial)
        for activity in ["idle", "walk", "carry", "gather", "work", "rest", "socialize", "turn"] {
            let pose = value()
            XCTAssertTrue(pose.contains("activity=\(activity)"), pose)
            XCTAssertTrue(pose.contains("figures=1"), pose)
            XCTAssertEqual(field("actorID", in: pose), actorID)
            XCTAssertEqual(field("nodes", in: pose), nodes)
            capture("villager-pose-" + activity, app: app)
            app.buttons["villagerNextPose"].tap()
        }
        XCTAssertTrue(value().contains("activity=idle"))
        for facing in ["nearLeft", "awayRight", "awayLeft", "nearRight"] {
            app.buttons["villagerFacing"].tap()
            let pose = value()
            XCTAssertTrue(pose.contains("facing=\(facing)"), pose)
            XCTAssertTrue(pose.contains("noseHidden=\(facing.hasPrefix("away") ? 1 : 0)"), pose)
        }
        app.buttons["villagerNextPose"].tap()
        app.buttons["villagerStatic"].tap()
        let frozen = value(); Thread.sleep(forTimeInterval: 1.2)
        XCTAssertEqual(value(), frozen)
        XCTAssertTrue(frozen.contains("moving=false"))
        let frozenJoints = field("joints", in: frozen)
        app.buttons["villagerStatic"].tap()
        let moving = XCTNSPredicateExpectation(predicate: NSPredicate { _,_ in
            let pose = value()
            return field("joints", in: pose) != frozenJoints && pose.contains("moving=true")
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [moving], timeout: 8), .completed)
        app.buttons["villagerPower"].tap()
        let lowPower = value(); Thread.sleep(forTimeInterval: 1.2)
        XCTAssertEqual(value(), lowPower); XCTAssertTrue(lowPower.contains("moving=false"))
        XCTAssertEqual(field("actorID", in: lowPower), actorID)
        app.buttons["closeVillagerMotionReview"].tap()
        XCTAssertTrue(app.buttons["closeVillagerMotionReview"].waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["visualReviewNotice"].waitForExistence(timeout: 5))
        XCTAssertEqual(try XCTUnwrap(lab.value as? String).components(separatedBy: " sceneBuilds=").first, movedLabCamera)
        app.buttons["closeNativeVisualReview"].tap()
        XCTAssertTrue(app.buttons["closeNativeVisualReview"].waitForNonExistence(timeout: 10))
        app.navigationBars["Developer tools"].buttons["Done"].tap()
        XCTAssertEqual(try XCTUnwrap(app.otherElements["settlementMap"].value as? String).components(separatedBy: " sceneBuilds=").first,
                       normal.components(separatedBy: " sceneBuilds=").first)
    }

    @MainActor func testOnboardingConstructionStagesUseActualWork() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = try openWalkthroughPlacement()
        let pause = app.buttons["walkthroughPauseTime"]
        XCTAssertTrue(pause.waitForExistence(timeout: 5)); pause.tap()
        let map = app.descendants(matching: .any).matching(identifier: "onboardingWalkthroughMap").firstMatch
        let tileParts = app.staticTexts["walkthroughPlacementLocation"].label.split { !($0.isNumber || $0 == "-") }.compactMap { Int($0) }
        let builtTile = Tile(x: try XCTUnwrap(tileParts.first), y: try XCTUnwrap(tileParts.dropFirst().first))
        app.buttons["walkthroughConfirmBuilding"].tap()
        func summary() -> String { map.value as? String ?? "" }
        func expectStage(_ stage: String, fraction: Double, frame: Int, walls: Int, roof: Int) {
            let value = summary()
            print("CONSTRUCTION_REVIEW_STAGE \(value)")
            XCTAssertTrue(value.contains("construction=\(stage)"), value)
            for (key, expected) in [("frameNodes", frame), ("wallNodes", walls), ("roofNodes", roof)] {
                XCTAssertTrue(value.contains("\(key)=\(expected)"), value)
            }
            let actual = value.split(separator: " ").first { $0.hasPrefix("workFraction=") }.flatMap { Double($0.dropFirst(13)) }
            XCTAssertEqual(actual ?? -1, fraction, accuracy: 0.001, value)
        }
        expectStage("foundation", fraction: 0, frame: 0, walls: 0, roof: 0)
        let frozen = summary().components(separatedBy: " construction=").last
        Thread.sleep(forTimeInterval: 2.2)
        XCTAssertEqual(summary().components(separatedBy: " construction=").last, frozen)
        capture("construction-01-foundation", app: app)
        app.buttons["walkthroughAdvanceSmall"].tap()
        expectStage("frame", fraction: 0.2, frame: 1, walls: 0, roof: 0)
        capture("construction-02-frame", app: app)
        app.buttons["walkthroughAdvanceSmall"].tap()
        expectStage("walls", fraction: 0.4, frame: 1, walls: 1, roof: 0)
        capture("construction-03-walls", app: app)
        app.buttons["walkthroughAdvanceSmall"].tap(); app.buttons["walkthroughAdvanceSmall"].tap()
        expectStage("roof", fraction: 0.8, frame: 1, walls: 1, roof: 1)
        capture("construction-04-roof", app: app)
        app.buttons["walkthroughAdvanceSmall"].tap()
        expectStage("finished", fraction: 1, frame: 0, walls: 0, roof: 0)
        XCTAssertTrue(summary().contains("temporaryNodes=0"), summary())
        XCTAssertTrue(summary().contains("artAlpha=1.00"), summary())
        XCTAssertEqual(app.staticTexts["onboardingWalkthroughStep"].value as? String, "expedition")
        let fields = summary().split(separator: " ")
        func field(_ key: String) throws -> Double {
            try XCTUnwrap(Double(try XCTUnwrap(fields.first { $0.hasPrefix(key + "=") }).dropFirst(key.count + 1)))
        }
        let configuration = try GameConfiguration.bundled()
        let center = configuration.definition(.hut).footprint.center(at: builtTile)
        let civic = MapGeometry.point(for: configuration.map.campfire)
        let zoom = try field("zoom")
        let roof = map.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
            dx: try field("civicX") + (center.x - civic.x) / zoom,
            dy: try field("civicY") - (center.y - civic.y + 55) / zoom))
        roof.tap()
        XCTAssertTrue(app.staticTexts["walkthroughInspectedBuilding"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["walkthroughInspectedBuilding"].value as? String, "hut")
        XCTAssertTrue(summary().contains("inspectionTiles=4"), summary())
        capture("construction-05-finished", app: app)
        app.buttons["closeOnboardingWalkthrough"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.otherElements["settlementMap"].exists)
    }

    @MainActor func testAtmosphereFullCycleRecording() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForNonExistence(timeout: 30))
        app.buttons["developerTools"].tap()
        let entry = app.buttons["openNativeVisualReview"]
        XCTAssertTrue(entry.waitForExistence(timeout: 5)); entry.tap()
        let fast = app.buttons["visualReviewFastCycle"]
        XCTAssertTrue(fast.waitForExistence(timeout: 10))
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: fast)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed)
        app.buttons["Center"].tap()
        app.buttons["visualReviewWeather-rain"].tap()
        fast.tap()
        let status = app.staticTexts["visualReviewAtmosphereStatus"]
        func fraction() -> Double {
            let value = status.value as? String ?? ""
            let result = value.split(separator: " ").first { $0.hasPrefix("fraction=") }.flatMap { Double($0.dropFirst(9)) } ?? -1
            print("ATMOSPHERE_CYCLE_SAMPLE \(result) \(value)")
            return result
        }
        print("ATMOSPHERE_FULL_CYCLE_RECORDING_STARTED")
        let dawn = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in fraction() > 0.75 }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [dawn], timeout: 90), .completed)
        app.buttons["visualReviewCycle"].tap()
        XCTAssertTrue(status.label.contains("Dawn"), "Pausing must label the retained dawn appearance, not the old Day preset")
        let frozen = fraction()
        Thread.sleep(forTimeInterval: 1.2)
        XCTAssertEqual(fraction(), frozen)
        app.buttons["visualReviewCycle"].tap()
        let wrapped = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in (0...0.15).contains(fraction()) }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [wrapped], timeout: 45), .completed)
        print("ATMOSPHERE_FULL_CYCLE_WRAPPED \(status.value as? String ?? "none")")
        app.buttons["visualReviewStatic"].tap()
        capture("atmosphere-cycle-wrapped", app: app)
    }

    @MainActor func testAtmosphereCycleAndStaticFallbackPreserveNormalGame() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForNonExistence(timeout: 30))
        let original = app.otherElements["settlementMap"].value as? String
        app.buttons["developerTools"].tap()
        let gallery = app.buttons["openNativeVisualReview"]
        XCTAssertTrue(gallery.waitForExistence(timeout: 5)); gallery.tap()
        let cycle = app.buttons["visualReviewCycle"]
        XCTAssertTrue(cycle.waitForExistence(timeout: 10))
        let status = app.staticTexts["visualReviewAtmosphereStatus"]
        func value(_ element: XCUIElement) -> String { element.value as? String ?? "" }
        func number(_ name: String, _ element: XCUIElement) -> Double {
            let field = value(element).split(separator: " ").first { $0.hasPrefix(name + "=") }
            return field.flatMap { Double($0.dropFirst(name.count + 1)) } ?? -1
        }
        func awaitCondition(_ condition: @escaping () -> Bool) {
            let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in condition() }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 8), .completed)
        }
        awaitCondition { cycle.isEnabled && number("nodes", status) > 0 }
        app.buttons["visualReview-day"].tap(); capture("atmosphere-day", app: app)
        let initial = number("fraction", status), nodes = number("nodes", status)
        cycle.tap()
        awaitCondition { number("fraction", status) > initial + 0.003 }
        XCTAssertGreaterThan(number("tint", status), 0, "The actual tint must advance with the visual clock")
        XCTAssertEqual(number("nodes", status), nodes, "Lighting updates must not allocate new actors/weather nodes")
        let figureBuilds = number("figureBuilds", status)
        app.buttons["visualReviewStatic"].tap()
        awaitCondition { value(status).contains("moving=false") && number("buildingActions", status) == 0 }
        XCTAssertEqual(number("figureBuilds", status), figureBuilds, "Static must retain the existing figures, not recreate them at route origins")
        let frozen = number("fraction", status)
        Thread.sleep(forTimeInterval: 1.2)
        XCTAssertEqual(number("fraction", status), frozen)
        app.buttons["visualReviewStatic"].tap()
        awaitCondition { number("fraction", status) > frozen + 0.003 }
        XCTAssertEqual(number("figureBuilds", status), figureBuilds, "Resuming motion must retain the frozen figure state")
        app.buttons["visualReviewPower"].tap()
        awaitCondition { value(status).contains("moving=false") && number("buildingActions", status) == 0 }
        let lowPower = number("fraction", status)
        Thread.sleep(forTimeInterval: 1.2)
        XCTAssertEqual(number("fraction", status), lowPower)
        app.buttons["visualReviewPower"].tap()
        awaitCondition { value(status).contains("moving=true") }
        app.buttons["Loading scenes"].tap()
        let covered = app.staticTexts["visualReviewCoveredStatus"]
        XCTAssertTrue(covered.waitForExistence(timeout: 5))
        awaitCondition { value(covered).contains("moving=false") }
        let paused = number("fraction", covered)
        Thread.sleep(forTimeInterval: 1.2)
        XCTAssertEqual(number("fraction", covered), paused)
        app.buttons["closeLoadingReview"].tap()
        awaitCondition { number("fraction", status) > paused + 0.003 }
        for phase in ["dusk", "night", "dawn"] {
            app.buttons["visualReview-" + phase].tap()
            awaitCondition { value(status).contains("cycle=false") }
            capture("atmosphere-" + phase, app: app)
            if phase == "night" {
                XCTAssertEqual(number("tint", status), 0.2, accuracy: 0.001)
                XCTAssertGreaterThan(number("lights", status), 0)
                XCTAssertLessThanOrEqual(number("lights", status), 8)
                XCTAssertGreaterThan(number("light", status), 0.9)
            }
        }
        app.buttons["visualReviewStatic"].tap()
        app.buttons["visualReviewWeather-rain"].tap(); capture("atmosphere-rain-static", app: app)
        app.buttons["visualReviewWeather-fog"].tap(); capture("atmosphere-fog-static", app: app)
        XCTAssertEqual(number("buildingActions", status), 0)
        app.buttons["closeNativeVisualReview"].tap(); app.buttons["Done"].tap()
        XCTAssertEqual((app.otherElements["settlementMap"].value as? String)?.components(separatedBy: " sceneBuilds=").first,
                       original?.components(separatedBy: " sceneBuilds=").first)
    }

    @MainActor private func openWalkthroughPlacement() throws -> XCUIApplication {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForNonExistence(timeout: 30))
        app.buttons["developerTools"].tap()
        let entry = app.buttons["openOnboardingWalkthrough"]
        XCTAssertTrue(entry.waitForExistence(timeout: 5)); entry.tap()
        XCTAssertTrue(app.buttons["walkthroughChooseHut"].waitForExistence(timeout: 10))
        app.buttons["walkthroughChooseHut"].tap()
        XCTAssertTrue(app.buttons["walkthroughConfirmBuilding"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor func testOnboardingCandidateDragMovesBuildingWithoutPanning() throws {
        let app = try openWalkthroughPlacement()
        let map = app.descendants(matching: .any).matching(identifier: "onboardingWalkthroughMap").firstMatch
        let initial = app.staticTexts["walkthroughPlacementLocation"].label
        let numbers = initial.split { !($0.isNumber || $0 == "-") }.compactMap { Int($0) }
        let tile = Tile(x: try XCTUnwrap(numbers.first), y: try XCTUnwrap(numbers.dropFirst().first))
        let value = try XCTUnwrap(map.value as? String)
        func field(_ name: String) throws -> Double {
            let part = try XCTUnwrap(value.split(separator: " ").first { $0.hasPrefix(name + "=") })
            return try XCTUnwrap(Double(part.dropFirst(name.count + 1)))
        }
        let configuration = try GameConfiguration.bundled()
        let center = configuration.definition(.hut).footprint.center(at: tile)
        let civic = MapGeometry.point(for: configuration.map.campfire)
        let zoom = try field("zoom")
        let roof = map.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
            dx: try field("civicX") + (center.x - civic.x) / zoom,
            dy: try field("civicY") - (center.y - civic.y + 55) / zoom))
        print("WALKTHROUGH_TOUCH before=\(value) roof=\(roof)")
        roof.tap()
        print("WALKTHROUGH_TOUCH after=\(map.value as? String ?? "none")")
        XCTAssertEqual(app.staticTexts["walkthroughPlacementLocation"].label, initial, "Tapping the candidate roof must keep its origin")
        let camera = (map.value as? String)?.components(separatedBy: "camera=").last
        roof.press(forDuration: 0.05, thenDragTo: roof.withOffset(CGVector(dx: 32 / zoom, dy: 16 / zoom)))
        let moved = app.staticTexts["walkthroughPlacementLocation"].label.split { !($0.isNumber || $0 == "-") }.compactMap { Int($0) }
        XCTAssertEqual(moved, [tile.x + 1, tile.y], "One projected tile of drag must move one logical tile while retaining the roof grab offset")
        XCTAssertEqual((map.value as? String)?.components(separatedBy: "camera=").last, camera,
                       "Dragging the candidate must retain the review camera")
        let movedLabel = app.staticTexts["walkthroughPlacementLocation"].label
        let cameraAfterCandidate = (map.value as? String)?.components(separatedBy: "camera=").last
        let empty = map.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.35))
        empty.press(forDuration: 0.05, thenDragTo: empty.withOffset(CGVector(dx: 40, dy: 12)))
        XCTAssertEqual(app.staticTexts["walkthroughPlacementLocation"].label, movedLabel, "Empty-map pan must not move the candidate")
        XCTAssertNotEqual((map.value as? String)?.components(separatedBy: "camera=").last, cameraAfterCandidate)
        let beforePinch = (map.value as? String)?.components(separatedBy: "zoom=").last
        map.pinch(withScale: 1.15, velocity: 1)
        XCTAssertNotEqual((map.value as? String)?.components(separatedBy: "zoom=").last, beforePinch)
        XCTAssertEqual(app.staticTexts["walkthroughPlacementLocation"].label, movedLabel, "Pinch must not move the candidate")
        capture("walkthrough-placement-drag-suggest", app: app)
    }

    @MainActor func testOnboardingSuggestionButtonSelectsAnotherValidSite() throws {
        let app = try openWalkthroughPlacement()
        let original = app.staticTexts["walkthroughPlacementLocation"].label
        app.buttons["walkthroughSuggestedSite"].tap()
        let second = app.staticTexts["walkthroughPlacementLocation"].label
        XCTAssertNotEqual(second, original, "A suggested-site action must move away from the already-selected suggestion")
        XCTAssertTrue(app.buttons["walkthroughConfirmBuilding"].isEnabled)
        app.buttons["walkthroughSuggestedSite"].tap()
        XCTAssertNotEqual(app.staticTexts["walkthroughPlacementLocation"].label, second)
        XCTAssertTrue(app.buttons["walkthroughConfirmBuilding"].isEnabled)
    }

    @MainActor func testOnboardingWalkthroughShowsAndPerformsEveryGuidedStep() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForNonExistence(timeout: 30))
        let before = app.otherElements["settlementMap"].value as? String
        app.buttons["developerTools"].tap()
        let entry = app.buttons["openOnboardingWalkthrough"]
        XCTAssertTrue(entry.waitForExistence(timeout: 5)); entry.tap()
        let guide = app.staticTexts["onboardingWalkthroughStep"]
        XCTAssertTrue(guide.waitForExistence(timeout: 10))
        XCTAssertEqual(guide.value as? String, "hut")
        let map = app.descendants(matching: .any).matching(identifier: "onboardingWalkthroughMap").firstMatch
        let fields = try XCTUnwrap(map.value as? String).split(separator: " ")
        let civicX = try XCTUnwrap(Double(try XCTUnwrap(fields.first { $0.hasPrefix("civicX=") }).dropFirst(7)))
        let civicY = try XCTUnwrap(Double(try XCTUnwrap(fields.first { $0.hasPrefix("civicY=") }).dropFirst(7)))
        let civicPoint = CGPoint(x: map.frame.minX + civicX, y: map.frame.minY + civicY)
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "onboardingGuidePanel").firstMatch.frame.insetBy(dx: -44, dy: -44).contains(civicPoint),
                       "The first guide must leave the civic center and touch clearance visible")
        capture("walkthrough-01-hut-guide", app: app)
        app.buttons["skipOnboardingWalkthroughGuide"].tap()
        XCTAssertFalse(guide.exists)
        app.buttons["reopenOnboardingWalkthroughGuide"].tap()
        app.buttons["walkthroughChooseHut"].tap()
        let confirm = app.buttons["walkthroughConfirmBuilding"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5)); XCTAssertTrue(confirm.isEnabled)
        let location = app.staticTexts["walkthroughPlacementLocation"].label
        map.coordinate(withNormalizedOffset: CGVector(dx: 0.20, dy: 0.60)).tap()
        XCTAssertNotEqual(app.staticTexts["walkthroughPlacementLocation"].label, location, "Map taps must choose a different candidate")
        app.buttons["walkthroughSuggestedSite"].tap()
        XCTAssertTrue(confirm.isEnabled)
        confirm.tap()
        XCTAssertEqual(guide.value as? String, "hut", "Placement alone must not finish construction")
        app.buttons["walkthroughAdvanceTime"].tap()
        XCTAssertEqual(guide.value as? String, "expedition")
        capture("walkthrough-02-expedition-guide", app: app)
        app.buttons["walkthroughStartExpedition"].tap()
        XCTAssertTrue(app.staticTexts["onboardingWorkRemaining"].exists)
        app.buttons["walkthroughAdvanceTime"].tap()
        XCTAssertTrue(app.buttons["walkthroughChooseWoodcutter"].waitForExistence(timeout: 8))
        capture("walkthrough-03-forest-woodcutter-guide", app: app)
        app.buttons["walkthroughChooseWoodcutter"].tap()
        XCTAssertTrue(confirm.isEnabled); confirm.tap()
        app.buttons["walkthroughAdvanceTime"].tap()
        XCTAssertEqual(guide.value as? String, "handoff")
        capture("walkthrough-04-goals-handoff", app: app)
        app.buttons["closeOnboardingWalkthrough"].tap()
        app.buttons["Done"].tap()
        XCTAssertEqual((app.otherElements["settlementMap"].value as? String)?.components(separatedBy: " sceneBuilds=").first,
                       before?.components(separatedBy: " sceneBuilds=").first)
    }

    @MainActor func testNativeVisualReviewPreservesNormalGame() throws {
        print("NATIVE_VISUAL_REVIEW_CONTRACT_V4_READY_REVEAL_PAN_ZOOM")
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForNonExistence(timeout: 30))
        let before = app.otherElements["settlementMap"].value as? String
        app.buttons["developerTools"].tap()
        let gallery = app.buttons["openNativeVisualReview"]
        XCTAssertTrue(gallery.waitForExistence(timeout: 5)); gallery.tap()
        XCTAssertTrue(app.staticTexts["visualReviewNotice"].waitForExistence(timeout: 10))
        capture("native-visual-review-day", app: app)
        app.buttons["visualReview-night"].tap()
        capture("native-visual-review-night", app: app)
        app.buttons["Loading scenes"].tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "settlementLoading").firstMatch.waitForExistence(timeout: 5))
        capture("native-loading-founding", app: app)
        app.buttons["River"].tap(); capture("native-loading-river", app: app)
        app.buttons["Mountain"].tap(); capture("native-loading-mountain", app: app)
        app.buttons["skipLoadingScenery"].tap()
        XCTAssertTrue(app.staticTexts["loadingStage"].exists)
        app.buttons["closeLoadingReview"].tap()
        app.buttons["visualReviewOnboarding"].tap()
        XCTAssertTrue(app.staticTexts["onboardingReviewCard"].waitForExistence(timeout: 10))
        capture("onboarding-continuous-fog-initial", app: app)
        app.buttons["onboardingReviewForest"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "identifier == %@ AND label BEGINSWITH %@", "onboardingReviewCard", "Forest area revealed")).firstMatch.waitForExistence(timeout: 5))
        capture("onboarding-continuous-fog-forest", app: app)
        let reviewMap = app.descendants(matching: .any).matching(identifier: "nativeVisualReviewMap").firstMatch
        let camera = (reviewMap.value as? String)?.components(separatedBy: " revision=").first
        reviewMap.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.8))
            .press(forDuration: 0.05, thenDragTo: reviewMap.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.75)))
        XCTAssertNotEqual((reviewMap.value as? String)?.components(separatedBy: " revision=").first, camera)
        let zoom = (reviewMap.value as? String)?.components(separatedBy: "zoom=").last?.components(separatedBy: " ").first
        reviewMap.pinch(withScale: 1.2, velocity: 1)
        XCTAssertNotEqual((reviewMap.value as? String)?.components(separatedBy: "zoom=").last?.components(separatedBy: " ").first, zoom)
        app.buttons["closeNativeVisualReview"].tap()
        app.buttons["Done"].tap()
        XCTAssertEqual((app.otherElements["settlementMap"].value as? String)?.components(separatedBy: " sceneBuilds=").first,
                       before?.components(separatedBy: " sceneBuilds=").first, "Review pan/zoom must preserve the normal camera as well as buildings/roads")
    }

    @MainActor func testUIThemeAuditEvidence() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        app.launch()
        XCTAssertTrue(app.buttons["newNormalGame"].waitForExistence(timeout: 30))
        capture("ui-audit-01-launch", app: app)
        app.buttons["newNormalGame"].tap()
        XCTAssertTrue(app.buttons["openResearch"].waitForExistence(timeout: 30))
        capture("ui-audit-02-hud", app: app)
        app.buttons["Build"].tap()
        XCTAssertTrue(app.buttons["details-building-hut"].waitForExistence(timeout: 5))
        capture("ui-audit-03-catalog", app: app)
        app.buttons["details-building-hut"].tap()
        XCTAssertTrue(app.staticTexts["building-description-hut"].waitForExistence(timeout: 5))
        capture("ui-audit-04-catalog-detail", app: app)
        app.buttons["closeBuildingCatalog"].tap()
        app.buttons["openResearch"].tap()
        XCTAssertTrue(app.buttons["details-research-oralTradition"].waitForExistence(timeout: 5))
        capture("ui-audit-05-research", app: app)
        app.buttons["details-research-oralTradition"].tap()
        XCTAssertTrue(app.staticTexts["research-description-oralTradition"].waitForExistence(timeout: 5))
        capture("ui-audit-06-research-detail", app: app)
        app.buttons["closeResearch"].tap()
        app.buttons["settlementBuildings"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let civic = app.descendants(matching: .any).matching(identifier: "inspectBuilding-0").firstMatch
        XCTAssertTrue(civic.waitForExistence(timeout: 5)); civic.tap()
        XCTAssertTrue(app.staticTexts["civicLevelName"].waitForExistence(timeout: 5))
        capture("ui-audit-07-inspector", app: app)
        app.otherElements["settlementMap"].coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)).tap()
        expandGoals(app)
        app.buttons["openJourney"].tap()
        XCTAssertTrue(app.navigationBars["Stone Age journey"].waitForExistence(timeout: 5))
        capture("ui-audit-08-journey", app: app)
        app.buttons["Done"].tap()
        app.buttons["openGames"].tap()
        XCTAssertTrue(app.staticTexts["activeGameName"].waitForExistence(timeout: 5))
        capture("ui-audit-09-games", app: app)
    }

    @MainActor private func launchNormal(_ app: XCUIApplication) {
        // Historical review/regression cases intentionally retain their original rules.
        // New ordinary Riverbend tests launch directly through the real menu.
        app.launchEnvironment["CIVILIZATION_UI_LEGACY_ENTRY"] = "1"
        app.launch()
        let resume = app.buttons["continueGame"]
        XCTAssertTrue(resume.waitForExistence(timeout: 30))
        if resume.isEnabled { resume.tap() } else { app.buttons["newNormalGame"].tap() }
    }

    @MainActor func testConnectivityPilotIsExplicitReviewOnlyAndPersistsPaths() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let c = try GameConfiguration.bundled(), epoch = Date().addingTimeInterval(-40)
        var earned = try GameEngine(configuration: c, now: epoch)
        let source = Tile(x: c.map.campfire.x - 3, y: c.map.campfire.y)
        let path = Tile(x: c.map.campfire.x - 1, y: c.map.campfire.y)
        try earned.build(.gatheringShelter, at: source)
        earned.advance(to: epoch.addingTimeInterval(20))
        struct Envelope: Encodable { let version = 6; let state: GameState }
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        app.launchEnvironment["CIVILIZATION_UI_EARNED_SAVE"] = try JSONEncoder().encode(Envelope(state: earned.state)).base64EncodedString()
        launchNormal(app)
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 20))
        app.buttons["developerTools"].tap(); XCTAssertFalse(app.buttons["activateReviewConnectivity"].exists)
        app.buttons["startGameplayReview"].tap()
        app.buttons["developerTools"].tap()
        let activate = app.buttons["activateReviewConnectivity"]
        XCTAssertTrue(activate.waitForExistence(timeout: 5)); activate.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "connectivityPilotStatus").firstMatch.waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        func inspect() {
            app.buttons["settlementBuildings"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            let row = app.descendants(matching: .any).matching(identifier: "inspectBuilding-1").firstMatch
            XCTAssertTrue(row.waitForExistence(timeout: 5)); row.tap()
        }
        inspect()
        let status = app.staticTexts["buildingOperatingStatus"]
        XCTAssertTrue(status.waitForExistence(timeout: 5)); XCTAssertTrue(status.label.contains("Not connected"))
        app.buttons["connectBuildingPaths"].tap()
        let map = app.otherElements["settlementMap"], frame = map.frame
        let scale = frame.width > 1000 ? 1.1 : 0.95
        let root = MapGeometry.point(for: c.map.campfire), p = MapGeometry.point(for: path)
        map.coordinate(withNormalizedOffset: CGVector(dx: 0.5 + (p.x - root.x - 80) / scale / frame.width,
                                                       dy: 0.5 - (p.y - root.y - 30) / scale / frame.height)).tap()
        app.buttons["confirmRoadStroke"].tap(); inspect()
        XCTAssertFalse(status.label.contains("Not connected")); XCTAssertTrue(app.staticTexts["buildingWorkers"].label.contains("1"))
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); attachment.name = "connected-review-service"; attachment.lifetime = .keepAlways; add(attachment)
        app.terminate(); launchNormal(app)
        XCTAssertFalse(app.staticTexts["developerModeBanner"].exists)
        XCTAssertTrue((map.value as? String ?? "").contains("0 road tiles"))
        app.buttons["developerTools"].tap(); app.buttons["startGameplayReview"].tap()
        XCTAssertTrue((map.value as? String ?? "").contains("1 road tiles"))
        inspect(); XCTAssertFalse(status.label.contains("Not connected"))
        app.buttons["developerTools"].tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "connectivityPilotStatus").firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(activate.exists)
    }

    @MainActor func testResearchPrerequisiteReturnsToExactSourceCard() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.buttons["openResearch"].waitForExistence(timeout: 20)); app.buttons["openResearch"].tap()
        app.buttons["pillarFilter-culture"].tap(); app.buttons["details-research-rituals"].tap()
        let prerequisite = app.buttons["researchPrerequisite-oralTradition"]
        for _ in 0..<5 where !prerequisite.isHittable { app.scrollViews["researchCatalog"].swipeUp() }
        XCTAssertTrue(prerequisite.isHittable); prerequisite.tap()
        XCTAssertTrue(app.buttons["research-oralTradition"].waitForExistence(timeout: 5))
        let back = app.buttons["returnToResearchItem"]
        XCTAssertTrue(back.waitForExistence(timeout: 5)); back.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "focusedResearch-rituals").firstMatch.exists)
        XCTAssertTrue(app.staticTexts["research-description-rituals"].exists)
        XCTAssertTrue(app.buttons["research-rituals"].isHittable)
    }

    @MainActor func testTerrainAndProductionIndicatorEvidence() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.buttons["developerTools"].waitForExistence(timeout: 20))
        app.buttons["developerTools"].tap(); app.buttons["scenario-early"].tap()
        XCTAssertTrue(app.buttons["Done"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["settlementMap"].exists)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "terrain-and-production-indicators"; attachment.lifetime = .keepAlways; add(attachment)
    }

    @MainActor func testGatheringPlacementPhysicalButtonAndDragRegression() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.buttons["Build"].waitForExistence(timeout: 20)); app.buttons["Build"].tap()
        app.buttons["buildingCategory-Food and water"].tap()
        app.buttons["build-gatheringShelter"].tap()
        let rotate = app.buttons["rotatePlacement"]
        XCTAssertTrue(rotate.waitForExistence(timeout: 5)); XCTAssertTrue(rotate.isEnabled)
        let initial = app.staticTexts["placementTile"].label
        for facing in ["East", "South", "West", "North"] {
            rotate.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            XCTAssertEqual(rotate.value as? String, facing)
            XCTAssertEqual(app.staticTexts["placementTile"].label, initial, "Rotate must not move the candidate")
        }
        let map = app.otherElements["settlementMap"]
        let config = try GameConfiguration.bundled()
        let numbers = initial.split { !($0.isNumber || $0 == "-") }.compactMap { Int($0) }
        let x = try XCTUnwrap(numbers.first), y = try XCTUnwrap(numbers.dropFirst().first)
        let camp = MapGeometry.point(for: config.map.campfire)
        let world = MapGeometry.point(for: Tile(x: x, y: y))
        let scale = map.frame.width > 1000 ? 1.1 : 0.95
        let start = map.coordinate(withNormalizedOffset: CGVector(dx: 0.5 + (world.x - camp.x - 80) / scale / map.frame.width,
            dy: 0.5 - (world.y - camp.y - 30) / scale / map.frame.height))
        let roof = start.withOffset(CGVector(dx: 0, dy: -55 / scale))
        roof.tap()
        XCTAssertEqual(app.staticTexts["placementTile"].label, initial, "Tapping the candidate roof must not relocate its origin")
        let cameraBefore = map.value as? String
        roof.press(forDuration: 0.05, thenDragTo: roof.withOffset(CGVector(dx: 40, dy: 15)))
        XCTAssertNotEqual(app.staticTexts["placementTile"].label, initial, "Dragging the visible candidate roof must move the candidate")
        XCTAssertEqual((map.value as? String)?.components(separatedBy: "camera=").last, cameraBefore?.components(separatedBy: "camera=").last, "Candidate dragging must not pan the camera")
        let moved = app.staticTexts["placementTile"].label
        rotate.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertEqual(rotate.value as? String, "East")
        XCTAssertEqual(app.staticTexts["placementTile"].label, moved)
        capture("gathering-placement-physical-controls", app: app)
        app.buttons["cancelPlacement"].tap()
        XCTAssertTrue((map.value as? String ?? "").contains("1 buildings"))
    }

    @MainActor func testLogicalRotationRoundTripsAndPersists() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.buttons["Build"].waitForExistence(timeout: 20)); app.buttons["Build"].tap()
        app.buttons["buildingCategory-Settlement"].tap(); app.buttons["build-hut"].tap()
        let rotate = app.buttons["rotatePlacement"]
        XCTAssertTrue(rotate.waitForExistence(timeout: 5)); XCTAssertTrue(rotate.isEnabled)
        for facing in ["East", "South", "West", "North", "East"] {
            rotate.tap(); XCTAssertEqual(rotate.value as? String, facing)
        }
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); shot.name = "logical-orientation-east"; shot.lifetime = .keepAlways; add(shot)
        app.buttons["confirmPlacement"].tap()
        app.terminate(); launchNormal(app)
        app.buttons["settlementBuildings"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let item = app.descendants(matching: .any).matching(identifier: "inspectBuilding-1").firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5)); item.tap()
        XCTAssertTrue(app.staticTexts["inspectedBuildingPosition"].label.contains("facing east"))
        app.buttons["moveBuilding"].tap(); XCTAssertEqual(rotate.value as? String, "East")
        rotate.tap(); app.buttons["cancelRelocation"].tap()
        app.buttons["settlementBuildings"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(item.waitForExistence(timeout: 5)); item.tap()
        XCTAssertTrue(app.staticTexts["inspectedBuildingPosition"].label.contains("facing east"))
    }

    @MainActor func testCandidateConfirmationSurvivesCameraGestures() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.buttons["Build"].waitForExistence(timeout: 20))
        app.buttons["Build"].tap(); app.buttons["buildingCategory-Settlement"].tap(); app.buttons["build-hut"].tap()
        let confirm = app.buttons["confirmPlacement"], cancel = app.buttons["cancelPlacement"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5)); XCTAssertTrue(confirm.isEnabled)
        XCTAssertTrue(cancel.isHittable); XCTAssertTrue(app.frame.contains(confirm.frame))
        let tile = app.staticTexts["placementTile"].label
        let map = app.otherElements["settlementMap"]
        let start = map.value as? String
        map.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.3)).press(forDuration: 0.05, thenDragTo: map.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.35)))
        map.pinch(withScale: 1.2, velocity: 1)
        XCTAssertTrue(confirm.isHittable); XCTAssertTrue(cancel.isHittable)
        XCTAssertEqual(app.staticTexts["placementTile"].label, tile)
        XCTAssertNotEqual(start, map.value as? String)
        map.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).press(forDuration: 0.05, thenDragTo: map.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.12)))
        for id in ["confirmPlacement", "cancelPlacement", "rotatePlacement"] { XCTAssertTrue(app.buttons[id].isHittable, id) }
        capture("candidate-camera-confirmation", app: app)
        confirm.tap(); XCTAssertFalse(cancel.exists)
        XCTAssertTrue((map.value as? String ?? "").contains("2 buildings"))
        app.buttons["Build"].tap(); app.buttons["build-hut"].tap()
        XCTAssertTrue(cancel.waitForExistence(timeout: 5)); cancel.tap()
        XCTAssertTrue((map.value as? String ?? "").contains("2 buildings"))
    }

    @MainActor func testLockedBuildingResearchLinkFindsExactPrerequisiteAndReturns() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment["CIVILIZATION_UI_FRESH_SAVE"] = "1"
        app.launchEnvironment["CIVILIZATION_UI_LIBRARY_ID"] = UUID().uuidString
        launchNormal(app)
        XCTAssertTrue(app.buttons["Build"].waitForExistence(timeout: 20)); app.buttons["Build"].tap()
        app.buttons["buildingCategory-Culture and knowledge"].tap()
        let details = app.buttons["details-building-storytellingCircle"]
        XCTAssertTrue(details.waitForExistence(timeout: 5)); details.tap()
        let link = app.buttons["buildingResearch-storytellingCircle"]
        for _ in 0..<4 where !link.isHittable { app.scrollViews["buildingCatalog"].swipeUp() }
        XCTAssertTrue(link.isHittable); link.tap()
        let research = app.buttons["research-oralTradition"]
        XCTAssertTrue(research.waitForExistence(timeout: 5)); XCTAssertTrue(research.isHittable)
        XCTAssertTrue(app.staticTexts["research-description-oralTradition"].exists)
        XCTAssertTrue(app.otherElements["focusedResearch-oralTradition"].exists)
        app.buttons["returnToSource"].tap()
        XCTAssertTrue(app.buttons["details-building-storytellingCircle"].waitForExistence(timeout: 5))
        link.tap(); XCTAssertTrue(research.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["research-description-oralTradition"].exists)
        capture("locked-building-research-target", app: app)
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
        XCTAssertTrue(app.buttons["research-socialOrder"].isHittable)
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
        XCTAssertTrue(app.buttons["cancelRelocation"].exists)
        app.buttons["confirmPlacement"].tap()
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
        XCTAssertFalse(app.buttons["openEconomyLab"].exists)
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
        XCTAssertTrue(app.buttons["confirmPlacement"].waitForExistence(timeout: 5))
        app.buttons["confirmPlacement"].tap()
        let position = app.staticTexts["inspectedBuildingPosition"]
        XCTAssertTrue(position.waitForExistence(timeout: 10))
        XCTAssertTrue(position.label.contains("Tile \(destination.x), \(destination.y)"), position.label)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); screenshot.name = "long-press-relocation"; screenshot.lifetime = .keepAlways; add(screenshot)
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
        XCTAssertTrue(app.frame.contains(app.buttons["confirmPlacement"].frame))
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
        XCTAssertTrue(app.buttons["cancelRelocation"].exists)
        app.buttons["confirmPlacement"].tap()
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
        map.coordinate(withNormalizedOffset: point(destination)).tap()
        XCTAssertTrue(indicator.exists)
        app.buttons["confirmPlacement"].tap()
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
        map.coordinate(withNormalizedOffset: point(tile)).tap()
        XCTAssertTrue(indicator.exists)
        app.buttons["confirmPlacement"].tap()
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
        XCTAssertTrue(app.navigationBars["Stone Age journey"].waitForExistence(timeout: 5))
        app.navigationBars["Stone Age journey"].buttons["Done"].tap()
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
        app.textFields["catalogSearch"].tap(); app.textFields["catalogSearch"].typeText("Gathering\n")
        app.buttons["details-building-gatheringShelter"].tap()
        let reason = app.staticTexts["building-reserve-gatheringShelter"]
        XCTAssertTrue(reason.waitForExistence(timeout: 5)); XCTAssertTrue(reason.label.contains("Woodcutter"))
        capture("reserve-explanation", app: app)
        let supplier = app.buttons["showBootstrapSupplier-gatheringShelter"]
        if !supplier.isHittable { app.scrollViews["buildingCatalog"].swipeUp() }
        supplier.tap()
        let woodcutter = app.buttons["build-woodcutter"]
        XCTAssertTrue(woodcutter.waitForExistence(timeout: 5)); XCTAssertTrue(woodcutter.isEnabled)
        let back = app.buttons["returnToBuildingItem"]
        XCTAssertTrue(back.waitForExistence(timeout: 5)); back.tap()
        XCTAssertEqual(app.textFields["catalogSearch"].value as? String, "Gathering")
        XCTAssertTrue(app.staticTexts["building-description-gatheringShelter"].exists)
        for _ in 0..<4 where !supplier.isHittable { app.scrollViews["buildingCatalog"].swipeUp() }
        supplier.tap(); XCTAssertTrue(woodcutter.waitForExistence(timeout: 5))
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
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
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
    @MainActor func testStoneAgeHUDHierarchyAndOrdinaryRoutes() throws { try verifyStoneAgeHUD(largeText: false) }
    @MainActor func testStoneAgeHUDLargerTextAndOrdinaryRoutes() throws { try verifyStoneAgeHUD(largeText: true) }
    @MainActor private func verifyStoneAgeHUD(largeText: Bool) throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        if largeText { app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["newNormalGame"].waitForExistence(timeout: 30)); app.buttons["newNormalGame"].tap()
        XCTAssertTrue(app.otherElements["settlementMap"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.buttons["settlementMenu"].waitForExistence(timeout: 5))
        XCTAssertGreaterThan(app.frame.width, app.frame.height, "Ordinary HUD stays in landscape")
        for id in ["toggleGoals", "openExplore", "openResearch", "openBuild", "settlementMenu"] {
            let button = app.buttons[id]
            XCTAssertTrue(button.isHittable, id)
            XCTAssertFalse(button.label.isEmpty, id)
            XCTAssertTrue(app.frame.contains(button.frame), id)
            XCTAssertGreaterThanOrEqual(button.frame.width, 44, id); XCTAssertGreaterThanOrEqual(button.frame.height, 44, id)
        }
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); shot.name = "stone-hud-01-ordinary-new-game"; shot.lifetime = .keepAlways; add(shot)
        app.buttons["toggleGoals"].tap()
        XCTAssertTrue(app.buttons["nextStepAction"].waitForExistence(timeout: 5)); app.buttons["nextStepAction"].tap()
        XCTAssertTrue(app.buttons["upgradeBuilding"].waitForExistence(timeout: 5)); app.buttons["upgradeBuilding"].tap()
        app.buttons["closeBuildingInspection"].tap()
        app.buttons["toggleGoals"].tap(); app.buttons["nextStepAction"].tap()
        XCTAssertTrue(app.buttons["build-hut"].waitForExistence(timeout: 5)); app.buttons["build-hut"].tap()
        XCTAssertTrue(app.buttons["confirmPlacement"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["cancelPlacement"].isHittable)
        XCTAssertTrue(app.buttons["toggleGoals"].isHittable)
        let map = app.otherElements["settlementMap"]
        let start = map.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.35))
        start.press(forDuration: 0.05, thenDragTo: map.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.35)))
        map.pinch(withScale: 1.05, velocity: 0.5)
        XCTAssertTrue(app.buttons["cancelPlacement"].isHittable)
        let placement = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); placement.name = "stone-hud-02-placement"; placement.lifetime = .keepAlways; add(placement)
        app.buttons["cancelPlacement"].tap()
        app.buttons["openBuild"].tap(); app.buttons["build-hut"].tap(); app.buttons["confirmPlacement"].tap()
        app.buttons["openExplore"].tap()
        XCTAssertTrue(app.buttons["riverbendRecoverFood"].waitForExistence(timeout: 5))
        app.buttons["Close panel"].tap()
        app.buttons["settlementMenu"].tap()
        XCTAssertTrue(app.buttons["Center on settlement"].waitForExistence(timeout: 5)); app.buttons["Center on settlement"].tap()
        app.terminate(); app.launch(); XCTAssertTrue(app.buttons["continueGame"].waitForExistence(timeout: 30)); app.buttons["continueGame"].tap()
        XCTAssertTrue(app.otherElements["settlementMap"].waitForExistence(timeout: 30))
        XCTAssertTrue((app.otherElements["settlementMap"].value as? String ?? "").contains("2 buildings"))
        XCTAssertTrue(app.buttons["toggleGoals"].isHittable)
        XCTAssertTrue(app.staticTexts["settlementMessage"].label.contains("Open Goals"))
        XCTAssertFalse(app.staticTexts["settlementMessage"].label.contains("kept producing"))
        let resumed = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); resumed.name = "stone-hud-03-ordinary-continue"; resumed.lifetime = .keepAlways; add(resumed)
        app.buttons["settlementMenu"].tap(); app.buttons["inspectBuilding-1"].tap()
        let move = app.buttons["moveBuilding"]
        XCTAssertTrue(move.waitForExistence(timeout: 5))
        XCTAssertTrue(move.isHittable); XCTAssertGreaterThanOrEqual(move.frame.height, 44)
        move.tap()
        XCTAssertTrue(app.buttons["cancelRelocation"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["toggleGoals"].isHittable)
        XCTAssertTrue(app.buttons["confirmPlacement"].isHittable)
        let relocating = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); relocating.name = "stone-hud-06-relocation"; relocating.lifetime = .keepAlways; add(relocating)
        app.buttons["cancelRelocation"].tap()
        XCTAssertTrue((map.value as? String ?? "").contains("2 buildings"))
    }

    @MainActor func testStoneAgeExploreResearchAndReturn() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launch()
        XCTAssertTrue(app.buttons["newNormalGame"].waitForExistence(timeout: 30)); app.buttons["newNormalGame"].tap()
        XCTAssertTrue(app.buttons["openExplore"].waitForExistence(timeout: 30)); app.buttons["openExplore"].tap()
        let link = app.buttons["explorationResearch"]
        XCTAssertTrue(link.waitForExistence(timeout: 5))
        let panel = app.scrollViews["riverbendExploreContent"]
        for _ in 0..<8 where !link.isHittable { panel.swipeUp() }
        XCTAssertTrue(link.isHittable); link.tap()
        XCTAssertTrue(app.descendants(matching: .any)["focusedResearch-exploration"].waitForExistence(timeout: 5))
        XCTAssertGreaterThan(app.frame.width, app.frame.height, "Research stays in landscape")
        let research = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); research.name = "stone-hud-04-exact-expedition-research"; research.lifetime = .keepAlways; add(research)
        app.buttons["returnToSource"].tap()
        XCTAssertTrue(panel.waitForExistence(timeout: 5)); XCTAssertTrue(link.isHittable)
        let returned = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); returned.name = "stone-hud-05-explore-return"; returned.lifetime = .keepAlways; add(returned)
    }

    @MainActor func testStoneAgeMapFeedback() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launch()
        XCTAssertTrue(app.buttons["newNormalGame"].waitForExistence(timeout: 30)); app.buttons["newNormalGame"].tap()
        XCTAssertTrue(app.otherElements["settlementMap"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.staticTexts["settlementMessage"].exists)
        XCTAssertTrue(app.staticTexts["settlementMessage"].label.contains("Open Goals"))
        app.otherElements["settlementMap"].coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.3)).tap()
        let message = app.staticTexts["settlementMessage"]
        let feedback = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "Unexplored terrain"), object: message)
        XCTAssertEqual(XCTWaiter.wait(for: [feedback], timeout: 5), .completed)
    }

    @MainActor func testStoneAgeGoalsStayAvailableDuringContext() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launch()
        XCTAssertTrue(app.buttons["newNormalGame"].waitForExistence(timeout: 30)); app.buttons["newNormalGame"].tap()
        XCTAssertTrue(app.buttons["openExplore"].waitForExistence(timeout: 30)); app.buttons["openExplore"].tap()
        XCTAssertTrue(app.buttons["toggleGoals"].isHittable)
        app.buttons["toggleGoals"].tap()
        XCTAssertTrue(app.buttons["nextStepAction"].waitForExistence(timeout: 5))
        app.buttons["nextStepAction"].tap()
        XCTAssertTrue(app.buttons["upgradeBuilding"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["toggleGoals"].isHittable)
        app.buttons["toggleGoals"].tap(); XCTAssertTrue(app.buttons["nextStepAction"].isHittable)
        app.buttons["toggleGoals"].tap()
        app.buttons["openBuild"].tap(); app.buttons["buildingCategory-Roads"].tap(); app.buttons["roadCatalog-trodden"].tap()
        XCTAssertTrue(app.buttons["toggleGoals"].isHittable)
        app.buttons["toggleGoals"].tap(); XCTAssertTrue(app.buttons["nextStepAction"].waitForExistence(timeout: 5))
    }

    @MainActor func testStoneAgeHomeScreenIcon() throws {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launch()
        XCTAssertTrue(app.buttons["newNormalGame"].waitForExistence(timeout: 30))
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertTrue(springboard.icons["Riverbend"].firstMatch.waitForExistence(timeout: 10))
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); shot.name = "stone-hud-home-screen-icon"; shot.lifetime = .keepAlways; add(shot)
        springboard.icons["Riverbend"].firstMatch.tap()
        XCTAssertTrue(app.buttons["newNormalGame"].waitForExistence(timeout: 15))
    }

    @MainActor func testPlayerCatalogContextualActionsAndReturn() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["newNormalGame"].waitForExistence(timeout: 30)); app.buttons["newNormalGame"].tap()
        XCTAssertTrue(app.otherElements["settlementMap"].waitForExistence(timeout: 30))
        app.buttons["toggleGoals"].tap(); app.buttons["nextStepAction"].tap(); app.buttons["upgradeBuilding"].tap()
        app.buttons["closeBuildingInspection"].tap()
        app.buttons["Build"].tap(); app.buttons["buildingCategory-Settlement"].tap()
        if app.buttons["selectBuilding-hut"].exists { app.buttons["selectBuilding-hut"].tap() }
        XCTAssertTrue(app.buttons["build-hut"].isEnabled); app.buttons["build-hut"].tap()
        XCTAssertTrue(app.buttons["confirmPlacement"].waitForExistence(timeout: 5)); app.buttons["confirmPlacement"].tap()
        app.buttons["Build"].tap(); app.buttons["buildingCategory-Settlement"].tap()
        if app.buttons["selectBuilding-storehouse"].exists { app.buttons["selectBuilding-storehouse"].tap() }
        let materials = app.buttons["build-storehouse"]
        XCTAssertTrue(materials.waitForExistence(timeout: 5))
        XCTAssertTrue(materials.label.contains("Find materials"), materials.label)
        materials.tap(); XCTAssertTrue(app.descendants(matching: .any)["playerCatalogRequirement"].waitForExistence(timeout: 5))
        app.buttons["playerCatalogBack"].tap()
        app.buttons["buildingCategory-All"].tap()
        let search = app.textFields["catalogSearch"]; search.tap(); search.typeText("scout")
        XCTAssertTrue(app.buttons["selectBuilding-scoutCamp"].waitForExistence(timeout: 5)); app.buttons["selectBuilding-scoutCamp"].tap()
        let research = app.buttons["build-scoutCamp"]
        XCTAssertTrue(research.label.contains("Open required research"), research.label); research.tap()
        XCTAssertTrue(app.descendants(matching: .any)["focusedResearch-exploration"].waitForExistence(timeout: 5))
        app.buttons["returnToSource"].tap()
        XCTAssertEqual(search.value as? String, "scout")
        let inspector = app.descendants(matching: .any)["playerCatalogInspector"].firstMatch
        XCTAssertTrue(inspector.exists)
        if app.frame.width < 1000 { XCTAssertGreaterThan(inspector.frame.midY, app.frame.midY) }
        else { XCTAssertGreaterThan(inspector.frame.midX, app.frame.midX) }
        XCTAssertGreaterThan(app.frame.width, app.frame.height, "Catalog stays in landscape")
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); shot.name = "riverbend-contextual-catalog-and-return"; shot.lifetime = .keepAlways; add(shot)
        app.buttons["closeCatalog"].tap(); app.buttons["Build"].tap()
        XCTAssertEqual(search.value as? String, "scout")
        XCTAssertTrue(app.buttons["build-scoutCamp"].label.contains("Open required research"))
    }

    @MainActor func testRiverbendOrdinaryOpeningAndContinue() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); app.launch()
        XCTAssertTrue(app.buttons["newNormalGame"].waitForExistence(timeout: 30)); app.buttons["newNormalGame"].tap()
        let map = app.otherElements["settlementMap"]
        XCTAssertTrue(map.waitForExistence(timeout: 30))
        XCTAssertFalse(app.buttons["resource-water"].exists)
        XCTAssertFalse(app.buttons["developerTools"].exists)
        app.buttons["toggleGoals"].tap()
        XCTAssertTrue(app.buttons["nextStepAction"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["nextStepSummary"].label.contains("Lodge"))
        app.buttons["nextStepAction"].tap()
        XCTAssertTrue(app.buttons["upgradeBuilding"].waitForExistence(timeout: 5)); app.buttons["upgradeBuilding"].tap()
        XCTAssertTrue(app.staticTexts["civicLevelName"].label.contains("Lodge"))
        app.buttons["closeBuildingInspection"].tap()
        if !app.buttons["nextStepAction"].exists { app.buttons["toggleGoals"].tap() }; app.buttons["nextStepAction"].tap()
        XCTAssertTrue(app.buttons["build-hut"].waitForExistence(timeout: 5)); app.buttons["build-hut"].tap()
        XCTAssertTrue(app.buttons["confirmPlacement"].waitForExistence(timeout: 5)); app.buttons["confirmPlacement"].tap()
        let built = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value CONTAINS %@", "2 buildings"), object: map)
        XCTAssertEqual(XCTWaiter.wait(for: [built], timeout: 10), .completed)
        let opening = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); opening.name = "riverbend-ordinary-opening"; opening.lifetime = .keepAlways; add(opening)
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["continueGame"].waitForExistence(timeout: 30)); app.buttons["continueGame"].tap()
        XCTAssertTrue(map.waitForExistence(timeout: 30))
        XCTAssertTrue((map.value as? String ?? "").contains("2 buildings"))
        XCTAssertFalse(app.buttons["developerTools"].exists)
        app.buttons["openExplore"].tap()
        XCTAssertTrue(app.buttons["riverbendRecoverFood"].waitForExistence(timeout: 5))
        let resumed = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); resumed.name = "riverbend-ordinary-continue"; resumed.lifetime = .keepAlways; add(resumed)
        app.buttons["Close panel"].tap()
        app.buttons["settlementMenu"].tap()
        let hut = app.descendants(matching: .any).matching(identifier: "inspectBuilding-1").firstMatch
        XCTAssertTrue(hut.waitForExistence(timeout: 5)); hut.tap()
        let connected = app.buttons["connectBuildingPaths"]
        XCTAssertTrue(connected.waitForExistence(timeout: 25)); connected.tap()
        XCTAssertTrue(app.buttons["confirmRoadStroke"].waitForExistence(timeout: 5)); app.buttons["confirmRoadStroke"].tap()
        app.buttons["closeRoads"].tap()
        map.swipeLeft(); map.swipeRight(); map.pinch(withScale: 1.1, velocity: 1)
        app.buttons["settlementMenu"].tap(); app.buttons["Center on settlement"].tap()
        app.buttons["openExplore"].tap()
        let coverage = app.staticTexts["explorationCoverage"].label
        let survey = app.buttons["startExploration"]
        for _ in 0..<8 where !survey.isHittable { app.scrollViews["riverbendExploreContent"].swipeUp() }
        XCTAssertTrue(survey.isHittable); XCTAssertTrue(survey.isEnabled)
        let surveyStart = Date(); survey.tap()
        XCTAssertTrue(app.staticTexts["explorationTimer"].waitForExistence(timeout: 5))
        let returned = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: app.staticTexts["explorationTimer"])
        XCTAssertEqual(XCTWaiter.wait(for: [returned], timeout: 75), .completed)
        print("RIVERBEND native real survey seconds=", Date().timeIntervalSince(surveyStart))
        XCTAssertNotEqual(app.staticTexts["explorationCoverage"].label, coverage)
        for _ in 0..<10 where !app.buttons["Close panel"].isHittable { app.scrollViews["riverbendExploreContent"].swipeDown() }
        app.buttons["Close panel"].tap()
        let forest = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); forest.name = "riverbend-whole-forest-real-survey"; forest.lifetime = .keepAlways; add(forest)
    }

    @MainActor func testNormalEntryPersistenceWithoutDeveloperHooks() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launch()
        let newGame = app.buttons["newNormalGame"]
        XCTAssertTrue(newGame.waitForExistence(timeout: 30))
        XCTAssertFalse(app.buttons["developerTools"].exists)
        XCTAssertFalse(app.buttons["openEconomyLab"].exists)
        newGame.tap()
        let map = app.otherElements["settlementMap"]
        XCTAssertTrue(map.waitForExistence(timeout: 30))
        XCTAssertTrue((map.value as? String ?? "").contains("64×48 tiles · 1 buildings · 0 road tiles"))
        app.buttons["toggleGoals"].tap(); app.buttons["nextStepAction"].tap()
        app.buttons["upgradeBuilding"].tap(); app.buttons["closeBuildingInspection"].tap()
        app.buttons["Build"].tap(); app.buttons["buildingCategory-Settlement"].tap()
        app.buttons["build-hut"].tap()
        XCTAssertTrue(app.buttons["confirmPlacement"].waitForExistence(timeout: 5))
        app.buttons["confirmPlacement"].tap()
        app.terminate(); app.launch()
        let resume = app.buttons["continueGame"]
        XCTAssertTrue(resume.waitForExistence(timeout: 30)); XCTAssertTrue(resume.isEnabled)
        XCTAssertFalse(map.exists)
        resume.tap()
        XCTAssertTrue(map.waitForExistence(timeout: 30))
        XCTAssertTrue((map.value as? String ?? "").contains("64×48 tiles · 2 buildings · 1 road tiles"))
        app.buttons["settlementMenu"].tap(); app.buttons["openGames"].tap()
        let selected = app.staticTexts["activeGameName"].label
        app.buttons["Done"].tap()
        app.terminate(); app.launch()
        XCTAssertTrue(newGame.waitForExistence(timeout: 30)); newGame.tap()
        XCTAssertTrue(map.waitForExistence(timeout: 30))
        XCTAssertTrue((map.value as? String ?? "").contains("64×48 tiles · 1 buildings · 0 road tiles"))
        app.buttons["settlementMenu"].tap(); app.buttons["openGames"].tap()
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
        XCTAssertFalse(app.buttons["openEconomyLab"].exists)
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
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "ordinary-release-earned-bronze-readiness"; shot.lifetime = .keepAlways; add(shot)
            app.navigationBars["Stone Age journey"].buttons["Done"].tap()
            app.buttons["Build"].tap(); app.buttons["buildingCategory-Settlement"].tap()
            XCTAssertTrue(app.buttons["build-hut"].isEnabled)
            app.terminate()
        }
    }
}

final class RiverbendEarnedUITests: XCTestCase {
    @MainActor private func open(_ app: XCUIApplication) {
        app.launch(); XCTAssertTrue(app.buttons["continueGame"].waitForExistence(timeout: 30)); app.buttons["continueGame"].tap()
        XCTAssertTrue(app.otherElements["settlementMap"].waitForExistence(timeout: 30))
        XCTAssertFalse(app.buttons["developerTools"].exists)
    }
    @MainActor private func tap(_ id: String, _ app: XCUIApplication) {
        let button = id.hasPrefix("resource-") ? app.descendants(matching: .any).matching(identifier: id).firstMatch : app.buttons[id].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 10), id)
        let scroller = [app.scrollViews["riverbendExploreContent"], app.scrollViews["buildingInspection"], app.scrollViews["playerCatalogDetails"], app.scrollViews["buildingCatalog"]].first { $0.exists } ?? app.scrollViews.firstMatch
        for _ in 0..<10 where !button.isHittable {
            let upward = button.frame.midY >= scroller.frame.midY
            let from = scroller.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: upward ? 0.82 : 0.18))
            let to = scroller.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: upward ? 0.22 : 0.78))
            print("RIVERBEND panel target=", id, "button=", button.frame, "viewport=", scroller.frame)
            from.press(forDuration: 0.2, thenDragTo: to, withVelocity: XCUIGestureVelocity(rawValue: 100), thenHoldForDuration: 0.2)
        }
        XCTAssertTrue(button.isHittable, id); button.tap()
    }
    @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); image.name = name; image.lifetime = .keepAlways; add(image)
    }
    @MainActor func testEarnedStockyardResourceInspector() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); open(app)
        let resource = app.descendants(matching: .any).matching(identifier: "resource-wood").firstMatch
        if !resource.waitForExistence(timeout: 5) { print("RIVERBEND resource tree", app.debugDescription) }
        XCTAssertTrue(resource.exists); resource.tap()
        let stored = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@ AND label ENDSWITH %@", "Stored:", " / 120")).firstMatch
        XCTAssertTrue(stored.waitForExistence(timeout: 5))
        capture("riverbend-earned-stockyard-actual-capacity", app)
    }
    @MainActor func testEarnedWorkshopContinuePresentation() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); open(app)
        capture("riverbend-earned-workshop-world", app)
        for resource in ["wood", "food"] {
            tap("resource-" + resource, app)
            let stored = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@ AND label ENDSWITH %@", "Stored:", " / 120")).firstMatch
            XCTAssertTrue(stored.waitForExistence(timeout: 5))
            capture("riverbend-earned-" + resource + "-capacity-continue", app)
            app.otherElements["settlementMap"].coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.9)).tap()
        }
        tap("openExplore", app)
        XCTAssertFalse(app.buttons["riverbendImproveWood"].isEnabled)
        XCTAssertFalse(app.buttons["riverbendFind-tracks"].exists)
        capture("riverbend-earned-workshop-continue", app)
    }
    @MainActor func testRealCraftStorageFindsAndRelaunch() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); open(app); tap("openExplore", app)
        tap("Inspect Stone / Flint production", app)
        tap("productionMode-flint", app); tap("productionMode-stone", app)
        tap("closeBuildingInspection", app); tap("openExplore", app)
        capture("riverbend-craft-price-and-project", app)
        for batch in 1...3 {
            tap("riverbendMakeTool", app); let started = Date()
            XCTAssertTrue(app.staticTexts["riverbendToolTimer"].waitForExistence(timeout: 5))
            if batch == 1 {
                app.terminate(); open(app); tap("openExplore", app)
                XCTAssertTrue(app.staticTexts["riverbendToolTimer"].waitForExistence(timeout: 5))
            }
            let done = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: app.staticTexts["riverbendToolTimer"])
            XCTAssertEqual(XCTWaiter.wait(for: [done], timeout: 75), .completed)
            print("RIVERBEND native Tool batch=", batch, " real seconds=", Date().timeIntervalSince(started))
        }
        tap("riverbendImproveWood", app)
        XCTAssertFalse(app.buttons["riverbendImproveWood"].isEnabled)
        capture("riverbend-lasting-woodcutter-project", app)
        tap("Close panel", app)
        for (index, role) in ["Stockyard", "Granary"].enumerated() {
            tap("Build", app); tap("buildingCategory-Settlement", app); tap("selectBuilding-storehouse", app)
            if role == "Granary" { tap("Granary", app) }
            tap("build-storehouse", app)
            tap("confirmPlacement", app)
            let map = app.otherElements["settlementMap"]
            let built = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value CONTAINS %@", "\(6 + index) buildings"), object: map)
            XCTAssertEqual(XCTWaiter.wait(for: [built], timeout: 5), .completed)
            app.buttons["settlementMenu"].tap()
            let item = app.descendants(matching: .any).matching(identifier: "inspectBuilding-\(5 + index)").firstMatch
            XCTAssertTrue(item.waitForExistence(timeout: 5)); item.tap()
            let operating = app.staticTexts["buildingOperatingStatus"]
            XCTAssertTrue(operating.waitForExistence(timeout: 40), "Paid storage construction must complete")
            if app.buttons["connectBuildingPaths"].exists {
                tap("connectBuildingPaths", app); tap("confirmRoadStroke", app); tap("closeRoads", app)
            } else {
                XCTAssertFalse(operating.label.contains("Not connected"), operating.label)
                tap("closeBuildingInspection", app)
            }
            for (resource, cap) in [("wood", 120), ("food", role == "Stockyard" ? 60 : 120)] {
                tap("resource-" + resource, app)
                let stored = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@ AND label ENDSWITH %@", "Stored:", " / \(cap)")).firstMatch
                XCTAssertTrue(stored.waitForExistence(timeout: 5), "Actual " + resource + " capacity")
                capture("riverbend-" + role.lowercased() + "-" + resource + "-capacity", app)
                app.otherElements["settlementMap"].coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.9)).tap()
            }
            capture("riverbend-connected-" + role.lowercased(), app)
        }
        tap("openExplore", app)
        if app.buttons["riverbendFind-tracks"].exists { tap("riverbendFind-tracks", app) }
        tap("riverbendRecoverFood", app); tap("riverbendRecoverWood", app)
        app.terminate(); open(app); tap("openExplore", app)
        XCTAssertFalse(app.buttons["riverbendImproveWood"].isEnabled)
        XCTAssertFalse(app.buttons["riverbendFind-tracks"].exists)
        capture("riverbend-craft-storage-and-finds-continue", app)
    }
    @MainActor func testEnclosureGateAndSameGameContinue() throws {
        continueAfterFailure = false; XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication(); open(app); tap("openExplore", app)
        tap("riverbendEnclosure", app); XCTAssertTrue(app.buttons["riverbendGate"].waitForExistence(timeout: 5))
        tap("riverbendGate", app); XCTAssertEqual(app.buttons["riverbendGate"].label, "Open gate")
        capture("riverbend-closed-gate", app)
        tap("riverbendGate", app); XCTAssertEqual(app.buttons["riverbendGate"].label, "Close gate")
        tap("Close panel", app); capture("riverbend-open-cliff-backed-enclosure", app)
        app.terminate(); open(app); tap("openExplore", app)
        XCTAssertEqual(app.buttons["riverbendGate"].label, "Close gate")
        XCTAssertFalse(app.buttons["riverbendEnclosure"].exists)
        capture("riverbend-enclosure-continue", app)
        tap("Close panel", app); tap("toggleGoals", app)
        XCTAssertEqual(app.staticTexts["nextStepSummary"].label, "Stone Age complete")
        XCTAssertTrue(app.buttons["toggleGoals"].label.contains("7/7"))
        tap("openJourney", app)
        XCTAssertTrue(app.staticTexts["bronzeAgeReadiness"].waitForExistence(timeout: 5))
        capture("riverbend-native-earned-bronze-readiness", app)
        app.navigationBars["Stone Age journey"].buttons["Done"].tap()
        tap("Build", app); tap("buildingCategory-Settlement", app)
        XCTAssertTrue(app.buttons["build-hut"].isEnabled)
    }
}
