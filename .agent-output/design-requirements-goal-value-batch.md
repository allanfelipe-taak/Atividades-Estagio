═══════════════════════════════════════════════════════════════════════════════
                    📋 DESIGN REQUIREMENTS
                   Goal Value Batch Job (New Requirement)
═══════════════════════════════════════════════════════════════════════════════

🎯 WHAT USER REQUESTED:

Create a new scheduled batch job that populates three existing GoalItem__c fields
with aggregated data from Opportunity and Order standard objects, matched by
Salesperson (OwnerId) and Year (CloseDate/EffectiveDate):

• ProjectedValue__c ← SUM(Opportunity.Amount) where IsClosed = false 
• NegotiatedValue__c ← SUM(Order.TotalAmount) where Status IN ('New','Processing')
• RealizedValue__c ← SUM(Order.TotalAmount) where Status IN ('Approved','Integrated')

Additionally, create a custom tab for Opportunity to provide UI navigation access
to the Opportunity object (no involvement in calculations).

───────────────────────────────────────────────────────────────────────────────
                    🔵 ADMIN WORK (salesforce-admin)
───────────────────────────────────────────────────────────────────────────────

1. **Create Custom Tab for Opportunity**
   - Tab name: "Opportunity" (or "Opportunities")
   - Icon: Standard Opportunity icon or user preference
   - Visibility: Include in main navigation for easy access
   - Purpose: Navigation convenience only (does NOT participate in batch calculations)

2. **Field-Level Security (Verify & Update if needed)**
   - Verify ProjectedValue__c, NegotiatedValue__c, RealizedValue__c have:
     • FLS granted in Permission Set (readable=true, editable=true)
     • FLS granted in ALL FOUR profiles (readable=true, editable=true):
       - Admin (System Administrator)
       - Custom%3A Sales Profile
       - Custom%3A Support Profile
       - Custom%3A Marketing Profile
   - Action: If fields are missing FLS entries, add them to both permission set
     and all four profiles via fieldPermissions blocks

3. **Page Layout Updates (if needed)**
   - Verify that ProjectedValue__c, NegotiatedValue__c, RealizedValue__c appear
     on the GoalItem__c page layout(s) assigned to relevant profiles
   - Action: If missing, add to main section for visibility in detail view

───────────────────────────────────────────────────────────────────────────────
                    🟢 DEVELOPMENT WORK (salesforce-developer)
───────────────────────────────────────────────────────────────────────────────

1. **GoalValueBatch Class**
   - Scope: Batch implementation that iterates GoalItem__c records
   - Responsibility:
     • Extract unique (Salesperson__c, Year__c) pairs from scope
     • Execute aggregated SOQL queries on Opportunity and Order grouped by
       (OwnerId, CALENDAR_YEAR of date field)
     • Map aggregated values back to GoalItem records
     • Update ProjectedValue__c, NegotiatedValue__c, RealizedValue__c in bulk
   - Batch size recommendation: 200 (consistent with existing GoalBatch pattern)
   - Error handling: Use Database.update(recordsToUpdate, false) with debug logging
   - Access modifier: `with sharing`

   **SOQL Query Structure (execute() method):**
   
   For each aggregation group in scope, execute:
   
   a) **Opportunity aggregation**
      ```
      SELECT OwnerId, 
             CALENDAR_YEAR(CloseDate) year,
             SUM(Amount) totalAmount
      FROM Opportunity
      WHERE IsClosed = false
        AND OwnerId IN [unique owner IDs from scope]
        AND CALENDAR_YEAR(CloseDate) IN [unique years from scope]
      GROUP BY OwnerId, CALENDAR_YEAR(CloseDate)
      ```
      → Result: Map<String, Decimal> keyed as "{OwnerId}#{YEAR}"
      → Field target: ProjectedValue__c

   b) **Order aggregation (Negotiated)**
      ```
      SELECT OwnerId,
             CALENDAR_YEAR(EffectiveDate) year,
             SUM(TotalAmount) totalAmount
      FROM Order
      WHERE Status IN ('New','Processing')
        AND OwnerId IN [unique owner IDs from scope]
        AND CALENDAR_YEAR(EffectiveDate) IN [unique years from scope]
      GROUP BY OwnerId, CALENDAR_YEAR(EffectiveDate)
      ```
      → Result: Map<String, Decimal> keyed as "{OwnerId}#{YEAR}"
      → Field target: NegotiatedValue__c

   c) **Order aggregation (Realized)**
      ```
      SELECT OwnerId,
             CALENDAR_YEAR(EffectiveDate) year,
             SUM(TotalAmount) totalAmount
      FROM Order
      WHERE Status IN ('Approved','Integrated')
        AND OwnerId IN [unique owner IDs from scope]
        AND CALENDAR_YEAR(EffectiveDate) IN [unique years from scope]
      GROUP BY OwnerId, CALENDAR_YEAR(EffectiveDate)
      ```
      → Result: Map<String, Decimal> keyed as "{OwnerId}#{YEAR}"
      → Field target: RealizedValue__c

   **Replication Strategy (for multiple GoalItems with same Salesperson+Year):**
   - The aggregated total for (Salesperson, Year) is replicated in EVERY GoalItem
     matching that (Salesperson, Year) pair.
   - No per-product/per-family distribution or rateio in this batch.

