trigger MarginTrigger on Margin__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerMaestro.execute(new MarginHandler());
}