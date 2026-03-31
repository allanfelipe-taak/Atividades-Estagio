public with sharing class PricingItem {

    public OrderItem record {get; private set;}
    public Decimal custoProducao {get; set;}
    public Decimal frete {get; set;}
    public Decimal imposto {get; set;}
    public Decimal margem {get; set;}

    public PricingItem(OrderItem item) {
        this.record = item;
        
        // o custo direto do produto para o cálculo ser real
        if(item.Product2.Custo_Producao__c != null) {
            this.custoProducao = item.Product2.Custo_Producao__c;
        } else {
            this.custoProducao = 100.0; 
        }
    }

    
    // LÓGICA DE ESPECIFICIDADE (AQUI É ONDE O SISTEMA "PENSA")
    
    public Integer calcularPeso(SObject parametro) {
        Integer peso = 0;

        // 1. REGRA POR PRODUTO (Base): Vale pouco (10 pontos)
        if (parametro.get('Produto__c') != null && parametro.get('Produto__c') == record.Product2Id) {
            peso += 10;
        }

        // 2. REGRA POR CONTA (Específica): Vale muito (500 pontos)
        try {
            if (parametro.get('Conta__c') != null && parametro.get('Conta__c') == record.Order.AccountId) {
                peso += 500;
            }
        } catch(Exception e) { }

        // 3. REGRA POR CIDADE (Muito Específica): Vale o máximo (1000 pontos)
        try {
            if (parametro.get('Cidade__c') != null && parametro.get('Cidade__c') == record.Order.ShippingCity) {
                peso += 1000;
            }
        } catch(Exception e) { }

        return peso;
    }

    
    // FÓRMULA OBRIGATÓRIA E PERSISTÊNCIA (AUDITORIA)
    
    public void aplicarCalculoFinal() {
        Decimal c = (custoProducao != null) ? custoProducao : 0;
        Decimal f = (frete != null) ? frete : 0;
        Decimal i = (imposto != null) ? imposto / 100 : 0;
        Decimal m = (margem != null) ? margem / 100 : 0;

        // Fórmula: (Custo + Frete) * (1 + Imposto) * (1 + Margem)
        Decimal precoSemMargem = (c + f) * (1 + i);
        Decimal precoFinal = precoSemMargem * (1 + m);
        
        this.record.UnitPrice = precoFinal; 

        if (precoFinal > 0) {
            // Desconto 
            this.record.Desconto__c = ((precoFinal - this.record.UnitPrice) / precoFinal) * 100;
        }
        
        // PERSISTÊNCIA (Carimbo de Auditoria)
        this.record.Custo_Producao__c = c;
        this.record.Valor_Frete__c = f;
        this.record.Porcentagem_Imposto__c = (imposto != null ? imposto : 0); 
        this.record.Porcentagem_Margem__c = (margem != null ? margem : 0);
        this.record.Preco_sem_Margem__c = precoSemMargem;
        this.record.Preco_Final__c = precoFinal;
    }

    public class PricingException extends Exception {}
}