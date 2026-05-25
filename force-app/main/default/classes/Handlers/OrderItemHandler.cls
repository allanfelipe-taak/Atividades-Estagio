/** * Handler é responsavel por filtrar os eventos do Produto e do Pedido 
 * e direcionar para o PricingService
 */
public with sharing class OrderItemHandler implements ContractTrigger {

    public void beforeInsert(List<SObject> newRecords) {
        validateItems((List<OrderItem>) newRecords);
        // MOVIDO PARA O BEFORE: Aqui o registro NÃO é read-only
        new PricingService().processPricing((List<OrderItem>) newRecords);
    }

    public void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        validateItems((List<OrderItem>) newRecords);
        validateActiveOrder((List<OrderItem>) newRecords, (Map<Id, OrderItem>) oldRecords);


        List<OrderItem> itemsToRecalculate = new List<OrderItem>();
        for (OrderItem newItem : (List<OrderItem>) newRecords) {

                itemsToRecalculate.add(newItem);

        }
        if (!itemsToRecalculate.isEmpty()) {
            new PricingService().processPricing(itemsToRecalculate);
        }
    }

    // --- MÉTODOS DE VALIDAÇÃO ---

    private void validateItems(List<OrderItem> items) {
        for (OrderItem item : items) {
            if (item.Quantity <= 0) {
                item.addError('A quantidade deve ser maior que zero.');
            }
        }
    }

    private void validateActiveOrder(List<OrderItem> items, Map<Id, OrderItem> oldMap) {
        Set<Id> orderIds = new Set<Id>();
        for(OrderItem oi : items) orderIds.add(oi.OrderId);

        Map<Id, Order> orderMap = new Map<Id, Order>([SELECT Id, Status FROM Order WHERE Id IN :orderIds]);

        for (OrderItem item : items) {
            if (orderMap.containsKey(item.OrderId) && orderMap.get(item.OrderId).Status == 'Activated') {
                item.addError('Não é permitido modificar itens de um pedido que já está Ativo.');
            }
        }
    }

    // --- MÉTODOS DE EXECUÇÃO (Limpar os Afters para evitar o erro de Read-Only) ---

    public void afterInsert(List<SObject> newRecords) {
        // Vazio: Lógica movida para o beforeInsert
    }

    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        // Vazio: Lógica movida para o beforeUpdate
    }

    public void afterDelete(List<SObject> oldRecords) {}

    public void afterUndelete(List<SObject> newRecords) {}
}