trigger DevUserTrigger on DevUser__c (after insert, after update) {
    
    List<Id> userIdsToProcess = new List<Id>();

    for (DevUser__c newUser : Trigger.new) {
        
        // Cenário 1: Registro Novo inserido com o Login preenchido
        if (Trigger.isInsert && newUser.Login__c != null) {
            userIdsToProcess.add(newUser.Id);
        } 
        
        // Cenário 2: Registro Atualizado (Só dispara callout se o campo Login__c mudou de valor)
        else if (Trigger.isUpdate) {
            DevUser__c oldUser = Trigger.oldMap.get(newUser.Id);
            if (newUser.Login__c != oldUser.Login__c && newUser.Login__c != null) {
                userIdsToProcess.add(newUser.Id);
            }
        }
    }

    // Se houver registros elegíveis, joga o lote para a nossa classe Queueable processar em segundo plano
    if (!userIdsToProcess.isEmpty()) {
        System.enqueueJob(new GitHubUserCalloutQueueable(userIdsToProcess));
    }
}