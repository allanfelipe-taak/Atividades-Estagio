trigger FreightTrigger on Freight__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerMaestro.execute(new FreightHandler());
}