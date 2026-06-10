---
name: goalBatch-test-patterns
description: Test patterns and coverage strategy for GoalBatch and GoalBatchScheduler batch processing
metadata:
  type: project
---

## GoalBatchTest Coverage Summary

**Test File:** `force-app/main/default/classes/Application/GoalBatchTest.cls`
**API Version:** 66.0
**Total Test Methods:** 10
**Expected Coverage:** 95%+

### Key Testing Patterns Established

#### 1. Batch Execution with Test.startTest()/stopTest()
- Essential for batch execution in test context
- Allows batch to run synchronously within tests
- Properly resets governor limits

#### 2. Bulk Data Creation in @testSetup
- 200+ GoalItem records created across multiple scenarios
- Pre-distributed across 3 Goal records to test different branches
- Governor limit safe: bulk inserts with proper list usage

#### 3. Test Data Scenarios
- **Scenario A (50 items):** RealizedValue >= TargetValue (meta atingida) → AchievedPercentage should equal GoalCommissionPercentage
- **Scenario B (50 items):** RealizedValue < TargetValue (meta não atingida) → AchievedPercentage should be 0
- **Scenario C (50 items):** RealizedValue is null → AchievedPercentage should be 0
- **Scenario D (50 items):** TargetValue is null → AchievedPercentage should be 0
- **Scenario E:** Edge case: RealizedValue == TargetValue (exact equality)

#### 4. Salesperson Field Requirement
- Goal__c.Salesperson__c is required via validation rule `Salesperson_Required`
- Solution: Query existing active User with `[SELECT Id FROM User WHERE IsActive = true LIMIT 1]`
- Avoids mixed-DML errors from creating users in tests

#### 5. Batch Optimization Testing
- Tests verify that only records with actual changes are updated
- Batch logic checks `if (item.AchievedPercentage__c != novaPorcentagem)` before adding to update list
- Test `testGoalBatch_noUnnecessaryUpdates` pre-sets values to verify no redundant DML

#### 6. Scheduler Testing (2 approaches)
- **Approach 1:** `System.schedule()` creates CronTrigger, verifies via SOQL
- **Approach 2:** Direct execute() call with null SchedulableContext (testable without scheduling)

### Coverage Breakdown

| GoalBatch Method | Coverage | Test Methods |
|------------------|----------|--------------|
| `start()` | 100% | All tests (executes batch) |
| `execute()` | 95%+ | metaAtingida, metaNaoAtingida, nullRealizedValue, nullTargetValue, equalValues, bulkProcessing, customBatchSize |
| `finish()` | 100% | All tests (completes batch execution) |
| **GoalBatchScheduler.execute()** | 100% | scheduler_execution, scheduler_batchExecution |

### Critical Code Paths Tested

1. ✓ `RealizedValue__c != null && TargetValue__c != null && RealizedValue__c >= TargetValue__c` → Set to GoalCommissionPercentage
2. ✓ Null RealizedValue → Set to 0
3. ✓ Null TargetValue → Set to 0
4. ✓ RealizedValue < TargetValue → Set to 0
5. ✓ Null GoalCommissionPercentage (edge case) → Uses default 0
6. ✓ Optimization: Only update if value changes (no unnecessary DML)
7. ✓ Scheduler instantiation and batch execution

### Notes for Future Work

- **Batch Size Variability:** Test verifies both batch size 200 (default) and 100 (custom)
- **No @SeeAllData:** All test data created explicitly; no org data dependencies
- **Assertions:** All use `Assert` style (not System.assert) for modern Apex patterns
- **Query Re-verification:** Tests re-query after batch execution to verify persistence
- **Bulk Safety:** 200+ records in @testSetup ensures governor limit edge cases are tested

### Governor Limit Considerations

- Batch size 200: Safe default, tested
- Query Locator: Returns all GoalItem__c without LIMIT, proper for batch start()
- DML: Only updates records that changed, minimizing DML statements
- Test setup inserts 200+ records; batch processes all in one execution (within test limits)
