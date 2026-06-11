---
name: error-logging-patterns
description: System.debug is transient; batch jobs need persistent error tracking
metadata:
  type: feedback
---

## Pattern: Batch Error Logging

Batch jobs often use `System.debug()` to log `Database.SaveResult[]` failures. This is insufficient in production because:
- Debug logs rotate off after 24 hours
- Ops teams typically monitor persistent objects, not debug console
- Silent failures accumulate over time (batch runs daily/hourly)

**Better approach:** Choose one:

1. **Persistent Error Object (Recommended)**  
   Create an `Error_Log__c` custom object to store batch failures. Insert after catching DML errors:
   ```apex
   if (!errorLogs.isEmpty()) {
       insert errorLogs;
   }
   ```

2. **AsyncApexJob Monitoring**  
   Query the batch's `AsyncApexJob` in `finish()` to detect failures:
   ```apex
   AsyncApexJob job = [SELECT NumberOfErrors FROM AsyncApexJob WHERE Id = :bc.getJobId()];
   if (job.NumberOfErrors > 0) {
       // Create alert / send notification
   }
   ```

**For this project:** GoalValueBatch should use one of these patterns instead of `System.debug()` only.
