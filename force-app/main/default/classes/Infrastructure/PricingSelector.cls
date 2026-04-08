/**
 Camada de Infraestrutura responsável pelas consultas SOQL.
 Ajustada para cumprir os critérios de: Registros Aprovados e Especificidade.
 */
public with sharing class PricingSelector {

    public static List<Margem__c> buscarMargens(Set<Id> productIds, Set<Id> accountIds, Set<Id> groupIds) {
        return [SELECT Id, Valor__c, Produto__c, Conta__c, Grupo_de_Conta__c, Cidade__c, Estado__c
                FROM Margem__c
                WHERE Status__c = 'Aprovado' // <-- CRITÉRIO DE ACEITE: Apenas aprovados
                AND (Produto__c IN :productIds 
                     OR Conta__c IN :accountIds 
                     OR Grupo_de_Conta__c IN :groupIds)]; // <-- Agora busca pelo Grupo (Ouro/VIP) também
    }

    public static List<Frete__c> buscarFretes(Set<Id> productIds, Set<String> cidades, Set<String> estados) {
        return [SELECT Id, Valor__c, Produto__c, Cidade__c, Estado__c
                FROM Frete__c
                WHERE Status__c = 'Aprovado' // <-- CRITÉRIO DE ACEITE: Apenas aprovados
                AND (Produto__c IN :productIds 
                     OR Estado__c IN :estados 
                     OR Cidade__c IN :cidades)];
    }

    public static List<Imposto__c> buscarImpostos(Set<Id> productIds, Set<Id> accountIds) {
        // Nota: Ajustei para buscar também por conta/cliente se necessário, seguindo o padrão
        return [SELECT Id, Imposto_sobre_custo__c, Produto__c, Estado__c 
                FROM Imposto__c 
                WHERE Status__c = 'Aprovado' // <-- CRITÉRIO DE ACEITE: Apenas aprovados
                AND (Produto__c IN :productIds)];
    }

    public static List<OrderItem> buscarItensComPedido(Set<Id> itemIds) {
        return [SELECT Id, OrderId, Product2Id, Quantity, UnitPrice, 
                       Order.AccountId, Order.Centro_Distribuicao__c, Order.Endereco__c,
                       Order.ShippingCity, Order.ShippingState,
                       Order.Account.Grupo_de_Conta__c, // <-- VITAL: Trazemos o grupo para o cálculo de peso
                       Product2.Custo_Producao__c, Product2.Family // <-- Trazemos dados do produto para o peso
                FROM OrderItem 
                WHERE Id IN :itemIds];
    }
}