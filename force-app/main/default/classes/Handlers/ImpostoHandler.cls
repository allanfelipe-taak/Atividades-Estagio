public with sharing class ImpostoHandler implements ContratoTrigger {

    public void beforeInsert(List<SObject> newRecords) {
        verificarDuplicidade((List<Imposto__c>) newRecords, new Set<Id>());
    }

    public void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        verificarDuplicidade((List<Imposto__c>) newRecords, oldRecords.keySet());
    }

    private void verificarDuplicidade(List<Imposto__c> novosImpostos, Set<Id> idsIgnorar) {
        Set<PricingKey> chavesNoBanco = new Set<PricingKey>();
        
        for (Imposto__c iEx : [SELECT Produto__c, Estado__c FROM Imposto__c WHERE Id NOT IN :idsIgnorar]) {
            chavesNoBanco.add(new PricingKey(iEx));
        }

        for (Imposto__c i : novosImpostos) {
            PricingKey chaveAtual = new PricingKey(i);
            if (chavesNoBanco.contains(chaveAtual)) {
                i.addError('Já existe uma alíquota de Imposto cadastrada para esta combinação.');
            }
        }
    }

    // Métodos vazios para o Contrato
    public void afterInsert(List<SObject> newRecords) {}
    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {}
    public void afterDelete(List<SObject> oldRecords) {}
    public void afterUndelete(List<SObject> newRecords) {}
}