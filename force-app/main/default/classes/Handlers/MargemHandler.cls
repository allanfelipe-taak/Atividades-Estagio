public with sharing class MargemHandler implements ContratoTrigger {

    public void beforeInsert(List<SObject> newRecords) {
        List<Margem__c> novasMargens = (List<Margem__c>) newRecords;
        // 1. Primeiro validamos se os campos estão certos
        validarCamposExclusivos(novasMargens);
        // 2. Depois verificamos duplicidade no banco
        verificarDuplicidade(novasMargens, new Set<Id>());
    }

    public void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        List<Margem__c> novasMargens = (List<Margem__c>) newRecords;
        validarCamposExclusivos(novasMargens);
        verificarDuplicidade(novasMargens, oldRecords.keySet());
    }

    // --- NOVO MÉTODO DE VALIDAÇÃO ---
   private void validarCamposExclusivos(List<Margem__c> margens) {
    for (Margem__c m : margens) {
        // 1. QUEM (Cliente) - Corrigido para Conta__c
        if (m.Conta__c != null && m.Grupo_de_Conta__c != null) {
            m.addError(' Erro: Escolha apenas Conta OU Grupo de Conta.');
        }

        // 2. O QUÊ (Produto) - Corrigido para Produto__c
        if (m.Produto__c != null && m.Hierarquia_de_Produto__c != null) {
            m.addError(' Erro: Escolha apenas Produto OU Hierarquia de Produto.');
        }

        // 3. ONDE (Geografia)
        Integer geoCount = 0;
        if (m.Cidade__c != null) geoCount++;
        if (m.Estado__c != null) geoCount++;
        if (m.Pais__c != null) geoCount++;

        if (geoCount > 1) {
            m.addError('🚨 Erro: Defina a localidade em apenas um nível (ou Cidade, ou Estado, ou País).');
        }
    }
}

    private void verificarDuplicidade(List<Margem__c> novasMargens, Set<Id> idsIgnorar) {
        if (idsIgnorar == null) { idsIgnorar = new Set<Id>(); }

        Set<PricingKey> chavesNoBanco = new Set<PricingKey>();
        
        List<Margem__c> existentes = [SELECT Produto__c, Conta__c, Grupo_de_Conta__c, Estado__c, Cidade__c 
                                     FROM Margem__c 
                                     WHERE Id NOT IN :idsIgnorar];
        
        for (Margem__c mEx : existentes) {
            chavesNoBanco.add(new PricingKey(mEx));
        }

        for (Margem__c m : novasMargens) {
            PricingKey chaveAtual = new PricingKey(m);
            
            if (chavesNoBanco.contains(chaveAtual)) {
                m.addError('Já existe uma Margem cadastrada para esta combinação de Produto/Cliente/Localidade.');
            }
        }
    }

    public void afterInsert(List<SObject> newRecords) {}
    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {}
    public void afterDelete(List<SObject> oldRecords) {}
    public void afterUndelete(List<SObject> newRecords) {}
}