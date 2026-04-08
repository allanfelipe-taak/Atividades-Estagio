
/** * Handler é responsavel por filtrar os eventos do Produto e do Pedido 
 * e direcionar para o PricingService
 */
public with sharing class OrderItemHandler implements ContratoTrigger {

    public void beforeInsert(List<SObject> newRecords) {
        validarItens((List<OrderItem>) newRecords);
        // MOVIDO PARA O BEFORE: Aqui o registro NÃO é read-only
        new PricingService().processarPricing((List<OrderItem>) newRecords);
    }

    public void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        validarItens((List<OrderItem>) newRecords);
        validarPedidoAtivo((List<OrderItem>) newRecords, (Map<Id, OrderItem>) oldRecords);
        
        
        List<OrderItem> itensParaRecalcular = new List<OrderItem>();
        for (OrderItem novo : (List<OrderItem>) newRecords) {
            
                itensParaRecalcular.add(novo);
            
        }
        if (!itensParaRecalcular.isEmpty()) {
            new PricingService().processarPricing(itensParaRecalcular);
        }
    }

    // --- MÉTODOS DE VALIDAÇÃO ---

    private void validarItens(List<OrderItem> itens) {
        for (OrderItem item : itens) {
            if (item.Quantity <= 0) {
                item.addError('A quantidade deve ser maior que zero.');
            }
        }
    }

    private void validarPedidoAtivo(List<OrderItem> itens, Map<Id, OrderItem> oldMap) {
        Set<Id> orderIds = new Set<Id>();
        for(OrderItem oi : itens) orderIds.add(oi.OrderId);
        
        Map<Id, Order> mapPedidos = new Map<Id, Order>([SELECT Id, Status FROM Order WHERE Id IN :orderIds]);

        for (OrderItem item : itens) {
            if (mapPedidos.containsKey(item.OrderId) && mapPedidos.get(item.OrderId).Status == 'Activated') {
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