# Civilization — Permanent Development and Coordination Protocol

## 1. Project organization

There is now one consolidated ChatGPT project named **Civilization**.

All previous Civilization ChatGPT projects should be considered legacy. Do not independently retrieve instructions from those projects.

The development team consists of:
- Human: Product Owner and final decision authority.
- ChatGPT: Game Designer, Project Architect and Roadmap Coordinator.
- Codex: Engineering Lead.

Repositories:
- Civilization — game implementation and canonical documentation.
- Civilization-Media — original media assets and related production resources.

Both repositories must remain under Git version control.

## 2. Canonical documentation

Read and maintain the following files:

- AGENTS.md
- DESIGN_BASELINE.md
- DEVELOPMENT_ROADMAP.md
- DESIGN_DECISIONS.md
- MEDIA_REQUIREMENTS.md
- DESIGN_SYNC.md

These files are the authoritative project record.

Do not create competing roadmaps or replace existing documentation with partial conversation summaries.

Merge new decisions into existing documentation without losing previously approved requirements.

Every roadmap item should have:
- Unique identifier.
- Description.
- Status.
- Priority.
- Dependencies.
- Acceptance criteria.
- Target milestone.
- Approval reference, where available.
- Implementation commit, when completed.

Supported statuses:
- Proposed
- Approved
- Ready
- In Progress
- Awaiting Human Review
- Accepted
- Blocked
- Deferred

Implementation completion does not automatically mean product acceptance.

## 3. Communicating with ChatGPT

Use the consolidated Civilization ChatGPT project for all game design coordination.

If browser or project access is available, locate the consolidated project and establish a dedicated conversation named:

**Civilization — Master Development Coordination**

Reuse that conversation for future engineering handovers.

Do not choose a different conversation based solely on its most recent activity.

If direct communication is unavailable, produce a complete handover message for the human to submit to the coordination conversation.

Never pretend communication occurred if it did not.

## 4. Requesting instructions

At the beginning of every development cycle:

1. Read all canonical documents.
2. Inspect both repositories and their Git status.
3. Identify the current approved milestone.
4. Prepare the current project status.
5. Contact ChatGPT using the following request:

---

CIVILIZATION — DEVELOPMENT COORDINATION REQUEST

Review the complete Civilization project context and all relevant design discussions, not only this conversation.

Reconcile any newly approved requirements with our existing canonical documentation.

Current game version:
Current branch:
Game repository commit:
Media repository commit:

Accepted roadmap items:
Completed items awaiting review:
In-progress items:
Blocked items:
Outstanding approvals:
Technical concerns:
Human feedback received:
Documentation changes:

Relevant canonical documentation:
[Provide current contents or accessible references.]

Please return:
1. Newly approved design decisions not yet reflected in Git.
2. Required roadmap changes.
3. Conflicting or unresolved requirements.
4. The next prioritized implementation milestone.
5. Detailed implementation requirements.
6. Acceptance criteria.
7. Required media assets.
8. Explicit scope exclusions.
9. Decisions requiring human approval.

Do not silently discard previously approved features.

---

## 5. Implementation workflow

After receiving instructions:

1. Reconcile the instructions with canonical documentation.
2. Report conflicts before implementation.
3. Separate approved decisions from new proposals.
4. Commit approved documentation changes.
5. Implement only the authorized scope.
6. Run relevant automated tests.
7. Verify affected save-game compatibility.
8. Perform simulator and device verification where available.
9. Update documentation and roadmap statuses.
10. Commit implementation.
11. Prepare a development handover.

Do not proceed into unrelated milestones without authorization.

Preserve existing working gameplay unless explicitly instructed otherwise.

## 6. Progress reporting

At the end of each milestone, report to the same ChatGPT coordination conversation:

---

CIVILIZATION — DEVELOPMENT HANDOVER

Version:
Milestone:
Branch:
Game repository commit:
Media repository commit:
Working tree status:

Implemented:
Acceptance criteria satisfied:
Automated test results:
Device verification:
Screenshots and visual evidence:
Save compatibility:
Performance:
Known defects:
Technical debt:
Deviations from approved design:
Documentation updated:
Roadmap items awaiting human acceptance:
Remaining backlog:
Decisions required:

Please reconcile this report with the master roadmap and prepare the next authorized implementation instructions.

---

## 7. Design authority

ChatGPT may propose design changes, research reference games and recommend implementation priorities.

The human has final approval authority.

Do not interpret a suggestion as an approved requirement.

Do not remove deferred features from the roadmap simply because they are outside the current development scope.

## 8. Immediate assignment

Before implementing further features, perform a complete design synchronization.

Consolidate all previously approved requirements and the latest human feedback, including:

- Improved building relocation with individual tile availability indicators.
- Footprint-only dragging.
- Automatic placement when valid.
- Remaining in relocation mode when placement is invalid.
- Bottom-center cancellation control.
- Road stroke reversal and individual tile removal.
- Compact goals HUD with three display states.
- Explore icon beside the goals icon.
- Roads moved into the Build menu.
- New game and independent saves.
- Separation of developer and regular player experiences.
- Larger persistent geographical maps.
- Accessible stone quarry on the settlement side of the river.
- Cloud-covered unexplored territory.
- Expedition-based territory discovery.
- Geographical expansion across historical eras.
- Realistic, highly saturated environment artwork.

Also preserve the existing long-term approved backlog, including regional civilizations, persistent landmarks, variable building footprints, Living City, audio systems and future civilization interactions.

Our immediate product milestone remains a complete, enjoyable and polished Stone Age experience.

Do not start second-era gameplay, additional playable cities, warfare or monetization without explicit authorization.

Begin by synchronizing the documentation and reporting the current project status to ChatGPT.