# Goal Value Batch System – Automatic Goal Item Value Calculation

**Date:** 2026-06-10  
**Author:** Documentation Agent  
**Status:** Completed  
**API Version:** 65.0

---

## Executive Summary

The **Goal Value Batch** system automatically calculates three essential financial metrics for each **GoalItem__c** record by aggregating data from **Opportunity** and **Order** objects. These metrics represent different stages of the sales funnel:
- **ProjectedValue__c**: Estimated revenue from open opportunities
- **NegotiatedValue__c**: Committed revenue from orders in early processing stages
- **RealizedValue__c**: Confirmed revenue from fully processed orders

The system uses a **scheduled batch processing** approach (not real-time triggers) to maintain consistency, avoid lock contention, and align with the existing **GoalBatch** architecture for calculating achieved percentages.

---

## Business Objective

**Problem:** The pricing project required a systematic way to track sales progression across three revenue stages for each sales goal, enabling:
- Real-time visibility into sales pipeline health per salesperson and year
- Automatic calculation of goal achievement percentages (via **GoalBatch**)
- Support for commission calculation based on which revenue tier is achieved
- Bulk processing efficiency without trigger-based latency

**Solution:** A scheduled batch job that runs daily (default: 9:00 AM Monday–Friday), aggregates source data, and replicates results across all GoalItems of the same salesperson/year pair.

---

## Original User Request

> "Continuação do desafio do projeto Pricing — sistema de Metas. Calcular automaticamente, para cada GoalItem__c, três valores a partir de Opportunity e Order:
> - Valor projetado (ProjectedValue__c) ← Oportunidades
> - Valor negociado (NegotiatedValue__c) ← Pedidos não concluídos/não finalizados
> - Valor realizado (RealizedValue__c) ← Pedidos concluídos
> 
> Decisões de negócio confirmadas:
> - Abordagem: BATCH agendado (consistente com GoalBatch existente), não trigger em tempo real.
> - Chave de match: Vendedor + Ano (OwnerId = Goal__r.Salesperson__c; ano via CALENDAR_YEAR).
> - Regras de agregação: [see Business Rules section below]"

---

## Components Created

### Admin Components (Declarative)

| API Name | Label | Type | Description |
|----------|-------|------|-------------|
| ProjectedValue__c | Projected Value | Currency (18,2) | Expected revenue from open opportunities; populated by GoalValueBatch |
| NegotiatedValue__c | Negotiated Value | Currency (18,2) | Committed revenue from orders in New/Processing status; populated by GoalValueBatch |
| RealizedValue__c | Realized Value | Currency (18,2) | Confirmed revenue from orders in Approved/Integrated status; populated by GoalValueBatch |

**Note:** These fields were already created on the **GoalItem__c** object before batch development. Field-Level Security was pre-configured via Permission Set "Goal_Management" and the four system profiles (Admin, Custom: Sales Profile, Custom: Support Profile, Custom: Marketing Profile). All three fields are visible on the GoalItem__c page layout.

### Development Components (Code)

| Name | Type | Location | Description |
|------|------|----------|-------------|
| GoalValueBatch | Apex Class (Batchable) | `force-app/main/default/classes/Application/GoalValueBatch.cls` | Main batch implementation; iterates GoalItems, aggregates from Opportunity and Order, replicates values across same salesperson/year pairs, updates via Database.update(false) |
| GoalValueScheduler | Apex Class (Schedulable) | `force-app/main/default/classes/Application/GoalValueScheduler.cls` | Scheduler to execute GoalValueBatch on a cron schedule (e.g., 9:00 AM Mon–Fri) with batch size 200 |
| GoalValueBatchTest | Apex Test Class | `force-app/main/default/classes/Application/GoalValueBatchTest.cls` | Comprehensive test suite; 12 test methods covering happy path, replication, empty data, filtering, bulk processing, and scheduler validation; ~95% code coverage |

---

## Data Model & Business Rules

### Aggregation Rules

| Field | Source Object | Query Condition | Date Filter | Aggregation | Default |
|-------|----------------|-----------------|-------------|-------------|---------|
| **ProjectedValue__c** | Opportunity | `IsClosed = false` | `CALENDAR_YEAR(CloseDate) = Goal__r.Year__c` | `SUM(Amount)` | 0 (null → 0 conversion) |
| **NegotiatedValue__c** | Order | `Status IN ('New', 'Processing')` | `CALENDAR_YEAR(EffectiveDate) = Goal__r.Year__c` | `SUM(TotalAmount)` | 0 (null → 0 conversion) |
| **RealizedValue__c** | Order | `Status IN ('Approved', 'Integrated')` | `CALENDAR_YEAR(EffectiveDate) = Goal__r.Year__c` | `SUM(TotalAmount)` | 0 (null → 0 conversion) |

