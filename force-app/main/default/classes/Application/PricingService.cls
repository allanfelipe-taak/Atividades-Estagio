public with sharing class PricingService {

    public void processPricing(List<OrderItem> originalItems) {
        Set<Id> orderIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();

        for (OrderItem oi : originalItems) {
            if (oi.OrderId != null) orderIds.add(oi.OrderId);
            if (oi.Product2Id != null) productIds.add(oi.Product2Id);
        }

        Map<Id, Order> orderMap = new Map<Id, Order>([
            SELECT Id, AccountId, ShippingCity, ShippingState, ShippingCountry,
                   DistributionCenter__c, Address__c
            FROM Order
            WHERE Id IN :orderIds
        ]);

       // 2. CORREÇÃO AQUI: Adicionado ProductionCost__c E Name no SELECT 👇
        Map<Id, Product2> productMap = new Map<Id, Product2>([
            SELECT Id, Name, ProductHierarchy__c, ProductionCost__c
            FROM Product2
            WHERE Id IN :productIds
        ]);

        Set<Id> accountIds = new Set<Id>();
        Set<String> cities = new Set<String>();
        Set<String> states = new Set<String>();
        Set<String> countries = new Set<String>();
        Set<Id> hierarchyIds = new Set<Id>();

        for (Order order : orderMap.values()) {
            if (order.AccountId != null) accountIds.add(order.AccountId);
            if (order.ShippingCity != null) cities.add(order.ShippingCity);
            if (order.ShippingState != null) states.add(order.ShippingState);
            if (order.ShippingCountry != null) countries.add(order.ShippingCountry);
        }

        for (Product2 product : productMap.values()) {
            if (product.ProductHierarchy__c != null) {
                hierarchyIds.add(product.ProductHierarchy__c);
            }
        }

        List<Margin__c> margins = PricingSelector.searchMargins(productIds, accountIds, new Set<Id>(), hierarchyIds);
        List<Tax__c> taxes = PricingSelector.searchTaxes(productIds, states, countries);
        List<Freight__c> freights = PricingSelector.searchFreights(productIds, hierarchyIds, cities, states, countries);

        for (OrderItem originalItem : originalItems) {
            Order relatedOrder = orderMap.get(originalItem.OrderId);
            if (relatedOrder == null) continue;

            originalItem.Order = relatedOrder;

            if (productMap.containsKey(originalItem.Product2Id)) {
                // VINCULAR O PRODUTO COMPLETO (COM CUSTO) AO ITEM
                originalItem.Product2 = productMap.get(originalItem.Product2Id);
            }


            PricingItem entity = new PricingItem(originalItem);

            Margin__c bestMargin = (Margin__c) findBestParameter(margins, entity);
            Freight__c bestFreight = (Freight__c) findBestParameter(freights, entity);
            Tax__c bestTax = (Tax__c) findBestParameter(taxes, entity);

            if (bestMargin != null) {
                System.debug('[MOTOR] MARGEM: ' + bestMargin.Name + ' | Peso: ' + entity.calculateWeight(bestMargin));
            }
            if (bestFreight != null) {
                System.debug(' [MOTOR] FRETE: ' + bestFreight.Name + ' | Peso: ' + entity.calculateWeight(bestFreight));
            }
            if (bestTax != null) {
                System.debug('[MOTOR] IMPOSTO: ' + bestTax.Name + ' | Peso: ' + entity.calculateWeight(bestTax));
            }

            if (bestMargin != null && bestFreight != null && bestTax != null) {
                entity.margin = bestMargin.Value__c;
                entity.freight = bestFreight.Value__c;
                entity.tax = bestTax.TaxOnCost__c;

                entity.applyFinalCalculation();

                originalItem.UnitPrice = entity.record.UnitPrice;
                originalItem.FreightValue__c = bestFreight.Value__c;
                originalItem.TaxPercentage__c = bestTax.TaxOnCost__c;
                originalItem.MarginPercentage__c = bestMargin.Value__c;
                originalItem.Discount__c = entity.record.Discount__c;
                originalItem.PriceWithoutMargin__c = entity.record.PriceWithoutMargin__c;
                originalItem.FinalPrice__c = entity.record.FinalPrice__c;
                originalItem.ProductionCost__c = entity.record.ProductionCost__c;
                originalItem.LastCalculationDate__c = entity.record.LastCalculationDate__c;

            } else {
                originalItem.addError('Não está autorizada a venda deste produto devido à falta de parâmetros. Contate o time de Pricing.');
            }
        } 
    }

   

    private SObject findBestParameter(List<SObject> candidates, PricingItem entity) {
        SObject winner = null;
        Integer highestWeight = -1;

        for (SObject candidate : candidates) {
            Integer currentWeight = entity.calculateWeight(candidate);
            if (currentWeight > highestWeight) {
                highestWeight = currentWeight;
                winner = candidate;
            }
        }
        return winner;
    }


    @AuraEnabled // Isso permite que o JavaScript enxergue esse método
    public static void recalculate(Id orderId) {
        // Busca os itens
        List<OrderItem> items = [SELECT Id FROM OrderItem WHERE OrderId = :orderId];

        // Faz o "touch" (atualiza os registros para disparar sua Trigger)
        update items;

        // Atualiza o checkbox do pedido para sumir o aviso
        update new Order(Id = orderId, PricesRecalculated__c = true);
    }
   
}