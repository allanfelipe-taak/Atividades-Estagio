---
name: goalBatch-test-patterns
description: Batch execution testing, bulk data scenarios, Order status filtering, replication logic, and salesperson/year aggregation patterns
metadata:
  type: reference
---

# GoalValueBatch Test Patterns

## Key Learnings from GoalValueBatchTest

### Order Status Values (REAL from org)
- `'New'` → NegotiatedValue
- `'In Approval'` → NegotiatedValue
- `'Approved'` → RealizedValue
- `'Integrated'` → RealizedValue
- `'Integration Error'` → IGNORED (not in any aggregation)

**What NOT to use:**
- `'Processing'` — does NOT exist as expected; was likely a misunderstanding
- `'Draft'` — is a StatusCode, not a real Status; don't use for business logic tests

### Setup Pattern for Orders with TotalAmount

Since `Order.TotalAmount` is READ-ONLY and calculated from OrderItems:

1. Create infrastructure: DistributionCenter, PaymentTerm, Address
2. Create Product2 with ProductionCost__c field populated
3. Create PricebookEntry with base UnitPrice
4. Create pricing rules: Margin, Freight, Tax (all Status='Approved')
5. Create Orders with real status values and EffectiveDate
6. Create OrderItems with deterministic Quantity (e.g., 3, 2, 4, 5)
7. TotalAmount auto-calculates from OrderItems via triggers

### Batch Testing Pattern

- Use Test.startTest()/stopTest() for proper governor limit reset
- Arrange: verify test data preconditions with SOQL
- Act: Database.executeBatch(batch, batchSize)
- Assert: query results and verify aggregation fields

### Key Gotchas

1. **Order.TotalAmount is READ-ONLY** — calculated from OrderItems only
2. **OrderItems trigger fires** — needs Product2.ProductionCost__c and pricing rules
3. **Status must be real** — New, In Approval, Approved, Integrated, Integration Error
4. **CALENDAR_YEAR** — Orders use EffectiveDate; Opportunities use CloseDate
5. **Default → 0** — unmatched aggregations default to 0, not null
6. **Replication by key** — same (Salesperson, Year) gets identical values
