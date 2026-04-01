public with sharing class MargemHandler implements ContratoTrigger {

    public void beforeInsert(List<SObject> newRecords) {
        // AJUSTE 1: Troquei 'null' por 'new Set<Id>()' para a Query não falhar
        verificarDuplicidade((List<Margem__c>) newRecords, new Set<Id>());
    }

    public void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        verificarDuplicidade((List<Margem__c>) newRecords, oldRecords.keySet());
    }

    private void verificarDuplicidade(List<Margem__c> novasMargens, Set<Id> idsIgnorar) {
        // AJUSTE 2: Garantia extra para o Set nunca ser null
        if (idsIgnorar == null) { idsIgnorar = new Set<Id>(); }

        Set<PricingKey> chavesNoBanco = new Set<PricingKey>();
        
        // Agora a Query vai trazer a MG-0032 corretamente porque o Filtro Id NOT IN está preenchido
        List<Margem__c> existentes = [SELECT Produto__c, Conta__c, Estado__c, Cidade__c 
                                     FROM Margem__c 
                                     WHERE Id NOT IN :idsIgnorar];
        
        for (Margem__c mEx : existentes) {
            chavesNoBanco.add(new PricingKey(mEx));
        }

        for (Margem__c m : novasMargens) {
            PricingKey chaveAtual = new PricingKey(m);
            
            if (chavesNoBanco.contains(chaveAtual)) {
                // Aqui o Salesforce barra a criação e seu script entra no CATCH
                m.addError('Já existe uma Margem cadastrada para esta combinação de Produto/Cliente/Localidade.');
            }
        }
    }

    public void afterInsert(List<SObject> newRecords) {}
    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {}
    public void afterDelete(List<SObject> oldRecords) {}
    public void afterUndelete(List<SObject> newRecords) {}
}