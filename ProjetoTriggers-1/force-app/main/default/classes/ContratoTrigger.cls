// Métodos da Interface (vazios por enquanto)
public interface ContratoTrigger {
    void executarBeforeInsert(List<SObject> newRecords);
    void executarAfterInsert(List<SObject> newRecords);
    void executarBeforeUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap);
    void executarAfterUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap);
    void executarBeforeDelete(Map<Id, SObject> oldMap);
    void executarAfterDelete(Map<Id, SObject> oldMap);
    void executarAfterUndelete(List<SObject> newRecords);
}