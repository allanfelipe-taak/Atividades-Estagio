/**
 * @description: Trigger do objeto Produto do Pedido. 
 * Note que ela chama o Maestro e passa uma nova instância do Handler.
 */
trigger OrderItemTrigger on OrderItem (before insert, before update, after insert, after update, after delete, after undelete) {
    // A mágica acontece aqui: 1 linha resolve tudo!
    TriggerMaestro.executa(new OrderItemHandler());
}