---
name: story-6-risk-cap-architecture
description: Complete architecture for Story 6 Risk Probability Cap & Audit System with all clarifications
metadata:
  type: project
---

# Story 6: Risk Probability Cap & Audit System

## Core Architecture

**Trigger Pattern**: Before Insert/Before Update on Opportunity
**Validator Class**: OpportunityRiskValidator (handler pattern)
**Audit Object**: Log_Ajuste_Risco__c (immutable, insert-only)

## Key Clarifications Incorporated

### 1. Silent Revert Behavior
- System forces Probability=10% without error messages
- No exceptions thrown to user
- Better UX approach (Scenario D)

### 2. Non-Retroactive Enforcement
- Only applies on NEW inserts/updates after Account Risk changes
- Existing Opps with Prob>10% NOT retroactively capped
- Next update triggers the cap

### 3. Bypass Logic
- Profile: System Admin + custom permission "Manager_Risk_Bypass"
- Simplification: Any user with permission + Bypass_Risco__c=true can override
- Standard profile-based permission model

### 4. Audit Logging
- Log EVERY probability change (forced OR bypass)
- Reasons: SystemForced, UserBlocked, BypassApproved
- 7-year retention via custom object (source of truth, not native Audit Trail)
- Access via custom permission "View_Risk_Logs"

### 5. Performance Assumptions
- 500-2000 Opps per Account (peak)
- Bulk batches: 100-200 Opps
- Single Account query per batch (WITH SECURITY_ENFORCED)
- Logs inserted batch (1 DML, same transaction)

## Implementation Details

### Trigger Handler Flow
1. Query Account.Risk_Level__c (bulk, one query)
2. For each Opp:
   - Check if Account Risk = Crítico
   - Check if user has Manager_Risk_Bypass permission
   - Check if Bypass_Risco__c = true
   - Apply cap logic (silent revert if needed)
   - Track audit data
3. Batch insert all logs (synchronous, no async)

### Test Coverage Requirements
- 8 scenarios minimum
- 85%+ code coverage
- Bulk insert with 200 records
- Permission isolation (different users)

## Custom Objects & Fields

### Log_Ajuste_Risco__c Structure
- Oportunidade__c (Lookup, required)
- Probabilidade_Anterior__c (Percent, required)
- Probabilidade_Nova__c (Percent, required)
- Usuario__c (Lookup, required)
- Data_Ajuste__c (DateTime, required)
- Motivo_Ajuste__c (Picklist: SystemForced, UserBlocked, BypassApproved)

### Custom Permissions
- Manager_Risk_Bypass
- View_Risk_Logs

### Custom Field
- Opportunity.Bypass_Risco__c (Checkbox, default=false)
