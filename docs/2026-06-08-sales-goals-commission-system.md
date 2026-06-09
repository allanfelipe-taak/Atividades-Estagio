# Sales Goals and Commission Management System

**Task Date:** 2026-06-08  
**Status:** Completed and Deployed  
**Author:** Documentation Agent  
**Project:** ProjetoPricing Salesforce DX

---

## Overview

### Original Request
Create metadata for two custom objects (Goal__c and GoalItem__c) for managing sales goals and commissions, with calculated fields, record types, and reference objects.

### Business Objective
Implement a comprehensive sales goal and commission tracking system that enables:
- Sales managers and leadership to define annual sales goals by salesperson
- Tracking of goal performance across multiple dimensions (by product, product family, and payment condition)
- Automatic calculation of commission values based on achieved percentages
- Flexible goal item types to support different tracking scenarios

### Summary
This implementation creates a hierarchical goal-tracking system where a Sales Goal (Goal__c) contains multiple Goal Items (GoalItem__c) with different tracking dimensions. The system automatically aggregates achievement percentages and calculates commission values through roll-up summaries and formula fields, eliminating manual calculation errors.

---

## Components Created

### Admin Components (Declarative Metadata)

| Component | API Name | Label | Type | Description |
|-----------|----------|-------|------|-------------|
| Custom Object | `Goal__c` | Sales Goal | Custom Object | Parent object for annual sales goals |
| Custom Object | `GoalItem__c` | Goal Item | Custom Object | Child object for detailed goal line items |
| Custom Object | `ProductFamily__c` | Product Family | Custom Object (Reference) | Lookup reference for product family categorization |
| Custom Object | `PaymentCondition__c` | Payment Condition | Custom Object (Reference) | Lookup reference for payment condition categorization |
| Permission Set | `Goal_Management` | Goal Management | Permission Set | Full read/write access to goal objects with FLS controls |

### Field Definitions

#### Goal__c Object Fields

| Field API Name | Label | Type | Required | Description | Technical Details |
|---|---|---|---|---|---|
| `Name` | Goal Name | AutoNumber | - | System-generated identifier | Format: SG-{0000} |
| `Salesperson__c` | Salesperson | Lookup (User) | No* | Link to assigned salesperson | Filtered: IsActive = true; See Known Limitations |
| `Year__c` | Year | Number | Yes | Goal year (e.g., 2024, 2025) | Precision: 4, Scale: 0 |
| `SalesValue__c` | Sales Value | Currency | No | Total sales value target | Precision: 18, Scale: 2 |
| `CommissionPercentage__c` | Commission Percentage | Summary (Roll-up) | - | Aggregate of achieved percentages from child items | Formula: SUM of GoalItem__c.AchievedPercentage__c |
| `CommissionValue__c` | Commission Value | Formula (Currency) | - | Calculated commission value | Formula: `SalesValue__c * CommissionPercentage__c / 100` |

**Note on Required Field:** Salesperson__c is marked as not required (required=false). See "Known Limitations" section for context.

#### GoalItem__c Object Fields

| Field API Name | Label | Type | Required | Description | Technical Details |
|---|---|---|---|---|---|
| `Name` | Goal Item Name | AutoNumber | - | System-generated identifier | Format: GI-{0000000} |
| `Goal__c` | Goal | Master-Detail | Yes | Parent goal reference | Links to Goal__c; sharing model: ControlledByParent |
| `TargetValue__c` | Target Value | Currency | Yes | Target value for this item | Precision: 18, Scale: 2 |
| `ProjectedValue__c` | Projected Value | Currency | No | Expected value before negotiation | Precision: 18, Scale: 2 |
| `NegotiatedValue__c` | Negotiated Value | Currency | No | Value after negotiation | Precision: 18, Scale: 2 |
| `RealizedValue__c` | Realized Value | Currency | No | Actual value achieved | Precision: 18, Scale: 2 |
| `GoalCommissionPercentage__c` | Goal Commission Percentage | Percent | Yes | Commission percentage for this item | Precision: 16, Scale: 2 |
| `AchievedPercentage__c` | Achieved Percentage | Percent | No | Percentage of target actually achieved | Precision: 16, Scale: 2; Feeds into parent roll-up |
| `TargetProduct__c` | Target Product | Lookup (Product2) | No | Standard Salesforce product reference | Relates to standard Product2 object |
| `TargetProductFamily__c` | Target Product Family | Lookup (ProductFamily__c) | No | Custom product family reference | Relates to ProductFamily__c reference object |
| `TargetPaymentCondition__c` | Target Payment Condition | Lookup (PaymentCondition__c) | No | Custom payment condition reference | Relates to PaymentCondition__c reference object |

