trigger OrderTrigger on Order (before insert, before update, after insert, after update) {
    TriggerMaestro.execute(new OrderHandler());
}