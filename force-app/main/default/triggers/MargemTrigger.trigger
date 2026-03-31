trigger MargemTrigger on Margem__c (before insert, before update) {
    TriggerMaestro.executa(new MargemHandler());
}