#### Record Types (GoalItem__c)

| Record Type | Active | Description |
|---|---|---|
| `Performance` | Yes | For tracking overall performance metrics |
| `Product` | Yes | For goal items targeting specific products |
| `ProductFamily` | Yes | For goal items targeting product families |
| `PaymentCondition` | Yes | For goal items targeting payment conditions |

#### Reference Objects

**ProductFamily__c**
- Label: Product Family
- Fields: Name (Text, required)
- Purpose: Enables GoalItem__c to categorize goals by custom product families

**PaymentCondition__c**
- Label: Payment Condition
- Fields: Name (Text, required)
- Purpose: Enables GoalItem__c to categorize goals by custom payment conditions

### Security Components

#### Permission Set: Goal_Management

**Overview:** Grants full CRUD access to the four goal-related objects with field-level security (FLS) controls.

**Object Permissions:**
- `Goal__c`: Create, Read, Edit, Delete (no ViewAll/ModifyAll)
- `GoalItem__c`: Create, Read, Edit, Delete (no ViewAll/ModifyAll)
- `ProductFamily__c`: Create, Read, Edit, Delete (no ViewAll/ModifyAll)
- `PaymentCondition__c`: Create, Read, Edit, Delete (no ViewAll/ModifyAll)

**Field-Level Security:**

| Object.Field | Readable | Editable | Rationale |
|---|---|---|---|
| `Goal__c.Salesperson__c` | Yes | Yes | User-editable lookup |
| `Goal__c.SalesValue__c` | Yes | Yes | User-editable target value |
| `Goal__c.CommissionPercentage__c` | Yes | No | Read-only roll-up summary |
| `Goal__c.CommissionValue__c` | Yes | No | Read-only calculated field |
| `GoalItem__c.AchievedPercentage__c` | Yes | Yes | User updates achievement |
| `GoalItem__c.GoalCommissionPercentage__c` | Yes | Yes | User sets commission rate |
| `GoalItem__c.NegotiatedValue__c` | Yes | Yes | User updates negotiated amount |
| `GoalItem__c.ProjectedValue__c` | Yes | Yes | User updates projected amount |
| `GoalItem__c.RealizedValue__c` | Yes | Yes | User updates realized amount |
| `GoalItem__c.TargetProduct__c` | Yes | Yes | User selects product lookup |
| `GoalItem__c.TargetProductFamily__c` | Yes | Yes | User selects product family lookup |
| `GoalItem__c.TargetPaymentCondition__c` | Yes | Yes | User selects payment condition lookup |

**Assignment Status:** Permission set assigned to user allanweb12@resilient-panda-2di41s.com via deployment.

---

## Data Flow and Architecture

### How It Works

