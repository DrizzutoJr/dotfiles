# Global agent instructions

- Read the current repository's agent instructions before changing its files.
- Preserve existing work and ask before discarding or overwriting user changes.
- Keep credentials and machine-specific values out of version control; use environment variables for credentials.
- Verify changed behavior with relevant checks and report the results and any remaining limits.
- pstack and mattpocock-skills may both be installed at user scope. Do not use them together. If the current repository names one, use only that one. If it does not specify which to use, or it is unclear, ask the user to choose pstack, mattpocock-skills, or none before applying either; if they choose none, do not use skills from either pack unless they ask for one later in the conversation.
