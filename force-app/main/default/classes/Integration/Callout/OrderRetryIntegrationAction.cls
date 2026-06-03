/**
 * Classe responsável por expor a chamada de integração para ferramentas visuais (Flows/Botões).
 */
public with sharing class OrderRetryIntegrationAction {

    @InvocableMethod(label='Reintegrar Pedido com ERP' description='Chama a integração outbound do pedido de forma manual.')
    public static void retryIntegration(List<Id> orderIds) {
        if (orderIds == null || orderIds.isEmpty()) {
            return;
        }

        // A classe CalloutOrder espera uma lista de Strings (IDs dos pedidos)
        List<String> orderIdStrings = new List<String>();
        for (Id orderId : orderIds) {
            orderIdStrings.add(String.valueOf(orderId));
        }

        // 🟢 CHAMADA CORRETA: Chama o seu motor oficial e atualizado!
        CalloutOrder.executeCalloutOrder(orderIdStrings);
    }
}