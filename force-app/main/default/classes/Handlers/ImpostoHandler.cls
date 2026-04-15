public with sharing class ImpostoHandler implements ContratoTrigger {

    public void beforeInsert(List<SObject> newRecords) {
        verificarDuplicidade((List<Imposto__c>) newRecords, new Set<Id>());
    }

    public void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        verificarDuplicidade((List<Imposto__c>) newRecords, oldRecords.keySet());
    }

 private void verificarDuplicidade(List<Imposto__c> novosImpostos, Set<Id> idsIgnorar) {
    if (idsIgnorar == null) idsIgnorar = new Set<Id>();
    
    // 1. SELECT corrigido: Removi o campo Hierarquia_de_Produto__c que não existe no Imposto__c
    Set<PricingKey> chavesNoBanco = new Set<PricingKey>();
    List<Imposto__c> existentes = [SELECT Produto__c, Estado__c, Pais__c 
                                   FROM Imposto__c 
                                   WHERE Id NOT IN :idsIgnorar];
    
    for (Imposto__c iEx : existentes) {
        chavesNoBanco.add(new PricingKey(iEx));
    }

    // 2. Memória para a lista atual (O segredo do M1/M2 que te ensinei)
    Set<PricingKey> chavesNaListaAtual = new Set<PricingKey>();

    for (Imposto__c i : novosImpostos) {
        PricingKey chaveAtual = new PricingKey(i);
        
        if (chavesNoBanco.contains(chaveAtual) || chavesNaListaAtual.contains(chaveAtual)) {
            i.addError('🚨 BLOQUEADO: Já existe uma alíquota de Imposto para esta combinação.');
        } else {
            chavesNaListaAtual.add(chaveAtual);
        }
    }
}

    // Métodos vazios para o Contrato
    public void afterInsert(List<SObject> newRecords) {}
    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {}
    public void afterDelete(List<SObject> oldRecords) {}
    public void afterUndelete(List<SObject> newRecords) {}
}