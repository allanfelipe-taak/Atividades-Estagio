trigger TaskTrigger on Task (before insert) {
    // O Maestro recebe o Handler da Task e o tipo de operação atual
   TriggerMaestroGatilho.gerenciar(new TaskHandler(), Trigger.operationType);
}