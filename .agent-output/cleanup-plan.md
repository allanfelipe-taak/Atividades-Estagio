# Salesforce Cleanup Plan: Portuguese → English Migration Finalization

**Org:** TaakProjetoPricing  
**Status:** Post-Migration Cleanup Phase  
**Date:** 2026-05-20  
**Objective:** Remove old Portuguese objects (Frete__c, Margem__c, Imposto__c) and associated code

---

## EXECUTIVE SUMMARY

The English language refactoring is complete. New objects (Freight__c, Margin__c, Tax__c) and handlers (FreightHandler, MarginHandler, TaxHandler) are deployed and functional. The blocking issue is 5 Flows that still reference old Portuguese objects, preventing destructive deletion.

**Cleanup sequence:**
1. Identify and deactivate blocking Flows
2. Delete Flow definitions from org
3. Execute destructive changes to remove old objects and code
4. Validate cleanup completeness

---

## PHASE 1: IDENTIFY BLOCKING FLOWS

### Current Blocking Flows
| Flow ID | Status | Purpose | Action |
|---------|--------|---------|--------|
| 301ak000027quXJ | Unknown | TBD | Deactivate & Delete |
| 301ak000027pSgN | Unknown | TBD | Deactivate & Delete |
| 301ak000027n5Po | Unknown | TBD | Deactivate & Delete |
| 301ak000027oUUI | Unknown | TBD | Deactivate & Delete |
| 301ak000027q34s | Unknown | TBD | Deactivate & Delete |

### Investigation Steps
1. Connect to TaakProjetoPricing org
2. Navigate to Setup > Flows (or Flow > All Flows)
3. Use Flow ID search or Developer Console to identify each Flow
4. Document:
   - Flow name
   - Type (Scheduled, Triggered, Cloud Flow, etc.)
   - Which objects they reference (Frete__c, Margem__c, Imposto__c)
   - Any dependent processes or automations
   - Whether they're part of active business processes

### Risks & Dependencies
- **Scheduled Flows:** If actively running, may need grace period for in-flight executions
- **Triggered Flows:** May be firing on Order, OrderItem, or other related objects
- **Cross-org Dependencies:** Check if these Flows trigger integrations
- **Audit Trail:** Document who created/modified each Flow (traceability)

---

## PHASE 2: SAFELY DEACTIVATE & DELETE FLOWS

### Prerequisites
- User account has Manage Flows permission
- Backup of Flow definitions (export from Salesforce or version control)
- Change set prepared for rollback if needed

### Deactivation Steps

#### Step 2.1: Deactivate Flows (Non-Destructive)
```
FOR EACH blocking Flow ID:
  1. Open Flow Definition in Flow Builder
  2. Click "Save" (if modified) or skip if no changes
  3. Click "Deactivate" button
  4. Confirm deactivation
  5. Wait for confirmation message
  6. Document status in log
```

**Why deactivate first?**
- Allows time to monitor for issues (24-48 hours recommended)
- No immediate deletion = safe rollback if issues arise
- Allows you to catch any missed downstream processes

#### Step 2.2: Wait for Stability Check
- Monitor order processing (if Flows touch Orders/OrderItems)
- Check Integration Logs for any integration failures
- Confirm no user-facing issues reported
- Review debug logs if automation should be running

#### Step 2.3: Delete Flow Definitions
```
FOR EACH deactivated Flow:
  1. Open the deactivated Flow in Flow Builder
  2. Click "Delete" button
  3. Confirm deletion
  4. Document status in log
```

**Best Practice:**
- Delete one Flow at a time and test org stability
- If issues occur, stop and restore from backup
- Do NOT delete all 5 at once

### Rollback Plan
If issues arise after deactivation:
1. Reactivate Flow from version control backup
2. Deploy via sf deploy or manual reimport
3. Investigate root cause before attempting cleanup again

---

## PHASE 3: EXECUTE DESTRUCTIVE CHANGES DEPLOYMENT

### Current Destructive Changes (destructiveChangesPre.xml)

**Contents:**
```xml
ApexClass:
  - FreteHandler
  - MargemHandler
  - ImpostoHandler

ApexTrigger:
  - FreteTrigger
  - MargemTrigger
  - ImpostoTrigger

CustomObject:
  - Frete__c
  - Margem__c
  - Imposto__c
```

**API Version:** 66.0 (current)

### Deployment Command

