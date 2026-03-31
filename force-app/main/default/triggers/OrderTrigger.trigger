trigger OrderTrigger on Order (before insert, before update, after insert, after update) {
    TriggerMaestro.executa(new OrderHandler());
}