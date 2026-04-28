public with sharing class FreteHandler implements ContratoTrigger {

    public void beforeInsert(List<SObject> newRecords) {
        List<Frete__c> novosFretes = (List<Frete__c>) newRecords;
        // 1. Bloqueia preenchimentos errados (Fail Fast)
        validarCamposFrete(novosFretes);
        // 2. Verifica se já existe no banco
        verificarDuplicidade(novosFretes, new Set<Id>());
    }

    public void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        List<Frete__c> novosFretes = (List<Frete__c>) newRecords;
        validarCamposFrete(novosFretes);
        verificarDuplicidade(novosFretes, oldRecords.keySet());
    }

    // MÉTODO NOVO: Valida a "Matriz de Especificidade"
    private void validarCamposFrete(List<Frete__c> fretes) {
        for (Frete__c f : fretes) {
            // Validação O QUE (Produto vs Hierarquia)
            Integer prodCount = (f.Produto__c != null ? 1 : 0) + (f.Hierarquia_de_Produto__c != null ? 1 : 0);
            if (prodCount == 0) f.addError('Defina um Produto ou uma Hierarquia.');
            if (prodCount > 1) f.addError('Escolha apenas Produto OU Hierarquia.');

            // Validação ONDE (Localidade)
            Integer geoCount = (f.Cidade__c != null ? 1 : 0) + (f.Estado__c != null ? 1 : 0) + (f.Pais__c != null ? 1 : 0);
            if (geoCount == 0) f.addError('Defina uma Localidade (Cidade, Estado ou País).');
            if (geoCount > 1) f.addError('Escolha apenas um nível de localidade.');
        }
    }

    private void verificarDuplicidade(List<Frete__c> novosFretes, Set<Id> idsIgnorar) {
        Set<PricingKey> chavesNoBanco = new Set<PricingKey>();
        
        // AJUSTE: Query com TODOS os campos que a PricingKey precisa
        List<Frete__c> existentes = [SELECT Produto__c, Hierarquia_de_Produto__c, 
                                            Estado__c, Cidade__c, Pais__c 
                                     FROM Frete__c 
                                     WHERE Id NOT IN :idsIgnorar];

        for (Frete__c fEx : existentes) {
            chavesNoBanco.add(new PricingKey(fEx));
        }

        for (Frete__c f : novosFretes) {
            PricingKey chaveAtual = new PricingKey(f);
            if (chavesNoBanco.contains(chaveAtual)) {
                f.addError('🚨 Duplicidade: Já existe uma regra de Frete idêntica no sistema.');
            }
        }
    }

    public void afterInsert(List<SObject> newRecords) {}
    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {}
    public void afterDelete(List<SObject> oldRecords) {}
    public void afterUndelete(List<SObject> newRecords) {}
}