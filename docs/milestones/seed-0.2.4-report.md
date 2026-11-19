# Seed0.2.4 completion report

Persistent terrain/deposits/discovery/identification layers implemented with unchanged mapID, rows and depositlocations. Newgames initiallyreveal257tiles includingknownsourcepaths; timedfood-cost expeditions expandrings, operational scoutcamprequired afterradius11. Hiddenfootprints/extractionblocked; bonusescountdiscoveredterrain; fishingrequiresrevealedwaterwithin3. Copper remainsunidentified/unextractablefuturedeposit. Rendererhidesunknownterrain/scenery, displaysreplaceabledepositmarkers. ExploreUIlistscoverage/cost/time/reserves.

`swift test --package-path Packages/GameCore` passes70tests; log /tmp/civilization-024-core.log. Includes60priorregressions, discoveryatomicity, hidden/unknownextraction, waterrestriction, v4migrationstrictness, fullfreshscoutbootstrap, hiddenbonusboundary/partitionequivalence, offlinecap/rollback andradius-vs-revealvalidation. Independentreview foundradiusinconsistency, fixedwithregression.

Phonefresh17ProMax26.5 andmigratedminiA17Pro18.6 built/run throughXcodeBuildMCP build_run_sim(extraArgs:[CODE_SIGNING_ALLOWED=NO]). Freshisolatedsimulator C654E7D7-6591-4E30-836B-F373FF94F261 keepsoldsettlementsuntouched. ActualUIexpedition10food/45s expanded257→382tiles afterrestart; tabletpreserves768revealedtiles andlevel2/flintmode7.5rate. Screenshots ../screenshots/seed-024. v4backups v3original beforeupgrade; testedbyteexact/idempotent.

Limits: sourcecontentforthe secondage isundefined, so two-agegeographicbalance cannotbeverified. Numericalradii/knownroutepresentationexperimental. Physicaldeviceperformance/signing/humanbalanceunverified. Maclockedbrowserpreventsreadingnewplanningreplies; connectorreportingworks. Alreadyretrievedapprovedbaselineauthorizes025, but latestreplycontentnotclaimedverified.
