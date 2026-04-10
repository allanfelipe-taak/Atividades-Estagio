public with sharing class ImpostoHandler implements ContratoTrigger {

    public void beforeInsert(List<SObject> newRecords) {
        List<Imposto__c> novosImpostos = (List<Imposto__c>) newRecords;
        // 1. Valida se preencheu os campos corretamente (XOR)
        validarCamposImposto(novosImpostos);
        // 2. Verifica se já existe no banco
        verificarDuplicidade(novosImpostos, new Set<Id>());
    }

    public void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        List<Imposto__c> novosImpostos = (List<Imposto__c>) newRecords;
        validarCamposImposto(novosImpostos);
        verificarDuplicidade(novosImpostos, oldRecords.keySet());
    }

    // --- BLOCO DE VALIDAÇÃO DE ESPECIFICIDADE ---
    private void validarCamposImposto(List<Imposto__c> impostos) {
        for (Imposto__c i : impostos) {
            // Validação O QUÊ: Produto vs Categoria (Somando +1 para cada preenchido)
            Integer prodCount = (i.Produto__c != null ? 1 : 0) + (i.Categoria__c != null ? 1 : 0);
            
            if (prodCount == 0) {
                i.addError('🚨 Imposto: Defina um Produto ou uma Categoria.');
            } else if (prodCount > 1) {
                i.addError('🚨 Imposto: Escolha apenas Produto OU Categoria, nunca os dois.');
            }

            // Validação ONDE: Estado vs País
            Integer geoCount = (i.Estado__c != null ? 1 : 0) + (i.Pais__c != null ? 1 : 0);
            
            if (geoCount == 0) {
                i.addError('🚨 Imposto: Defina uma Localidade (Estado ou País).');
            } else if (geoCount > 1) {
                i.addError('🚨 Imposto: Escolha apenas Estado OU País para este registro.');
            }
        }
    }

    // --- BLOCO DE DUPLICIDADE ---
    private void verificarDuplicidade(List<Imposto__c> novosImpostos, Set<Id> idsIgnorar) {
        Set<PricingKey> chavesNoBanco = new Set<PricingKey>();
        
        // Buscamos os campos que compõem a chave única
        List<Imposto__c> existentes = [SELECT Produto__c, Categoria__c, Estado__c, Pais__c 
                                       FROM Imposto__c 
                                       WHERE Id NOT IN :idsIgnorar];

        for (Imposto__c iEx : existentes) {
            chavesNoBanco.add(new PricingKey(iEx));
        }

        for (Imposto__c i : novosImpostos) {
            PricingKey chaveAtual = new PricingKey(i);
            if (chavesNoBanco.contains(chaveAtual)) {
                i.addError('🚨 Duplicidade: Já existe uma regra de Imposto para esta combinação.');
            }
        }
    }

    public void afterInsert(List<SObject> newRecords) {}
    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {}
    public void afterDelete(List<SObject> oldRecords) {}
    public void afterUndelete(List<SObject> newRecords) {}
}