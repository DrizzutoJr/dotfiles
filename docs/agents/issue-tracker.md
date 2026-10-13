# Issue tracker: Local Markdown

Specs and tickets for this repo live under `.scratch/<feature>/` and travel with the repo.

- Write the spec to `.scratch/<feature>/spec.md`.
- Write one implementation ticket per file under `.scratch/<feature>/issues/`, numbered in dependency order.
- Record triage state in a `Status:` field and discussion under `## Comments`.
- Publish to the tracker by creating or updating these files; fetch a ticket by reading its file.

For wayfinding, use `.scratch/<effort>/map.md` as the map and one numbered child file per decision ticket. Record `Type:`, `Status:`, and `Blocked by:` in each ticket. Claim a ticket by setting `Status: claimed`; resolve it by recording its answer, setting `Status: resolved`, and linking the decision from the map.
