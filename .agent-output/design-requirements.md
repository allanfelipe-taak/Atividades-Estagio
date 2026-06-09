# DESIGN REQUIREMENTS: Sales Goal & Commission Tracking System

**Generated:** 2026-06-08  
**Project:** ProjetoPricing  
**API Version:** 66.0  
**Package Directory:** `force-app/main/default`

---

## EXECUTIVE SUMMARY

This design specifies the creation of a fully declarative Sales Goal and Commission Tracking system. Four custom objects will be created with supporting fields, relationships, and metadata. All work is administrative (no Apex, no LWC, no flows). Deployment follows a dependency-order sequence: parent objects first, child objects second, with Page Layout and Permission Set updates.

**Total Components:**
- 4 Custom Objects (Goal__c, GoalItem__c, ProductFamily__c, PaymentCondition__c)
- 9 Custom Fields (distributed across Goal__c and GoalItem__c)
- 4 Record Types (Performance, Product, ProductFamily, PaymentCondition)
- 2 Page Layouts (Goal__c, GoalItem__c)
- 1 Permission Set (Goal_Management)
- Multiple FLS configurations

---

## WHAT USER REQUESTED

User requested the creation of a complete Salesforce metadata structure for:
1. Goal__c object (Sales Goal) with commission calculation fields
2. GoalItem__c object (Goal Item) with performance tracking and lookup relationships
3. ProductFamily__c and PaymentCondition__c objects as supporting reference objects
4. All objects fully configured with Page Layouts and Permission Sets
5. Declarative implementation (admin work only, no code)
6. Immediate deployment upon completion

---

## OBJECT DEPENDENCY GRAPH

```
ProductFamily__c (standalone)
PaymentCondition__c (standalone)
Goal__c (parent, references User standard object)
  └─ GoalItem__c (child, Master-Detail to Goal__c + Lookups to Product2, ProductFamily__c, PaymentCondition__c)
```

**Deployment Order:**
1. ProductFamily__c (no dependencies)
2. PaymentCondition__c (no dependencies)
3. Goal__c (depends only on standard User object)
4. GoalItem__c (depends on Goal__c, Product2, ProductFamily__c, PaymentCondition__c)
5. Page Layouts & Permission Sets (after all objects exist)

---

## OBJECT 1: Goal__c (Sales Goal / Meta de Vendas)

### Metadata Files Required
- `Goal__c.object-meta.xml` — object definition with API version 66.0
- `Goal__c.layout-meta.xml` — page layout including all fields
- `Goal_Management.permset-meta.xml` — permission set with FLS

### Fields

| API Name | Label | Type | Properties | Required |
|----------|-------|------|-----------|----------|
| Salesperson__c | Salesperson | Lookup(User) | - | Yes |
| Year__c | Year | Number(4,0) | Decimal Places: 0 | Yes |
| SalesValue__c | Sales Value | Currency | Precision: 18, Scale: 2 | No |
| CommissionPercentage__c | Commission Percentage | Number(16,2) | Roll-up Summary, SUM aggregation of GoalItem__c.AchievedPercentage__c | No |
| CommissionValue__c | Commission Value | Formula(Currency) | Formula: `SalesValue__c * CommissionPercentage__c / 100` | No |

### Field Details

**Salesperson__c** (Lookup(User))
- Related List: "Salesperson Goals"
- Allow re-parenting: No
- Shows recent items: Yes
- Filter logic: (Not required—User object is global)

**Year__c** (Number(4,0))
- Range validation: 1900–2999 (recommended)
- Decimal Places: 0
- Used for filtering and reporting by year

**SalesValue__c** (Currency)
- Precision: 18, Scale: 2
- Required for commission calculation formula
- Stored in org currency

**CommissionPercentage__c** (Roll-up Summary)
- **CRITICAL:** Type is Number(16,2), NOT Percent
- Aggregation function: SUM
- Parent object: GoalItem__c
- Field to aggregate: AchievedPercentage__c (raw percent values from child records)
- Filter logic: None (sum all)
- **Note:** Salesforce does not allow roll-up summaries on Percent field type; sum of raw numeric values is used

**CommissionValue__c** (Formula — Currency)
- Formula: `SalesValue__c * CommissionPercentage__c / 100`
- Return type: Currency
- Decimal places: 2
- Calculated on save
- Read-only, non-editable

### Page Layout: Goal__c

**Standard Button Customization:**
- Include: New, Edit, Delete, Clone, Submit for Approval
- Remove: (none—all standard)

