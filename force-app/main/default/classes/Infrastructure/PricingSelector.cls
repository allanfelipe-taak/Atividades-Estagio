/**
 * Camada de Infraestrutura responsável pelas consultas SOQL.
 * Ajustada para cumprir os critérios de: Registros Aprovados, Especificidade e Custo.
 */
public with sharing class PricingSelector {

    public static List<Margin__c> searchMargins(Set<Id> productIds, Set<Id> accountIds, Set<Id> groupIds, Set<Id> hierarchyIds) {
        return [SELECT Id, Name, Value__c, Product__c, ProductHierarchy__c, Account__c, AccountGroup__c, City__c, State__c, Country__c, DistributionCenter__c
                FROM Margin__c
                WHERE Status__c = 'Approved'
                AND (Product__c IN :productIds
                     OR ProductHierarchy__c IN :hierarchyIds
                     OR Account__c IN :accountIds
                     OR AccountGroup__c IN :groupIds)];
    }

    public static List<Freight__c> searchFreights(Set<Id> productIds, Set<Id> hierarchyIds, Set<String> cities, Set<String> states, Set<String> countries) {
        return [SELECT Id, Name, Value__c, Product__c, ProductHierarchy__c, City__c, State__c, Country__c, DistributionCenter__c
                FROM Freight__c
                WHERE Status__c = 'Approved'
                AND (Product__c IN :productIds
                     OR ProductHierarchy__c IN :hierarchyIds
                     OR State__c IN :states
                     OR City__c IN :cities
                     OR Country__c IN :countries)];
    }

    public static List<Tax__c> searchTaxes(Set<Id> productIds, Set<String> states, Set<String> countries) {
        return [SELECT Id, Name, TaxOnCost__c, Product__c, State__c, Country__c, DistributionCenter__c
                FROM Tax__c
                WHERE Status__c = 'Approved'
                AND (Product__c IN :productIds
                     OR State__c IN :states
                     OR Country__c IN :countries)];
    }

    public static List<OrderItem> searchItemsWithOrder(Set<Id> itemIds) {
        return [SELECT Id, OrderId, Product2Id, Quantity, UnitPrice,
                       Order.AccountId, Order.DistributionCenter__c, Order.Address__c,
                       Order.ShippingCity, Order.ShippingState, Order.ShippingCountry,
                       Order.Account.AccountGroup__c,
                       Product2.ProductionCost__c, // <--- AQUI: O CUSTO QUE FALTAVA!
                       Product2.ProductHierarchy__c
                FROM OrderItem
                WHERE Id IN :itemIds];
    }
}