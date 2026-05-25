# BLOCKING FLOWS INVENTORY
## 5 Flows Preventing Destructive Changes Deployment

**Target Org:** TaakProjetoPricing  
**Status:** BLOCKING destructive deployment  
**Action Required:** Deactivate and delete all 5 before cleanup can proceed

---

## FLOW IDs TO INVESTIGATE

| Flow ID | Status | Purpose | Owner | Business Critical |
|---------|--------|---------|-------|-------------------|
| 301ak000027quXJ | Unknown | TBD | ? | ? |
| 301ak000027pSgN | Unknown | TBD | ? | ? |
| 301ak000027n5Po | Unknown | TBD | ? | ? |
| 301ak000027oUUI | Unknown | TBD | ? | ? |
| 301ak000027q34s | Unknown | TBD | ? | ? |

---

## INVESTIGATION TEMPLATE

For each Flow ID, complete the following:

### Flow: [Flow ID]

**Name:** _______________________________________________

**Type:** (Circle one)
- Scheduled Flow
- Triggered Flow (Trigger)
- Cloud Flow
- Other: _______________________

**Objects Referenced:** (Check all that apply)
- [ ] Frete__c
- [ ] Margem__c
- [ ] Imposto__c
- [ ] Other: _______________________

**Business Purpose:**
```
What does this Flow do?
When is it used?
How frequently does it run?
What systems does it integrate with?
```

**Business Criticality:** (Circle one)
- **CRITICAL** — Must keep (need to recreate with new objects first)
- **IMPORTANT** — Use occasionally, could recreate with new objects
- **LOW** — Nice to have, safe to delete
- **NONE** — Not used, safe to delete

**Dependent Processes:** (List any other automations that depend on this Flow)
- Process A
- Process B
- etc.

**Action:** (Circle one)
- **DELETE** — Flow can be safely deleted
- **RECREATE** — Flow must be recreated with new English objects, THEN delete old
- **INVESTIGATE** — Need more information before deciding

**Owner Signature:** _______________________  
**Date:** _______________________

---

## INVESTIGATION INSTRUCTIONS

### Where to Find Flows

1. **In Salesforce UI:**
   - Setup > Flows
   - Search for Flow ID (copy/paste into search box)
   - Click the Flow name to open

2. **In Developer Console:**
   - Open Developer Console (F12 in Salesforce)
   - Debug > Open Execute Anonymous
   - Run this query:
     ```apex
     Flow__c flow = [SELECT Id, ApiName, Description FROM Flow__c 
                     WHERE Id = '301ak000027quXJ' LIMIT 1];
     System.debug(flow);
     ```

### What to Document

For each Flow:

1. **Name** — What is the Flow called? (e.g., "Update_Order_Pricing")
2. **Type** — Is it scheduled, triggered, cloud flow, etc.?
3. **Objects Referenced** — Which objects does it interact with?
   - Look for resource references (variable types)
   - Look for query actions
   - Look for record create/update actions
4. **Business Purpose** — What problem does this Flow solve?
5. **Frequency** — How often does it run? (daily, hourly, on-demand, trigger)
6. **Dependencies** — What other things depend on this Flow?
7. **Business Criticality** — Can we safely delete it?

### Questions to Ask Business Owner

1. **Is this Flow currently being used?**
   - Can check in Salesforce Flows dashboard > Runs tab
   - Filter by date (last 30 days)

2. **What would break if we delete this Flow?**
   - No answer = probably safe to delete
   - Any answer = might need to recreate with new objects

3. **Does this Flow touch Orders, Order Items, or Pricing?**
   - If YES: Might be critical for order processing
   - If NO: Probably safe to delete

4. **Can you run for 48 hours without this Flow?**
   - If YES: Safe to deactivate during monitoring window
   - If NO: Critical process, must recreate with new objects first

---

## DECISION MATRIX

### If Flow is Business-Critical (Must Keep)

**What to do:**
1. Recreate Flow in Flow Builder using new English objects (Freight__c, Margin__c, Tax__c)
2. Test new Flow with sample data
3. Deploy new Flow to production
4. Switch all triggers to use new Flow
5. Wait 24 hours to verify new Flow works
6. Delete old Flow
7. Then proceed with destructive changes

**Timeline impact:** Add 2-3 days to cleanup

---

### If Flow is Not Critical (Safe to Delete)

**What to do:**
1. Document current behavior (if needed for audit trail)
2. Deactivate Flow (Phase 2)
3. Monitor for 48 hours
4. If no issues: Delete Flow (Phase 3)
5. Proceed with destructive changes (Phase 4)

**Timeline impact:** No delay, follows normal cleanup schedule

---

### If Flow Purpose Unclear

**What to do:**
1. Search for Flow usage in last 30 days (Flows > Runs)
2. If runs exist: Flow is in use, ask business owner
3. If no runs: Probably orphaned, safe to delete
4. Document findings and decision