**Custom Buttons/Links:**
- (None requested)

**Field Organization:**
- **Section 1: Goal Details**
  - Salesperson__c
  - Year__c
  - SalesValue__c
- **Section 2: Commission Tracking**
  - CommissionPercentage__c (read-only)
  - CommissionValue__c (read-only)
- **Section 3: Related Lists**
  - Goal Items (related list from GoalItem__c)

### Record Types
- Goal__c uses the Master record type (default)
- No additional record types required for Goal__c

---

## OBJECT 2: GoalItem__c (Goal Item / Item da Meta)

### Metadata Files Required
- `GoalItem__c.object-meta.xml` — object definition with API version 66.0
- `GoalItem__c.layout-meta.xml` — page layout for all four record types
- Field definitions (separate .field-meta.xml files)

### Fields

| API Name | Label | Type | Properties | Record Types | Required |
|----------|-------|------|-----------|---------------|----------|
| Goal__c | Goal | Master-Detail(Goal__c) | Reparenting: No, Delete: Cascade | All | Yes |
| TargetValue__c | Target Value | Currency | Precision: 18, Scale: 2 | All | Yes |
| ProjectedValue__c | Projected Value | Currency | Precision: 18, Scale: 2 | All | No |
| NegotiatedValue__c | Negotiated Value | Currency | Precision: 18, Scale: 2 | All | No |
| RealizedValue__c | Realized Value | Currency | Precision: 18, Scale: 2 | All | No |
| GoalCommissionPercentage__c | Goal Commission Percentage | Percent(16,2) | Precision: 16, Scale: 2 | All | Yes |
| AchievedPercentage__c | Achieved Percentage | Percent(16,2) | Precision: 16, Scale: 2 | All | No |
| TargetProduct__c | Target Product | Lookup(Product2) | Related List: "Goal Items" (on Product2), Allow re-parenting: Yes | All | No |
| TargetProductFamily__c | Target Product Family | Lookup(ProductFamily__c) | Related List: "Goal Items" (on ProductFamily__c), Allow re-parenting: Yes | All | No |
| TargetPaymentCondition__c | Target Payment Condition | Lookup(PaymentCondition__c) | Related List: "Goal Items" (on PaymentCondition__c), Allow re-parenting: Yes | All | No |

### Field Details

**Goal__c** (Master-Detail(Goal__c))
- Parent object: Goal__c
- Reparenting allowed: No
- Child records cascade delete: Yes (delete Goal__c → all GoalItem__c deleted)
- Write permission: Controlled by parent object sharing
- Related list label on parent: "Goal Items"

**TargetValue__c** (Currency)
- Precision: 18, Scale: 2
- Represents the target currency value for this goal item
- Mandatory field

**ProjectedValue__c, NegotiatedValue__c, RealizedValue__c** (Currency)
- Precision: 18, Scale: 2
- ProjectedValue__c: Expected value before negotiation
- NegotiatedValue__c: Value after negotiation
- RealizedValue__c: Actual value achieved
- All optional fields for tracking variance

**GoalCommissionPercentage__c** (Percent(16,2))
- Precision: 16, Scale: 2
- Represents the commission percentage for this specific goal item
- **CRITICAL:** Type is Percent (NOT Number)—this is the raw value summed in Goal__c.CommissionPercentage__c
- Mandatory field
- User can enter values like 5.50 (representing 5.50%)

**AchievedPercentage__c** (Percent(16,2))
- Precision: 16, Scale: 2
- Represents the percentage of target value actually achieved
- This is the field aggregated into Goal__c.CommissionPercentage__c
- Optional field
- Calculated field or manually entered

**TargetProduct__c** (Lookup(Product2))
- Links to standard Product2 object
- Allows filtering goal items by product
- Optional, allows re-parenting
- Related list on Product2: "Goal Items"

**TargetProductFamily__c** (Lookup(ProductFamily__c))
- Links to custom ProductFamily__c object
- Allows filtering goal items by product family
- Optional, allows re-parenting
- Related list on ProductFamily__c: "Goal Items"

**TargetPaymentCondition__c** (Lookup(PaymentCondition__c))
- Links to custom PaymentCondition__c object
- Allows filtering goal items by payment condition
- Optional, allows re-parenting
- Related list on PaymentCondition__c: "Goal Items"

### Page Layout: GoalItem__c

Layout must support all four Record Types. Configure layout per record type or use a single layout.

**For all Record Types:**

**Section 1: Goal Information**
- Goal__c (Master-Detail lookup)
- TargetValue__c

