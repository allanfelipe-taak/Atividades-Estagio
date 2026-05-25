/**
 * @description Testes para PricingService
 * @author Unit Testing Agent
 */
@isTest
private class PricingServiceTest {

    @testSetup
    static void setupData() {
        TestFactorySObject factory = TestFactorySObject.getInstance();

        // Infraestrutura
        DistributionCenter__c cd = (DistributionCenter__c) factory.createSObject(new DistributionCenter__c(Name = 'CD Test'));
        insert cd;

        City__c city = (City__c) factory.createSObject(new City__c(Name = 'Test City'));
        insert city;

        State__c state = (State__c) factory.createSObject(new State__c(Name = 'Test State'));
        insert state;

        Country__c country = (Country__c) factory.createSObject(new Country__c(Name = 'Test Country'));
        insert country;

        Address__c address = (Address__c) factory.createSObject(new Address__c(Name = 'Test Address'));
        insert address;

        PaymentTerm__c paymentTerm = (PaymentTerm__c) factory.createSObject(new PaymentTerm__c(Name = 'Test Payment Term'));
        insert paymentTerm;

        // Produtos
        ProductHierarchy__c hierarchy = (ProductHierarchy__c) factory.createSObject(new ProductHierarchy__c(Name = 'Test Hierarchy'));
        insert hierarchy;

        Product2 product = (Product2) factory.createSObject(new Product2(
            Name = 'Test Product',
            ProductionCost__c = 100.00,
            ProductHierarchy__c = hierarchy.Id
        ));
        insert product;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 150.00,
            IsActive = true
        );
        insert pbe;

        // Contas
        AccountGroup__c accountGroup = (AccountGroup__c) factory.createSObject(new AccountGroup__c(Name = 'Test Group'));
        insert accountGroup;

        Account account = (Account) factory.createSObject(new Account(Name = 'Test Account'));
        insert account;

        // Regras de Preço
        Margin__c margin = (Margin__c) factory.createSObject(new Margin__c(
            Product__c = product.Id,
            Account__c = account.Id,
            City__c = city.Id,
            Value__c = 10,
            Status__c = 'Approved',
            DistributionCenter__c = cd.Id
        ));
        insert margin;

        Freight__c freight = (Freight__c) factory.createSObject(new Freight__c(
            Product__c = product.Id,
            City__c = city.Id,
            Value__c = 50,
            Status__c = 'Approved',
            DistributionCenter__c = cd.Id
        ));
        insert freight;

        Tax__c tax = (Tax__c) factory.createSObject(new Tax__c(
            Product__c = product.Id,
            State__c = state.Id,
            TaxOnCost__c = 12,
            Status__c = 'Approved',
            DistributionCenter__c = cd.Id
        ));
        insert tax;

        // Pedido
        Order order = new Order(
            AccountId = account.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId(),
            DistributionCenter__c = cd.Id,
            Address__c = address.Id,
            PaymentTerm__c = paymentTerm.Id,
            ShippingCity = 'Test City',
            ShippingState = 'Test State',
            ShippingCountry = 'Test Country'
        );
        insert order;
    }

    @isTest
    static void testPricingService_processPricing_singleItem() {
        // Arrange
        Order order = [SELECT Id, AccountId FROM Order LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        OrderItem item = new OrderItem(
            OrderId = order.Id,
            Product2Id = product.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert item;

        // Aqui a trigger vai chamar PricingService
        OrderItem processed = [SELECT
            Id,
            FreightValue__c,
            TaxPercentage__c,
            MarginPercentage__c
            FROM OrderItem
            WHERE Id = :item.Id
        ];

        // Verify - O motor deve ter preenchido os campos
        System.assertNotEquals(null, processed.FreightValue__c, 'Frete deve ter sido preenchido');
        System.assertNotEquals(null, processed.TaxPercentage__c, 'Imposto deve ter sido preenchido');
        System.assertNotEquals(null, processed.MarginPercentage__c, 'Margem deve ter sido preenchida');
    }

    @isTest
    static void testPricingService_processPricing_bulkItems() {
        // Arrange
        Order order = [SELECT Id FROM Order LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        List<OrderItem> items = new List<OrderItem>();
        for (Integer i = 0; i < 200; i++) {
            items.add(new OrderItem(
                OrderId = order.Id,
                Product2Id = product.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1 + Math.mod(i, 10),
                UnitPrice = 100 + i
            ));
        }

        Test.startTest();
        insert items;
        Test.stopTest();

        // Verify
        List<OrderItem> processed = [
            SELECT Id, FreightValue__c, TaxPercentage__c, MarginPercentage__c
            FROM OrderItem
            WHERE OrderId = :order.Id
        ];

        System.assertEquals(200, processed.size(), 'Todos os 200 itens devem ter sido processados');
        for (OrderItem item : processed) {
            System.assertNotEquals(null, item.FreightValue__c, 'Frete deve ter sido preenchido para cada item');
        }
    }

    @isTest
    static void testPricingService_recalculate() {
        // Arrange
        Order order = [SELECT Id FROM Order LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        OrderItem item = new OrderItem(
            OrderId = order.Id,
            Product2Id = product.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert item;

        Boolean initialRecalculated = order.PricesRecalculated__c;

        Test.startTest();
        PricingService.recalculate(order.Id);
        Test.stopTest();

        // Verify
        Order updated = [SELECT PricesRecalculated__c FROM Order WHERE Id = :order.Id];
        System.assertEquals(true, updated.PricesRecalculated__c, 'Flag de recalculação deve estar marcada');
    }

    @isTest
    static void testPricingService_processPricing_missingRulesError() {
        // Arrange
        Account account = [SELECT Id FROM Account LIMIT 1];
        Order order = [SELECT Id, Pricebook2Id FROM Order LIMIT 1];

        // Criar produto SEM regras de preço
        Product2 orphanProduct = new Product2(Name = 'Orphan Product', ProductionCost__c = 100);
        insert orphanProduct;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = order.Pricebook2Id,
            Product2Id = orphanProduct.Id,
            UnitPrice = 150,
            IsActive = true
        );
        insert pbe;

        OrderItem item = new OrderItem(
            OrderId = order.Id,
            Product2Id = orphanProduct.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );

        Test.startTest();
        try {
            insert item;
            System.assert(false, 'Deveria ter dado erro: Produto sem regras de preço');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('falta de parâmetros') || e.getMessage().contains('não tem custo'),
                'Mensagem de erro esperada');
        }
        Test.stopTest();
    }

    @isTest
    static void testPricingService_calculateWeight() {
        // Arrange
        Product2 product = [SELECT Id, ProductionCost__c FROM Product2 LIMIT 1];
        OrderItem item = new OrderItem(UnitPrice = 100, Quantity = 1);
        item.Product2 = product;

        PricingItem pricingItem = new PricingItem(item);

        // Criar uma regra para testar o peso
        Account account = [SELECT Id FROM Account LIMIT 1];
        City__c city = [SELECT Id FROM City__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Margin__c specificMargin = new Margin__c(
            Product__c = product.Id,
            Account__c = account.Id,
            City__c = city.Id,
            Value__c = 10,
            Status__c = 'Approved',
            DistributionCenter__c = cd.Id
        );
        insert specificMargin;

        Test.startTest();
        Integer weight = pricingItem.calculateWeight(specificMargin);
        Test.stopTest();

        // Verify - A especificidade deve ter gerado peso alto
        Assert.isTrue(weight > 0, 'Peso deve ser positivo');
        Assert.isTrue(weight > 10000, 'Peso para regra específica deve ser alto (>10000 para Account)');
    }
}