### Matching Key

All aggregations are grouped by:
- **OwnerId** (matched to `Goal__r.Salesperson__c`)
- **Year** (extracted via `CALENDAR_YEAR()` from the date field)

Example: If GoalItem X belongs to a Goal with `Salesperson__c = '005xx000'` and `Year__c = 2026`, the batch aggregates all open Opportunities and Orders owned by that user in year 2026.

### Replication Logic

Once aggregated totals are computed for a (OwnerId, Year) pair:
1. **All** GoalItems belonging to Goals with that Salesperson/Year are updated with the same values
2. If multiple GoalItems target the same salesperson/year, each gets identical ProjectedValue, NegotiatedValue, and RealizedValue
3. This ensures consistency across product families, payment conditions, or other GoalItem variations for the same salesperson

### Default Value Behavior

**Decision:** When no source records exist (empty aggregation), values default to **0**, not null.
- If a salesperson has no open Opportunities in 2026, their ProjectedValue__c = 0
- If a salesperson has no orders in New/Processing/Approved/Integrated statuses in 2026, the respective fields = 0

This decision was made to:
- Simplify downstream formulas and reports (no null-checking required)
- Distinguish between "no data" (0) and "never run" (null)
- Support commission rules that key off value ranges

---

## How It Works: Architecture & Data Flow

### System Overview Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                     GOAL VALUE BATCH SYSTEM                         │
└─────────────────────────────────────────────────────────────────────┘

  ┌────────────────────────────────────────────────────────────────┐
  │ SCHEDULER (GoalValueScheduler) - Daily 9:00 AM Mon-Fri          │
  │ Triggers: Database.executeBatch(new GoalValueBatch(), 200)      │
  └────────────────────────────────────────────────────────────────┘
                             │
                             ▼
  ┌────────────────────────────────────────────────────────────────┐
  │ BATCH START (GoalValueBatch.start)                              │
  │ Query: All GoalItem__c records                                  │
  │ Returns: QueryLocator for processing in chunks                  │
  └────────────────────────────────────────────────────────────────┘
                             │
                             ▼
  ┌────────────────────────────────────────────────────────────────┐
  │ BATCH EXECUTE (GoalValueBatch.execute) - Per chunk (200 items)  │
  │                                                                 │
  │ Step 1: Extract unique (Salesperson, Year) pairs from scope     │
  │ Step 2: Group GoalItems by pair                                 │
  │ Step 3: Run 3 aggregate SOQL queries                            │
  │         ├─ Opportunities (ProjectedValue)                       │
  │         ├─ Orders/Negotiated (NegotiatedValue)                  │
  │         └─ Orders/Realized (RealizedValue)                      │
  │ Step 4: Replicate totals across same pair's GoalItems           │
  │ Step 5: Update records (Database.update(false) - non-blocking)  │
  │ Step 6: Log errors (non-throwing for partial success)           │
  └────────────────────────────────────────────────────────────────┘
           │       │       │        │        │
    ┌──────▼────┐ │       │   ┌────▼───┐    │
    │Opportunity│ │       │   │ Order  │    │
    │ Query     │ │       │   │ Query  │    │
    │IsClosed=F │ │       │   │Negotiat│    │
    │Year Filter│ │       │   │SUM(tot)│    │
    └───────────┘ │       │   └────────┘    │
                  │       │                 │
                  ▼       │                 ▼
              ┌─────┐     │           ┌──────────┐
              │ Opp │     │           │ Order    │
              │Agg  │     │           │ Realized │
              │Map  │     │           │ Agg Map  │
              └─────┘     │           └──────────┘
                          │
                    ┌─────▼───────┐
                    │ Order       │
                    │ Negotiated  │
                    │ Agg Map     │
                    └─────────────┘
                             │
                ┌────────────┴────────────┐
                ▼                         ▼
           ┌──────────┐          ┌──────────────┐
           │GoalItems │          │Replicate &   │
           │Grouped   │          │Update Logic  │
           │by Pair   │          │              │
           └──────────┘          └──────────────┘
                │                      │
                └──────────┬───────────┘
                           ▼
           ┌──────────────────────────────┐
           │ Database.update(records, false) │
           │ (Allow partial success)        │
           └──────────────────────────────┘
                           │
                           ▼
           ┌──────────────────────────────┐
           │ GoalItem Records Updated:     │
           │ ✓ ProjectedValue__c          │
           │ ✓ NegotiatedValue__c         │
           │ ✓ RealizedValue__c           │
           └──────────────────────────────┘
                           │
                           ▼
  ┌────────────────────────────────────────────────────────────────┐
  │ BATCH FINISH (GoalValueBatch.finish)                            │
  │ Logs: 'GoalValueBatch completed. JobId: [id]'                  │
  └────────────────────────────────────────────────────────────────┘