---

## FLOW DEACTIVATION CHECKLIST

Before deactivating each Flow:

- [ ] Flow owner/stakeholder identified
- [ ] Business purpose documented
- [ ] No critical dependencies found
- [ ] Backup of Flow definition created (save as text)
- [ ] Monitoring plan prepared
- [ ] Team notified of deactivation

---

## FLOW DELETION CHECKLIST

Before deleting each Flow:

- [ ] Flow has been deactivated for minimum 24 hours
- [ ] No errors in Integration Logs
- [ ] No spike in error rates
- [ ] Business confirms no issues during deactivation
- [ ] Flow definition backed up (export from Salesforce)
- [ ] Delete timestamp recorded

---

## SAMPLE INVESTIGATION RESULTS

### Example: Flow 301ak000027quXJ

**Name:** Update_Order_Status_on_Pricing  
**Type:** Scheduled Flow  
**Objects:** Frete__c, Order, OrderItem  
**Purpose:** Every hour, check Frete__c records. If pricing complete, update Order status to "Ready".  
**Critical:** YES — This is core order processing  
**Decision:** RECREATE with new Freight__c object, THEN delete old

---

### Example: Flow 301ak000027pSgN

**Name:** Integration_Notification_Handler  
**Type:** Triggered Flow  
**Objects:** Margem__c (on insert)  
**Purpose:** When new Margem__c record created, send notification to pricing team  
**Critical:** NO — Informational only, nice-to-have  
**Decision:** DELETE (team can live without hourly notifications)

---

## INVESTIGATION EXECUTION STEPS

1. **Assign owner** — Who investigates? (Recommend: DevOps + Business Analyst)
2. **Schedule time** — How long? (Estimate: 1-2 hours for all 5)
3. **Gather people** — Need: DevOps, Business Owner, Salesforce Admin
4. **Document findings** — Use this template for each Flow
5. **Make decisions** — For each Flow: DELETE or RECREATE
6. **Get approval** — Stakeholder signs off on all decisions
7. **Report** — Present findings to Tech Lead

---

## WHAT HAPPENS NEXT

### If All 5 Flows Are Safe to Delete
- Proceed to Phase 2: Deactivation
- Proceed to Phase 3: Deletion
- Proceed to Phase 4: Destructive deployment
- **Timeline:** Normal (4 days)

### If 1-2 Flows Need Recreation
- Identify which ones (document)
- Recreate them with new English objects
- Test new Flows
- Deactivate old Flows
- Delete old Flows
- Proceed with destructive deployment
- **Timeline:** Delayed by 2-3 days

### If Most/All Flows are Business-Critical
- Recommend postponing cleanup
- Instead: Migrate all Flows to new objects
- This is actually the safer approach
- Cleanup becomes post-Flow-migration task
- **Timeline:** Delay cleanup 1 week while recreating Flows

---

## APPROVAL & SIGN-OFF

### Phase 1 Sign-Off Required From:

1. **DevOps Engineer** — Confirms investigation complete
   - Signature: _______________________
   - Date: _______________________

2. **Business Owner** — Approves Flow deletion decisions
   - Signature: _______________________
   - Date: _______________________

3. **Salesforce Admin** — Confirms no dependencies missed
   - Signature: _______________________
   - Date: _______________________

4. **Tech Lead** — Approves overall plan
   - Signature: _______________________
   - Date: _______________________

**All signatures required before Phase 2 begins.**

---

## TIPS FOR SUCCESSFUL INVESTIGATION

1. **Open Flow definitions side-by-side with this template**
2. **Talk to the person who created each Flow** (they remember why)
3. **Check Flow Runs dashboard** (proves if Flow is active)
4. **Ask "What would break if this was gone?"** (business answer)
5. **Document even if flow seems obvious** (audit trail)
6. **If unsure: ASK** (better safe than sorry)

---

## ESCALATION

If you can't find a Flow ID:
1. Try searching in Flows list (use ID in search box)
2. Try searching in Recent Flows
3. If still not found: Contact Salesforce Admin
4. If not found: May indicate Flow was already deleted (check git history)

If you can't determine if a Flow is critical:
1. Ask the business owner who uses that area
2. Check Runs dashboard for recent executions
3. Check logs for related errors
4. When in doubt: Treat as critical (recreate it)

---

## SUMMARY

**Your task:** Complete this investigation for all 5 Flow IDs

**What to deliver:** 
1. Completed investigation template for each Flow
2. Decision matrix (which Flows to DELETE vs RECREATE)
3. Approval signatures from 4 stakeholders
4. List of any Flow recreation needs
5. Timeline adjustment if recreations needed

**When done:** Report back to Tech Lead with findings. They'll decide next steps.

---

**Status:** READY FOR PHASE 1 INVESTIGATION  
**Estimated Time:** 1-2 hours  
**Next Review:** After investigation complete (expected tomorrow)
