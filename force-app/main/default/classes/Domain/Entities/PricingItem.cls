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
    // Regra: Produto (Milhões) > Clientes (Milhares) > Localidade (Dezenas)
    
    
    public Integer calcularPeso(SObject parametro) {
    Integer peso = 0;
    
    // Pega os campos de forma segura (sem precisar de try-catch!)
    Map<String, Object> campos = parametro.getPopulatedFieldsAsMap();

    // --- 3. CATEGORIA LOCALIDADE (Valores Baixos: 1 a 100) ---
    if (campos.containsKey('Pais__c') && parametro.get('Pais__c') != null) {
        peso += 1;
    }
    if (campos.containsKey('Estado__c') && parametro.get('Estado__c') != null) {
        peso += 10;
    }
    if (campos.containsKey('Cidade__c') && parametro.get('Cidade__c') != null) {
        peso += 100;
    }

    // --- 2. CATEGORIA CLIENTES (Valores Médios: 1.000 a 10.000) ---
    if (campos.containsKey('Grupo_de_Conta__c') && parametro.get('Grupo_de_Conta__c') != null) {
        peso += 1000;
    }
    if (campos.containsKey('Conta__c') && parametro.get('Conta__c') != null) {
        peso += 10000;
    }

    // --- 1. CATEGORIA PRODUTOS (Valores Gigantes: 100.000 a 1.000.000) ---
    // Corrigido para "Hierarquia_de_Produto__c"
    if (campos.containsKey('Hierarquia_de_Produto__c') && parametro.get('Hierarquia_de_Produto__c') != null) {
        peso += 100000;
    }
    if (campos.containsKey('Produto__c') && parametro.get('Produto__c') != null) {
        peso += 1000000; // 👑 O REI
    }

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
        
        // CARIMBO DE AUDITORIA (Não mexa aqui
        this.record.Custo_Producao__c = c;
        this.record.Valor_Frete__c = f;
        this.record.Porcentagem_Imposto__c = (imposto != null ? imposto : 0); 
        this.record.Porcentagem_Margem__c = (margem != null ? margem : 0);
        this.record.Preco_sem_Margem__c = precoSemMargem;
        this.record.Preco_Final__c = precoSugerido; // O valor que o motor queria cobrar
    }

    public class PricingException extends Exception {}
}