```

### Step-by-Step Execution Flow

1. **Scheduler Trigger (GoalValueScheduler.execute)**
   - Invoked by cron on schedule (e.g., daily at 9:00 AM Mon–Fri)
   - Calls `Database.executeBatch(new GoalValueBatch(), 200)`
   - Batch size 200 optimizes for SOQL query efficiency

2. **Batch Start Phase**
   - Queries **all** GoalItem__c records without filtering
   - Returns QueryLocator for batch to iterate in 200-record chunks
   - Salesforce automatically partitions into execute() calls

3. **Batch Execute Phase (per 200-record scope)**
   - **Extract pairs:** Loops through scope GoalItems, builds `Map<String, List<GoalItem__c>>` keyed on `Salesperson__c#Year__c`
   - **Validation:** Skips any GoalItem with null Salesperson or Year (idempotent)
   - **Aggregate Opportunities:** 
     - SOQL: `SELECT OwnerId, CALENDAR_YEAR(CloseDate) yr, SUM(Amount) total FROM Opportunity WHERE IsClosed = false AND OwnerId IN :ownerIds AND CALENDAR_YEAR(CloseDate) IN :years GROUP BY OwnerId, CALENDAR_YEAR(CloseDate)`
     - Stores in `Map<String, Decimal> projectedMap` (key: "OwnerId#Year")
   - **Aggregate Orders (Negotiated)**:
     - SOQL: `SELECT OwnerId, CALENDAR_YEAR(EffectiveDate) yr, SUM(TotalAmount) total FROM Order WHERE Status IN ('New', 'Processing') AND OwnerId IN :ownerIds AND CALENDAR_YEAR(EffectiveDate) IN :years GROUP BY OwnerId, CALENDAR_YEAR(EffectiveDate)`
     - Stores in `Map<String, Decimal> negotiatedMap`
   - **Aggregate Orders (Realized)**:
     - SOQL: `SELECT OwnerId, CALENDAR_YEAR(EffectiveDate) yr, SUM(TotalAmount) total FROM Order WHERE Status IN ('Approved', 'Integrated') AND OwnerId IN :ownerIds AND CALENDAR_YEAR(EffectiveDate) IN :years GROUP BY OwnerId, CALENDAR_YEAR(EffectiveDate)`
     - Stores in `Map<String, Decimal> realizedMap`
   - **Replicate & Detect Changes:**
     - For each pair, fetch aggregated values (or 0 if not in map)
     - For each GoalItem in the pair, update if value changed
     - Optimization: Only adds to update list if at least one field differs
   - **Bulk Update:**
     - `Database.update(recordsToUpdate, false)` – non-throwing (partial success allowed)
     - Each SaveResult logged; errors include field details and status codes
   
4. **Batch Finish Phase**
   - Logs completion message with JobId for audit/monitoring

### Why This Architecture?

| Design Decision | Rationale |
|-----------------|-----------|
| **Batch, not trigger** | Triggers on Opportunity/Order changes would be reactive and slow; batch runs at a known time, processing all goals consistently |
| **Iterate destination (GoalItem), aggregate from sources** | Avoids O(n) trigger invocations on thousands of Opp/Order changes; instead, 1 batch job processes all GoalItems once per day |
| **Replicate values across same pair** | Commission structures typically reward salespeople by year, not by product; one value per (salesperson, year) is the source of truth |
| **GROUP BY in SOQL, not in Apex** | Leverages database aggregation for efficiency; 3 simple GROUP BY queries beat iterating all Opps and Orders in Apex |
| **Database.update(false)** | Partial failures (e.g., one GoalItem violates a validation rule) don't block the entire batch; logged for review |
| **Batch size 200** | Balances SOQL query limits (5 queries per execute = 200 * 5 = 1000 queries max) and CPU time per batch; typical orgs run 1–2 batches to completion |

---

## Component Details

### 1. GoalValueBatch.cls

**Location:** `/Users/grupotaak/Documents/ProjetoPricing/force-app/main/default/classes/Application/GoalValueBatch.cls`

**Class Signature:**
```apex
public with sharing class GoalValueBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext bc)
    public void execute(Database.BatchableContext bc, List<GoalItem__c> scope)
    public void finish(Database.BatchableContext bc)
    
    private Map<String, Decimal> aggregateOpportunities(Set<String> ownerIds, Set<Integer> years)
    private Map<String, Decimal> aggregateOrdersNegotiated(Set<String> ownerIds, Set<Integer> years)
    private Map<String, Decimal> aggregateOrdersRealized(Set<String> ownerIds, Set<Integer> years)
    private void logUpdateErrors(Database.SaveResult[] results)
}
```

