#!/usr/bin/env python3
"""Compile API probes against built Debug/Release modules; debug APIs must not exist in Release.
Run after swift test and swift test -c release. Optional arguments: debug and release module directories.
"""
from pathlib import Path
import subprocess
import sys
import tempfile
root = Path(__file__).resolve().parents[1]
build = root / 'Packages/GameCore/.build'
def module_dir(configuration):
    for path in (build / 'out/Products' / configuration, build / configuration.lower() / 'Modules'):
        if (path / 'GameApplication.swiftmodule').exists():
            return path
    raise SystemExit(f'Build {configuration} modules first')
debug, release = map(Path, sys.argv[1:]) if len(sys.argv) == 3 else (module_dir('Debug'), module_dir('Release'))
probes = {
    'riverbendFoothillReview': 'import GameCore\nlet c = try GameConfiguration.riverbendFoothillReview()\n',
    'FoothillBoundary': 'import GameCore\nlet t = FoothillBoundary.gate\n',
    'ReviewForestPresentation': 'import GameApplication\nlet presentation = ReviewForestPresentation.self\n',
    'ReviewFogBoundary': 'import GameApplication\nlet edges = ReviewFogBoundary.edges(known: [], width: 4, height: 4)\n',
    'RiverbendFoundingReview': 'import Foundation\nimport GameApplication\nlet review = try RiverbendFoundingReview(now: Date())\n',
    'RiverbendFoundingStore': 'import Foundation\nimport GameApplication\nlet store = try RiverbendFoundingStore(directory: URL(fileURLWithPath: "/tmp"), now: Date())\n',
    'riverbendFoundingReview': 'import GameCore\nlet config = try GameConfiguration.riverbendFoundingReview()\n',
    'RiverbendGatheringMode': 'import GameApplication\nlet mode = RiverbendGatheringMode.flint\n',
    'RiverbendStorageRole': 'import GameApplication\nlet role = RiverbendStorageRole.granary\n',
    'RiverbendMapFindID': 'import GameApplication\nlet find = RiverbendMapFindID.berries\n',
    'RiverbendEconomyLab': 'import Foundation\nimport GameApplication\nlet lab = try RiverbendEconomyLab(now: Date())\n',
    'riverbendEconomyLab': 'import GameCore\nlet config = try GameConfiguration.riverbendEconomyLab()\n',
    'VisualAgentPowerObservation': 'import GameApplication\n@MainActor func probe() { _ = VisualAgentPowerObservation() }\n',
    'reviewStage': 'import GameApplication\nlet stage = ConstructionPresentation(remaining: 10, duration: 20).reviewStage\n',
    'OnboardingReviewWalkthrough': 'import Foundation\nimport GameCore\nimport GameApplication\nfunc probe(_ c: GameConfiguration) throws { _ = try OnboardingReviewWalkthrough(configuration: c, now: Date()) }\n',
    'activateReviewConnectivity': 'import GameApplication\n@MainActor func probe(_ s: GameSession) { s.activateReviewConnectivity() }\n',
    'startGameplayReview': 'import GameApplication\n@MainActor func probe(_ s: GameSession) { s.startGameplayReview() }\n',
    'resumeGameplayReview': 'import GameApplication\n@MainActor func probe(_ s: GameSession) { s.resumeGameplayReview() }\n',
    'renderBenchmark': 'import Foundation\nimport GameApplication\n@MainActor func probe() throws { _ = try GameSession.renderBenchmark(in: URL(fileURLWithPath: "/tmp")) }\n',
    'DeveloperScenario': 'import GameApplication\nlet scenario = DeveloperScenario.early\n',
    'developerFastConstruction': 'import GameCore\nfunc probe(_ e: inout GameEngine) { e.developerFastConstruction = true }\n',
    'loadDeveloperScenario': 'import GameApplication\n@MainActor func probe(_ s: GameSession) { s.loadDeveloperScenario(.early) }\n',
    'developerAddResources': 'import GameCore\nfunc probe(_ e: inout GameEngine) { e.developerAddResources(1) }\n',
}
with tempfile.TemporaryDirectory() as folder:
    source = Path(folder) / 'probe.swift'
    for name, text in probes.items():
        source.write_text(text)
        for modules, should_compile in ((debug, True), (release, False)):
            result = subprocess.run(['xcrun', 'swiftc', '-typecheck', '-I', str(modules), str(source)], capture_output=True, text=True)
            assert (result.returncode == 0) == should_compile, result.stderr
            if not should_compile:
                assert name in result.stderr and ('no member' in result.stderr or 'cannot find' in result.stderr), result.stderr
        print(f'PASS: {name} exists in Debug and is unavailable in Release')
