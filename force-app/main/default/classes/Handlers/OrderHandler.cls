/**
 * Handler responsável pelas regras de negócio do objeto Pedido (Order).
 * Implementa as travas de segurança exigidas no desafio.
 */
public with sharing class OrderHandler implements ContractTrigger {

    public void beforeInsert(List<SObject> newRecords) {
        // Espaço para futuras validações de insert
    }

    public void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        Set<Id> ordersToProcess = new Set<Id>();

        for (SObject rec : newRecords) {
            Order newOrder = (Order) rec;
            Order oldOrder = (Order) oldRecords.get(newOrder.Id);

            // REGRA 1: Não permitir alterar a conta do pedido após a criação (MANTIDO)
            if (newOrder.AccountId != oldOrder.AccountId) {
                newOrder.addError('Não é permitido alterar o Cliente após a criação do pedido.');
            }

            // REGRA 2: Não permitir alterações se o pedido estiver com status 'Ativo' (MANTIDO)
            if (oldOrder.Status == 'Activated' && newOrder.Status == 'Activated') {
                newOrder.addError('Este pedido está Ativo e não pode ser modificado. Para alterar, retorne o status para rascunho.');
            }

            /* =========================================================================
               A PARTIR DAQUI, TUDO FOI COMENTADO PARA USARMOS FLOWS E REGRAS DE VALIDAÇÃO
               ========================================================================= */
            
            /*
            // CRITÉRIO 4 (Inbound): Atualização automática de Status com base no retorno do ERP
            Boolean logMudou = newOrder.IntegrationLogInbound__c != oldOrder.IntegrationLogInbound__c;
            
            if (logMudou) {
                if (newOrder.ExternalId__c != null) {
                    newOrder.Status = 'Integrated';
                } else {
                    newOrder.Status = 'Integration Error';
                }
            }

            // Captura os pedidos que estão tentando ir de 'New' para 'In Approval' (Ação do Usuário)
            if (oldOrder.Status == 'New' && newOrder.Status == 'In Approval') {
                ordersToProcess.add(newOrder.Id);
            }
            
            // Trava para o usuário não pular etapas manualmente
            if (oldOrder.Status == 'New' && newOrder.Status != 'New' && newOrder.Status != 'In Approval') {
                newOrder.Status.addError('A única mudança de Status permitida a partir de New é para In Approval.');
            }
            */
        }

        /*
        // LÓGICA CONSOLIDADA DE PRODUTOS E DESCONTOS (Critérios 2 e 3)
        if (!ordersToProcess.isEmpty()) {
            Map<Id, List<OrderItem>> orderToItemsMap = new Map<Id, List<OrderItem>>();
            for (OrderItem item : [SELECT OrderId, Quantity, UnitPrice, Discount__c FROM OrderItem WHERE OrderId IN :ordersToProcess]) {
                if (!orderToItemsMap.containsKey(item.OrderId)) {
                    orderToItemsMap.put(item.OrderId, new List<OrderItem>());
                }
                orderToItemsMap.get(item.OrderId).add(item);
            }

            for (SObject rec : newRecords) {
                Order newOrder = (Order) rec;
                if (!ordersToProcess.contains(newOrder.Id)) { continue; }

                List<OrderItem> items = orderToItemsMap.get(newOrder.Id);

                // CRITÉRIO 2: Barrar se não tiver produtos
                if (items == null || items.isEmpty()) {
                    newOrder.addError('Não é possível enviar para aprovação um pedido sem produtos.');
                    continue;
                }

                // CRITÉRIO 3: Calcular o Desconto Total Consolidado
                Decimal totalGrossAmount = 0;
                Decimal totalDiscountAmount = 0;

                for (OrderItem item : items) {
                    Decimal itemGross = item.Quantity * item.UnitPrice;
                    totalGrossAmount += itemGross;

                    if (item.Discount__c != null) {
                        totalDiscountAmount += itemGross * (item.Discount__c / 100);
                    }
                }

                Decimal totalDiscountPercent = totalGrossAmount > 0 ? (totalDiscountAmount / totalGrossAmount) * 100 : 0;

                // Se o desconto for menor ou igual a 20%, pula a aprovação e vai direto para aprovado
                if (totalDiscountPercent <= 20) {
                    newOrder.Status = 'Approved';
                }
            }
        }
        */
    }

    public void afterInsert(List<SObject> newRecords) {
        for (SObject rec : newRecords) {
            Order newOrder = (Order) rec;
            if (newOrder.ExternalId__c != null) {
                // IntegrationOutboundOrder.sendOrderToERP(newOrder.Id);
            }
        }
    }

    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
        /*
        List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();

        for (SObject rec : newRecords) {
            Order newOrder = (Order) rec;
            Order oldOrder = (Order) oldRecords.get(newOrder.Id);

            // CRITÉRIO 3: Se o desconto foi alto, joga no processo oficial de aprovação
            if (oldOrder.Status == 'New' && newOrder.Status == 'In Approval') {
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments('Pedido enviado para aprovação automática devido ao desconto superior a 20%.');
                req.setObjectId(newOrder.Id);
                approvalRequests.add(req);
                newOrder.addError('O pedido não pôde ser aprovado automaticamente porque o desconto calculado foi maior que 20%. Ajuste o preço ou fale com o administrador.');
            }

            // CRITÉRIO 3 & 4 (Outbound): Dispara o envio para o ERP se o status virou 'Approved'
            if (oldOrder.Status != 'Approved' && newOrder.Status == 'Approved') {
                // IntegrationOutboundOrder.sendOrderToERP(newOrder.Id);
            }
        }

        if (!approvalRequests.isEmpty()) {
            Approval.process(approvalRequests);
        }
        */
    }
    
    public void afterDelete(List<SObject> oldRecords) {}
    public void afterUndelete(List<SObject> newRecords) {}
}