public with sharing class PricingService {
   
    public void processarPricing(List<OrderItem> itensOriginais) {
        Set<Id> orderIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();

        for (OrderItem oi : itensOriginais) {
            if (oi.OrderId != null) orderIds.add(oi.OrderId);
            if (oi.Product2Id != null) productIds.add(oi.Product2Id);
        }

        Map<Id, Order> mapPedidos = new Map<Id, Order>([
            SELECT Id, AccountId, ShippingCity, ShippingState, 
                   Centro_Distribuicao__c, Endereco__c 
            FROM Order 
            WHERE Id IN :orderIds
        ]);

        Set<Id> accountIds = new Set<Id>();
        Set<String> cidades = new Set<String>();
        Set<String> estados = new Set<String>();

        for (Order ped : mapPedidos.values()) {
            accountIds.add(ped.AccountId);
            cidades.add(ped.ShippingCity);
            estados.add(ped.ShippingState);
        }

        List<Margem__c> margens = PricingSelector.buscarMargens(productIds, accountIds, new Set<Id>());
        List<Imposto__c> impostos = PricingSelector.buscarImpostos(productIds, accountIds);
        List<Frete__c> fretes = PricingSelector.buscarFretes(productIds, cidades, estados);

        for (OrderItem itemOriginal : itensOriginais) {
            Order pedidoRelacionado = mapPedidos.get(itemOriginal.OrderId);
            if (pedidoRelacionado == null) continue;

            itemOriginal.Order = pedidoRelacionado; 
            PricingItem entity = new PricingItem(itemOriginal);
            
            Margem__c melhorMargem = (Margem__c) encontrarMelhorParametro(margens, entity);
            Frete__c melhorFrete = (Frete__c) encontrarMelhorParametro(fretes, entity);
            Imposto__c melhorImposto = (Imposto__c) encontrarMelhorParametro(impostos, entity);

            if (melhorMargem != null && melhorFrete != null && melhorImposto != null) {
                entity.margem = melhorMargem.Valor__c;
                entity.frete = melhorFrete.Valor__c;
                entity.imposto = melhorImposto.Imposto_sobre_custo__c;

                entity.aplicarCalculoFinal();
                
                // Atribui ao campo padrão UnitPrice
                itemOriginal.UnitPrice = entity.record.UnitPrice; 

                // --- LINHAS COMENTADAS PARA O DEPLOY PASSAR ---
                // Descomente apenas após criar os campos no Salesforce Object Manager
                /*
                itemOriginal.Valor_de_Frete__c = melhorFrete.Valor__c;
                itemOriginal.Porcentagem_de_Imposto__c = melhorImposto.Imposto_sobre_custo__c;
                itemOriginal.Porcentagem_de_Margem__c = melhorMargem.Valor__c;
                itemOriginal.Custo_Producao_Base__c = entity.custoProducao;
                */
                
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
}