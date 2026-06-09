# Salesforce Admin Agent Memory - ProjetoPricing Project

## Project Metadata Patterns

- **API Version:** 66.0 (standard for this project)
- **Project Structure:** force-app/main/default/ with organized object folders
- **Naming Convention:** Use `__c` suffix for custom objects/fields, underscore_case for API names
- **Deployment Approach:** Declarative-only (no Apex, no LWC) - all code work delegated to developer agents

## Successfully Created Metadata Components

### Sales Goal & Commission Tracking System (2026-06-08)

Created 4 custom objects with complete declarative configuration:

1. **Goal__c** (Parent) - 5 custom fields + page layout
   - Salesperson__c (Lookup User, required)
   - Year__c (Number 4,0, required)  
   - SalesValue__c (Currency 18,2)
   - CommissionPercentage__c (Roll-up Summary type, SUM aggregation)
   - CommissionValue__c (Formula Currency)

2. **GoalItem__c** (Child) - 10 custom fields + 4 record types + page layout
   - Goal__c (Master-Detail, required, not reparentable)
   - TargetValue__c (Currency 18,2, required)
   - ProjectedValue__c, NegotiatedValue__c, RealizedValue__c (Currency)
   - GoalCommissionPercentage__c (Percent 16,2, required)
   - AchievedPercentage__c (Percent 16,2, aggregated in roll-up)
   - TargetProduct__c, TargetProductFamily__c, TargetPaymentCondition__c (Lookups)

3. **ProductFamily__c** & **PaymentCondition__c** (Reference objects)
   - Simple name-only reference objects
   - Standard layouts with related lists

4. **Goal_Management** Permission Set
   - CRUD on all 4 objects
   - FLS: editable fields grant read+write, roll-up/formula fields read-only
   - Goal__c Master-Detail field set read-only (standard behavior)

## Critical Configuration Details

- **Roll-up Summary (CommissionPercentage__c):** Type=Summary (NOT Percent), SUM aggregation on AchievedPercentage__c via Goal__c→GoalItem__c Master-Detail
- **Formula Field (CommissionValue__c):** SalesValue__c * CommissionPercentage__c / 100, returns Currency
- **Master-Detail (Goal__c→GoalItem__c):** reparentableMasterDetail=false, cascade delete enabled (default), sharingModel=ControlledByParent on child
- **All Page Layouts:** Created in standard sections with all custom fields visible

## File Organization

All metadata stored in force-app/main/default/ following Salesforce source format:
- Objects in /objects/{ObjectName}__c/ folders
- Fields in /objects/{ObjectName}__c/fields/ subdirectories
- Record Types in /objects/{ObjectName}__c/recordTypes/ subdirectories
- Permission Sets in /permissionsets/ folder
- All files use .xml metadata format with API 66.0

## Deployment Sequence Pattern

For projects with dependent objects:
1. Reference objects first (no dependencies)
2. Parent objects (depend on standard objects only)
3. Child objects (depend on parent objects)
4. Security/Permissions last

This pattern ensures successful metadata deployment without dependency errors.
