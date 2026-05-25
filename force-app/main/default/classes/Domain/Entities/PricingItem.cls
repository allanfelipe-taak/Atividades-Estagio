public with sharing class PricingItem {

    public OrderItem record {get; private set;}
    public Decimal productionCost {get; set;}
    public Decimal freight {get; set;}
    public Decimal tax {get; set;}
    public Decimal margin {get; set;}

public PricingItem(OrderItem item) {
    this.record = item;

    if(item.Product2.ProductionCost__c == null) {
        throw new PricingException('Erro: O produto ' + item.Product2.Name + ' não tem custo cadastrado!');
    }

    //  Guarda o custo na propriedade da classe!
    this.productionCost = item.Product2.ProductionCost__c;
}

    

    
    
    public Integer calculateWeight(SObject parameter) {
    Integer weight = 0;

    // Pega os campos de forma segura (sem precisar de try-catch!)
    Map<String, Object> fields = parameter.getPopulatedFieldsAsMap();

    // --- 3. CATEGORIA LOCALIDADE (Valores Baixos: 1 a 100) ---
    if (fields.containsKey('Country__c') && parameter.get('Country__c') != null) {
        weight += 1;
    }
    if (fields.containsKey('State__c') && parameter.get('State__c') != null) {
        weight += 10;
    }
    if (fields.containsKey('City__c') && parameter.get('City__c') != null) {
        weight += 100;
    }

    // --- 2. CATEGORIA CLIENTES (Valores Médios: 1.000 a 10.000) ---
    if (fields.containsKey('AccountGroup__c') && parameter.get('AccountGroup__c') != null) {
        weight += 1000;
    }
    if (fields.containsKey('Account__c') && parameter.get('Account__c') != null) {
        weight += 10000;
    }

    // --- 1. CATEGORIA PRODUTOS (Valores Gigantes: 100.000 a 1.000.000) ---
    // Corrigido para "ProductHierarchy__c"
    if (fields.containsKey('ProductHierarchy__c') && parameter.get('ProductHierarchy__c') != null) {
        weight += 100000;
    }
    if (fields.containsKey('Product__c') && parameter.get('Product__c') != null) {
        weight += 1000000; // 👑 O REI
    }

    return weight;
}

    
   
    // FÓRMULA OBRIGATÓRIA E PERSISTÊNCIA (AUDITORIA) 
    
    
    public void applyFinalCalculation() {
        Decimal c = (productionCost != null) ? productionCost : 0;
        Decimal f = (freight != null) ? freight : 0;
        Decimal i = (tax != null) ? tax / 100 : 0;
        Decimal m = (margin != null) ? margin / 100 : 0;

        // Fórmula: (Custo + Frete) * (1 + Imposto) * (1 + Margem)
        Decimal priceWithoutMargin = (c + f) * (1 + i);
        Decimal suggestedPrice = priceWithoutMargin * (1 + m);

        // Se o UnitPrice vier zerado (nova inserção), usamos o sugerido
        if (this.record.UnitPrice == null || this.record.UnitPrice <= 0) {
            this.record.UnitPrice = suggestedPrice;
        }

        if (suggestedPrice > 0) {
            // Se o UnitPrice for menor que o sugerido, teremos um desconto positivo.
            this.record.Discount__c = ((suggestedPrice - this.record.UnitPrice) / suggestedPrice) * 100;
        }

        // --- NOVIDADE: CARIMBO DE DATA PARA O AVISO INTELIGENTE ---
    // Este campo diz ao sistema EXATAMENTE quando o motor rodou.
    this.record.LastCalculationDate__c = System.now();

        // CARIMBO DE AUDITORIA (Não mexa aqui
        this.record.ProductionCost__c = c;
        this.record.FreightValue__c = f;
        this.record.TaxPercentage__c = (tax != null ? tax : 0);
        this.record.MarginPercentage__c = (margin != null ? margin : 0);
        this.record.PriceWithoutMargin__c = priceWithoutMargin;
        this.record.FinalPrice__c = suggestedPrice; // O valor que o motor queria cobrar
    }

    public class PricingException extends Exception {}
}