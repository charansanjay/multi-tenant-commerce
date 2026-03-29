# Feature/Module Development Prompt

Read CLAUDE.md at the repo root, then read .claude/modules/01_auth/STATUS.md, then read apps/admin/src/modules/auth/FEATURE_ARCH.md. Do not write any code until you have read all three files.

After reading, confirm back to me:

1. The current step and what needs to be built
2. The four CDS components that need to be built before the module features
3. The exact file list this module creates
4. Which Supabase client is used in each context

Then wait for me to say "go" before writing any code.

When I say go, follow the build order defined in STATUS.md exactly:

- Build the four missing CDS components first (FormField, Select, Tooltip, DropdownMenu)
- Then implement module features in the order listed
- After each file is created, confirm it is done before moving to the next
- Open .claude/modules/01_auth/mockups/01_login.html and .claude/modules/01_auth/mockups/02_admin_shell.html in your browser tool if available, or read them directly — pixel-match every component against the approved mockups
- Run pnpm type-check after every third file — fix any errors before continuing
- Do not move to the next file if the current one has TypeScript errors or lint warnings

When all files are created:

- Run pnpm type-check
- Run pnpm lint
- Fix everything until both pass clean
- Report back with a summary of what was built
