---
name: year-field-casting
description: CALENDAR_YEAR returns Integer; verify Goal__r.Year__c field type before casting
metadata:
  type: feedback
---

## Pattern: Type Coercion in SOQL Aggregations

In `GoalValueBatch`, the code casts `Goal__r.Year__c` to `Integer`:
```apex
years.add((Integer) item.Goal__r.Year__c);
```

And casts aggregation result:
```apex
Integer year = (Integer) ar.get('yr');
```

**Risk:** If the schema field `Goal__c.Year__c` is defined as `Text`, `Formula`, or a different numeric type (not `Number`/`Decimal`), the cast throws `System.TypeException` at runtime.

**Check before casting:**
- Verify `Year__c` field type in `/objects/Goal__c/Goal__c.object-meta.xml`
- If numeric: document the assumption in a comment
- If text/formula: add type-safe casting (try/catch or explicit instanceof check)

**For this project:** Confirmed `Year__c` is a proper numeric field based on usage in GoalBatch.cls. Document this assumption in GoalValueBatch comments.