2. **GoalValueScheduler Class**
   - Scope: Schedulable that triggers GoalValueBatch on a schedule
   - Pattern: Match existing GoalBatchScheduler structure
   - Recommended schedule: '0 0 9 ? * MON-FRI' (weekdays, 9 AM)
   - Batch size: 200 (consistent with GoalBatch)
   - Access modifier: `with sharing`

3. **Test Class (GoalValueBatchTest)**
   - Required test coverage for both batch and scheduler
   - Scenarios to cover:
     • Setup: Create Goal__c record(s) with Salesperson + Year
     • Create corresponding GoalItem__c record(s)
     • Create test Opportunity records (IsClosed=false, matching Salesperson+Year)
     • Create test Order records (Status='New' and Status='Approved', matching Salesperson+Year)
     • Execute batch via Database.executeBatch()
     • Assert ProjectedValue__c, NegotiatedValue__c, RealizedValue__c populated correctly
     • Edge cases: null values, no matching Opportunity/Order, multiple GoalItems
   - Use Database.executeBatch() to trigger batch in test context
   - Scheduler test (if possible): verify Schedulable instantiation

───────────────────────────────────────────────────────────────────────────────
                    🔗 EXECUTION ORDER & DEPENDENCIES
───────────────────────────────────────────────────────────────────────────────

1. **Admin work (FIRST)**
   - Create Opportunity custom tab → no dependencies
   - Verify/update FLS and Page Layouts → no dependencies
   - Can run in parallel with Developer work (independent teams)

2. **Developer work (CONCURRENT with Admin)**
   - Develop GoalValueBatch class
   - Develop GoalValueScheduler class
   - Develop GoalValueBatchTest class

3. **Code Review** (AFTER development complete)
   - Review both batch and scheduler for bulkification, governor limits
   - Verify test coverage and patterns match existing GoalBatch

4. **Deployment** (AFTER code review passes)
   - Deploy metadata (Opportunity tab) via admin agent
   - Deploy Apex classes (batch, scheduler, test) via developer agent
   - Assign permission set if needed
   - Schedule GoalValueScheduler via Execute Anonymous

───────────────────────────────────────────────────────────────────────────────
                    ❓ CLARIFICATIONS & ASSUMPTIONS
───────────────────────────────────────────────────────────────────────────────

**Confirmed Assumptions (Per User Alignment):**

1. ✅ Match key is (Salesperson + Year) only
   - Salesperson: Goal__r.Salesperson__c = Opportunity.OwnerId = Order.OwnerId
   - Year: Goal__r.Year__c = CALENDAR_YEAR(Opportunity.CloseDate) = CALENDAR_YEAR(Order.EffectiveDate)
   - No filtering by Product, ProductFamily, or PaymentCondition in this batch

2. ✅ Replication strategy: Aggregate (Salesperson, Year) values replicate in ALL
   matching GoalItems for that pair (no rateio/distribution per item)

3. ✅ Iteration model: Batch iterates GoalItem__c (destination), not Opportunity/Order
   - Single QueryLocator on GoalItem__c in start() method
   - Aggregation queries in execute() use collected (Salesperson, Year) pairs

4. ✅ Error handling: If Order.Status='Integrated' with errors, IGNORE (no special
   integration error field consulted; standard Status check only)

5. ✅ Opportunity date field: CloseDate (standard field for pipeline/forecasting)

**Remaining Question (MINOR - Proceed with Assumption if User Confirms):**

❓ **Order.EffectiveDate assumption:**
   - Design assumes Order.EffectiveDate as the date field for year matching
   - Alternative (if different): confirm whether to use CreatedDate, OrderDate,
     or a different field from Order standard fields
   - **Assumption:** EffectiveDate is standard and correct; proceed unless user
     specifies otherwise

