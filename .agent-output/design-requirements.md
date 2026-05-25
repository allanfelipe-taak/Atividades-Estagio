# PROJECT TRANSLATION DESIGN REQUIREMENTS

**Date:** 2026-05-20  
**Project:** ProjetoPricing (Salesforce DX)  
**Scope:** Internationalization - Portuguese to English  
**Complexity:** HIGH RISK  
**Design Status:** PENDING USER CONFIRMATION

---

## EXECUTIVE SUMMARY

This project requires translating **17 custom objects, 12 tabs, 29 Apex classes, 5 triggers, 1 LWC component, plus all related metadata** from Portuguese to English. This is a **structural refactoring** that will impact:
- Salesforce metadata (object/field API names, layout references, permission assignments)
- Codebase structure (class names, folder organization, handler names)
- Data integrity (potential data loss if object API names are renamed without migration)
- Org dependencies (any formulas, workflows, flows, or external integrations referencing Portuguese API names)

**Critical Risk:** Renaming custom object API names is NOT a safe in-place operation in Salesforce. The metadata API does not support renaming object API names. This requires either:
1. Recreating objects (data loss) or
2. Executing a careful data migration strategy

---

## WHAT USER REQUESTED

"Transform the entire project into English — tabs, objects, classes, everything. Comments in Portuguese can stay in Portuguese."

**Scope as stated:**
- Translate all visible names to English (UI labels, API names, class names)
- Keep Portuguese comments in code files
- Apply to all components: objects, fields, classes, triggers, LWC, tabs, metadata

---

## INVENTORY OF COMPONENTS TO TRANSLATE

### Custom Objects (17 total)
**Portuguese → Proposed English:**
- Centro_Distribuicao__c → DistributionCenter__c
- Cidade__c → City__c
- Condicao_Pagamento__c → PaymentCondition__c (or PaymentTerm__c)
- Endereco__c → Address__c
- Estado__c → State__c
- Frete__c → Freight__c (or Shipping__c)
- Grupo_de_Conta__c → AccountGroup__c
- Hierarquia_de_Produto__c → ProductHierarchy__c
- Imposto__c → Tax__c
- IntegrationLog__c → (Already English)
- IntegrationSetting__c → (Already English)
- Margem__c → Margin__c
- Pais__c → Country__c
- Plus standard objects: Order, OrderItem, Product2, PricebookEntry (unchanged)

### Custom Fields (estimated 50+)
Fields in custom objects, all with Portuguese names:
- Categoria__c, Valor__c, Produto__c, Status__c, etc.
Example: Categoria__c → Category__c, Valor__c → Value__c

### Tabs (12 total)
All custom object tabs, named after objects:
- Frete__c.tab-meta.xml → Freight__c.tab-meta.xml
- Margem__c.tab-meta.xml → Margin__c.tab-meta.xml
- (etc. - one per custom object)

### Apex Classes (29 total)
**Portuguese class names that must be renamed:**
- FreteHandler.cls → FreightHandler.cls (or ShippingHandler.cls)
- ImpostoHandler.cls → TaxHandler.cls
- MargemHandler.cls → MarginHandler.cls
- ContratoTrigger.cls → (in Shared/Interfaces - context unclear, needs clarification)

