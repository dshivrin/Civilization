# Stone Age research

Seed 0.2.5 status: APPROVED five-pillar research structure and meaningful unlocks. This twenty-technology tree, costs, bonuses and prerequisite details are EXPERIMENTAL delegated content. All values are bundled in `seed.json`; no second age or copper extraction is implemented.

The original Oral Tradition, Stone Tools and Social Order IDs, costs, prerequisites and numerical effects are preserved. Oral Tradition and Stone Tools are classified as Science; Social Order remains Population. Stone Tools additionally unlocks toolmakers. Basic campfire, huts, gathering shelters, woodcutters, stone gatherers and storehouses require no research. The remaining fourteen building types have explicit unlock technologies.

| Pillar | Technology | Prerequisites | Cost | Effect |
|---|---|---|---|---|
| Science | Oral Tradition | None | 20 food, 10 wood | Storytelling circle |
| Science | Stone Tools | Oral Tradition | 15 knowledge | Toolmaker; +20% wood/stone output |
| Science | Construction | Stone Tools | 10 knowledge, 10 stone | New construction duration ×0.9 |
| Science | Natural Knowledge | Oral Tradition | 20 knowledge, 10 food | +20% knowledge output |
| Population | Social Order | Oral Tradition | 50 knowledge | Growth interval ×0.75 |
| Population | Permanent Settlement | Oral Tradition | 15 knowledge, 10 wood | Growth interval ×0.9 |
| Population | Herbal Medicine | Leatherworking, Natural Knowledge | 20 knowledge, 3 leather | Healer's hut; +10% water output |
| Economy | Hunting | Oral Tradition | 10 knowledge, 5 wood | Hunting lodge |
| Economy | Fishing | Oral Tradition | 10 knowledge, 5 wood | Fishing shelter |
| Economy | Cultivation | Hunting | 20 knowledge, 10 food | Farm; +10% food output |
| Economy | Animal Domestication | Cultivation | 20 knowledge, 15 food | Animal pen |
| Economy | Leatherworking | Stone Tools, Hunting | 15 knowledge, 5 hides | Tannery |
| Economy | Pottery | Stone Tools | 15 knowledge, 5 clay | Pottery workshop |
| Economy | Food Preservation | Pottery | 20 knowledge, 3 pottery | +100 food capacity; +10% food output |
| Economy | Basketry | Oral Tradition | 10 knowledge, 10 wood | +50 wood/water capacity |
| Culture | Rituals | Oral Tradition | 15 knowledge, 10 stone | Shrine; +10% culture output |
| Culture | Burial Traditions | Rituals | 15 knowledge, 15 stone | Burial ground |
| Military & Security | Exploration | Oral Tradition | 10 knowledge, 10 food | Scout camp |
| Military & Security | Surveillance | Exploration, Stone Tools | 20 knowledge, 10 wood | Watchtower |
| Military & Security | Fortification | Surveillance | 15 knowledge, 10 stone | Palisade |

Knowledge is produced by storytelling circles after Oral Tradition; its initial purchase uses only food and wood. Basic stone-gatherer modes supply clay before pottery is researched. Hunting supplies hides before leatherworking. No technology requires the manufactured output of its own locked building. Fishing is inexpensive enough to restore positive water income after population reaches the passive campfire's water limit.

Research purchases remain atomic and permanent. Production fractions add to other technology bonuses; growth and construction multipliers multiply. These benefits operate through the existing native simulation effects. Original seven onboarding goals and construction rewards are retained; research does not grant extra goal rewards.

Older saves may contain advanced buildings without the newly introduced unlock research. Migration preserves the ability to construct each already-established building kind, without granting its technology or bonus. New branches still require normal research. Grandfathered construction knowledge is explicit saved history, not a blanket unlock of the expanded catalog.

The future `futureMetalworking` identifier remains solely a deposit identification requirement. None of this tree reveals copper as an extractable Stone Age resource. Military/security research provides watch, exploration and building foundations, not combat.
