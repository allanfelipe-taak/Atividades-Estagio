public with sharing class LocalAssociadoHandler implements ContratoTrigger {

    public void beforeInsert(List<SObject> newRecords) {}
    public void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {}
    
    public void afterInsert(List<SObject> newRecords) {
        handleChanges((List<Local_Associado__c>) newRecords);
    }

    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        handleChanges((List<Local_Associado__c>) newRecords);
    }

    public void afterDelete(Map<Id, SObject> oldRecords) {
        // No delete, precisamos pegar os IDs das contas que estavam nos registros deletados
        handleChanges((List<Local_Associado__c>) oldRecords.values());
    }

    private void handleChanges(List<Local_Associado__c> las) {
        Set<Id> accountIds = new Set<Id>();
        for (Local_Associado__c la : las) {
            if(la.Conta__c != null) {
                accountIds.add(la.Conta__c);
            }
        }
        if(!accountIds.isEmpty()) recalculateTeams(accountIds);
    }
private void recalculateTeams(Set<Id> accountIds) {
    // 1. Busca todos os LAs que AINDA existem para essas contas
    List<Local_Associado__c> allLAs = [SELECT Conta__c, Representante__c 
                                       FROM Local_Associado__c 
                                       WHERE Conta__c IN :accountIds];
    
    // 2. Busca TODOS os membros atuais do time nessas contas (sem filtrar por Role para não dar erro)
    List<AccountTeamMember> currentMembers = [SELECT Id, AccountId, UserId 
                                              FROM AccountTeamMember 
                                              WHERE AccountId IN :accountIds];

    // 3. Mapeia quem DEVE estar lá (baseado nos LAs atuais)
    Map<String, AccountTeamMember> membersToKeepMap = new Map<String, AccountTeamMember>();
    for (Local_Associado__c la : allLAs) {
        if (la.Representante__c != null) {
            String key = la.Conta__c + '-' + la.Representante__c;
            membersToKeepMap.put(key, new AccountTeamMember(
                AccountId = la.Conta__c,
                UserId = la.Representante__c,
                TeamMemberRole = 'Gerente de Contas', // Use exatamente o nome que aparece no seu Setup (Ex: Gerente de Contas)
                AccountAccessLevel = 'Edit',
                OpportunityAccessLevel = 'Read',
                CaseAccessLevel = 'Read'
            ));
        }
    }

    // 4. Lógica de remoção: Se o membro atual não está no mapa de "quem deve ficar", ele vai pro lixo
    List<AccountTeamMember> membersToDelete = new List<AccountTeamMember>();
    for (AccountTeamMember existing : currentMembers) {
        String key = existing.AccountId + '-' + existing.UserId;
        
        // Se ele não está na lista de LAs ativos, adiciona para deletar
        if (!membersToKeepMap.containsKey(key)) {
            membersToDelete.add(existing);
        }
    }

    // 5. Operações DML
    if (!membersToDelete.isEmpty()) {
        delete membersToDelete;
    }
    
    if (!membersToKeepMap.isEmpty()) {
        upsert membersToKeepMap.values();
    }
}
}