**Already-English classes (no change needed):**
- PricingService.cls, OrderHandler.cls, OrderItemHandler.cls
- IntegrationLog.cls, IntegrationUtils.cls, etc.
- All Integration/* classes

### Triggers (5 total)
**Portuguese trigger names:**
- FreteTrigger.trigger → FreightTrigger.trigger
- ImpostoTrigger.trigger → TaxTrigger.trigger
- MargemTrigger.trigger → MarginTrigger.trigger
- OrderTrigger.trigger, OrderItemTrigger.trigger (already English, no change)

### Lightning Web Components (1 total)
- recalcularPricing → (Portuguese word: recalcularPricing = "recalculate pricing")
  Proposed: recalculatePricing (LWC naming usually camelCase, already English-ish)

### Page Layouts (12+)
- Frete__c-Frete Layout.layout-meta.xml → Freight__c-Freight Layout.layout-meta.xml
- (All layouts referencing Portuguese object names must be renamed)

### Other Metadata
- Flexipages, Permission Sets, List Views, etc.
- All references to Portuguese object/field API names must be updated

---

## CRITICAL RISKS & CONSTRAINTS

### Risk 1: Object API Name Renaming (HIGHEST)
**Problem:** Salesforce metadata API does NOT support renaming custom object API names.

**Impact:**
- Cannot simply rename Centro_Distribuicao__c → DistributionCenter__c in-place
- Existing data under the old object name will become inaccessible if object is deleted
- Any external integrations, formulas, or reports referencing old API names will break

**Solutions (User must choose):**
1. **Data Migration Path** (Recommended if data exists in org):
   - Create new objects with English API names
   - Migrate data from old objects to new objects
   - Update all relationships (lookups, master-detail)
   - Delete old objects
   - Update all references in metadata, code, and formulas
   - **Timeline:** High effort, 2-3x complexity

2. **Org Rebuild** (If org is empty or dev-only):
   - Delete existing custom objects (data loss acceptable)
   - Recreate objects with English API names
   - Deploy metadata, code, and relationships fresh
   - **Timeline:** Moderate effort, lower complexity

### Risk 2: Field API Name Renaming
**Problem:** Same as objects — cannot rename in-place.

**Impact:**
- All field lookups, master-detail relationships, and formula references will break
- Page layouts must be regenerated
- Permission sets must be updated

### Risk 3: Code Cross-References
**Problem:** Apex code contains hardcoded references to object/field API names.

**Impact:**
- `SOQL` queries: `SELECT Categoria__c FROM Frete__c WHERE Valor__c > 100`
- Handler methods: `FreteHandler.handle(Frete__c record)`
- Integration mappings, data factories, test fixtures

**Must be updated:** Every SOQL query, every string literal, every method signature

### Risk 4: Metadata Cross-References
**Problem:** Metadata files contain hardcoded references to object/field API names.

**Impact:**
- Page layouts reference field API names in `<fields>` elements
- Validation rules reference object/field API names
- Flows, workflows, and assignments reference API names
- Permission sets enumerate object/field access by API name

**Must be updated:** All metadata XML files

### Risk 5: External Integrations
**Problem:** If this org is integrated with external systems, those systems may hardcode API name references.

**Impact:**
- REST/SOAP APIs may expect `Frete__c` in payloads
- Data integrations may map to old field names
- Any webhook or external callout expecting specific field names will fail

**Solution:** Coordinate with external system owners; may require dual deployment (accept both old and new names during transition)

### Risk 6: Ambiguous Translation Terms
**Problem:** Some Portuguese terms have multiple valid English translations.

**Clarification needed from user:**
- `Frete__c` → "Freight" or "Shipping"?
- `Condicao_Pagamento__c` → "PaymentCondition" or "PaymentTerm"?
- `Margem__c` → "Margin" (as in profit margin) or something else?
- `Imposto__c` → "Tax" (standard in pricing)
- `ContratoTrigger` → "ContractTrigger"? (What is this interface for? Context unclear.)

---

## SCOPE OPTIONS FOR USER TO CHOOSE

### Option A: FULL TRANSLATION (Highest Risk, Highest Effort)
**What gets renamed:**
- All custom object API names (Centro_Distribuicao__c → DistributionCenter__c, etc.)
- All custom field API names
- All class names (FreteHandler → FreightHandler, etc.)
- All trigger names
- All tab names
- All metadata references
- All SOQL and string literals in code

**Effort:** ~150-200 hours of work across:
- Admin agent: Recreate 17 objects + 50+ fields + layouts + permission sets
- Developer agent: Rename/update 29 classes, 5 triggers, 1 LWC, all SOQL queries
- Unit testing agent: Update all test data factories, mocks, fixtures
- Code review: Full regression testing required
- DevOps: Plan data migration strategy (if org has data)

**Risk:** HIGH (data loss possible, external integrations will break)

**Prerequisite:** User must confirm:
1. Is the org empty (dev-only) or does it have production data?
2. Are there external integrations that depend on Portuguese API names?
3. Are you prepared for a potential rollback/retry cycle?

---

### Option B: SELECTIVE TRANSLATION (Medium Risk, Medium Effort)
**What gets renamed:**
- Apex class names only (FreteHandler → FreightHandler)
- Trigger names only (FreteTrigger → FreightTrigger)
- LWC names and internal code comments
- Tab UI labels (in .tab-meta.xml `<label>` field, not API name)
- **KEEP unchanged:**
  - Custom object API names (Centro_Distribuicao__c stays as-is)
  - Custom field API names (all fields keep Portuguese API names)
  - Page layouts (no rename, just update if class names change)
  - Permission sets (reference Portuguese object/field names, no change needed)

**UI behavior:** Users see English tab names and English object labels, but object/field API names remain Portuguese (developers see it in Inspector/logs)

**Effort:** ~40-60 hours across:
- Developer agent: Rename 15-20 classes/triggers, update SOQL queries
- Unit testing: Update test class names and fixtures
- Code review: Verify SOQL still works
- DevOps: Deploy only Apex + triggers (no metadata changes)

**Risk:** MEDIUM (safer, code-focused, no data migration)

**Tradeoff:** "Under the hood" is still Portuguese; full translation is not achieved

---

### Option C: MINIMAL TRANSLATION (Low Risk, Low Effort) — NOT RECOMMENDED
**What gets renamed:**
- UI labels only (object labels, field labels, tab labels)
- **KEEP unchanged:**
  - All API names (objects, fields, classes, everything)
  - All code (Apex stays as-is)

**UI behavior:** Users see English, developers see Portuguese everywhere

**Effort:** ~10-15 hours (admin-only work, update label fields in metadata XML)

**Risk:** LOW (safe, reversible)

**Tradeoff:** Project is NOT truly "transformed to English" — only surface-level cosmetic change. Internal naming remains Portuguese, confusing for new developers.

---

## PROPOSED NAMING MAP

**User must confirm these translations before implementation:**

### Objects
| Portuguese | English | Field/API |
|-----------|---------|-----------|
| Centro_Distribuicao__c | DistributionCenter__c | API Name |
| Cidade__c | City__c | API Name |
| Condicao_Pagamento__c | PaymentCondition__c | API Name (confirm: PaymentTerm vs Condition?) |
| Endereco__c | Address__c | API Name |
| Estado__c | State__c | API Name |
| Frete__c | **[CONFIRM: Freight or Shipping?]**__c | API Name |
| Grupo_de_Conta__c | AccountGroup__c | API Name |
| Hierarquia_de_Produto__c | ProductHierarchy__c | API Name |
| Imposto__c | Tax__c | API Name |
| Margem__c | Margin__c | API Name |
| Pais__c | Country__c | API Name |

### Apex Classes (Sample)
| Portuguese | English |
|-----------|---------|
| FreteHandler.cls | **[CONFIRM: FreightHandler or ShippingHandler?]** |
| ImpostoHandler.cls | TaxHandler.cls |
| MargemHandler.cls | MarginHandler.cls |
| ContratoTrigger.cls | ContractTrigger.cls (or clarify purpose?) |
| Other classes already English — no change |

### Triggers
| Portuguese | English |
|-----------|---------|
| FreteTrigger.trigger | FreightTrigger.trigger (or ShippingTrigger?) |
| ImpostoTrigger.trigger | TaxTrigger.trigger |
| MargemTrigger.trigger | MarginTrigger.trigger |

### Fields (Sample — many more)
All field API names would follow pattern:
- Categoria__c → Category__c
- Valor__c → Value__c
- Produto__c → Product__c
- Status__c → Status__c (already English)

---

## ADMIN vs DEVELOPMENT SPLIT

### **ADMIN WORK** (salesforce-admin)
Only if **Option A** (Full Translation) is chosen:

1. Create 17 new custom objects with English API names (all fields, relationships, lookups)
2. Create 50+ custom fields on those objects with English API names
3. Update all page layouts to reference new field API names
4. Update all permission sets to grant access to new object/field API names
5. Create all tabs for new objects
6. Update any validation rules, formulas, or field dependencies

**If Option B or C:** Only update UI labels in existing metadata (minimal admin work)

### **DEVELOPMENT WORK** (salesforce-developer + salesforce-unit-testing)

For **Option A:**
1. Rename all Apex classes (29 files)
2. Rename all triggers (5 files)
3. Update all SOQL queries to use new object/field API names
4. Update all test data factories (FactoryDataIntegration, TestFactorySObject, etc.)
5. Update all mock data and fixtures
6. Rename class method signatures that reference Portuguese object names
7. Update LWC component names and any hardcoded API references
8. Create new test classes (if broken by renames)

For **Option B:**
1. Rename class files (FreteHandler → FreightHandler, etc.)
2. Rename trigger files
3. Update internal class/method names to English
4. Keep SOQL queries as-is (still reference Portuguese object/field names)
5. Update test class names and factories

For **Option C:**
No development work — only admin updates to XML labels.

---

## EXECUTION ORDER (If Option A - Full Translation)

1. **DESIGN CONFIRMATION** (Gate 1)
   - User confirms scope (A, B, or C)
   - User confirms naming map (Freight vs Shipping, etc.)
   - User confirms data migration readiness

2. **ADMIN** (if Option A)
   - Create new objects with English API names
   - Create all new fields
   - Create layouts, tabs, permission sets
   - (Do NOT delete old objects yet)

3. **DATA MIGRATION** (if org has data)
   - Create migration plan
   - Execute data transfer from old objects to new objects
   - Validate data integrity
   - Confirm all relationships migrated

4. **DEVELOPER**
   - Rename all classes, triggers, LWC
   - Update all SOQL queries to new API names
   - Update test data factories
   - Update configuration/integration mappings

5. **UNIT TESTING**
   - Create/update test classes
   - Test all handler triggers
   - Test all SOQL queries
   - Test data factories

6. **CODE REVIEW**
   - Verify all references updated
   - Check for any missed Portuguese API name references
   - Validate test coverage

7. **DEVOPS** (with safeguards)
   - Deploy admin metadata (new objects, layouts, permission sets)
   - Deploy all Apex/trigger code
   - Execute data migration scripts (if applicable)
   - Perform smoke tests
   - Delete old objects (if migration successful)

8. **DOCUMENTATION**
   - Document translation mapping
   - Update any developer guides referencing old API names
   - Record migration steps for future reference

---

## CLARIFYING QUESTIONS FOR USER

**You MUST answer these before we proceed:**

### Scope & Risk Acceptance
1. **Which scope option do you choose?**
   - Option A: Full translation (objects, fields, classes — HIGH RISK)
   - Option B: Classes & triggers only (MEDIUM RISK)
   - Option C: UI labels only (LOW RISK)

2. **Does your Salesforce org currently contain data?**
   - Empty/development org? (Easier, can delete old objects)
   - Production or test org with data? (Requires careful migration)

3. **Are there external systems integrated with this org?**
   - REST APIs expecting Portuguese field names?
   - Data integrations with hardcoded field mappings?
   - Webhooks or callouts referencing API names?

### Translation Decisions
4. **For ambiguous terms, which do you prefer?**
   - `Frete__c` → "Freight" or "Shipping"?
   - `Condicao_Pagamento__c` → "PaymentCondition" or "PaymentTerm"?
   - `ContratoTrigger` → What is this interface? (Purpose/context for naming)

5. **For class names like `FreteHandler`:**
   - Should it follow the object name? (FreightHandler)
   - Or use industry-standard name? (ShippingHandler, which may be clearer)

### Rollback & Contingency
6. **Do you have a backup/snapshot of your org before we start?**
   - Recommending you take a snapshot before any changes

7. **If something goes wrong mid-migration, are you okay with:**
   - Rolling back and re-attempting?
   - Possible downtime to recreate objects?
   - Redeploying all Apex code?

---

## DESIGN STATUS

**This design is PENDING your answers to the clarifying questions above.**

Once you provide:
1. Scope choice (A, B, or C)
2. Translation preferences (Freight vs Shipping, etc.)
3. Risk acceptance confirmation
4. Data status confirmation

Then I will invoke the specialist agents in the correct order and produce the full implementation.

---

## FILES INVOLVED

**Total components to translate:**
- 17 custom objects
- 12 tabs
- ~50+ custom fields
- 1 page layout (per object, ~12-15 layouts)
- 2 permission sets (estimated)
- 29 Apex classes
- 5 triggers
- 1 LWC component
- Various flexipages, list views, etc.

**Estimated total files to change: 150-200 metadata/code files**

---

## NEXT STEPS

1. **User responds** to the 7 clarifying questions above
2. **Design agent confirms** scope and naming map
3. **Gate 1 Confirmation:** User approves finalized design
4. **Specialist agents invoked** in order:
   - Admin (if Option A)
   - Developer (all options)
   - Unit Testing (all options)
   - Code Review (all options)
   - DevOps + Documentation (parallel, after review passes)

---

**Design Document Created:** 2026-05-20  
**Design Status:** AWAITING USER CONFIRMATION  
**Prepared by:** salesforce-design agent
