/**
 * Handler responsável pelas regras de negócio do objeto Pedido (Order).
 * Implementa as travas de segurança exigidas no desafio.
 */
public with sharing class OrderHandler implements ContratoTrigger {
    
    public void beforeInsert(List<SObject> newRecords) {
        // Espaço para futuras validações de insert
    }

    public void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        for (Order pedidoNovo : (List<Order>) newRecords) {
            Order pedidoAntigo = (Order) oldRecords.get(pedidoNovo.Id);

            // REGRA 1: Não permitir alterar a conta do pedido após a criação
            if (pedidoNovo.AccountId != pedidoAntigo.AccountId) {
                pedidoNovo.addError('Não é permitido alterar o Cliente após a criação do pedido.');
            }

            // REGRA 2: Não permitir alterações se o pedido estiver com status 'Ativo'
            if (pedidoAntigo.Status == 'Activated' && pedidoNovo.Status == 'Activated') {
                pedidoNovo.addError('Este pedido está Ativo e não pode ser modificado. Para alterar, retorne o status para rascunho.');
            }
        }
    }
    
     // 1. REGRA PARA PEDIDOS NOVOS (Insert)
    public void afterInsert(List<SObject> newRecords) {
        for (Order pedidoNovo : (List<Order>) newRecords) {
            // Se o pedido já nasce com ExternalId, a gente já envia!
            if (pedidoNovo.ExternalId__c != null) {
                // Linha desativada para não quebrar o deploy do projeto novo:
                // IntegrationOutboundOrder.sendOrderToERP(pedidoNovo.Id);
            }
        }
    }
  
    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        for (Order pedidoNovo : (List<Order>) newRecords) {
            Order pedidoAntigo = (Order) oldRecords.get(pedidoNovo.Id);

            // A MÁGICA ESTÁ AQUI:
            // Só dispara o Outbound se o ExternalId não for nulo e não for um update de log
            Boolean foiApenasAtualizacaoDeLog = pedidoNovo.IntegrationLogInbound__c != pedidoAntigo.IntegrationLogInbound__c;

            if (pedidoNovo.ExternalId__c != null && !foiApenasAtualizacaoDeLog) {
                // Linha desativada para não quebrar o deploy do projeto novo:
                // IntegrationOutboundOrder.sendOrderToERP(pedidoNovo.Id);
            }
        }
    }
    
    public void afterDelete(List<SObject> oldRecords) {}
    
    public void afterUndelete(List<SObject> newRecords) {}
}