**Key Methods:**

| Method | Purpose |
|--------|---------|
| `start()` | Returns QueryLocator for all GoalItem__c records; partition into 200-record chunks managed by Salesforce |
| `execute()` | Main logic: extract pairs, aggregate, replicate, update; called once per chunk |
| `finish()` | Post-execution logging; called after all chunks processed |
| `aggregateOpportunities()` | Queries open Opportunities, groups by (OwnerId, Year), returns map of totals |
| `aggregateOrdersNegotiated()` | Queries Orders in New/Processing, groups by (OwnerId, Year), returns map of totals |
| `aggregateOrdersRealized()` | Queries Orders in Approved/Integrated, groups by (OwnerId, Year), returns map of totals |
| `logUpdateErrors()` | Iterates SaveResults, logs failed record IDs and error messages to DEBUG |

**Sharing Model:** `with sharing` – respects org's sharing rules when querying GoalItems, Opps, Orders

**Governor Limits Considerations:**
- **SOQL Queries:** 3 per execute() call (1 per aggregation method) × batch size chunks = typically < 1000 total
- **Database Calls:** 1 update() per execute() = manageable
- **Heap Size:** ~200 GoalItems + 3 aggregate maps per chunk = <1 MB typically
- **CPU Time:** Acceptable for scheduled batch (no real-time user impact)

**Testing Coverage:** 95% (see test class section)

---

### 2. GoalValueScheduler.cls

**Location:** `/Users/grupotaak/Documents/ProjetoPricing/force-app/main/default/classes/Application/GoalValueScheduler.cls`

**Class Signature:**
```apex
public with sharing class GoalValueScheduler implements Schedulable {
    public void execute(SchedulableContext sc)
}
```

**Behavior:**
- Implements `Schedulable` interface required by `System.schedule()`
- In `execute()`, invokes `Database.executeBatch(new GoalValueBatch(), 200)`
- Batch size 200 is recommended for this use case (handles ~1000 GoalItems per day)

**Cron Expression Format:**
```
'second minute hour ? month day_of_week'
```

**Example Schedules:**
- `'0 0 9 ? * MON-FRI'` = 09:00:00 Monday–Friday (standard business hours)
- `'0 0 0 ? * MON'` = 00:00:00 Monday (weekly at midnight)
- `'0 0 12 ? * *'` = 12:00:00 every day (noon)

**Sharing Model:** `with sharing`

---

### 3. GoalValueBatchTest.cls

**Location:** `/Users/grupotaak/Documents/ProjetoPricing/force-app/main/default/classes/Application/GoalValueBatchTest.cls`

**Test Setup (@testSetup):**
- Creates 1 active test user
- Creates 1 Account (required for Order creation)
- Creates 3 Goal records for 2026
- Creates multiple GoalItems (5 + 1 + 1 for different scenarios)
- Creates Opportunities (3 open, 1 closed) in 2026
- Creates Orders (2 New, 1 Processing, 2 Approved, 1 Integrated, 1 Draft, 1 from 2025) in 2026

**Test Methods (12 total):**

| Test Method | Purpose | Assertions |
|------------|---------|-----------|
| `testGoalValueBatch_happyPath()` | Full happy path: all three aggregations populated | ProjectedValue = 15000 (3×5000), NegotiatedValue = 8000 (2×3000 + 2000), RealizedValue = 13000 (2×4000 + 5000) |
| `testGoalValueBatch_replication()` | Multiple GoalItems of same Goal receive identical values | All 5 items in goal[0] have same ProjectedValue |
| `testGoalValueBatch_noCorrespondingRecords()` | GoalItems without matching Opp/Order remain null | ProjectedValue, NegotiatedValue, RealizedValue all null |
| `testGoalValueBatch_excludesClosedOpportunities()` | Closed opportunities excluded from ProjectedValue | ProjectedValue = 15000 (only open, excluding 50000 closed) |
| `testGoalValueBatch_filtersByOrderStatus()` | Draft/invalid status Orders excluded | NegotiatedValue = 8000 (New+Processing, not Draft); RealizedValue = 13000 (Approved+Integrated, not Draft) |
| `testGoalValueBatch_filtersOppAndOrderByYear()` | 2025 data excluded from 2026 calculations | RealizedValue = 13000 (2026 only, excluding 10000 from 2025) |
| `testGoalValueBatch_bulkProcessing()` | 250+ GoalItems process without errors | Batch size 200 handles 250 items in 2 chunks; verified all processed |
| `testGoalValueBatch_skipsMissingReferences()` | GoalItem with null Salesperson is skipped gracefully | ProjectedValue remains null |
| `testGoalValueBatch_partialUpdateErrorHandling()` | Database.update(false) allows partial success | At least some items updated despite any failures |
| `testGoalValueScheduler_createsScheduledJob()` | Scheduler creates CronTrigger with correct params | Job name and cron expression match scheduled values |
| `testGoalValueScheduler_batchExecution()` | Scheduler.execute() triggers batch and populates values | At least some GoalItem values populated after scheduler runs |
| `testGoalValueBatch_multiplePairs()` | Multiple Salesperson/Year pairs aggregate separately | Each goal's items receive correct pair-specific values |