**Section 2: Projected vs. Realized**
- ProjectedValue__c
- NegotiatedValue__c
- RealizedValue__c

**Section 3: Commission & Performance**
- GoalCommissionPercentage__c
- AchievedPercentage__c

**Section 4: Target Specification**
- TargetProduct__c
- TargetProductFamily__c
- TargetPaymentCondition__c

**Section 5: Related Lists**
- (None—GoalItem__c has no child objects)

**Standard Buttons:**
- Include: New, Edit, Delete, Clone
- Remove: (none)

### Record Types

| Record Type | API Name | Description | Availability |
|-------------|----------|-------------|---------------|
| Performance | Performance | Goal item tracking performance metrics | All users |
| Product | Product | Goal item for specific product target | All users |
| ProductFamily | ProductFamily | Goal item for product family target | All users |
| PaymentCondition | PaymentCondition | Goal item for payment condition target | All users |

**Implementation Notes:**
- No picklist controller field is required (all four record types are independent)
- If a picklist controller is desired in future, it can be added via admin actions without redesign
- All record types share the same fields; layout can be uniform or customized per type
- Default record type: Performance

### Compact Layouts
- Compact Layout (for Chatter, Mobile, etc.): Goal__c, TargetValue__c, AchievedPercentage__c

---

## OBJECT 3: ProductFamily__c (Product Family)

### Metadata Files Required
- `ProductFamily__c.object-meta.xml` — minimal object definition
- `ProductFamily__c.layout-meta.xml` — simple page layout

### Fields

| API Name | Label | Type | Properties | Required |
|----------|-------|------|-----------|----------|
| Name | Product Family Name | Text(255) | Unique: No | Yes |

### Details
- **Purpose:** Reference object for GoalItem__c lookups
- **Fields:** Only the standard Name field (auto-generated)
- **Record Types:** Master (default only)
- **Page Layout:**
  - Section: Basic Information
    - Name (editable)
  - Section: Related Lists
    - Goal Items (from GoalItem__c.TargetProductFamily__c)

### No custom fields, triggers, or validation rules required

---

## OBJECT 4: PaymentCondition__c (Payment Condition)

### Metadata Files Required
- `PaymentCondition__c.object-meta.xml` — minimal object definition
- `PaymentCondition__c.layout-meta.xml` — simple page layout

### Fields

| API Name | Label | Type | Properties | Required |
|----------|-------|------|-----------|----------|
| Name | Payment Condition Name | Text(255) | Unique: No | Yes |

### Details
- **Purpose:** Reference object for GoalItem__c lookups
- **Fields:** Only the standard Name field (auto-generated)
- **Record Types:** Master (default only)
- **Page Layout:**
  - Section: Basic Information
    - Name (editable)
  - Section: Related Lists
    - Goal Items (from GoalItem__c.TargetPaymentCondition__c)

### No custom fields, triggers, or validation rules required

---

## METADATA SUMMARY

### Files to Create

```
force-app/main/default/objects/

├── Goal__c/
│   ├── Goal__c.object-meta.xml
│   ├── fields/
│   │   ├── Salesperson__c.field-meta.xml
│   │   ├── Year__c.field-meta.xml
│   │   ├── SalesValue__c.field-meta.xml
│   │   ├── CommissionPercentage__c.field-meta.xml
│   │   └── CommissionValue__c.field-meta.xml
│   └── Goal__c.layout-meta.xml
│
├── GoalItem__c/
│   ├── GoalItem__c.object-meta.xml
│   ├── fields/
│   │   ├── Goal__c.field-meta.xml
│   │   ├── TargetValue__c.field-meta.xml
│   │   ├── ProjectedValue__c.field-meta.xml
│   │   ├── NegotiatedValue__c.field-meta.xml
│   │   ├── RealizedValue__c.field-meta.xml
│   │   ├── GoalCommissionPercentage__c.field-meta.xml
│   │   ├── AchievedPercentage__c.field-meta.xml
│   │   ├── TargetProduct__c.field-meta.xml
│   │   ├── TargetProductFamily__c.field-meta.xml
│   │   └── TargetPaymentCondition__c.field-meta.xml
│   ├── recordTypes/
│   │   ├── Performance.recordType-meta.xml
│   │   ├── Product.recordType-meta.xml
│   │   ├── ProductFamily.recordType-meta.xml
│   │   └── PaymentCondition.recordType-meta.xml
│   └── GoalItem__c.layout-meta.xml
│
├── ProductFamily__c/
│   ├── ProductFamily__c.object-meta.xml
│   └── ProductFamily__c.layout-meta.xml
│
└── PaymentCondition__c/
    ├── PaymentCondition__c.object-meta.xml
    └── PaymentCondition__c.layout-meta.xml

permissionsets/
├── Goal_Management.permset-meta.xml

profiles/
├── Admin.profile-meta.xml (update with FLS for new fields)
```

