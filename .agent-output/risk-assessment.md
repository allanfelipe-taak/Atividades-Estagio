# RISK ASSESSMENT & MITIGATION
## ProjetoPricing Portuguese → English Migration Cleanup

**Date:** 2026-05-20  
**Org:** TaakProjetoPricing  
**Status:** Phase 1 - Flow Investigation Required

---

## RISK MATRIX

| Risk | Probability | Impact | Severity | Mitigation |
|------|-------------|--------|----------|-----------|
| Flow deletion fails (Flows can't be deleted from UI) | MEDIUM | HIGH | HIGH | Test deactivation first; consult Salesforce documentation if deletion fails |
| Destructive deployment fails (object dependencies) | MEDIUM | HIGH | HIGH | Execute dry-run before real deployment |
| Unidentified Flow dependencies | MEDIUM | MEDIUM | MEDIUM | Phase 1 investigation discovers all dependencies |
| Data records still in old objects | LOW | HIGH | HIGH | Query objects before deployment; delete records if found |
| Integration errors during Flow deactivation | MEDIUM | MEDIUM | MEDIUM | 48-hour monitoring window detects and allows rollback |
| Permission sets reference old objects | LOW | MEDIUM | MEDIUM | Deployment fails with clear error message |
| Validation rules reference old objects | LOW | MEDIUM | MEDIUM | Deployment fails with clear error message |
| Old handlers still referenced in TriggerMaestro | LOW | HIGH | HIGH | Code review confirms new handlers are registered |
| Rollback needed after deployment | VERY LOW | CRITICAL | CRITICAL | Salesforce org snapshot available for restore |

---

## DETAILED RISK ANALYSIS

### 1. BLOCKING FLOWS (HIGH RISK)

**Description:** 5 Flows still reference old Portuguese objects  
**Current Status:** BLOCKING deployment  
**Probability:** 100% (confirmed)  
**Impact:** Prevents destructive deployment  
**Severity:** CRITICAL

**Why This Is a Problem:**
- Salesforce prevents deletion of objects referenced by active metadata
- Any Flow definition (active or inactive) blocks object deletion
- Must delete Flow definitions entirely; deactivation is insufficient

**Mitigation Strategy:**

| Step | Action | Owner | Timeline |
|------|--------|-------|----------|
| 1 | Document all Flow IDs and purposes | DevOps | Phase 1 |
| 2 | Determine if Flows are business-critical | Business | Phase 1 |
| 3 | Deactivate Flows one-by-one | DevOps | Phase 2 |
| 4 | Monitor for 48 hours | DevOps/QA | Phase 2 |
| 5 | Delete Flow definitions | DevOps | Phase 3 |
| 6 | Verify deletion | DevOps | Phase 3 |
| 7 | Test destructive deployment (dry-run) | DevOps | Phase 4 |

**Contingency Plan:**
- If a Flow cannot be deleted from UI: Use Salesforce Developer Console or Apex to delete via metadata API
- If Flow deletion breaks business process: Recreate Flow using new English objects, then delete old Flow
- If deletion impossible: Contact Salesforce support for metadata cleanup

**Success Indicators:**
- [ ] All 5 Flow IDs identified and documented
- [ ] Each Flow's business purpose confirmed
- [ ] Decision made on each Flow (delete vs. recreate)
- [ ] Deactivation completed without errors
- [ ] 48-hour monitoring shows no impact
- [ ] All Flows deleted from org
- [ ] Dry-run deployment succeeds

---

### 2. UNEXPECTED OBJECT DEPENDENCIES (MEDIUM RISK)

**Description:** Validation rules, process builder, custom metadata, picklists, or other metadata may reference old objects  
**Current Status:** TBD  
**Probability:** MEDIUM  
**Impact:** Deployment failure with error message  
**Severity:** MEDIUM

**Potential Dependencies:**
```
Validation Rules           → May reference old objects in formulas
Process Builder            → May trigger on old objects
Custom Settings            → May have old object references
Field Dependencies         → Lookup fields pointing to old objects
Permission Sets            → Field-level security for old objects
Connected Apps             → May integrate with old objects
Scheduled Apex             → May query old objects
Batch Jobs                 → May process old objects
```

**Mitigation Strategy:**

1. **Pre-Deployment Audit (Phase 1):**
   ```bash
   # Search for validation rule references
   sf apex query "SELECT Id, FullName FROM ValidationRule 
                  WHERE FullName LIKE '%Frete%' OR FullName LIKE '%Margem%' OR FullName LIKE '%Imposto%'"
   
   # Check custom settings
   Setup > Custom Settings > Search for old object names
   
   # Check flows (already known)
   Setup > Flows > Search for old object names
   ```

2. **Dry-Run Validation (Phase 4):**
   - Dry-run catches all metadata dependencies
   - If it fails, error message indicates exactly what's blocking

3. **Fix Strategy:**
   - Validation rules: Update to reference new objects or delete if unnecessary
   - Permission sets: Remove old object access, add new object access
   - Connections: Redirect integrations to new objects

**Success Indicators:**
- [ ] Validation rules audit complete (zero findings on old objects)
- [ ] Custom settings audit complete
- [ ] Permission sets audit complete
- [ ] Dry-run deployment succeeds without dependency errors

---

### 3. DATA STILL EXISTS IN OLD OBJECTS (MEDIUM RISK)

**Description:** Records may still exist in old Portuguese objects  
**Current Status:** TBD  
**Probability:** MEDIUM  
**Impact:** Deployment failure (prevents object deletion while records exist)  
**Severity:** MEDIUM

**Assumption:** Refactoring phase should have migrated all data, but records may remain

**Mitigation Strategy:**

1. **Query old objects (Phase 1):**
   ```bash
   sf data query --query "SELECT COUNT() FROM Frete__c" --target-org TaakProjetoPricing
   sf data query --query "SELECT COUNT() FROM Margem__c" --target-org TaakProjetoPricing
   sf data query --query "SELECT COUNT() FROM Imposto__c" --target-org TaakProjetoPricing
   ```

2. **If records found:**
   - Investigate: Why are these records still here?
   - Determine: Are they duplicates or legitimate orphaned records?
   - Decide:
     - Option A: Delete old records, verify new objects have migrated data
     - Option B: Migrate remaining records to new objects
     - Option C: Archive old records before deletion

3. **Delete if necessary:**
   ```bash
   sf data delete sobject --sobject Frete__c --where "LastModifiedDate < 2026-05-01" --target-org TaakProjetoPricing
   sf data delete sobject --sobject Margem__c --where "LastModifiedDate < 2026-05-01" --target-org TaakProjetoPricing
   sf data delete sobject --sobject Imposto__c --where "LastModifiedDate < 2026-05-01" --target-org TaakProjetoPricing
   ```

**Success Indicators:**
- [ ] All three old objects queried
- [ ] Record counts documented
- [ ] If records exist: Reason documented and owner acknowledged
- [ ] If records exist: Remediation plan approved
- [ ] Zero records in old objects before deployment

---

### 4. PERMISSION SET FIELD-LEVEL SECURITY (MEDIUM RISK)

**Description:** Permission sets may have field-level security (FLS) assignments for old objects  
**Current Status:** TBD  
**Probability:** MEDIUM  
**Impact:** Deployment failure (FLS prevents object deletion)  
**Severity:** MEDIUM

**Mitigation Strategy:**

1. **Audit Permission Sets (Phase 1):**
   ```bash
   # In Salesforce Setup:
   - Go to Security > Permission Sets
   - For each permission set, click "Object Settings"
   - Search for "Frete", "Margem", "Imposto"
   - Document any that appear
   ```

2. **Update Permission Sets:**
   - Remove access to old objects
   - Ensure new objects have proper access
   - Test permission set assignments

3. **Deploy via Salesforce Admin:**
   - Use Admin profile or permission set changes deployment
   - Part of normal metadata deployment workflow

**Success Indicators:**
- [ ] All permission sets audited
- [ ] Zero FLS assignments to old objects found (or documented and removed)
- [ ] New objects have correct FLS in permission sets
- [ ] Dry-run succeeds without permission-related errors

---

### 5. HANDLER/TRIGGER REFERENCES IN MAESTRO (LOW RISK)

**Description:** TriggerMaestro (dispatcher) must reference new handlers, not old ones  
**Current Status:** VERIFIED (code review confirms new handlers registered)  
**Probability:** LOW  
**Impact:** Triggers may not fire correctly if wrong handlers registered  
**Severity:** MEDIUM

**Mitigation Strategy:**

1. **Code Review (COMPLETED):**
   - Verify TriggerMaestro.cls registers new handlers
   - Confirm handlers match new object names
   - Check for any remaining old handler references

2. **Test (Phase 5):**
   - Create test records in new objects
   - Verify handlers fire and execute correctly
   - Check debug logs for correct handler execution

**Success Indicators:**
- [ ] Code review shows new handlers registered
- [ ] Zero references to old handlers in TriggerMaestro
- [ ] Trigger execution test passes

---

### 6. SCHEDULED JOBS / BATCH APEX (LOW RISK)

**Description:** Scheduled Apex or batch jobs may reference old objects  
**Current Status:** TBD  
**Probability:** LOW  
**Impact:** Batch jobs fail if they query old objects  
**Severity:** LOW

**Mitigation Strategy:**

1. **Search code for old object references:**
   ```bash
   grep -r "Frete__c\|Margem__c\|Imposto__c" force-app/main/default/classes --include="*.cls"
   grep -r "Frete__c\|Margem__c\|Imposto__c" force-app/main/default/triggers --include="*.trigger"
   ```

2. **If found:**
   - Update batch jobs to query new objects
   - Test batch execution
   - Schedule jobs to run after deployment

**Success Indicators:**
- [ ] No old object references found in code
- [ ] All batch jobs query new objects only
- [ ] Batch execution tests pass

---

### 7. INTEGRATION IMPACTS (MEDIUM RISK)

**Description:** External integrations may expect old object names or old field API names  
**Current Status:** TBD  
**Probability:** MEDIUM  
**Impact:** Integration failures, data sync issues  
**Severity:** MEDIUM

**Mitigation Strategy:**

1. **Inventory Integrations (Phase 1):**
   - Identify all systems connecting to Salesforce
   - Document which objects they interact with
   - Check if they reference old Portuguese object names

2. **Testing (Phase 2):**
   - During 48-hour deactivation window:
   - Monitor Integration Logs for errors
   - Check inbound/outbound processes
   - Verify no integration failures

3. **Fix if needed:**
   - Update integration endpoints to reference new objects
   - Test integration mappings
   - Verify data flows correctly

**Success Indicators:**
- [ ] All integrations identified
- [ ] Integration Logs show no errors during 48-hour window
- [ ] No spike in error rates after Flow deactivation
- [ ] Inbound orders process correctly

---

### 8. ROLLBACK CAPABILITY (CRITICAL CONTROL)

**Description:** Ability to revert to previous state if deployment causes issues  
**Current Status:** TBD  
**Probability:** LOW (but critical to have)  
**Impact:** CRITICAL  
**Severity:** CRITICAL

**Mitigation Strategy:**

1. **Pre-Deployment Backup:**
   ```bash
   # Salesforce provides automated backups:
   - Daily backups (included)
   - Weekly incremental backups (included)
   
   # Additional protection:
   - Create manual export of data before deployment
   - Save current metadata snapshot
   - Document org baseline
   ```

2. **Rollback Plan:**
   - **If deployment fails:** No rollback needed (destructive hasn't completed)
   - **If deployment succeeds but causes business issues:**
     - Restore from Salesforce backup
     - Or restore from exported metadata
     - Investigate root cause
     - Replan cleanup steps

3. **Testing Before Rollback:**
   - Don't rollback based on single error
   - Verify error is related to cleanup
   - Consider if issue is in new objects or elsewhere

**Success Indicators:**
- [ ] Backup confirmed available
- [ ] Rollback procedure documented and tested
- [ ] Team understands rollback is possible but risky (data integrity)

---

## GO/NO-GO DECISION CHECKLIST

### Pre-Phase 1 Decision

| Check | Required | Status | Owner |
|-------|----------|--------|-------|
| Design plan reviewed | YES | ✓ DONE | DevOps |
| Stakeholder approval obtained | YES | PENDING | Tech Lead |
| Backup strategy confirmed | YES | PENDING | DevOps |
| Team trained on rollback | YES | PENDING | Tech Lead |

### Pre-Phase 2 Decision (After Flow Inventory)

| Check | Required | Status | Owner |
|-------|----------|--------|-------|
| All 5 Flows identified | YES | PENDING | DevOps |
| Business criticality assessed | YES | PENDING | Product Owner |
| Deactivation window scheduled | YES | PENDING | DevOps |
| Monitoring plan created | YES | PENDING | QA |

### Pre-Phase 4 Decision (After Flow Deletion)

| Check | Required | Status | Owner |
|-------|----------|--------|-------|
| 48-hour monitoring complete | YES | PENDING | QA |
| Zero integration errors detected | YES | PENDING | DevOps |
| All old records deleted | YES | PENDING | DevOps |
| All permission sets updated | YES | PENDING | Admin |
| Dry-run deployment succeeds | YES | PENDING | DevOps |
| Code review passed | YES | DONE | Code Review |

### Pre-Phase 5 Decision (Final Gate)

| Check | Required | Status | Owner |
|-------|----------|--------|-------|
| All previous gates passed | YES | PENDING | DevOps |
| Management approval obtained | YES | PENDING | Tech Lead |
| Rollback tested | YES | PENDING | DevOps |
| Team on standby for support | YES | PENDING | Tech Lead |

**STOP if any check is blocked or failed**

---

## DECISION CRITERIA

### PROCEED with cleanup if:
- [ ] All 5 Flows identified and documented
- [ ] No blocking dependencies found in audit
- [ ] Zero records in old objects
- [ ] Dry-run deployment succeeds
- [ ] Business owner approves Flow deletion
- [ ] 48-hour monitoring shows stability
- [ ] Rollback procedure confirmed

### DELAY cleanup if:
- [ ] Any Flow cannot be deactivated
- [ ] Integration errors detected during monitoring
- [ ] Records remain in old objects (investigate why)
- [ ] Dependency audit finds blocking metadata
- [ ] Dry-run deployment fails

### CANCEL cleanup if:
- [ ] Critical business process depends on old objects (recreate with new objects first)
- [ ] Flow deletion causes production issues (restore and redesign Flows)
- [ ] Integration failures persist after 48-hour window

---

## CONTINGENCY TRIGGERS

### If Flows Cannot Be Deleted
**Trigger:** Flow delete button absent or error occurs  
**Response:**
1. Try deletion in Flow Builder
2. If fails, try deletion in Setup > Flows
3. If still fails, check for active scheduled actions
4. If still fails, contact Salesforce Support

**Fallback:** Use Metadata API directly via Salesforce CLI

### If Deployment Dry-Run Fails
**Trigger:** Dry-run shows dependency errors  
**Response:**
1. Read error message carefully
2. Identify blocking metadata
3. Resolve dependency (update validation rule, permission set, etc.)
4. Re-run dry-run
5. Do NOT proceed to real deployment until dry-run passes

### If Integration Errors During Monitoring
**Trigger:** Integration Logs show errors related to old objects  
**Response:**
1. Identify which integration is failing
2. Determine root cause (Flows? Batch jobs? Connectors?)
3. Reactivate Flows if they were deactivated
4. Fix integration mappings
5. Re-run stability monitoring for another 24 hours

### If Deployment Fails
**Trigger:** Real deployment execution fails  
**Response:**
1. Check error message
2. Identify what blocked deployment
3. Do NOT attempt immediate rollback (risk data integrity)
4. Contact Salesforce Support for guidance
5. Investigate root cause
6. Fix issues and retry deployment

---

## APPROVAL SIGNOFFS

Before proceeding, obtain approval from:

1. **Technical Lead** — Confirms plan and rollback strategy
2. **Product Owner** — Confirms Flow deletions won't block business
3. **Salesforce Admin** — Confirms org is stable for cleanup
4. **DevOps Engineer** — Confirms backup and deployment readiness

**All signatures required before Phase 2 begins**