───────────────────────────────────────────────────────────────────────────────
                    📝 PROMPTS FOR SPECIALIST AGENTS
───────────────────────────────────────────────────────────────────────────────

🔵 PROMPT FOR salesforce-admin:

---

**Task: Create Custom Tab & Verify Field Configuration for Goal Value Batch**

Create the following metadata to support the new GoalValueBatch scheduled job:

1. **Create Custom Tab for Opportunity**
   - Object: Opportunity (standard object)
   - Tab name: "Opportunity"
   - Tab icon: Standard Opportunity icon (or select appropriate)
   - Include in app navigation for easy access
   - Purpose: Navigation convenience; does NOT participate in batch calculations
   - Deploy to org

2. **Verify & Update Field-Level Security (FLS)**
   - Retrieve current FLS configuration for these GoalItem__c fields:
     • ProjectedValue__c (Currency)
     • NegotiatedValue__c (Currency)
     • RealizedValue__c (Currency)
   
   - Ensure BOTH of the following grant FLS readable=true, editable=true:
     a) The relevant **Permission Set** (if one exists; otherwise note if missing)
     b) ALL FOUR **Profiles**:
        - Admin (System Administrator)
        - Custom%3A Sales Profile
        - Custom%3A Support Profile
        - Custom%3A Marketing Profile
   
   - If FLS is missing from any of the above, add fieldPermissions entries to
     the permission set and all four profiles
   
   - Deploy the updated permission set and profiles to the org

3. **Verify Page Layout Configuration**
   - Check GoalItem__c page layout(s) assigned to relevant profiles
   - Ensure ProjectedValue__c, NegotiatedValue__c, RealizedValue__c appear in
     the main section (for visibility in detail and new record views)
   - If missing, add to layout and deploy

4. **Do NOT deploy to org yet—prepare metadata files only**
   - All files created should be saved in force-app/main/default/
   - Admin agent will coordinate final deployment in the next step

**Reference:** API version 66.0 (per sfdx-project.json). Follow CLAUDE.md metadata conventions.

---

🟢 PROMPT FOR salesforce-developer:

---

**Task: Create GoalValueBatch, GoalValueScheduler, and Test Class**

Develop the batch job that populates three GoalItem__c fields by aggregating
Opportunity and Order records matched on Salesperson + Year:

**1. GoalValueBatch Class** (force-app/main/default/classes/Application/GoalValueBatch.cls)

- Implements: Database.Batchable<sObject>
- Access: `with sharing`
- Pattern: Follow existing GoalBatch.cls structure (same folder, similar style)

**start() Method:**
- Query all GoalItem__c records with fields: Id, Goal__r.Salesperson__c, Goal__r.Year__c
- Return Database.QueryLocator

**execute(Database.BatchableContext bc, List<GoalItem__c> scope) Method:**
- Extract unique (Salesperson__c, Year__c) pairs from scope GoalItem records
- Build maps to track scope GoalItems by pair
- Execute aggregated SOQL queries on Opportunity and Order:

  **Opportunity (ProjectedValue__c):**
  ```
  SELECT OwnerId, CALENDAR_YEAR(CloseDate) year, SUM(Amount) totalAmount
  FROM Opportunity
  WHERE IsClosed = false
    AND OwnerId IN [owner IDs from scope pairs]
    AND CALENDAR_YEAR(CloseDate) IN [years from scope pairs]
  GROUP BY OwnerId, CALENDAR_YEAR(CloseDate)
  ```
  → Map keyed as "{OwnerId}#{YEAR}" → value = Amount sum

  **Order (NegotiatedValue__c):**
  ```
  SELECT OwnerId, CALENDAR_YEAR(EffectiveDate) year, SUM(TotalAmount) totalAmount
  FROM Order
  WHERE Status IN ('New','Processing')
    AND OwnerId IN [owner IDs from scope pairs]
    AND CALENDAR_YEAR(EffectiveDate) IN [years from scope pairs]
  GROUP BY OwnerId, CALENDAR_YEAR(EffectiveDate)
  ```
  → Map keyed as "{OwnerId}#{YEAR}" → value = TotalAmount sum

  **Order (RealizedValue__c):**
  ```
  SELECT OwnerId, CALENDAR_YEAR(EffectiveDate) year, SUM(TotalAmount) totalAmount
  FROM Order
  WHERE Status IN ('Approved','Integrated')
    AND OwnerId IN [owner IDs from scope pairs]
    AND CALENDAR_YEAR(EffectiveDate) IN [years from scope pairs]
  GROUP BY OwnerId, CALENDAR_YEAR(EffectiveDate)
  ```
  → Map keyed as "{OwnerId}#{YEAR}" → value = TotalAmount sum

