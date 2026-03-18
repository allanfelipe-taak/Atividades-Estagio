trigger LocalAssociadoTrigger on Local_Associado__c (after insert, after update, after delete, after undelete) {
    // O Maestro recebe a classe e decide quem chamar.
    TriggerMaestroGatilho.executar(LocalAssociadoHandler.class);
}