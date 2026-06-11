---
name: batch-null-handling
description: Aggregation map returns null when no source records match key; clarify if this overwrites or skips
metadata:
  type: feedback
---

## Pattern: Null Aggregation Results in Batch Jobs

In `GoalValueBatch`, when a `(ownerId, year)` pair has no matching Opportunity or Order records, the aggregation map `.get(key)` returns `null`. The batch then assigns this to `GoalItem__c` fields.

**Decision point:** Is this intentional nulling (clear old values) or a gap?

The test `testGoalValueBatch_noCorrespondingRecords()` expects `null` when no source records exist, which suggests nulling is intentional. **However**, the batch also updates GoalItems even if aggregation returns `null`, creating ambiguity about whether this is:
- A) Intentional: "No source records = clear the field to null"
- B) A gap: "Should skip if aggregation was empty"

**How to apply:**  
When reviewing batch jobs with aggregations, always ask: what happens to target records when source data is absent? Ensure both the code and tests document this clearly.

**For this project:** GoalValueBatch should add a comment explaining the null behavior (Option A or B from review) and confirm tests align.
