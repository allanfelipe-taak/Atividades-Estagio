trigger FreteTrigger on Frete__c (before insert, before update) {
    TriggerMaestro.executa(new FreteHandler());
}