```bash
# Prerequisite: All Flows must be deleted first
# User must have Administrator or Modify All permission

sf project deploy start \
  --manifest MDAPI/destructiveChangesPre.xml \
  --target-org TaakProjetoPricing \
  --wait 30 \
  --test-level NoTestRun
```

**Alternative (if manifest-based fails):**
```bash
sf project deploy destructive \
  --manifest MDAPI/destructiveChangesPre.xml \
  --target-org TaakProjetoPricing \
  --wait 30
```

### Validation Before Deployment
1. Confirm all Flows deleted from org
2. Verify new objects (Freight__c, Margin__c, Tax__c) are in use
3. Confirm new handlers (FreightHandler, MarginHandler, TaxHandler) are deployed
4. Check that no code references the old Portuguese object names
5. Review logs for any data dependencies

### Risks & Mitigation
| Risk | Impact | Mitigation |
|------|--------|-----------|
| Flows still present | Deployment fails | Verify all 5 Flows deleted before deploying |
| Custom validation rules reference old objects | Deployment fails | Check Setup > Custom Settings, Rules for dependencies |
| Apex code references old objects | Deployment fails | Grep codebase for "Frete__c", "Margem__c", "Imposto__c" |
| Data records still exist | Deployment fails | Delete all records from old objects first |
| Page layouts reference old objects | May cause issues | Already included in destructiveChangesPre.xml |
| Permission sets reference old objects | Deployment fails | Check permission set field-level security assignments |

---

## PHASE 4: VALIDATION & CLEANUP CONFIRMATION

### Post-Deployment Checklist

#### 4.1 Object Verification
```bash
# Verify old objects are gone
sf sobject describe -s Frete__c --target-org TaakProjetoPricing
  # Expected: Object not found (SHOULD FAIL - this is success)

sf sobject describe -s Margem__c --target-org TaakProjetoPricing
  # Expected: Object not found (SHOULD FAIL - this is success)

sf sobject describe -s Imposto__c --target-org TaakProjetoPricing
  # Expected: Object not found (SHOULD FAIL - this is success)
```

#### 4.2 New Objects Verification
```bash
# Verify new objects still exist
sf sobject describe -s Freight__c --target-org TaakProjetoPricing
  # Expected: Object found, all fields present

sf sobject describe -s Margin__c --target-org TaakProjetoPricing
  # Expected: Object found, all fields present

sf sobject describe -s Tax__c --target-org TaakProjetoPricing
  # Expected: Object found, all fields present
```

#### 4.3 Code Verification
```bash
# Verify handlers deployed
sf apex list --target-org TaakProjetoPricing | grep -E "Freight|Margin|Tax"
  # Expected:
  #   FreightHandler (class)
  #   MarginHandler (class)
  #   TaxHandler (class)
  #   FreightTrigger (trigger)
  #   MarginTrigger (trigger)
  #   TaxTrigger (trigger)
```

#### 4.4 Codebase Verification
```bash
# Search for any remaining references to old objects
grep -r "Frete__c" force-app/main/default/classes --include="*.cls" --include="*.trigger"
grep -r "Margem__c" force-app/main/default/classes --include="*.cls" --include="*.trigger"
grep -r "Imposto__c" force-app/main/default/classes --include="*.cls" --include="*.trigger"
  # Expected: No results (all references removed during refactoring)
```

#### 4.5 Data Verification
```bash
# Query old objects (should return no results)
sf data query --query "SELECT Id FROM Frete__c LIMIT 1" --target-org TaakProjetoPricing
  # Expected: No records found

sf data query --query "SELECT Id FROM Margem__c LIMIT 1" --target-org TaakProjetoPricing
  # Expected: No records found

sf data query --query "SELECT Id FROM Imposto__c LIMIT 1" --target-org TaakProjetoPricing
  # Expected: No records found
```

#### 4.6 Dependencies Check
```bash
# Verify no remaining dependencies
sf apex execute --target-org TaakProjetoPricing << 'EOF'
List<MetadataContainer> mc = [SELECT Id FROM MetadataContainer WHERE Name = 'DeployContainer' LIMIT 1];
System.debug('Checking for lingering dependencies...');
EOF
```