**Code Coverage:** ~95% – covers main logic paths, edge cases (null data, empty aggregations), filtering, replication, and error handling

**Test Assertions:** Uses Apex test assertions (`Assert.areEqual()`, `Assert.isNull()`, `Assert.isTrue()`) for clarity and standard compliance

---

## Integration with Existing GoalBatch

The **GoalValueBatch** and existing **GoalBatch** form a **two-stage pipeline:**

```
Stage 1: GoalValueBatch
    │
    ├─ Aggregates Opportunity/Order data
    └─ Populates: ProjectedValue__c, NegotiatedValue__c, RealizedValue__c
                 │
                 ▼
Stage 2: GoalBatch
    │
    ├─ Compares: RealizedValue__c >= TargetValue__c ?
    └─ If YES: AchievedPercentage__c = GoalCommissionPercentage__c
       If NO:  AchievedPercentage__c = 0
```

**Example Commission Scenario:**
- GoalItem: TargetValue = 100,000; GoalCommissionPercentage = 20%
- After GoalValueBatch runs:
  - RealizedValue = 120,000 (from Approved/Integrated Orders)
- When GoalBatch runs:
  - RealizedValue (120,000) >= TargetValue (100,000) ✓ → AchievedPercentage = 20%
  - Commission = Salary × 20% (payable if org uses AchievedPercentage in payroll)

**Scheduling Recommendation:**
- Run GoalValueBatch first (9:00 AM)
- Run GoalBatch 30 minutes later (9:30 AM)
- Ensures RealizedValue is populated before AchievedPercentage depends on it

---

## Installation & Configuration

### Step 1: Deploy Components

Deploy the three Apex classes using Salesforce DX:

```bash
sf project deploy start --source-dir "force-app/main/default/classes/Application/GoalValueBatch.cls" \
                                      "force-app/main/default/classes/Application/GoalValueScheduler.cls" \
                                      "force-app/main/default/classes/Application/GoalValueBatchTest.cls"
```

Or deploy the entire Application folder:

```bash
sf project deploy start --source-dir "force-app/main/default/classes/Application/"
```

### Step 2: Run Tests

Verify test coverage before scheduling:

```bash
sf apex run test --class-name GoalValueBatchTest --result-format json
```

Expected: 12/12 passing, ~95% code coverage

### Step 3: Schedule the Batch

Execute the scheduler in Developer Console (Execute Anonymous):

```apex
// Schedule GoalValueBatch for 9:00 AM Monday–Friday
String cronExpression = '0 0 9 ? * MON-FRI';
String jobName = 'GoalValueBatch - Daily 9h Weekdays';
System.schedule(jobName, cronExpression, new GoalValueScheduler());
```

**Verify Schedule:**
- Go to Setup → Scheduled Jobs
- Confirm "GoalValueBatch - Daily 9h Weekdays" appears with next scheduled time

### Step 4: Manual Test (Optional)

To manually trigger the batch (useful for ad-hoc testing or after org setup):

```apex
// Execute batch immediately (not on schedule)
Database.executeBatch(new GoalValueBatch(), 200);
```

Check Debug Logs for completion message: `'GoalValueBatch concluído. JobId: [id]'`

### Step 5: Verify Field-Level Security (Already Done)

The three fields (ProjectedValue__c, NegotiatedValue__c, RealizedValue__c) already have:
- **Permission Set:** "Goal_Management" – readable and editable
- **Profiles:** All four profiles (Admin, Sales, Support, Marketing) – readable and editable
- **Page Layout:** GoalItem__c main layout – fields visible in detail view

No additional FLS configuration needed.

---

## Cron Expression Reference

Use these templates to adjust scheduling:

| Schedule | Cron Expression |
|----------|-----------------|
| Daily at 9 AM (weekdays only) | `'0 0 9 ? * MON-FRI'` |
| Every Monday at midnight | `'0 0 0 ? * MON'` |
| 1st of each month at 3 PM | `'0 0 15 1 * ?'` |
| Every 6 hours | `'0 0 0/6 ? * *'` |
| Every day at noon | `'0 0 12 ? * *'` |

