public with sharing class MarginHandler implements ContractTrigger {

    public void beforeInsert(List<SObject> newRecords) {
        List<Margin__c> newMargins = (List<Margin__c>) newRecords;
        // 1. Primeiro validamos se os campos estão certos
        validateExclusiveFields(newMargins);
        // 2. Depois verificamos duplicidade no banco
        checkDuplicates(newMargins, new Set<Id>());
    }

    public void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        List<Margin__c> newMargins = (List<Margin__c>) newRecords;
        validateExclusiveFields(newMargins);
        checkDuplicates(newMargins, oldRecords.keySet());
    }

    // --- NOVO MÉTODO DE VALIDAÇÃO ---
   private void validateExclusiveFields(List<Margin__c> margins) {
    for (Margin__c m : margins) {
        // 1. QUEM (Cliente) - Corrigido para Account__c
        if (m.Account__c != null && m.AccountGroup__c != null) {
            m.addError(' Erro: Escolha apenas Conta OU Grupo de Conta.');
        }

        // 2. O QUÊ (Produto) - Corrigido para Product__c
        if (m.Product__c != null && m.ProductHierarchy__c != null) {
            m.addError(' Erro: Escolha apenas Produto OU Hierarquia de Produto.');
        }

        // 3. ONDE (Geografia)
        Integer geoCount = 0;
        if (m.City__c != null) geoCount++;
        if (m.State__c != null) geoCount++;
        if (m.Country__c != null) geoCount++;

        if (geoCount > 1) {
            m.addError('🚨 Erro: Defina a localidade em apenas um nível (ou Cidade, ou Estado, ou País).');
        }
    }
}

private void checkDuplicates(List<Margin__c> newMargins, Set<Id> idsIgnore) {
    if (idsIgnore == null) { idsIgnore = new Set<Id>(); }

    // 1. Memória do Passado: O que já está no banco de dados
    Set<PricingKey> keysInDatabase = new Set<PricingKey>();
    List<Margin__c> existing = [SELECT Product__c, Account__c, AccountGroup__c,
                                         State__c, City__c, Country__c, ProductHierarchy__c
                                  FROM Margin__c
                                  WHERE Id NOT IN :idsIgnore];

    for (Margin__c mEx : existing) {
        keysInDatabase.add(new PricingKey(mEx));
    }

    // 🎯 2. Memória do Presente: O que está na lista do insert AGORA
    Set<PricingKey> keysInCurrentList = new Set<PricingKey>();

    for (Margin__c m : newMargins) {
        PricingKey currentKey = new PricingKey(m);

        // A mágica acontece aqui: verificamos no banco OU na lista atual
        if (keysInDatabase.contains(currentKey) || keysInCurrentList.contains(currentKey)) {
            m.addError('🚨 BLOQUEADO: Já existe uma Margem cadastrada para esta combinação!');
        } else {
            // Se passou, "batizamos" na lista atual para o próximo não repetir
            keysInCurrentList.add(currentKey);
        }
    }
}

    public void afterInsert(List<SObject> newRecords) {}
    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {}
    public void afterDelete(List<SObject> oldRecords) {}
    public void afterUndelete(List<SObject> newRecords) {}
}