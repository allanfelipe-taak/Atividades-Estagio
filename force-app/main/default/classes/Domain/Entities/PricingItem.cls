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

    
    // LÓGICA DE ESPECIFICIDADE (O NOVO CÉREBRO)
    // Regra do Matheus: Produto (Milhões) > Clientes (Milhares) > Localidade (Dezenas)
    
    
    public Integer calcularPeso(SObject parametro) {
        Integer peso = 0;

        // --- 3. CATEGORIA LOCALIDADE (Valores Baixos: 1 a 100) ---
        // País (Se você tiver esse campo, vale 1)
        try {
            if (parametro.get('Pais__c') != null && parametro.get('Pais__c') == record.Order.ShippingCountry) peso += 1;
        } catch(Exception e) { }
        
        // Estado (Vale 10)
        try {
            if (parametro.get('Estado__c') != null && parametro.get('Estado__c') == record.Order.ShippingState) peso += 10;
        } catch(Exception e) { }
        
        // Cidade (Vale 100 - Mais forte da localidade)
        try {
            if (parametro.get('Cidade__c') != null && parametro.get('Cidade__c') == record.Order.ShippingCity) peso += 100;
        } catch(Exception e) { }


        // --- 2. CATEGORIA CLIENTES (Valores Médios: 1.000 a 10.000) ---
        // Grupo de Conta (Vale 1.000)
        try {
            Id grupoDoCliente = record.Order.Account.Grupo_de_Conta__c; 
            Id grupoNaRegra = (Id)parametro.get('Grupo_de_Conta__c'); 
            if (grupoDoCliente != null && grupoDoCliente == grupoNaRegra) peso += 1000;
        } catch(Exception e) { }
        
        // Conta Exata (Vale 10.000 - Mais forte de clientes)
        try {
            if (parametro.get('Conta__c') != null && parametro.get('Conta__c') == record.Order.AccountId) peso += 10000;
        } catch(Exception e) { }


        // --- 1. CATEGORIA PRODUTOS (Valores Gigantes: 100.000 a 1.000.000) ---
        // Hierarquia de Produto (Ex: Família do Produto - Vale 100.000)
        try {
            if (parametro.get('Hierarquia_Produto__c') != null && parametro.get('Hierarquia_Produto__c') == record.Product2.Family) peso += 100000;
        } catch(Exception e) { }
        
        // Produto Exato (O REI 👑 - Vale 1.000.000!)
        try {
            if (parametro.get('Produto__c') != null && parametro.get('Produto__c') == record.Product2Id) peso += 1000000;
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
        Decimal precoSugerido = precoSemMargem * (1 + m);
        
        // Se o UnitPrice vier zerado (nova inserção), usamos o sugerido
        if (this.record.UnitPrice == null || this.record.UnitPrice <= 0) {
            this.record.UnitPrice = precoSugerido;
        }

        // Agora o cálculo do desconto faz sentido! 
        // Comparamos o PREÇO SUGERIDO pelo motor vs o PREÇO PRATICADO (UnitPrice)
        if (precoSugerido > 0) {
            // Se o UnitPrice for menor que o sugerido, teremos um desconto positivo.
            this.record.Desconto__c = ((precoSugerido - this.record.UnitPrice) / precoSugerido) * 100;
        }
        
        // CARIMBO DE AUDITORIA (Não mexa aqui, está ótimo para provar pro Matheus)
        this.record.Custo_Producao__c = c;
        this.record.Valor_Frete__c = f;
        this.record.Porcentagem_Imposto__c = (imposto != null ? imposto : 0); 
        this.record.Porcentagem_Margem__c = (margem != null ? margem : 0);
        this.record.Preco_sem_Margem__c = precoSemMargem;
        this.record.Preco_Final__c = precoSugerido; // O valor que o motor queria cobrar
    }

    public class PricingException extends Exception {}
}