```
1. GOAL CREATION
   User creates Goal__c record → Sets Salesperson, Year, SalesValue
   
2. GOAL ITEM ADDITION
   User creates GoalItem__c as child of Goal__c
   → Selects Record Type (Performance/Product/ProductFamily/PaymentCondition)
   → Enters TargetValue__c (required)
   → Sets GoalCommissionPercentage__c (required) - e.g., 5.5%
   → Optionally links to Product, ProductFamily, or PaymentCondition
   
3. GOAL TRACKING (Ongoing)
   User updates GoalItem__c fields as sales progress:
   → ProjectedValue__c: initial expectations
   → NegotiatedValue__c: after price negotiation
   → RealizedValue__c: final achieved value
   → AchievedPercentage__c: % of TargetValue achieved
   
4. AUTOMATIC AGGREGATION
   CommissionPercentage__c (on Goal__c) automatically:
   → Sums all AchievedPercentage__c from child GoalItems
   → Updates in real-time as items are modified
   
5. COMMISSION CALCULATION
   CommissionValue__c (on Goal__c) automatically:
   → Formula: SalesValue__c × CommissionPercentage__c ÷ 100
   → Displays final calculated commission amount
   → Updates whenever SalesValue or CommissionPercentage changes
```

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        GOAL__C (Parent)                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Fields:                                                  │  │
│  │  • Name (AutoNumber): SG-0001                           │  │
│  │  • Salesperson__c (Lookup User): John Doe              │  │
│  │  • Year__c (Number): 2025                              │  │
│  │  • SalesValue__c (Currency): 500,000.00                │  │
│  │                                                          │  │
│  │ ┌─ ROLL-UP SUMMARY ─────────────────────────────────┐ │  │
│  │ │ CommissionPercentage__c = SUM(                    │ │  │
│  │ │   AchievedPercentage__c from all children)        │ │  │
│  │ │                                                    │ │  │
│  │ │ Example: 25% (sum of 10% + 8% + 7%)              │ │  │
│  │ └────────────────────────────────────────────────────┘ │  │
│  │                                                          │  │
│  │ ┌─ FORMULA FIELD ───────────────────────────────────┐ │  │
│  │ │ CommissionValue__c =                              │ │  │
│  │ │   SalesValue__c × CommissionPercentage__c ÷ 100  │ │  │
│  │ │                                                    │ │  │
│  │ │ Example: 500,000 × 25 ÷ 100 = 125,000.00        │ │  │
│  │ └────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
│                            │                                    │
│                Master-Detail Relationship                       │
│                            │                                    │
│                  (Creates Parent-Child Link)                    │
│                            │                                    │
└─────────────────────────────────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌─────────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│  GOALITEM__C #1     │ │  GOALITEM__C #2  │ │  GOALITEM__C #3  │
│  (Performance)      │ │  (Product)       │ │  (ProductFamily) │
├─────────────────────┤ ├──────────────────┤ ├──────────────────┤
│ Name: GI-0000001    │ │ Name: GI-0000002 │ │ Name: GI-0000003 │
│ Goal: SG-0001       │ │ Goal: SG-0001    │ │ Goal: SG-0001    │
│ TargetValue: 250K   │ │ TargetValue: 150K│ │ TargetValue: 100K│
│ AchievedPerc: 10%   │ │ AchievedPerc: 8% │ │ AchievedPerc: 7% │
│ CommissionPerc: 5%  │ │ CommissionPerc:3%│ │ CommissionPerc:2%│
│ RecordType: Perf    │ │ TargetProduct: X │ │ TargetProdFam: Y │
├─────────────────────┤ ├──────────────────┤ ├──────────────────┤
│ Controls:           │ │ Controls:        │ │ Controls:        │
│ • Read-write        │ │ • Read-write     │ │ • Read-write     │
│ • Parent Goal is    │ │ • Parent Goal is │ │ • Parent Goal is │
│   mandatory         │ │   mandatory      │ │   mandatory      │
│ • Sharing:          │ │ • Sharing:       │ │ • Sharing:       │
│   ControlledByParent│ │   ControlledByParent
│                     │ │                  │ │   ControlledByParent
└─────────────────────┘ └──────────────────┘ └──────────────────┘
        │
        └──────────────────────────┬──────────────────────────────
                                   │
                           FEEDS ROLL-UP SUMMARY
                                   │
                        SUM = 10% + 8% + 7% = 25%
```

### Component Relationships

```
Goal__c (1) ────── Master-Detail ────── (Many) GoalItem__c
                   Mandatory                   Required field: Goal__c
                   No reparenting
                   ControlledByParent sharing

