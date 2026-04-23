trigger MargemTrigger on Margem__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerMaestro.executa(new MargemHandler());
}