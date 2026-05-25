trigger TaxTrigger on Tax__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerMaestro.execute(new TaxHandler());
}