Goal__c             → (Optional) Salesperson__c (User Lookup)
GoalItem__c         → (Optional) TargetProduct__c (Product2 Lookup)
GoalItem__c         → (Optional) TargetProductFamily__c (ProductFamily__c Lookup)
GoalItem__c         → (Optional) TargetPaymentCondition__c (PaymentCondition__c Lookup)
```

---

## File Locations

| Component Type | Location | File Count |
|---|---|---|
| Objects (Metadata) | `force-app/main/default/objects/Goal__c/` | 1 (.object-meta.xml) |
| Objects (Metadata) | `force-app/main/default/objects/GoalItem__c/` | 1 (.object-meta.xml) |
| Objects (Metadata) | `force-app/main/default/objects/ProductFamily__c/` | 1 (.object-meta.xml) |
| Objects (Metadata) | `force-app/main/default/objects/PaymentCondition__c/` | 1 (.object-meta.xml) |
| Custom Fields (Goal__c) | `force-app/main/default/objects/Goal__c/fields/` | 5 (.field-meta.xml files) |
| Custom Fields (GoalItem__c) | `force-app/main/default/objects/GoalItem__c/fields/` | 10 (.field-meta.xml files) |
| Layouts | `force-app/main/default/layouts/` | 4 layout files |
| Permission Sets | `force-app/main/default/permissionsets/` | 1 (Goal_Management.permissionset-meta.xml) |

### Detailed File Paths

```
force-app/main/default/
├── objects/
│   ├── Goal__c/
│   │   ├── Goal__c.object-meta.xml
│   │   └── fields/
│   │       ├── Salesperson__c.field-meta.xml
│   │       ├── Year__c.field-meta.xml
│   │       ├── SalesValue__c.field-meta.xml
│   │       ├── CommissionPercentage__c.field-meta.xml
│   │       └── CommissionValue__c.field-meta.xml
│   ├── GoalItem__c/
│   │   ├── GoalItem__c.object-meta.xml
│   │   └── fields/
│   │       ├── Goal__c.field-meta.xml (Master-Detail)
│   │       ├── TargetValue__c.field-meta.xml
│   │       ├── ProjectedValue__c.field-meta.xml
│   │       ├── NegotiatedValue__c.field-meta.xml
│   │       ├── RealizedValue__c.field-meta.xml
│   │       ├── GoalCommissionPercentage__c.field-meta.xml
│   │       ├── AchievedPercentage__c.field-meta.xml
│   │       ├── TargetProduct__c.field-meta.xml
│   │       ├── TargetProductFamily__c.field-meta.xml
│   │       └── TargetPaymentCondition__c.field-meta.xml
│   ├── ProductFamily__c/
│   │   └── ProductFamily__c.object-meta.xml
│   └── PaymentCondition__c/
│       └── PaymentCondition__c.object-meta.xml
├── layouts/
│   ├── Goal__c-Goal Layout.layout-meta.xml
│   ├── GoalItem__c-Goal Item Layout.layout-meta.xml
│   ├── ProductFamily__c-Product Family Layout.layout-meta.xml
│   └── PaymentCondition__c-Payment Condition Layout.layout-meta.xml
└── permissionsets/
    └── Goal_Management.permissionset-meta.xml
```

---

## Configuration Details

### Goal__c Configuration

**Metadata Settings:**
- Label: Sales Goal
- Plural Label: Sales Goals
- API Name: Goal__c
- Sharing Model: ReadWrite (external sharing enabled)
- Enable Reports: Yes
- Enable Search: Yes
- Enable Feeds: No (activities only)
- Enable History: No

**Key Business Features:**
- AutoNumber name field formatted as "SG-{0000}" ensures human-readable identifiers
- Year field is required to enforce proper temporal organization
- Lookup to User with active filter ensures only active salespeople are assigned
- Search layouts include Year and SalesValue for quick list view analysis

### GoalItem__c Configuration

**Metadata Settings:**
- Label: Goal Item
- Plural Label: Goal Items
- API Name: GoalItem__c
- Sharing Model: ControlledByParent (inherits from Goal__c parent)
- Enable Reports: Yes
- Enable Search: Yes
- Enable Feeds: No (activities only)
- Enable History: No

**Record Type Configuration:**
All record types are active and required for different tracking scenarios:

1. **Performance:** Generic performance tracking across the entire goal
2. **Product:** Tracking goal achievement by specific product (uses TargetProduct__c lookup)
3. **ProductFamily:** Tracking goal achievement by product family (uses TargetProductFamily__c lookup)
4. **PaymentCondition:** Tracking goal achievement by payment condition (uses TargetPaymentCondition__c lookup)

**Key Business Features:**
- Master-Detail relationship ensures GoalItems cannot exist without a parent Goal
- AutoNumber format "GI-{0000000}" provides large sequence space for high-volume scenarios
- ControlledByParent sharing ensures security inheritance from parent Goal
- AchievedPercentage__c field explicitly supports decimal percentages (16,2 precision) for precise tracking

### Formula Field Logic: CommissionValue__c

```
Formula: SalesValue__c * CommissionPercentage__c / 100
Treatment: Treat blank values as zero

