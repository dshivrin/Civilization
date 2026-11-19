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
        let tap = UITapGestureRecognizer(target: coordinator, action: #selector(Coordinator.tap(_:)))
        let pan = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.pan(_:)))
        pan.maximumNumberOfTouches = 1
        let pinch = UIPinchGestureRecognizer(target: coordinator, action: #selector(Coordinator.pinch(_:)))
        pinch.delegate = coordinator
        tap.require(toFail: hold); pan.require(toFail: hold)
        for recognizer in [tap, pan, pinch, hold] { view.addGestureRecognizer(recognizer) }
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Settlement map"
        view.accessibilityIdentifier = "settlementMap"
        view.accessibilityHint = "Drag to pan, pinch to zoom. Choose a new building to enter drag mode automatically. Drag and release to place. Long-press an existing building to move it. Tap and Confirm are also available."
        return view
    }
    func updateUIView(_ view: SKView, context: Context) {
        scene.onReady = onReady
        view.isPaused = session.shouldPauseRendering || isObscured
        scene.isPaused = session.shouldPauseAnimation
        scene.reduceMotion = reduceMotion
        scene.activeProductionIDs = session.operatingProductionBuildingIDs
        scene.display(state: session.state, kind: session.previewKind, tile: session.selectedTile, valid: session.placementIssue == nil, inspected: session.currentInspection, movingBuildingID: session.movingBuildingID, centerRequest: session.centerRequest, deposits: session.discoveredDeposits, identifiedDepositIDs: Set(session.discoveredDeposits.filter { session.isIdentified($0) }.map(\.id)))
    }
    @MainActor final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let scene: SettlementScene
        let session: GameSession
        private var dragOffset = Tile(x: 0, y: 0)
        private var isDragging = false
        init(scene: SettlementScene, session: GameSession) { self.scene = scene; self.session = session }
        private func tile(_ recognizer: UIGestureRecognizer) -> Tile {
            IsometricProjection.tile(scene.convertPoint(fromView: recognizer.location(in: recognizer.view)))
        }
        private func building(at point: CGPoint) -> PlacedBuilding? {
            if let id = scene.buildingID(at: point) { return session.state.buildings.first { $0.id == id } }
            let tile = IsometricProjection.tile(point)
            return session.state.buildings.first { session.configuration.definition($0.kind).tiles(at: $0.origin).contains(tile) }
        }
        private func movableBuilding(at point: CGPoint) -> PlacedBuilding? {
            guard !session.isDragMode else { return nil }
            guard let building = building(at: point), building.kind != .campfire else { return nil }
            return building
        }
        func gestureRecognizer(_ recognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard recognizer is UILongPressGestureRecognizer else { return true }
            let location = scene.convertPoint(fromView: touch.location(in: recognizer.view))
            return movableBuilding(at: location) != nil
        }
        func gestureRecognizer(_ first: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith second: UIGestureRecognizer) -> Bool {
            // A second finger can start zoom; the pinch handler cancels the preview before moving the camera.
            (first is UIPinchGestureRecognizer && second is UILongPressGestureRecognizer) ||
            (second is UIPinchGestureRecognizer && first is UILongPressGestureRecognizer)
        }
        @objc func tap(_ recognizer: UITapGestureRecognizer) {
            let point = scene.convertPoint(fromView: recognizer.location(in: recognizer.view))
            if session.previewKind == nil, let building = building(at: point) { session.inspect(buildingID: building.id) }
            else { session.tap(IsometricProjection.tile(point)) }
        }
        @objc func move(_ recognizer: UILongPressGestureRecognizer) {
            switch recognizer.state {
            case .began:
                let touched = tile(recognizer)
                guard let building = movableBuilding(at: scene.convertPoint(fromView: recognizer.location(in: recognizer.view))) else { return }
                dragOffset = Tile(x: touched.x - building.origin.x, y: touched.y - building.origin.y)
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
            if recognizer.state == .began {
                isDragging = session.isDragMode
                if isDragging {
                    let touched = tile(recognizer)
                    let point = scene.convertPoint(fromView: recognizer.location(in: recognizer.view))
                    if let origin = session.selectedTile, scene.previewContains(point) {
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
            if recognizer.state == .began, session.isDragMode { session.cancel(); isDragging = false }
            scene.zoom(factor: recognizer.scale); recognizer.scale = 1
        }
    }
}