---

## FIELD-LEVEL SECURITY (FLS)

### Permission Set: Goal_Management

Grant CRUD on all Goal__c and GoalItem__c fields:

| Object | Field | Read | Create | Edit |
|--------|-------|------|--------|------|
| Goal__c | Salesperson__c | ✓ | ✓ | ✓ |
| Goal__c | Year__c | ✓ | ✓ | ✓ |
| Goal__c | SalesValue__c | ✓ | ✓ | ✓ |
| Goal__c | CommissionPercentage__c | ✓ | ✗ | ✗ |
| Goal__c | CommissionValue__c | ✓ | ✗ | ✗ |
| GoalItem__c | Goal__c | ✓ | ✓ | ✗ |
| GoalItem__c | TargetValue__c | ✓ | ✓ | ✓ |
| GoalItem__c | ProjectedValue__c | ✓ | ✓ | ✓ |
| GoalItem__c | NegotiatedValue__c | ✓ | ✓ | ✓ |
| GoalItem__c | RealizedValue__c | ✓ | ✓ | ✓ |
| GoalItem__c | GoalCommissionPercentage__c | ✓ | ✓ | ✓ |
| GoalItem__c | AchievedPercentage__c | ✓ | ✓ | ✓ |
| GoalItem__c | TargetProduct__c | ✓ | ✓ | ✓ |
| GoalItem__c | TargetProductFamily__c | ✓ | ✓ | ✓ |
| GoalItem__c | TargetPaymentCondition__c | ✓ | ✓ | ✓ |

**Notes:**
- CommissionPercentage__c and CommissionValue__c are read-only (system-calculated)
- Goal__c Master-Detail field is editable on create only (standard Master-Detail behavior)
- Goal_Management permission set will be assigned to all sales users and managers

---

## DEPLOYMENT SEQUENCE

### Phase 1: Reference Objects (No Dependencies)
1. Create ProductFamily__c object
2. Create PaymentCondition__c object
3. Deploy to org

### Phase 2: Parent Object
4. Create Goal__c object with all fields and formula
5. Create Goal__c page layout
6. Deploy to org

### Phase 3: Child Object & Relationships
7. Create GoalItem__c object with all fields
8. Create GoalItem__c page layout
9. Create four record types (Performance, Product, ProductFamily, PaymentCondition)
10. Deploy to org

### Phase 4: Security & Permissions
11. Create Goal_Management permission set with all FLS configurations
12. Update Admin profile with FLS (read/write on all fields)
13. Deploy to org
14. Assign Goal_Management permission set to users: `sf org assign permset --name Goal_Management`

### Phase 5: Validation
15. Verify all objects exist in org
16. Verify fields are present and configured correctly
17. Verify page layouts display all fields
18. Verify lookups resolve correctly
19. Verify Master-Detail relationship enforces cascade delete
20. Verify roll-up summary calculates correctly (Commission Percentage on Goal__c)

---

## CRITICAL IMPLEMENTATION NOTES

### CommissionPercentage__c (Roll-up Summary)
- **Type:** Number(16,2), NOT Percent
- **Parent:** GoalItem__c
- **Field Aggregated:** AchievedPercentage__c
- **Aggregation Function:** SUM
- **Reason:** Salesforce does not support roll-up summaries on Percent field type; sum of raw numeric values is used instead

### CommissionValue__c (Formula)
- **Formula:** `SalesValue__c * CommissionPercentage__c / 100`
- **Return Type:** Currency
- **Behavior:** Auto-calculated on save; read-only in UI

### Master-Detail Relationship (Goal__c → GoalItem__c)
- Enables roll-up summary on Goal__c
- Enforces cascade delete: Deleting Goal__c deletes all GoalItem__c records
- Child records inherit sharing from parent
- Cannot be re-parented by design

### Lookups (Optional)
- TargetProduct__c, TargetProductFamily__c, TargetPaymentCondition__c are optional
- Allow re-parenting (users can change lookup values)
- No cascade delete (orphaned records remain if lookup is cleared)

### Page Layouts
- All custom fields must be included in the main section of page layouts
- Layouts must be created for Goal__c and GoalItem__c before users access the objects
- Compact Layout should include key fields for mobile and Chatter

