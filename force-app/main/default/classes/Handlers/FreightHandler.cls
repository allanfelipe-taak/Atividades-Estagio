public with sharing class FreightHandler implements ContractTrigger {

    public void beforeInsert(List<SObject> newRecords) {
        List<Freight__c> newFreights = (List<Freight__c>) newRecords;
        // 1. Bloqueia preenchimentos errados (Fail Fast)
        validateFreightFields(newFreights);
        // 2. Verifica se já existe no banco
        checkDuplicates(newFreights, new Set<Id>());
    }

    public void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        List<Freight__c> newFreights = (List<Freight__c>) newRecords;
        validateFreightFields(newFreights);
        checkDuplicates(newFreights, oldRecords.keySet());
    }

    // MÉTODO NOVO: Valida a "Matriz de Especificidade"
    private void validateFreightFields(List<Freight__c> freights) {
        for (Freight__c f : freights) {
            // Validação O QUE (Produto vs Hierarquia)
            Integer prodCount = (f.Product__c != null ? 1 : 0) + (f.ProductHierarchy__c != null ? 1 : 0);
            if (prodCount == 0) f.addError('Defina um Produto ou uma Hierarquia.');
            if (prodCount > 1) f.addError('Escolha apenas Produto OU Hierarquia.');

            // Validação ONDE (Localidade)
            Integer geoCount = (f.City__c != null ? 1 : 0) + (f.State__c != null ? 1 : 0) + (f.Country__c != null ? 1 : 0);
            if (geoCount == 0) f.addError('Defina uma Localidade (Cidade, Estado ou País).');
            if (geoCount > 1) f.addError('Escolha apenas um nível de localidade.');
        }
    }

    private void checkDuplicates(List<Freight__c> newFreights, Set<Id> idsIgnore) {
        Set<PricingKey> keysInDatabase = new Set<PricingKey>();

        // AJUSTE: Query com TODOS os campos que a PricingKey precisa
        List<Freight__c> existing = [SELECT Product__c, ProductHierarchy__c,
                                            State__c, City__c, Country__c
                                     FROM Freight__c
                                     WHERE Id NOT IN :idsIgnore];

        for (Freight__c fEx : existing) {
            keysInDatabase.add(new PricingKey(fEx));
        }

        for (Freight__c f : newFreights) {
            PricingKey currentKey = new PricingKey(f);
            if (keysInDatabase.contains(currentKey)) {
                f.addError('🚨 Duplicidade: Já existe uma regra de Frete idêntica no sistema.');
            }
        }
    }

    public void afterInsert(List<SObject> newRecords) {}
    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {}
    public void afterDelete(List<SObject> oldRecords) {}
    public void afterUndelete(List<SObject> newRecords) {}
}