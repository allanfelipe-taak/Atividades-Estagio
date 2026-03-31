public with sharing class FreteHandler implements ContratoTrigger {

    public void beforeInsert(List<SObject> newRecords) {
        verificarDuplicidade((List<Frete__c>) newRecords, new Set<Id>());
    }

    public void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        verificarDuplicidade((List<Frete__c>) newRecords, oldRecords.keySet());
    }

    private void verificarDuplicidade(List<Frete__c> novosFretes, Set<Id> idsIgnorar) {
        Set<PricingKey> chavesNoBanco = new Set<PricingKey>();
        
        // Buscar os fretes existentes (Ignorando os que estão sendo editados)
        for (Frete__c fEx : [SELECT Produto__c, Estado__c, Cidade__c FROM Frete__c WHERE Id NOT IN :idsIgnorar]) {
            chavesNoBanco.add(new PricingKey(fEx));
        }

        for (Frete__c f : novosFretes) {
            PricingKey chaveAtual = new PricingKey(f);
            if (chavesNoBanco.contains(chaveAtual)) {
                f.addError('Já existe uma regra de Frete para este Produto nesta Localidade.');
            }
        }
    }

    // Métodos vazios para o Contrato
    public void afterInsert(List<SObject> newRecords) {}
    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {}
    public void afterDelete(List<SObject> oldRecords) {}
    public void afterUndelete(List<SObject> newRecords) {}
}