### Permission Set Assignment
- After deployment, assign Goal_Management to all sales users and managers
- Command: `sf org assign permset --name Goal_Management`
- Admin profile is updated automatically with full read/write access

---

## TESTING CHECKLIST (For Admin Post-Deployment)

- [ ] ProductFamily__c created and accessible
- [ ] PaymentCondition__c created and accessible
- [ ] Goal__c created with all 5 fields
- [ ] GoalItem__c created with all 10 fields
- [ ] Master-Detail relationship works (GoalItem__c.Goal__c requires parent Goal__c)
- [ ] Roll-up summary calculates (Goal__c.CommissionPercentage__c sums AchievedPercentage__c)
- [ ] Formula field calculates (Goal__c.CommissionValue__c = SalesValue__c * CommissionPercentage__c / 100)
- [ ] All four Record Types visible on GoalItem__c
- [ ] Page Layouts display all fields for both objects
- [ ] Goal_Management permission set grants read/write on all fields
- [ ] Admin profile has read/write on all fields
- [ ] Lookups resolve to Product2, ProductFamily__c, PaymentCondition__c
- [ ] Cascade delete works (delete Goal__c → all GoalItem__c deleted)
- [ ] Picklist values for GoalItem__c record types show correctly in "New" button

---

## SUCCESS CRITERIA

Deployment is complete when:

1. All four custom objects exist in the org
2. All fields are present with correct types and configurations
3. Page Layouts include all fields in visible sections
4. Goal_Management permission set is created with appropriate FLS
5. Permission set is assigned to intended users
6. Roll-up summary on Goal__c.CommissionPercentage__c calculates correctly
7. Formula on Goal__c.CommissionValue__c calculates correctly
8. Master-Detail relationship enforces cascade delete
9. All lookups resolve correctly
10. Users can create and edit Goal and GoalItem records without permission errors

---

## FILES TO DELIVER

Upon completion, the following files are created in `force-app/main/default/`:

- **Objects:** Goal__c/, GoalItem__c/, ProductFamily__c/, PaymentCondition__c/
- **Permission Set:** permissionsets/Goal_Management.permset-meta.xml
- **Profile Update:** profiles/Admin.profile-meta.xml (if applicable)

All files follow Salesforce metadata format (XML) with API version 66.0.

---

**Document Status:** Ready for Admin Implementation  
**Next Step:** Invoke salesforce-admin subagent with the prompt below

---

# PROMPT FOR salesforce-admin

