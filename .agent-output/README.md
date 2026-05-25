# ProjetoPricing Cleanup Plan: Portuguese → English Migration

**Completion of Portuguese to English refactoring by removing old objects, handlers, triggers, and blocking Flows**

---

## 📋 DOCUMENTS IN THIS FOLDER

### START HERE
1. **EXECUTIVE-SUMMARY.md** — 5-minute overview for decision makers
   - Situation, timeline, risks, approvals needed
   - Read first if you're new to this project

### THEN READ BASED ON YOUR ROLE

**For Everyone:**
2. **cleanup-summary.md** — Complete timeline and phases
   - What's done, what's blocking, how to proceed
   - Go/no-go decision gates

**For DevOps/QA:**
3. **cleanup-plan.md** — Detailed step-by-step procedures
   - Every command, every check, every validation
   - Complete contingency procedures
   - Testing and rollback strategies

4. **devops-commands.sh** — Ready-to-run bash script
   - Copy-paste commands for each phase
   - Interactive flow guide
   - Logging and validation built-in

**For Tech Lead/Managers:**
5. **risk-assessment.md** — Risk analysis and mitigation
   - 8 major risk categories
   - Probability and impact assessment
   - Go/no-go decision matrix
   - Escalation triggers

---

## 🎯 WHAT NEEDS TO BE DONE

### Current State ✅
- Portuguese to English refactoring: COMPLETE
- New objects (Freight__c, Margin__c, Tax__c): DEPLOYED
- New handlers (FreightHandler, MarginHandler, TaxHandler): DEPLOYED
- Destructive manifest: READY

### Blocking Issue ⚠️
- 5 Flows still reference old Portuguese objects
- These Flows prevent deletion of old objects
- **Must be deleted before destructive deployment**

### Required Cleanup Steps
1. **Phase 1 (TODAY):** Identify 5 blocking Flows — 1-2 hours
2. **Phase 2 (DAY 2):** Deactivate Flows — 30 min + 48 hr monitoring
3. **Phase 3 (DAY 4):** Delete Flow definitions — 30 min
4. **Phase 4 (DAY 4):** Deploy destructive changes — 15 min
5. **Phase 5 (DAY 4):** Validate cleanup — 30 min

---

## 📅 TIMELINE

| Phase | Day | Owner | Time | Status |
|-------|-----|-------|------|--------|
| 1: Flow Investigation | TODAY | DevOps | 1-2 hrs | READY |
| 2: Flow Deactivation | Day 2 | DevOps | 30 min + 48 hrs | PENDING |
| 3: Flow Deletion | Day 4 | DevOps | 30 min | PENDING |
| 4: Destructive Deploy | Day 4 | DevOps | 15 min | PENDING |
| 5: Validation | Day 4 | DevOps/QA | 30 min | PENDING |

**Total elapsed:** ~4 days  
**Active work:** ~2.5 hours  
**Projected completion:** End of this week

---

## 🔑 KEY POINTS

### Go/No-Go Gates
- **Before Phase 2:** All 5 Flows documented, business approves deletion
- **Before Phase 4:** 48-hour monitoring complete with zero integration errors
- **Before Phase 5:** Dry-run deployment succeeds

### What Gets Deleted
```
Apex Classes:
  - FreteHandler
  - MargemHandler
  - ImpostoHandler

Apex Triggers:
  - FreteTrigger
  - MargemTrigger
  - ImpostoTrigger

Custom Objects:
  - Frete__c
  - Margem__c
  - Imposto__c

Flows (5 total):
  - 301ak000027quXJ
  - 301ak000027pSgN
  - 301ak000027n5Po
  - 301ak000027oUUI
  - 301ak000027q34s
```

### What Stays (New Objects)
```
Apex Classes:
  - FreightHandler ✓
  - MarginHandler ✓
  - TaxHandler ✓

Apex Triggers:
  - FreightTrigger ✓
  - MarginTrigger ✓
  - TaxTrigger ✓

Custom Objects:
  - Freight__c ✓
  - Margin__c ✓
  - Tax__c ✓
```

---

## ⚠️ RISKS & MITIGATION

| Risk | Level | Mitigation |
|------|-------|-----------|
| Flows can't be deleted | MEDIUM | Use Metadata API or Salesforce Support |
| Unexpected dependencies | MEDIUM | Dry-run deployment catches issues |
| Integration breaks | MEDIUM | 48-hour monitoring detects problems |
| Data in old objects | LOW | Query before deployment; delete if found |
| Rollback needed | VERY LOW | Salesforce automatic backup available |

**Overall Risk Level:** LOW-MEDIUM  
**Confidence in Plan:** HIGH

See **risk-assessment.md** for complete analysis.

---

## 👥 ROLES & RESPONSIBILITIES

| Role | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Phase 5 |
|------|---------|---------|---------|---------|---------|
| **DevOps** | Identify Flows | Deactivate | Delete | Deploy | Validate |
| **QA** | Consult | Monitor | Monitor | Verify | Test |
| **Tech Lead** | Approve plan | Oversight | Oversight | Oversight | Sign-off |
| **Product Owner** | Consult | — | Approve | — | Sign-off |
| **Salesforce Admin** | Consult | — | — | Monitor | Confirm |

---

## 🚀 HOW TO START

### Option 1: Quick Start (Executives)
1. Read **EXECUTIVE-SUMMARY.md** (5 min)
2. Share with team
3. Get approvals
4. Begin Phase 1

### Option 2: Detailed Review (Tech Lead)
1. Read **EXECUTIVE-SUMMARY.md** (5 min)
2. Read **cleanup-summary.md** (15 min)
3. Read **risk-assessment.md** (20 min)
4. Review **cleanup-plan.md** (30 min)
5. Approve or request changes