Example Calculation:
  SalesValue__c = 500,000.00 (user-entered)
  CommissionPercentage__c = 25.50 (automatically aggregated from children)
  
  CommissionValue__c = 500,000 × 25.50 ÷ 100 = 127,500.00
```

**Use Case:** Automatically calculates total commission amount to be paid to salesperson based on percentage of goals achieved.

### Roll-up Summary Configuration: CommissionPercentage__c

```
Type: Summary (Roll-up)
Summarized Field: GoalItem__c.AchievedPercentage__c
Operation: SUM
Foreign Key: GoalItem__c.Goal__c

Example Aggregation:
  GoalItem #1 AchievedPercentage = 10.00%
  GoalItem #2 AchievedPercentage = 8.50%
  GoalItem #3 AchievedPercentage = 7.25%
  
  CommissionPercentage__c = 10 + 8.5 + 7.25 = 25.75%
```

**Use Case:** Automatically aggregates achievement percentages from all child goal items, providing a single roll-up metric for commission calculation.

---

## Implementation Details

### Key Technical Decisions

#### 1. Master-Detail vs. Lookup for Goal Relationship
**Decision:** Master-Detail (Goal__c → GoalItem__c)

**Rationale:**
- Enforces parent-child relationship integrity (child cannot exist without parent)
- Enables automatic sharing inheritance via ControlledByParent
- Allows roll-up summaries on parent Goal__c
- Prevents accidental orphaning of goal items
- Simplifies data model hierarchy

#### 2. Roll-up Summary Type for CommissionPercentage__c
**Decision:** Summary field (type=Summary, operation=sum)

**Rationale:**
- Provides real-time aggregation without triggers or batch processes
- Handles large datasets efficiently
- Platform-native solution requiring no custom code
- Automatically handles new/updated/deleted child records

**Important Note:** CommissionPercentage__c is a Summary field (not a Percent field) because Salesforce does not support Percent-type roll-up summaries. The field stores the numeric sum directly (e.g., 25.75 for 25.75%).

#### 3. Formula Field for CommissionValue__c
**Decision:** Formula field with Currency type

**Rationale:**
- Automatic calculation eliminates manual entry errors
- Updates instantly when SalesValue or CommissionPercentage changes
- No trigger or process needed
- Precise currency handling with proper scale

#### 4. Reference Objects (ProductFamily__c, PaymentCondition__c)
**Decision:** Custom objects instead of picklists

**Rationale:**
- Allows dynamic management of product families and payment conditions
- Scalable to handle growing business requirements
- Enables reporting and filtering by these dimensions
- Supports lookups rather than maintaining hardcoded picklists

---

## Deployment Guide

### Prerequisites
- Salesforce org with API version 65.0 or higher
- User with admin privileges for permission set assignment
- Target user email: allanweb12@resilient-panda-2di41s.com

### Deployment Sequence

**Step 1: Deploy All Metadata**
```bash
sf project deploy start --source-dir force-app/main/default/objects/ProductFamily__c,force-app/main/default/objects/PaymentCondition__c,force-app/main/default/objects/Goal__c,force-app/main/default/objects/GoalItem__c,force-app/main/default/permissionsets/Goal_Management.permissionset-meta.xml,force-app/main/default/layouts
```

Expected outcome:
- 4 custom objects created/updated
- 15 custom fields created
- 4 page layouts created/updated
- 1 permission set created

**Step 2: Verify Deployment**
```bash
sf org display
```

**Step 3: Assign Permission Set to User**
```bash
sf org assign permset --name Goal_Management
```

This command automatically assigns the permission set to the org's default user. For alternative users:
```bash
sf org assign permset --name Goal_Management --target-org <org-alias> --on-behalf-of <username>
```

Or manually via Salesforce UI:
1. Navigate to Setup → Users
2. Select target user (allanweb12@resilient-panda-2di41s.com)
3. Click "Edit Assignments" in Permission Set Assignments section
4. Add "Goal_Management" permission set
5. Save

### Post-Deployment Validation

1. **Verify Object Creation:**
   - Setup → Objects and Fields → Objects
   - Confirm Goal__c, GoalItem__c, ProductFamily__c, PaymentCondition__c exist

2. **Verify Fields:**
   - Open Goal__c → Fields and Relationships
   - Verify all 5 fields present with correct types
   - Open GoalItem__c → Fields and Relationships
   - Verify all 10 fields present with correct types

3. **Verify Record Types:**
   - Setup → Objects and Fields → Record Types
   - Confirm 4 record types on GoalItem__c (Performance, Product, ProductFamily, PaymentCondition)

4. **Test Master-Detail Relationship:**
   - Create Goal record
   - Create GoalItem child record under Goal
   - Verify parent reference is mandatory and working

5. **Test Formulas and Roll-ups:**
   - Create Goal with SalesValue__c = 500,000.00
   - Create multiple GoalItems with AchievedPercentage values (e.g., 10%, 8%, 7%)
   - Verify CommissionPercentage__c auto-sums to 25.00%
   - Verify CommissionValue__c calculates to 125,000.00

6. **Verify Permission Set:**
   - Login as assigned user
   - Attempt CRUD operations on Goal__c and GoalItem__c (should succeed)
   - Verify CommissionPercentage__c and CommissionValue__c are read-only

---

## Known Limitations & Workarounds

### Limitation 1: Salesperson__c Lookup Not Required
**Issue:** The Salesperson__c field on Goal__c is marked as not required (required=false), even though the business logic expects it to always be assigned.

**Root Cause:** Salesforce's deployment restrictions for required Lookup fields referencing User. When deploying a required Lookup to User, specific deleteConstraint metadata is required, which caused deployment failures during implementation.

**Impact:** Users can create Goal records without assigning a salesperson.

**Recommended Workaround:**
1. **Option A (Admin Control):** Create a Validation Rule on Goal__c:
   ```
   Rule: ISBLANK(Salesperson__c)
   Error Message: "Salesperson is required for all Sales Goals"
   Condition: Trigger on create/edit
   ```
   This enforces the requirement at the data layer.

2. **Option B (User Experience):** Update the Goal Layout to display Salesperson__c prominently at the top of the form and include help text "Required field - must be assigned before saving."

3. **Option C (Future Fix):** In next deployment cycle, can be made required by adding proper deleteConstraint configuration to Salesperson__c.field-meta.xml.

### Limitation 2: CommissionPercentage__c as Summary Field (Not Percent)
**Issue:** CommissionPercentage__c is implemented as a Summary field of numeric type, not a Percent field, displaying values like "25.75" instead of "25.75%".

**Root Cause:** Salesforce does not support Percent-type roll-up summaries. Summary fields are restricted to numeric, currency, and count operations.

**Impact:** Field displays raw numbers (25.75 instead of 25.75%), requiring admin/user interpretation.

**Recommended Workaround:**
1. Add field help text: "Sum of percentages from Goal Items (e.g., 25.75 means 25.75%)"
2. Update page layout to include field description clarifying the display format
3. In reporting, create a formula field if percentage symbol formatting is needed: `TEXT(CommissionPercentage__c) & "%"`

### Limitation 3: No Automatic Commission Calculation at Item Level
**Issue:** Commission is calculated only at the Goal level (CommissionValue__c), not at individual GoalItem levels.

**Impact:** Cannot easily see item-level commission amounts without manual calculation.

**Recommended Future Enhancement:** Add formula field to GoalItem__c: `Goal__r.SalesValue__c * AchievedPercentage__c / 100`

---

## Security Considerations

### Sharing Model

**Goal__c:**
- Sharing Model: ReadWrite
- External Sharing: Enabled
- Admin users can share individually or via sharing rules
- Default: Only record owner can access (can be shared via sharing rules or manual share)

**GoalItem__c:**
- Sharing Model: ControlledByParent
- Parent: Goal__c
- GoalItem sharing automatically inherits from parent Goal
- No independent sharing configuration needed; access is controlled by parent Goal record

### Field-Level Security

The Goal_Management permission set controls access to sensitive fields:

**Read-Only Fields (for insight, no editing):**
- `CommissionPercentage__c` - Calculated roll-up, protected from manual editing
- `CommissionValue__c` - Calculated formula, protected from manual editing

**Editable Fields (for operational use):**
- All value fields (SalesValue, TargetValue, ProjectedValue, NegotiatedValue, RealizedValue)
- All reference lookups (Salesperson, TargetProduct, TargetProductFamily, TargetPaymentCondition)
- Achievement metrics (AchievedPercentage, GoalCommissionPercentage)

### SOQL and Data Access

When querying these objects programmatically, ensure proper use of sharing model:

**Goal__c Queries:**
```apex
// Respectful of sharing model (user sees only shared records)
List<Goal__c> goals = [SELECT Id, Name, SalesValue__c, CommissionValue__c FROM Goal__c];

