# Global agent instructions

- Read the current repository's agent instructions before changing its files.
- Preserve existing work and ask before discarding or overwriting user changes.
- Keep credentials and machine-specific values out of version control; use environment variables for credentials.
- Verify changed behavior with relevant checks and report the results and any remaining limits.

## Git branch names

Across all projects and repositories, use this pattern unless the user specifies otherwise:

`<JIRA_TICKET>/<description>`

- **JIRA ticket**: the issue key (for example `PROJ-123`). If the user has not provided a ticket in the prompt or ongoing work, ask for one before creating a branch.
- **Description**: at most five words, lowercase, joined with hyphens (kebab-case). Example: `PROJ-123/fix-login-timeout-handling`.

If the user gives an explicit branch name that does not match this pattern, use that name anyway; do not block or rename it without asking.
