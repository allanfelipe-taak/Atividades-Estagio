trigger ImpostoTrigger on Imposto__c (before insert, before update) {
    TriggerMaestro.executa(new ImpostoHandler());
}