// For admin reports bypassing sharing (use with caution)
List<Goal__c> allGoals = [SELECT Id, Name FROM Goal__c ALL ROWS];
```

**GoalItem__c Queries:**
Since GoalItem__c uses ControlledByParent, sharing is automatic:
```apex
// Only returns items whose parent Goal is accessible to user
List<GoalItem__c> items = [SELECT Id, TargetValue__c, AchievedPercentage__c FROM GoalItem__c];
```

### Required Permissions for Users

Users granted the Goal_Management permission set can:
- Create, read, edit, delete records in all 4 objects
- View and edit all explicitly listed fields
- Cannot edit CommissionPercentage__c or CommissionValue__c (read-only via FLS)

---

## Testing & Validation

### Test Scenarios

#### Scenario 1: Goal Creation and Field Visibility
1. Create a new Goal__c record
2. Verify Name auto-generates as SG-0001
3. Verify all required fields are marked as required
4. Verify optional fields are optional
5. Save record and verify successful creation

#### Scenario 2: Master-Detail Relationship
1. Create Goal record with SalesValue__c = 500,000
2. From Goal, create first GoalItem__c child
3. Verify Goal__c field is pre-populated in GoalItem
4. Verify Goal__c field cannot be changed to blank
5. Create additional GoalItems and verify all display in related list

#### Scenario 3: Roll-up Summary Aggregation
1. Create Goal with SalesValue__c = 500,000
2. Create GoalItem #1 with AchievedPercentage__c = 10.00%
3. Verify Goal.CommissionPercentage__c = 10.00
4. Create GoalItem #2 with AchievedPercentage__c = 8.50%
5. Verify Goal.CommissionPercentage__c = 18.50 (auto-updated)
6. Create GoalItem #3 with AchievedPercentage__c = 7.25%
7. Verify Goal.CommissionPercentage__c = 25.75 (auto-updated)

#### Scenario 4: Formula Field Calculation
1. Using scenario 3 state (CommissionPercentage = 25.75%)
2. Verify Goal.CommissionValue__c = 500,000 × 25.75 ÷ 100 = 128,750.00
3. Update Goal.SalesValue__c to 600,000
4. Verify CommissionValue__c auto-updates to 154,500.00 (600,000 × 25.75 ÷ 100)
5. Update GoalItem #1.AchievedPercentage to 12.00%
6. Verify Goal.CommissionPercentage__c = 27.75%
7. Verify Goal.CommissionValue__c = 166,500.00 (600,000 × 27.75 ÷ 100)

#### Scenario 5: Record Type Selection
1. Create GoalItem, choose Record Type = "Product"
2. Verify TargetProduct__c lookup appears and is usable
3. Create GoalItem, choose Record Type = "ProductFamily"
4. Verify TargetProductFamily__c lookup appears and is usable
5. Create GoalItem, choose Record Type = "PaymentCondition"
6. Verify TargetPaymentCondition__c lookup appears and is usable

#### Scenario 6: Lookup Filtering (Salesperson)
1. Create Goal and attempt to select inactive user in Salesperson__c
2. Verify inactive users do not appear in lookup dropdown (filtered by IsActive = true)
3. Verify only active users are available for selection

#### Scenario 7: Permission Set Access
1. Login as user with Goal_Management permission set
2. Navigate to Goal__c list - should have full CRUD access
3. Create new Goal record - should succeed
4. Edit Goal record - all fields should be editable except CommissionPercentage__c and CommissionValue__c
5. Attempt to edit CommissionPercentage__c or CommissionValue__c - should fail with "insufficient access" message
6. Navigate to GoalItem__c list - should have full CRUD access
7. Verify similar FLS restrictions on GoalItem fields

---

## Component Statistics

| Component Type | Count | Notes |
|---|---|---|
| Custom Objects | 4 | Goal__c, GoalItem__c, ProductFamily__c, PaymentCondition__c |
| Custom Fields | 15 | 5 on Goal__c, 10 on GoalItem__c |
| Master-Detail Relationships | 1 | Goal__c → GoalItem__c |
| Lookup Relationships | 6 | Salesperson, TargetProduct, TargetProductFamily, TargetPaymentCondition, plus standard refs |
| Roll-up Summaries | 1 | CommissionPercentage__c on Goal__c |
| Formula Fields | 1 | CommissionValue__c on Goal__c |
| Record Types | 4 | Performance, Product, ProductFamily, PaymentCondition (all on GoalItem__c) |
| Page Layouts | 4 | One per object |
| Permission Sets | 1 | Goal_Management |
| Field-Level Security Rules | 12 | Via Goal_Management permission set |
| **Total Metadata Components** | **38+** | Objects, fields, layouts, permission sets, and configurations |

---

## Change History

| Date | Author | Change | Status |
|---|---|---|---|
| 2026-06-08 | Salesforce Admin Agent | Initial deployment of 4 custom objects with 15 fields, 4 record types, layouts, and Goal_Management permission set | Deployed to org |
| 2026-06-08 | Documentation Agent | Created comprehensive documentation including architecture, configuration details, deployment guide, and known limitations | Completed |

---

## Appendix: Quick Reference

### Important Field Formulas and Aggregations

```
CommissionValue__c (Goal__c) = SalesValue__c * CommissionPercentage__c / 100
CommissionPercentage__c (Goal__c) = SUM(AchievedPercentage__c from all GoalItem__c children)
```

### Record Type Use Cases

| Record Type | Use Case | Primary Lookup |
|---|---|---|
| Performance | Track overall performance across all dimensions | None (generic) |
| Product | Analyze goal achievement by specific product | TargetProduct__c → Product2 |
| ProductFamily | Analyze goal achievement by product family | TargetProductFamily__c → ProductFamily__c |
| PaymentCondition | Analyze goal achievement by payment terms | TargetPaymentCondition__c → PaymentCondition__c |

### Common SOQL Queries

```apex
// Get all goals for a salesperson with commission calculation
SELECT Id, Name, Year__c, SalesValue__c, CommissionPercentage__c, CommissionValue__c 
FROM Goal__c 
WHERE Salesperson__c = :userId 
ORDER BY Year__c DESC;

// Get all goal items for a specific goal
SELECT Id, Name, TargetValue__c, RealizedValue__c, AchievedPercentage__c 
FROM GoalItem__c 
WHERE Goal__c = :goalId 
ORDER BY CreatedDate DESC;

// Aggregate commission value by salesperson and year
SELECT Salesperson__r.Name, Year__c, SUM(SalesValue__c), SUM(CommissionValue__c) 
FROM Goal__c 
WHERE Year__c = 2025 
GROUP BY Salesperson__r.Name, Year__c 
ORDER BY Year__c DESC;
```

### User Provisioning Checklist

- [x] Goal_Management permission set created
- [x] Permission set deployed to org
- [x] Permission set assigned to allanweb12@resilient-panda-2di41s.com
- [ ] Verify user can access Goal__c objects (post-deployment)
- [ ] Provide user training on Goal and GoalItem creation
- [ ] Document team-specific commission calculation policies

---

**Document Version:** 1.0  
**Last Updated:** 2026-06-08  
**Status:** Complete and Ready for Reference