```
PROJECT CONTEXT:
- API Version: 66.0
- Package Directory: force-app/main/default
- All work is declarative (no code, no Apex, no LWC)
- Deployment will follow the sequence specified in the design document
- Do NOT deploy to org yet — create metadata files only

CRITICAL REQUIREMENTS:
1. CommissionPercentage__c on Goal__c is a Roll-up Summary (NOT Percent field type), SUM of GoalItem__c.AchievedPercentage__c
2. CommissionValue__c on Goal__c is a Formula (Currency): SalesValue__c * CommissionPercentage__c / 100
3. Goal__c → GoalItem__c is Master-Detail (cascade delete enabled)
4. All four Record Types on GoalItem__c (Performance, Product, ProductFamily, PaymentCondition) must exist
5. ProductFamily__c and PaymentCondition__c are reference objects with only a Name field (text)
6. All page layouts must include all custom fields in visible sections
7. Goal_Management permission set must grant read/write on all fields (except roll-up and formula fields which are read-only)

SCOPE:

OBJECT 1: Goal__c (Sales Goal / Meta de Vendas)
Fields to create:
- Salesperson__c: Lookup(User), required
- Year__c: Number(4,0), required
- SalesValue__c: Currency, optional
- CommissionPercentage__c: Roll-up Summary Number(16,2), aggregates GoalItem__c.AchievedPercentage__c with SUM function
- CommissionValue__c: Formula(Currency) = SalesValue__c * CommissionPercentage__c / 100

Page Layout Goal__c:
- Section 1 (Goal Details): Salesperson__c, Year__c, SalesValue__c
- Section 2 (Commission Tracking): CommissionPercentage__c, CommissionValue__c (both read-only)
- Section 3 (Related Lists): Goal Items

OBJECT 2: GoalItem__c (Goal Item / Item da Meta)
Fields to create:
- Goal__c: Master-Detail(Goal__c), required, cascade delete enabled
- TargetValue__c: Currency(18,2), required
- ProjectedValue__c: Currency(18,2), optional
- NegotiatedValue__c: Currency(18,2), optional
- RealizedValue__c: Currency(18,2), optional
- GoalCommissionPercentage__c: Percent(16,2), required
- AchievedPercentage__c: Percent(16,2), optional (this is the field aggregated into Goal__c.CommissionPercentage__c)
- TargetProduct__c: Lookup(Product2), optional, allow re-parenting
- TargetProductFamily__c: Lookup(ProductFamily__c), optional, allow re-parenting
- TargetPaymentCondition__c: Lookup(PaymentCondition__c), optional, allow re-parenting

Record Types to create:
- Performance (default)
- Product
- ProductFamily
- PaymentCondition

Page Layout GoalItem__c (same for all record types):
- Section 1 (Goal Information): Goal__c, TargetValue__c
- Section 2 (Projected vs. Realized): ProjectedValue__c, NegotiatedValue__c, RealizedValue__c
- Section 3 (Commission & Performance): GoalCommissionPercentage__c, AchievedPercentage__c
- Section 4 (Target Specification): TargetProduct__c, TargetProductFamily__c, TargetPaymentCondition__c

OBJECT 3: ProductFamily__c (Product Family) - Reference Object
Fields:
- Name: Text(255) — standard field only

Page Layout ProductFamily__c:
- Section 1 (Basic Information): Name
- Section 2 (Related Lists): Goal Items

OBJECT 4: PaymentCondition__c (Payment Condition) - Reference Object
Fields:
- Name: Text(255) — standard field only

Page Layout PaymentCondition__c:
- Section 1 (Basic Information): Name
- Section 2 (Related Lists): Goal Items

PERMISSION SET: Goal_Management
Create permission set with read/write access to:
- Goal__c: Salesperson__c, Year__c, SalesValue__c (CommissionPercentage__c and CommissionValue__c read-only)
- GoalItem__c: All fields except Cascade Delete is enforced by Master-Detail relationship

FLS Permissions:
- CommissionPercentage__c (Goal__c): Read only
- CommissionValue__c (Goal__c): Read only
- Goal__c (GoalItem__c): Create/Read allowed, Edit NOT allowed (Master-Detail)
- All other fields: Create/Read/Edit allowed

DEPLOYMENT SEQUENCE:
1. Create ProductFamily__c object with layout
2. Create PaymentCondition__c object with layout
3. Create Goal__c object with all 5 fields and layout
4. Create GoalItem__c object with all 10 fields, 4 record types, and layout
5. Create Goal_Management permission set with FLS
6. Update Admin profile with FLS (if needed)

VALIDATION AFTER CREATION (before deployment):
- Verify all object metadata files are created in force-app/main/default/objects/
- Verify Goal__c layout includes all fields in sections
- Verify GoalItem__c layout includes all fields and supports all record types
- Verify CommissionPercentage__c is configured as Roll-up Summary with SUM aggregation
- Verify CommissionValue__c formula is correct: SalesValue__c * CommissionPercentage__c / 100
- Verify Master-Detail relationship on Goal__c → GoalItem__c
- Verify all lookups are properly configured

OUTPUT:
- Create all metadata files in force-app/main/default/ following Salesforce XML format
- Metadata API version: 66.0
- Do NOT run any deployment commands (sf project deploy, etc.)
- Do NOT assign permission sets
- Save all files to the local file system only

COMPLETION CHECKLIST:
- [ ] ProductFamily__c object created with object-meta.xml and layout
- [ ] PaymentCondition__c object created with object-meta.xml and layout
- [ ] Goal__c object created with 5 fields, layout, and page layout
- [ ] GoalItem__c object created with 10 fields, 4 record types, and layout
- [ ] Goal_Management permission set created with FLS
- [ ] All files use API version 66.0
- [ ] CommissionPercentage__c configured as Roll-up Summary (Number type, SUM)
- [ ] CommissionValue__c configured as Formula (Currency)
- [ ] Master-Detail relationship created with cascade delete
- [ ] All page layouts include all custom fields in visible sections
- [ ] All files saved to force-app/main/default/
```

---

CONFIRMATION GATE:
After the Admin Agent completes, you will receive the metadata files. Review them to ensure:
1. All objects exist
2. All fields are present with correct types
3. Page layouts include all fields
4. Roll-up and formula fields are correctly configured
5. Master-Detail relationship is enabled
6. Permission set has appropriate FLS

Once confirmed, proceed to deployment with salesforce-devops agent.
