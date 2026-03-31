public with sharing class MargemHandler implements ContratoTrigger {

    public void beforeInsert(List<SObject> newRecords) {
        verificarDuplicidade((List<Margem__c>) newRecords, null);
    }

    public void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        verificarDuplicidade((List<Margem__c>) newRecords, oldRecords.keySet());
    }

    private void verificarDuplicidade(List<Margem__c> novasMargens, Set<Id> idsIgnorar) {
        // 1.  a  Classe Mestra de Chaves
        Set<PricingKey> chavesNoBanco = new Set<PricingKey>();
        
        // as margens, mas ignorar as que estamos editando agora 
        // para não dar "falso positivo" de duplicidade
        List<Margem__c> existentes = [SELECT Produto__c, Conta__c, Estado__c, Cidade__c 
                                     FROM Margem__c 
                                     WHERE Id NOT IN :idsIgnorar];
        
        for (Margem__c mEx : existentes) {
            chavesNoBanco.add(new PricingKey(mEx));
        }

        // 3. Comparação limpa e segura
        for (Margem__c m : novasMargens) {
            PricingKey chaveAtual = new PricingKey(m);
            
            if (chavesNoBanco.contains(chaveAtual)) {
                m.addError('Já existe uma Margem cadastrada para esta combinação de Produto/Cliente/Localidade.');
            }
        }
    }

    // Métodos vazios para cumprir o contrato
    public void afterInsert(List<SObject> newRecords) {}
    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {}
    public void afterDelete(List<SObject> oldRecords) {}
    public void afterUndelete(List<SObject> newRecords) {}
}