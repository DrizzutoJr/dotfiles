# Global agent instructions

- Read the current repository's agent instructions before changing its files.
- Preserve existing work and ask before discarding or overwriting user changes.
- Keep credentials and machine-specific values out of version control; use environment variables for credentials.
- Verify changed behavior with relevant checks and report the results and any remaining limits.
- pstack and mattpocock-skills are installed at user scope on this machine. Do not use them together in one task. Before using either pack, read the current repository's `AGENTS.md` (including nested `AGENTS.md` when working in a subdirectory). If that file names **pstack**, **mattpocock-skills**, or **none**, follow it for this repository. If it does not say, or it is ambiguous, stop and ask the user which skill pack this repository should use (**pstack**, **mattpocock-skills**, or **none**). If they choose none, do not use skills from either pack unless they ask for one later in the conversation. Offer to record their choice in the repository's `AGENTS.md` when they want that default saved for future sessions.
