/**
 * Camada de Infraestrutura responsável pelas consultas SOQL.
 * Ajustada para cumprir os critérios de: Registros Aprovados, Especificidade e Custo.
 */
public with sharing class PricingSelector {

    public static List<Margem__c> buscarMargens(Set<Id> productIds, Set<Id> accountIds, Set<Id> groupIds, Set<Id> hierarquiaIds) {
        return [SELECT Id, Name, Valor__c, Produto__c, Hierarquia_de_Produto__c, Conta__c, Grupo_de_Conta__c, Cidade__c, Estado__c, Pais__c, Centro_Distribuicao__c
                FROM Margem__c
                WHERE Status__c = 'Aprovado' 
                AND (Produto__c IN :productIds 
                     OR Hierarquia_de_Produto__c IN :hierarquiaIds
                     OR Conta__c IN :accountIds 
                     OR Grupo_de_Conta__c IN :groupIds)]; 
    }

    public static List<Frete__c> buscarFretes(Set<Id> productIds, Set<Id> hierarquiaIds, Set<String> cidades, Set<String> estados, Set<String> paises) {
        return [SELECT Id, Name, Valor__c, Produto__c, Hierarquia_de_Produto__c, Cidade__c, Estado__c, Pais__c, Centro_Distribuicao__c
                FROM Frete__c
                WHERE Status__c = 'Aprovado' 
                AND (Produto__c IN :productIds 
                     OR Hierarquia_de_Produto__c IN :hierarquiaIds
                     OR Estado__c IN :estados 
                     OR Cidade__c IN :cidades
                     OR Pais__c IN :paises)];
    }

    public static List<Imposto__c> buscarImpostos(Set<Id> productIds, Set<String> estados, Set<String> paises) {
        return [SELECT Id, Name, Imposto_sobre_custo__c, Produto__c, Estado__c, Pais__c, Centro_Distribuicao__c
                FROM Imposto__c 
                WHERE Status__c = 'Aprovado' 
                AND (Produto__c IN :productIds
                     OR Estado__c IN :estados
                     OR Pais__c IN :paises)];
    }

    public static List<OrderItem> buscarItensComPedido(Set<Id> itemIds) {
        return [SELECT Id, OrderId, Product2Id, Quantity, UnitPrice, 
                       Order.AccountId, Order.Centro_Distribuicao__c, Order.Endereco__c,
                       Order.ShippingCity, Order.ShippingState, Order.ShippingCountry,
                       Order.Account.Grupo_de_Conta__c, 
                       Product2.Custo_Producao__c, // <--- AQUI: O CUSTO QUE FALTAVA!
                       Product2.Hierarquia_de_Produto__c 
                FROM OrderItem 
                WHERE Id IN :itemIds];
    }
}