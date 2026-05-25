public interface ContractTrigger {
    void beforeInsert (List<SObject> newRecords);
    void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords);
    void afterInsert(List<SObject> newRecords);
    void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords);
    void afterDelete(List<SObject> oldRecords);
    void afterUndelete(List<SObject> oldRecords);
}