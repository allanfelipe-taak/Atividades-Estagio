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
            if (pedidoAntigo.Status == 'Ativo' && pedidoNovo.Status == 'Ativo') {
                pedidoNovo.addError('Este pedido está Ativo e não pode ser modificado. Para alterar, retorne o status para rascunho.');
            }
        }
    }

    // --- AJUSTE NAS ASSINATURAS PARA BATER COM A INTERFACE ---
    
    public void afterInsert(List<SObject> newRecords) {}
    
    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {}
    
    
    public void afterDelete(List<SObject> oldRecords) {}
    
    public void afterUndelete(List<SObject> newRecords) {}
}