- Iterate scope GoalItems and update:
  • ProjectedValue__c = value from Opportunity map (or null if no match)
  • NegotiatedValue__c = value from Order negotiated map (or null if no match)
  • RealizedValue__c = value from Order realized map (or null if no match)

- Only update GoalItems if values actually changed (avoid unnecessary updates)
- Use Database.update(recordsToUpdate, false) for error handling with logging
- Log summary in debug statements

**finish(Database.BatchableContext bc) Method:**
- Log completion message with JobId (follow GoalBatch pattern)

**Important:**
- Bulkify queries: use IN clauses, GROUP BY, and aggregation
- Stay within governor limits (one batch iteration per unique scope)
- null-safe checks (aggregate queries may return no results)
- Use WITH USER_MODE if organization API version permits (66.0 supports it)

---

**2. GoalValueScheduler Class** (force-app/main/default/classes/Application/GoalValueScheduler.cls)

- Implements: Schedulable
- Access: `with sharing`
- Pattern: Match GoalBatchScheduler.cls structure

**execute(SchedulableContext sc) Method:**
- Instantiate GoalValueBatch
- Call Database.executeBatch(new GoalValueBatch(), 200)

**Scheduling Instructions:**
- Recommended CRON: '0 0 9 ? * MON-FRI' (weekdays, 9:00 AM)
- User may schedule manually in Salesforce UI or via Execute Anonymous

---

**3. GoalValueBatchTest Class** (force-app/main/default/classes/Application/GoalValueBatchTest.cls)

- Implements: Test class with @isTest annotation
- Use @TestSetup for shared test data

**Test Scenarios:**

a) **testBasicAggregation** - Happy path
   - Create Goal__c (Salesperson: testUser, Year: 2025)
   - Create GoalItem__c (Goal: above Goal)
   - Create Opportunity (OwnerId: testUser, CloseDate: 2025-xx-xx, IsClosed=false, Amount=1000)
   - Create Order (OwnerId: testUser, EffectiveDate: 2025-xx-xx, Status='New', TotalAmount=2000)
   - Create Order (OwnerId: testUser, EffectiveDate: 2025-xx-xx, Status='Approved', TotalAmount=3000)
   - Execute batch: Database.executeBatch(new GoalValueBatch(), 200)
   - Assert: ProjectedValue__c = 1000, NegotiatedValue__c = 2000, RealizedValue__c = 3000

b) **testMultipleGoalItemsSameGoal**
   - Create Goal__c with Year 2025
   - Create TWO GoalItem__c records linked to same Goal
   - Create matching Opportunity/Orders
   - Assert: Both GoalItems receive same aggregated values (replication)

c) **testNoMatchingRecords**
   - Create GoalItem__c for (Salesperson: userA, Year: 2025)
   - Create Opportunity/Order for (Salesperson: userB, Year: 2025) - mismatch
   - Execute batch
   - Assert: ProjectedValue__c, NegotiatedValue__c, RealizedValue__c remain null (or 0)

d) **testClosedOpportunitiesExcluded**
   - Create Opportunity (IsClosed=true) for same user/year
   - Execute batch
   - Assert: ProjectedValue__c does not include closed Opportunity amount

e) **testStatusFiltering**
   - Create Order (Status='Draft') for same user/year
   - Assert: NegotiatedValue__c excludes 'Draft' status
   - Create Order (Status='Integrated') for same user/year
   - Assert: RealizedValue__c includes 'Integrated' status only

f) **testNullHandling**
   - GoalItem__c with null Goal__r.Salesperson__c or null Goal__r.Year__c
   - Assert: batch handles gracefully (skip or handle with try/catch)

**Test Best Practices:**
- Use System.runAs(testUser) for proper execution context
- Create test data via @TestSetup and query in test methods
- Use Database.executeBatch() to run batch in test context
- Assert both on record updates and on absence of exceptions
- Verify debug logs for batch progress (optional but recommended)

**NOTE:** Test class is REQUIRED before code review. No test = no approval.

---

**Deployment Notes:**
- Place both classes in force-app/main/default/classes/Application/
- Create .cls-meta.xml for each class with apiVersion 66.0, status=Active
- Do NOT deploy to org—prepare files only; orchestrator will deploy in next step
- Follow existing GoalBatch naming/folder convention for consistency

---

═══════════════════════════════════════════════════════════════════════════════
