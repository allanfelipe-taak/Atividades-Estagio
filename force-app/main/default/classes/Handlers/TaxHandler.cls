public with sharing class TaxHandler implements ContractTrigger {

    public void beforeInsert(List<SObject> newRecords) {
        checkDuplicates((List<Tax__c>) newRecords, new Set<Id>());
    }

    public void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        checkDuplicates((List<Tax__c>) newRecords, oldRecords.keySet());
    }

 private void checkDuplicates(List<Tax__c> newTaxes, Set<Id> idsIgnore) {
    if (idsIgnore == null) idsIgnore = new Set<Id>();

    // 1. SELECT corrigido: Removi o campo ProductHierarchy__c que não existe no Tax__c
    Set<PricingKey> keysInDatabase = new Set<PricingKey>();
    List<Tax__c> existing = [SELECT Product__c, State__c, Country__c
                                   FROM Tax__c
                                   WHERE Id NOT IN :idsIgnore];

    for (Tax__c iEx : existing) {
        keysInDatabase.add(new PricingKey(iEx));
    }

    // 2. Memória para a lista atual (O segredo do M1/M2 que te ensinei)
    Set<PricingKey> keysInCurrentList = new Set<PricingKey>();

    for (Tax__c i : newTaxes) {
        PricingKey currentKey = new PricingKey(i);

        if (keysInDatabase.contains(currentKey) || keysInCurrentList.contains(currentKey)) {
            i.addError('🚨 BLOQUEADO: Já existe uma alíquota de Imposto para esta combinação.');
        } else {
            keysInCurrentList.add(currentKey);
        }
    }
}

    // Métodos vazios para o Contrato
    public void afterInsert(List<SObject> newRecords) {}
    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {}
    public void afterDelete(List<SObject> oldRecords) {}
    public void afterUndelete(List<SObject> newRecords) {}
}