### Success Criteria
- [ ] All 5 old objects (Frete__c, Margem__c, Imposto__c) deleted from org
- [ ] All 3 old handlers (FreteHandler, MargemHandler, ImpostoHandler) removed
- [ ] All 3 old triggers (FreteTrigger, MargemTrigger, ImpostoTrigger) removed
- [ ] All 5 Flows deleted
- [ ] New objects (Freight__c, Margin__c, Tax__c) fully functional
- [ ] New handlers deployed and registered in TriggerMaestro
- [ ] No code references to old Portuguese objects in codebase
- [ ] No errors in Integration Logs for current processing
- [ ] Order pricing engine using new objects/handlers

---

## PHASE 5: POST-CLEANUP ACTIONS

### 1. Update Version Control
```bash
# Ensure destructive changes and deletion records are in git history
git log --oneline | grep -i "destructive\|cleanup\|delete"
git show HEAD:MDAPI/destructiveChangesPre.xml
```

### 2. Document Changes
- Update CHANGELOG.md with cleanup completion date
- Add entry to migration log noting successful object deletion
- Record Flow IDs and names deleted (for audit trail)

### 3. Communication
- Notify team that old Portuguese objects are removed
- Confirm new objects are now the system of record
- Remove any documentation referencing old object names

### 4. Cleanup Artifacts
```bash
# After successful cleanup, you may optionally:
# - Archive destructiveChangesPre.xml to a folder: archives/2026-05-20-cleanup/
# - Add comment to git noting cleanup completion
# - Tag release: git tag v1.0-migration-complete
```

---

## DECISION MATRIX: WHEN TO PROCEED

### Go/No-Go Checklist
Before executing Phase 3 (destructive deployment), verify:

| Check | Status | Owner | Sign-off |
|-------|--------|-------|----------|
| All 5 Flows identified and documented | [ ] | DevOps | ___ |
| All 5 Flows deactivated without issues | [ ] | DevOps | ___ |
| All 5 Flows deleted from org | [ ] | DevOps | ___ |
| 48-hour stability period completed | [ ] | QA | ___ |
| New objects in production use | [ ] | Business | ___ |
| Zero errors in IntegrationLog for 24hrs | [ ] | DevOps | ___ |
| Backup of org created | [ ] | DevOps | ___ |
| Rollback plan reviewed | [ ] | DevOps | ___ |
| Stakeholder approval obtained | [ ] | Business | ___ |

**PROCEED to Phase 3 ONLY when ALL checks are signed off.**

---

## APPENDIX: COMMANDS QUICK REFERENCE

### Connect to Org
```bash
sf org login web --alias TaakProjetoPricing
sf config set target-org=TaakProjetoPricing
```

### Dry-Run Deployment (Recommended)
```bash
sf project deploy start \
  --manifest MDAPI/destructiveChangesPre.xml \
  --target-org TaakProjetoPricing \
  --dry-run \
  --wait 30
```

### Real Deployment
```bash
sf project deploy start \
  --manifest MDAPI/destructiveChangesPre.xml \
  --target-org TaakProjetoPricing \
  --wait 30 \
  --test-level NoTestRun
```

### Monitor Deployment
```bash
sf project deploy report \
  --job-id <deployment-id> \
  --target-org TaakProjetoPricing
```

### Retrieve Old Objects (if rollback needed)
```bash
sf project retrieve start \
  --manifest <manifest-with-old-objects> \
  --target-org TaakProjetoPricing
```

---

## APPENDIX: TESTING STRATEGY

### Unit Test Validation
After cleanup, run existing test suite:
```bash
sf apex run test \
  --target-org TaakProjetoPricing \
  --code-coverage \
  --result-format human
```

Expected: All tests pass, especially:
- `FreightHandlerTest` (formerly FreteHandlerTest)
- `MarginHandlerTest` (formerly MargemHandlerTest)
- `TaxHandlerTest` (formerly ImpostoHandlerTest)

### Integration Testing
1. Create test Order with items
2. Verify pricing calculation uses new handlers
3. Verify Freight__c, Margin__c, Tax__c records created (not Frete__c, Margem__c, Imposto__c)
4. Verify Integration Logs show success
5. Verify no errors in debug logs

### Smoke Testing (Business Verification)
- Order creation: PASS/FAIL
- Order line item addition: PASS/FAIL
- Pricing calculation: PASS/FAIL
- Tax calculation: PASS/FAIL
- Margin validation: PASS/FAIL
- Freight estimation: PASS/FAIL

---

## CONTACT & ESCALATION

- **Primary:** DevOps Engineer
- **Escalation:** Salesforce Administrator
- **Rollback Authority:** Release Manager
