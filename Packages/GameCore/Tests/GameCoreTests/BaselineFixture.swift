import Foundation
import GameCore

func baselineConfiguration() throws -> GameConfiguration {
    let url = Bundle.module.url(forResource: "seed-0.1", withExtension: "json", subdirectory: "Fixtures")!
    let config = try JSONDecoder().decode(GameConfiguration.self, from: Data(contentsOf: url))
    try config.validate()
    return config
}

func foundationConfiguration() throws -> GameConfiguration {
    let url = Bundle.module.url(forResource: "seed-0.2.1", withExtension: "json", subdirectory: "Fixtures")!
    let config = try JSONDecoder().decode(GameConfiguration.self, from: Data(contentsOf: url))
    try config.validate()
    return config
}

func economyConfiguration() throws -> GameConfiguration {
    let url = Bundle.module.url(forResource: "seed-0.2.2", withExtension: "json", subdirectory: "Fixtures")!
    let config = try JSONDecoder().decode(GameConfiguration.self, from: Data(contentsOf:url))
    try config.validate(); return config
}

func workforceConfiguration() throws -> GameConfiguration {
    let url = Bundle.module.url(forResource:"seed-0.2.3",withExtension:"json",subdirectory:"Fixtures")!
    let config = try JSONDecoder().decode(GameConfiguration.self,from:Data(contentsOf:url))
    try config.validate(); return config
}

func geographyConfiguration() throws -> GameConfiguration {
    let url = Bundle.module.url(forResource:"seed-0.2.4",withExtension:"json",subdirectory:"Fixtures")!
    let config = try JSONDecoder().decode(GameConfiguration.self,from:Data(contentsOf:url))
    try config.validate(); return config
}