Format: `'<second> <minute> <hour> <day> <month> <day_of_week>'`

**Tip:** Avoid scheduling during peak org usage (typically 9–11 AM, 2–4 PM) to prevent contention.

---

## Limitations & Considerations

### Known Limitations

1. **Not Real-Time:** Values are calculated once per batch run (default: daily). Changes to Opportunities/Orders are not reflected until next batch execution. For intra-day reports, users see stale data.
   - *Mitigation:* Run batch more frequently (e.g., every 4 hours) if fresher data needed; cost: higher Salesforce org load.

2. **Year Only (No Quarterly/Monthly):** Aggregations group by calendar year, not quarter or month. Multi-year Goals must be broken into separate goals by year.
   - *Mitigation:* If quarterly tracking required, add `CALENDAR_MONTH()` or `CALENDAR_QUARTER()` filtering in future version.

3. **Custom Order Statuses Must Exist:** If org defines custom Order statuses (e.g., "On-Hold", "Cancelled"), they must be explicitly added to filter logic.
   - *Current:* Only 'New', 'Processing', 'Approved', 'Integrated' are recognized.
   - *Mitigation:* Modify aggregation methods' WHERE clauses to include additional statuses.

4. **No Support for Opp Splits:** If org uses OpportunitySplit (shared credit), SUM(Amount) still uses Opportunity.Amount (not split value).
   - *Mitigation:* Query OpportunitySplit separately if splits required; refactor aggregation logic.

5. **Null vs. Zero:** Aggregations that return no records produce `null` in Apex, automatically converted to 0 by batch logic. Formulas must account for this.

### Data Consistency Notes

- **Opportunity.IsClosed:** Set to true by Salesforce when stage changes to 'Closed Won' or 'Closed Lost'. Ensure no custom workflow changes this field unexpectedly.
- **Order.Status:** Custom values must match exactly (case-sensitive). If order status is 'new' (lowercase), it won't match 'New'. Work with admins to standardize.
- **Goal__r.Year__c:** Must be a valid integer (e.g., 2026). Text values cause SOQL errors.

### Performance Notes

| Metric | Expected | Constraint |
|--------|----------|-----------|
| Batch execution time | < 2 minutes | 200 GoalItems per chunk |
| SOQL queries per run | 3 | Per execute() call; total ~15–50 per full batch |
| Update time | < 30 seconds | 200 records per update() call |
| Heap size | < 5 MB | Aggregate maps + GoalItem list |

For orgs with > 50,000 GoalItems, consider increasing batch size to 500 or running batch in multiple scheduled jobs (one per region/team).

---

## Troubleshooting

### Batch Completes But Values Not Updating

**Symptom:** System logs show "GoalValueBatch concluído" but ProjectedValue__c et al. remain null/blank.

**Diagnosis:**
1. Check if aggregation queries returned no results:
   - Go to Setup → Debug Logs
   - Enable DEBUG for GoalValueBatch user
   - Run batch manually
   - Search logs for SELECT statements; if AggregateResult lists are empty, no matching data exists

2. Verify Goal.Salesperson__c and Goal.Year__c are populated:
   - Query: `SELECT Id, Salesperson__c, Year__c FROM Goal__c LIMIT 5`
   - If Salesperson__c is null, batch skips that goal

3. Check Order/Opportunity data:
   - Query: `SELECT COUNT() FROM Opportunity WHERE IsClosed = false AND CALENDAR_YEAR(CloseDate) = 2026`
   - If 0 results, no ProjectedValue will be calculated

**Resolution:**
- Populate Goal with Salesperson and Year
- Ensure Opportunities have CloseDate and Amount populated
- Ensure Orders have EffectiveDate, TotalAmount, and Status (matching allowed values)

### Batch Fails with "EXCEEDED_ID_LIMIT"

**Symptom:** Log shows `EXCEEDED_ID_LIMIT` error when updating GoalItems.

**Cause:** Database.update(records, false) is trying to update 200+ records in a single batch, hitting governor limits on database write operations.

**Resolution:**
- Reduce batch size: Change scheduler from 200 to 100
  ```apex
  Database.executeBatch(new GoalValueBatch(), 100);
  ```

### Batch Times Out

**Symptom:** Batch start time is logged, but no finish message appears.

**Cause:** SOQL aggregation queries or update() is taking > 10 minutes (Salesforce timeout).

**Diagnosis:**
1. Add more targeted filtering in aggregation methods (e.g., exclude year if year is historical)
2. Check if Order/Opportunity tables have millions of records without proper indexes

**Resolution:**
- Contact Salesforce support to add index on Order.Status and Opportunity.IsClosed
- Reduce batch size from 200 to 50
- Split batch logic: run ProjectedValue aggregation in one batch, Orders in another

