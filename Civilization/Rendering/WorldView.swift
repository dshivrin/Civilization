import GameApplication
import SwiftUI
import SpriteKit
import GameCore

struct WorldView: UIViewRepresentable {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let scene: SettlementScene
    let session: GameSession
    let onReady: () -> Void
    var isObscured = false
    func makeCoordinator() -> Coordinator { Coordinator(scene: scene, session: session) }
    func makeUIView(context: Context) -> SKView {
        let view = SKView(); view.ignoresSiblingOrder = true; view.preferredFramesPerSecond = 60
        view.presentScene(scene)
        let coordinator = context.coordinator
        let hold = UILongPressGestureRecognizer(target: coordinator, action: #selector(Coordinator.move(_:)))
        hold.minimumPressDuration = 0.35; hold.allowableMovement = 10; hold.numberOfTouchesRequired = 1; hold.delegate = coordinator
        coordinator.holdRecognizer = hold
        let tap = UITapGestureRecognizer(target: coordinator, action: #selector(Coordinator.tap(_:)))
        let pan = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.pan(_:)))
        pan.maximumNumberOfTouches = 1; pan.delegate = coordinator
        let pinch = UIPinchGestureRecognizer(target: coordinator, action: #selector(Coordinator.pinch(_:)))
        pinch.delegate = coordinator
        tap.require(toFail: hold)
        for recognizer in [tap, pan, pinch, hold] { view.addGestureRecognizer(recognizer) }
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Settlement map"
        view.accessibilityIdentifier = "settlementMap"
        view.accessibilityHint = "Drag to pan, pinch to zoom. Choose a new building to enter drag mode automatically. Drag and release to place. Long-press an existing building to move it. Tap and Confirm are also available."
        return view
    }
    func updateUIView(_ view: SKView, context: Context) {
        context.coordinator.updateAccessibility(in: view)
        scene.onReady = onReady
        view.isPaused = session.shouldPauseRendering || isObscured
        scene.isPaused = session.shouldPauseAnimation
        scene.reduceMotion = reduceMotion
        scene.activeProductionIDs = session.operatingProductionBuildingIDs
        scene.display(state: session.state, kind: session.previewKind, tile: session.selectedTile, valid: session.placementIssue == nil, inspected: session.currentInspection, movingBuildingID: session.movingBuildingID, previewFootprint: session.previewFootprint, relocationGrid: session.relocationGrid, unavailablePreviewTiles: session.movingBuildingID == nil ? nil : Set((session.previewFootprint?.tiles(at: session.selectedTile ?? Tile(x: 0, y: 0)) ?? []).filter { !session.isPreviewTileAvailable($0) }), roadTool: session.roadTool, roadDraft: session.roadDraft, roadInvalid: session.roadPreviewIssue != nil, centerRequest: session.centerRequest, deposits: session.discoveredDeposits, identifiedDepositIDs: Set(session.discoveredDeposits.filter { session.isIdentified($0) }.map(\.id)))
    }
    @MainActor final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let scene: SettlementScene
        let session: GameSession
        private var dragOffset = Tile(x: 0, y: 0)
        private var isDragging = false
        private var panTouchDownTile: Tile?
        private var holdTouchDown: (buildingID: Int, tile: Tile)?
        weak var holdRecognizer: UILongPressGestureRecognizer?
        #if DEBUG
        private var panCount = 0, pinchCount = 0
        #endif
        init(scene: SettlementScene, session: GameSession) { self.scene = scene; self.session = session }
        func updateAccessibility(in view: UIView?) {
            var value = "\(session.configuration.map.width)×\(session.configuration.map.height) tiles · \(session.state.buildings.count) buildings · \(session.state.roads?.count ?? 0) road tiles"
            #if DEBUG
            value += " · pan=\(panCount) pinch=\(pinchCount) " + scene.cameraAccessibilityValue
            #endif
            view?.accessibilityValue = value
        }
        private func tile(_ recognizer: UIGestureRecognizer) -> Tile {
            IsometricProjection.tile(scene.convertPoint(fromView: recognizer.location(in: recognizer.view)))
        }
        private func building(at point: CGPoint) -> PlacedBuilding? {
            if let id = scene.buildingID(at: point) { return session.state.buildings.first { $0.id == id } }
            let tile = IsometricProjection.tile(point)
            return session.state.buildings.first { $0.tiles(in: session.configuration).contains(tile) }
        }
        private func movableBuilding(at point: CGPoint) -> PlacedBuilding? {
            guard !session.isDragMode && session.roadTool == nil else { return nil }
            let touched = IsometricProjection.tile(point)
            return session.state.buildings.first { $0.kind != .campfire && $0.tiles(in: session.configuration).contains(touched) }
        }
        func gestureRecognizer(_ recognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            let location = scene.convertPoint(fromView: touch.location(in: recognizer.view))
            let touched = IsometricProjection.tile(location)
            if recognizer is UIPanGestureRecognizer {
                panTouchDownTile = touched
                return true
            }
            if recognizer is UILongPressGestureRecognizer {
                guard let building = movableBuilding(at: location) else { holdTouchDown = nil; return false }
                holdTouchDown = (building.id, touched)
            }
            return true
        }
        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            // Pan immediately unless a deliberate hold already owns relocation.
            if recognizer is UIPanGestureRecognizer,
               holdRecognizer?.state == .began || holdRecognizer?.state == .changed { return false }
            return true
        }
        func gestureRecognizer(_ first: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith second: UIGestureRecognizer) -> Bool {
            // A second finger can start zoom; the pinch handler cancels the preview before moving the camera.
            (first is UIPinchGestureRecognizer && second is UILongPressGestureRecognizer) ||
            (second is UIPinchGestureRecognizer && first is UILongPressGestureRecognizer) ||
            (first is UIPinchGestureRecognizer && second is UIPanGestureRecognizer) ||
            (second is UIPinchGestureRecognizer && first is UIPanGestureRecognizer)
        }
        @objc func tap(_ recognizer: UITapGestureRecognizer) {
            let point = scene.convertPoint(fromView: recognizer.location(in: recognizer.view))
            if session.roadTool != nil { session.extendRoadStroke(to: IsometricProjection.tile(point)); return }
            if session.previewKind == nil, let building = building(at: point) { session.inspect(buildingID: building.id) }
            else { session.tap(IsometricProjection.tile(point)) }
        }
        @objc func move(_ recognizer: UILongPressGestureRecognizer) {
            switch recognizer.state {
            case .began:
                guard let start = holdTouchDown, !session.isDragMode,
                      let building = session.state.buildings.first(where: { $0.id == start.buildingID }) else { return }
                dragOffset = Tile(x: start.tile.x - building.origin.x, y: start.tile.y - building.origin.y)
                session.beginRelocation(buildingID: building.id)
                isDragging = true
            case .changed:
                guard isDragging, session.movingBuildingID != nil else { return }
                let touched = tile(recognizer)
                session.tap(Tile(x: touched.x - dragOffset.x, y: touched.y - dragOffset.y))
            case .ended:
                guard isDragging else { return }
                let touched = tile(recognizer)
                if session.movingBuildingID != nil {
                    session.tap(Tile(x: touched.x - dragOffset.x, y: touched.y - dragOffset.y))
                    session.finishRelocation()
                }
                isDragging = false
            case .cancelled, .failed:
                if isDragging { session.cancel() }; isDragging = false
            default: break
            }
        }
        @objc func pan(_ recognizer: UIPanGestureRecognizer) {
            #if DEBUG
            if recognizer.state == .began { panCount += 1 }
            #endif
            defer { if recognizer.state == .ended || recognizer.state == .cancelled { updateAccessibility(in: recognizer.view) } }
            if session.roadTool != nil {
                switch recognizer.state {
                case .began, .changed, .ended: session.extendRoadStroke(to: tile(recognizer))
                case .cancelled, .failed: session.clearRoadStroke()
                default: break
                }
                recognizer.setTranslation(.zero, in: recognizer.view);return
            }
            if recognizer.state == .began {
                let touched = panTouchDownTile ?? tile(recognizer)
                isDragging = session.canDragPreview(from: touched)
                if isDragging {
                    if let origin = session.selectedTile, session.previewFootprint?.tiles(at: origin).contains(touched) == true {
                        dragOffset = Tile(x: touched.x - origin.x, y: touched.y - origin.y)
                    } else { dragOffset = Tile(x: 0, y: 0) }
                }
            }
            if isDragging {
                guard session.isDragMode else { isDragging = false; return }
                switch recognizer.state {
                case .began, .changed, .ended:
                    let touched = tile(recognizer)
                    session.tap(Tile(x: touched.x - dragOffset.x, y: touched.y - dragOffset.y))
                    if recognizer.state == .ended { session.finishDragging(); isDragging = false }
                case .cancelled, .failed:
                    session.cancel(); isDragging = false
                default: break
                }
                recognizer.setTranslation(.zero, in: recognizer.view)
                return
            }
            let translation = recognizer.translation(in: recognizer.view)
            scene.pan(dx: translation.x, dy: translation.y); recognizer.setTranslation(.zero, in: recognizer.view)
        }
        @objc func pinch(_ recognizer: UIPinchGestureRecognizer) {
            #if DEBUG
            if recognizer.state == .began { pinchCount += 1 }
            #endif
            defer { if recognizer.state == .ended || recognizer.state == .cancelled { updateAccessibility(in: recognizer.view) } }
            if recognizer.state == .began {
                session.clearRoadStroke()
                holdRecognizer?.isEnabled = false; holdRecognizer?.isEnabled = true
            }
            if recognizer.state == .began, session.isDragMode { session.cancel(); isDragging = false }
            scene.zoom(factor: recognizer.scale); recognizer.scale = 1
        }
    }
}
