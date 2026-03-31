/**
 Camada de Infraestrutura responsável pelas consultas SOQL.
 */
public with sharing class PricingSelector {

    public static List<Margem__c> buscarMargens(Set<Id> productIds, Set<Id> accountIds, Set<Id> groupIds) {
        return [SELECT Id, Valor__c, Produto__c, 
                       Conta__c, Cidade__c, Estado__c, CreatedDate
                FROM Margem__c
                WHERE (Produto__c IN :productIds 
                     OR Conta__c IN :accountIds)
                // PRIORIDADE: Conta preenchida primeiro, depois a mais recente
                ORDER BY Conta__c DESC, CreatedDate DESC];
    }

    public static List<Frete__c> buscarFretes(Set<Id> productIds, Set<String> cidades, Set<String> estados) {
        return [SELECT Id, Valor__c, Produto__c, Cidade__c, Estado__c, CreatedDate
                FROM Frete__c
                WHERE (Produto__c IN :productIds OR Estado__c IN :estados OR Cidade__c IN :cidades)
                // PRIORIDADE: Cidade primeiro, depois Estado, por fim o Geral (null)
                ORDER BY Cidade__c DESC, Estado__c DESC, CreatedDate DESC];
    }

    public static List<Imposto__c> buscarImpostos(Set<Id> productIds, Set<Id> accountIds) {
        return [SELECT Id, Imposto_sobre_custo__c, Produto__c, CreatedDate 
                FROM Imposto__c 
                WHERE (Produto__c IN :productIds)
                // PRIORIDADE: O imposto mais atualizado (novo)
                ORDER BY CreatedDate DESC];
    }

    public static List<OrderItem> buscarItensComPedido(Set<Id> itemIds) {
        return [SELECT Id, OrderId, Product2Id, Quantity, UnitPrice, 
                       Order.AccountId, Order.Centro_Distribuicao__c, Order.Endereco__c,
                       Order.ShippingCity, Order.ShippingState
                FROM OrderItem 
                WHERE Id IN :itemIds];
    }
}