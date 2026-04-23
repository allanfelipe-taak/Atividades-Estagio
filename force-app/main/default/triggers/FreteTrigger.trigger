trigger FreteTrigger on Frete__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerMaestro.executa(new FreteHandler());
}