### Option 3: Ready to Execute (DevOps)
1. Read **cleanup-plan.md** (30 min)
2. Review **devops-commands.sh** (10 min)
3. Execute Phase 1: `bash devops-commands.sh phase_0_preflight`
4. Then: `bash devops-commands.sh phase_1_identify_flows`

---

## ✅ SUCCESS CRITERIA

After cleanup completes:
- [ ] All old Portuguese objects deleted from org
- [ ] All old handlers removed from codebase
- [ ] All old triggers removed from codebase
- [ ] All 5 blocking Flows deleted
- [ ] New English objects fully functional
- [ ] New handlers deployed and working
- [ ] All tests passing
- [ ] Integration Logs clean
- [ ] Orders processing correctly

---

## 📞 SUPPORT

### Before You Start
- Review **EXECUTIVE-SUMMARY.md**
- Review **cleanup-plan.md**
- Get approvals documented

### During Execution
- Use **devops-commands.sh** for step-by-step guidance
- Check **risk-assessment.md** for contingencies
- Contact Tech Lead if you hit Go/No-Go gate

### If Something Goes Wrong
1. Check **risk-assessment.md** for your scenario
2. Follow mitigation steps
3. Escalate to Tech Lead if unsure
4. Contact Salesforce Support if Salesforce-specific issue

---

## 📁 FILE STRUCTURE

```
.agent-output/
├── README.md (this file)
├── EXECUTIVE-SUMMARY.md (decision-makers)
├── cleanup-summary.md (timeline & overview)
├── cleanup-plan.md (detailed procedures)
├── devops-commands.sh (ready-to-run script)
├── risk-assessment.md (risk analysis)
└── cleanup-execution.log (populated during execution)
```

---

## 🔗 REFERENCE FILES

**In ProjetoPricing repository:**
- `MDAPI/destructiveChangesPre.xml` — Destructive changes manifest
- `package.xml` — Current package manifest
- `CLAUDE.md` — Project guidelines
- `force-app/main/default/classes/` — Code to be cleaned up

---

## 📝 DOCUMENT QUICK REFERENCE

### What's in Each Document?

**EXECUTIVE-SUMMARY.md** (8 pages)
- Situation analysis
- Timeline (4 days)
- Key decisions
- Risks in plain English
- Approval requirements
- FAQ

**cleanup-summary.md** (10 pages)
- What's complete
- What's blocking
- Five cleanup phases with procedures
- Go/no-go gates
- Risk assessment summary
- Post-cleanup actions

**cleanup-plan.md** (20 pages)
- Detailed procedures for each phase
- All command examples
- Pre-flight checks
- Dependencies analysis
- Validation checklist
- Testing strategy
- Appendix with quick commands

**devops-commands.sh** (300 lines)
- Interactive bash script
- Phase-by-phase execution
- Built-in validation
- Error handling
- Logging

**risk-assessment.md** (15 pages)
- Risk matrix (9 major risks)
- Probability/impact analysis
- Mitigation strategies
- Contingency plans
- Go/no-go decision criteria
- Escalation triggers

---

## 🎓 RECOMMENDED READING ORDER

1. **First:** EXECUTIVE-SUMMARY.md (5 min) — Understand what/why/when
2. **Second:** cleanup-summary.md (15 min) — Understand how phases work
3. **Third:** Choose based on role:
   - **Managers:** risk-assessment.md (20 min)
   - **DevOps:** cleanup-plan.md (30 min) + devops-commands.sh (10 min)
   - **Tech Lead:** All of the above (60 min)

---

## ❓ FREQUENTLY ASKED QUESTIONS

**Q: Can we skip the 48-hour monitoring window?**  
A: Not recommended. The monitoring window catches integration issues early. Minimum 24 hours.

**Q: What if we find issues during Phase 1?**  
A: Document them and solve them before proceeding. Phase 1 is specifically designed to catch blockers early.

**Q: Can we delete all 5 Flows at once instead of one-by-one?**  
A: High-risk approach. Better to delete sequentially and validate each deletion.

**Q: What if dry-run fails?**  
A: We don't proceed to real deployment. Fix the issues and re-test dry-run.

**Q: How do we rollback if something goes wrong?**  
A: Salesforce automatic backups (daily). Can restore from backup if absolutely necessary.

**Q: How long will users be impacted?**  
A: Zero impact. New objects already in production. Cleanup runs in background.

See **EXECUTIVE-SUMMARY.md** for more FAQ.

---

## 📊 APPROVAL CHECKLIST

Before proceeding past Phase 1:

- [ ] Tech Lead reviewed plan and approved
- [ ] Product Owner confirmed Flows not critical
- [ ] Salesforce Admin confirmed backup ready
- [ ] DevOps Lead confirmed execution capability
- [ ] All stakeholders understand timeline (4 days)
- [ ] All stakeholders understand risks (documented in risk-assessment.md)

---

## 🏁 COMPLETION CRITERIA

**Cleanup is successful when:**
1. Org has zero errors in Integration Logs post-deployment
2. Old Portuguese objects completely gone
3. New English objects fully operational
4. Orders processing with new objects/handlers
5. All tests passing
6. Team ready to close migration tickets

---

## 📞 CONTACTS

| Role | Email |
|------|-------|
| DevOps Lead | allanweb12@gmail.com |
| Project Owner | — |
| Tech Lead | — |

---

## 📋 VERSION HISTORY

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-05-20 | Initial plan created, ready for Phase 1 |

---

## 🎯 NEXT STEP

**Read:** `EXECUTIVE-SUMMARY.md`  
**Time:** 5 minutes  
**Then:** Share with stakeholders for approval

---

**Last Updated:** 2026-05-20  
**Status:** READY FOR EXECUTION