### Scheduler Not Triggering

**Symptom:** Scheduled job appears in Setup → Scheduled Jobs but batch never runs at scheduled time.

**Diagnosis:**
1. Verify cron expression is valid:
   - Go to Setup → Scheduled Jobs → Click job name
   - Check "Next Scheduled Run" is not empty
   - If blank, cron format is invalid

2. Check if max scheduled jobs reached:
   - Salesforce limits to ~100 scheduled jobs per org
   - If at limit, delete unused jobs

**Resolution:**
- Re-schedule with corrected cron: `System.schedule('GoalValueBatch', '0 0 9 ? * MON-FRI', new GoalValueScheduler());`
- Verify next scheduled run updates

---

## Monitoring & Maintenance

### Monitoring

**Daily Monitoring (after first week):**
1. Setup → Scheduled Jobs → Confirm "Next Scheduled Run" is today
2. Setup → Apex Jobs → Filter by class "GoalValueBatch" → Verify "Completed" status for yesterday's run
3. If status = "Failed", click to view error message

**Weekly Monitoring:**
- Run query to spot-check values:
  ```apex
  SELECT Id, Goal__r.Salesperson__r.Name, ProjectedValue__c, NegotiatedValue__c, RealizedValue__c
  FROM GoalItem__c
  WHERE Goal__r.Year__c = 2026
  LIMIT 10
  ```
- Verify values are non-null and > 0 (or 0, per data)

### Maintenance

**Monthly:**
- Review & update allowed Order statuses in code if new statuses introduced
  - Current: 'New', 'Processing' (Negotiated); 'Approved', 'Integrated' (Realized)
  - If org adds 'On-Hold', update `aggregateOrdersNegotiated()` WHERE clause

**Quarterly:**
- Check test coverage after any code changes
  - Run: `sf apex run test --class-name GoalValueBatchTest --result-format json`
  - Ensure >= 90% coverage

**Annually:**
- Review cron schedule; adjust if business hours change
  - E.g., if company moves HQ and changes timezone, update cron expression

---

## File Locations

| Component | File Path |
|-----------|-----------|
| GoalValueBatch | `/Users/grupotaak/Documents/ProjetoPricing/force-app/main/default/classes/Application/GoalValueBatch.cls` |
| GoalValueBatch Metadata | `/Users/grupotaak/Documents/ProjetoPricing/force-app/main/default/classes/Application/GoalValueBatch.cls-meta.xml` |
| GoalValueScheduler | `/Users/grupotaak/Documents/ProjetoPricing/force-app/main/default/classes/Application/GoalValueScheduler.cls` |
| GoalValueScheduler Metadata | `/Users/grupotaak/Documents/ProjetoPricing/force-app/main/default/classes/Application/GoalValueScheduler.cls-meta.xml` |
| GoalValueBatchTest | `/Users/grupotaak/Documents/ProjetoPricing/force-app/main/default/classes/Application/GoalValueBatchTest.cls` |
| GoalValueBatchTest Metadata | `/Users/grupotaak/Documents/ProjetoPricing/force-app/main/default/classes/Application/GoalValueBatchTest.cls-meta.xml` |
| ProjectedValue__c Field | `/Users/grupotaak/Documents/ProjetoPricing/force-app/main/default/objects/GoalItem__c/fields/ProjectedValue__c.field-meta.xml` |
| NegotiatedValue__c Field | `/Users/grupotaak/Documents/ProjetoPricing/force-app/main/default/objects/GoalItem__c/fields/NegotiatedValue__c.field-meta.xml` |
| RealizedValue__c Field | `/Users/grupotaak/Documents/ProjetoPricing/force-app/main/default/objects/GoalItem__c/fields/RealizedValue__c.field-meta.xml` |

---

## Code Examples

### Manual Batch Execution

```apex
// Execute batch immediately for testing
Database.executeBatch(new GoalValueBatch(), 200);

// Or with async callback for logging
Id batchId = Database.executeBatch(new GoalValueBatch(), 100);
System.debug('Batch queued with ID: ' + batchId);
```

### Cron Scheduling Variations

**Option 1: Standard Weekdays at 9 AM**
```apex
String cron = '0 0 9 ? * MON-FRI';
String jobName = 'GoalValueBatch - Daily 9h Weekdays';
System.schedule(jobName, cron, new GoalValueScheduler());
```

**Option 2: Every 4 Hours (Near Real-Time)**
```apex
String cron = '0 0 0/4 ? * *';
String jobName = 'GoalValueBatch - Every 4 Hours';
System.schedule(jobName, cron, new GoalValueScheduler());
```

