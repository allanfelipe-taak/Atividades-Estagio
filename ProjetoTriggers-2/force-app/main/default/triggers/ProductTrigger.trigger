trigger ProductTrigger on Product2 (after insert) {
    // Chamamos o Maestro, que por sua vez aciona o ProductHandler
    TriggerMaestroGatilho.executar(ProductHandler.class);
}