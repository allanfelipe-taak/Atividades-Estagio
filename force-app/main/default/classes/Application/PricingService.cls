public with sharing class PricingService {
   
    public void processarPricing(List<OrderItem> itensOriginais) {
        Set<Id> orderIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();

        for (OrderItem oi : itensOriginais) {
            if (oi.OrderId != null) orderIds.add(oi.OrderId);
            if (oi.Product2Id != null) productIds.add(oi.Product2Id);
        }

        Map<Id, Order> mapPedidos = new Map<Id, Order>([
            SELECT Id, AccountId, ShippingCity, ShippingState, ShippingCountry, 
                   Centro_Distribuicao__c, Endereco__c 
            FROM Order 
            WHERE Id IN :orderIds
        ]);

        // 2. CORREÇÃO AQUI: Adicionado Custo_Producao__c no SELECT 👇
        Map<Id, Product2> mapProdutos = new Map<Id, Product2>([
            SELECT Id, Hierarquia_de_Produto__c, Custo_Producao__c 
            FROM Product2
            WHERE Id IN :productIds
        ]);

        Set<Id> accountIds = new Set<Id>();
        Set<String> cidades = new Set<String>();
        Set<String> estados = new Set<String>();
        Set<String> paises = new Set<String>();
        Set<Id> hierarquiaIds = new Set<Id>();

        for (Order ped : mapPedidos.values()) {
            if (ped.AccountId != null) accountIds.add(ped.AccountId);
            if (ped.ShippingCity != null) cidades.add(ped.ShippingCity);
            if (ped.ShippingState != null) estados.add(ped.ShippingState);
            if (ped.ShippingCountry != null) paises.add(ped.ShippingCountry);
        }

        for (Product2 prod : mapProdutos.values()) {
            if (prod.Hierarquia_de_Produto__c != null) {
                hierarquiaIds.add(prod.Hierarquia_de_Produto__c);
            }
        }

        List<Margem__c> margens = PricingSelector.buscarMargens(productIds, accountIds, new Set<Id>(), hierarquiaIds);
        List<Imposto__c> impostos = PricingSelector.buscarImpostos(productIds, estados, paises);
        List<Frete__c> fretes = PricingSelector.buscarFretes(productIds, hierarquiaIds, cidades, estados, paises);

        for (OrderItem itemOriginal : itensOriginais) {
            Order pedidoRelacionado = mapPedidos.get(itemOriginal.OrderId);
            if (pedidoRelacionado == null) continue;

            itemOriginal.Order = pedidoRelacionado; 
            
            if (mapProdutos.containsKey(itemOriginal.Product2Id)) {
                // 👇 VINCULAMOS O PRODUTO COMPLETO (COM CUSTO) AO ITEM
                itemOriginal.Product2 = mapProdutos.get(itemOriginal.Product2Id);
            }

            // Agora a linha 64 não vai mais dar erro!
            PricingItem entity = new PricingItem(itemOriginal);
            
            Margem__c melhorMargem = (Margem__c) encontrarMelhorParametro(margens, entity);
            Frete__c melhorFrete = (Frete__c) encontrarMelhorParametro(fretes, entity);
            Imposto__c melhorImposto = (Imposto__c) encontrarMelhorParametro(impostos, entity);

            if (melhorMargem != null) {
                System.debug('🏆 [MOTOR] MARGEM: ' + melhorMargem.Name + ' | Peso: ' + entity.calcularPeso(melhorMargem));
            }
            if (melhorFrete != null) {
                System.debug('🚚 [MOTOR] FRETE: ' + melhorFrete.Name + ' | Peso: ' + entity.calcularPeso(melhorFrete));
            }
            if (melhorImposto != null) {
                System.debug('📑 [MOTOR] IMPOSTO: ' + melhorImposto.Name + ' | Peso: ' + entity.calcularPeso(melhorImposto));
            }

            if (melhorMargem != null && melhorFrete != null && melhorImposto != null) {
                entity.margem = melhorMargem.Valor__c;
                entity.frete = melhorFrete.Valor__c;
                entity.imposto = melhorImposto.Imposto_sobre_custo__c;

                entity.aplicarCalculoFinal();
                
                itemOriginal.UnitPrice = entity.record.UnitPrice; 
                itemOriginal.Valor_Frete__c = melhorFrete.Valor__c;
                itemOriginal.Porcentagem_Imposto__c = melhorImposto.Imposto_sobre_custo__c;
                itemOriginal.Porcentagem_Margem__c = melhorMargem.Valor__c;
                
            } else {
                itemOriginal.addError('Não está autorizada a venda deste produto devido à falta de parâmetros. Contate o time de Pricing.');
            }
        } 
    }

   

    private SObject encontrarMelhorParametro(List<SObject> candidatos, PricingItem entity) {
        SObject vencedor = null;
        Integer maiorPeso = -1;

        for (SObject cand : candidatos) {
            Integer pesoAtual = entity.calcularPeso(cand);
            if (pesoAtual > maiorPeso) {
                maiorPeso = pesoAtual;
                vencedor = cand;
            }
        }
        return vencedor;
    }

    
    @AuraEnabled // Isso permite que o JavaScript enxergue esse método
    public static void recalcular(Id orderId) {
        // Busca os itens
        List<OrderItem> itens = [SELECT Id FROM OrderItem WHERE OrderId = :orderId];
        
        // Faz o "touch" (atualiza os registros para disparar sua Trigger)
        update itens; 
        
        // Atualiza o checkbox do pedido para sumir o aviso
        update new Order(Id = orderId, Precos_Recalculados__c = true);
    }



   
}