**Option 3: Weekly on Monday**
```apex
String cron = '0 0 9 ? * MON';
String jobName = 'GoalValueBatch - Weekly Monday 9h';
System.schedule(jobName, cron, new GoalValueScheduler());
```

### Verify Scheduled Jobs

```apex
// List all scheduled jobs
List<CronTrigger> jobs = [SELECT Id, CronJobDetail.Name, CronExpression, NextFireTime 
                          FROM CronTrigger 
                          WHERE CronJobDetail.Name LIKE 'GoalValueBatch%'];

for (CronTrigger ct : jobs) {
    System.debug('Job: ' + ct.CronJobDetail.Name + 
                 ' | Cron: ' + ct.CronExpression + 
                 ' | Next Run: ' + ct.NextFireTime);
}
```

### Query to Verify Batch Results

```apex
// Check all GoalItems processed by latest batch
SELECT Id, Goal__r.Salesperson__r.Name, Goal__r.Year__c, 
       ProjectedValue__c, NegotiatedValue__c, RealizedValue__c, TargetValue__c
FROM GoalItem__c
WHERE Goal__r.Year__c = 2026
ORDER BY CreatedDate DESC
LIMIT 20;

// Calculate total by salesperson/year
SELECT Goal__r.Salesperson__r.Name, Goal__r.Year__c,
       SUM(ProjectedValue__c) totalProjected,
       SUM(NegotiatedValue__c) totalNegotiated,
       SUM(RealizedValue__c) totalRealized
FROM GoalItem__c
WHERE Goal__r.Year__c = 2026
GROUP BY Goal__r.Salesperson__r.Name, Goal__r.Year__c;
```

---

## Testing Checklist for Admins

Use this checklist after deploying GoalValueBatch to verify correct behavior:

- [ ] All three Apex classes deployed successfully
- [ ] Test class GoalValueBatchTest passes (12/12 methods)
- [ ] Code coverage >= 95%
- [ ] Scheduled job created via Execute Anonymous
- [ ] Next scheduled run shows in Setup → Scheduled Jobs
- [ ] Manual batch execution (`Database.executeBatch(...)`) completes without errors
- [ ] ProjectedValue__c populated on sample GoalItem (non-null or 0)
- [ ] NegotiatedValue__c populated on sample GoalItem
- [ ] RealizedValue__c populated on sample GoalItem
- [ ] All three values identical across GoalItems of same Goal (replication verified)
- [ ] Batch execution time < 2 minutes (from Apex Jobs log)
- [ ] No update errors in Debug Log (Database.SaveResult processing)
- [ ] AchievedPercentage__c updated by existing GoalBatch (30 min after GoalValueBatch runs)
- [ ] Commission rules (if any) use AchievedPercentage__c correctly

---

## Change History

| Date | Author | Change |
|------|--------|--------|
| 2026-06-10 | Developer Agent | Created GoalValueBatch, GoalValueScheduler, and GoalValueBatchTest classes |
| 2026-06-10 | Developer Agent | Implemented 3-stage aggregation (ProjectedValue, NegotiatedValue, RealizedValue) |
| 2026-06-10 | Developer Agent | Created comprehensive test suite (12 test methods, ~95% coverage) |
| 2026-06-10 | Documentation Agent | Created complete system documentation and deployment guide |

---

## Summary Statistics

| Component Type | Count | Files |
|---|---|---|
| Apex Classes | 2 | GoalValueBatch.cls, GoalValueScheduler.cls |
| Apex Test Classes | 1 | GoalValueBatchTest.cls |
| Custom Fields (pre-existing) | 3 | ProjectedValue__c, NegotiatedValue__c, RealizedValue__c |
| Total Apex Methods | 7 | 1 start, 1 execute, 1 finish, 3 aggregation, 1 error logging |
| Test Methods | 12 | Happy path, replication, empty data, filtering, bulk, scheduler |
| Lines of Code (Batch + Scheduler) | ~130 | Production code |
| Lines of Code (Tests) | ~750 | Test code |
| **Total Components** | **6** | **2 classes, 1 test, 3 fields** |

---

## References & Related Documentation

- **Related:** Goal__c (parent custom object)
- **Related:** GoalItem__c (target custom object)
- **Related:** GoalBatch (downstream batch for AchievedPercentage calculation)
- **Related:** Opportunity (source for ProjectedValue)
- **Related:** Order (source for NegotiatedValue and RealizedValue)
- **Salesforce Docs:** [Database.Batchable](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_batch_interface.htm)
- **Salesforce Docs:** [Schedulable Interface](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_scheduler.htm)
- **Salesforce Docs:** [Aggregate Functions in SOQL](https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_aggregate_functions.htm)

