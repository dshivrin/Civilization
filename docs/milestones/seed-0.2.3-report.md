# Seed 0.2.3 completion report

Approved workforce/population extension implemented: housing/food/water-dependent growth, continuous water consumption, workforce derived from population, configurable per-building requirements, automatic fractional allocation, saved player priorities and combined worker/input productivity. No manual citizen assignments or deaths. Survival labor reserve and passive campfire avoid bootstrap locks; parameters documented EXPERIMENTAL in ../design/population.md.

Verification: `swift test --package-path Packages/GameCore` passes60tests (53historical plus7workforce/review). /tmp/civilization-023-core.log. Independent review found no confirmed defect; added real-cost bootstrap with competing priorities, priority/timer save+catchup equivalence, precise waterthreshold timing and corruptpriority rejection. Original0.1/021/022mechanics use frozenfixtures, preserving exact assertions.

XcodeBuildMCP build_run_sim(extraArgs:[CODE_SIGNING_ALLOWED=NO]) succeeded on miniA17Pro18.6 and phone17ProMax26.5. Actualtabletinspection via new accessiblebuildingpicker: change stonegatherer priorityhigh, modeflint, upgradelevel2; flintrate6→7.5/min, costsdeducted10wood5stone. Restartlaunch succeeded. Phonepopulationpopover verifies workforce8available4required, wateruse0.5/person and visible pausedgrowthconditions. Screenshots ../screenshots/seed-023.

Version3 saves retain optionalpriority alongside mode/level/reserves; old saves defaultnormalpriority. No identifiers, geography or earnedrewards reset. Constructors remain household tasks under fixedtimers (documenteddelegatedchoice); only operationalproductivebuildings requireworkers.

Limits: hardwareperformance/signing andhumanpacingunverified. Survivalreserve values may needplaytest tuning. Allfinalart/deeperdemographics deferred. Continue approved0.2.4 after statuscheck.
