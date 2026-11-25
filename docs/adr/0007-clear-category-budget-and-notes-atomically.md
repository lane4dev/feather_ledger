# Clear a category budget and its review notes atomically

**Status**: accepted

Clearing a category budget also clears its category review notes for the same currency and month range. A forward clear includes notes in months that inherit their budget. The presence of a later budget breakpoint only determines whether the confirmation also warns about replacing later rules.

The existing BudgetDao write transaction applies the [budget timeline rules](0006-budget-stepped-timeline-and-crud-exemption.md) and deletes the matching notes in one commit. A failure rolls back both changes. Separate writes could leave a cleared budget with its old note or erase a note while the budget is still in effect. Month-level notes have their own identity and remain available after a category budget is cleared.
