/**
 * @description Testes para os Triggers (FreightTrigger, TaxTrigger, MarginTrigger, OrderTrigger, OrderItemTrigger)
 * @author Unit Testing Agent
 */
@isTest
private class TriggersTest {

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
            PaymentTerm__c = paymentTerm.Id
        );
        insert order;
    }

    // ===================================================================
    // FREIGHT TRIGGER TESTS
    // ===================================================================

    @isTest
    static void testFreightTrigger_insertSingleRecord() {
        // Arrange
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        City__c city = [SELECT Id FROM City__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Freight__c freight = new Freight__c(
            Product__c = product.Id,
            City__c = city.Id,
            Value__c = 50,
            Status__c = 'Approved',
            DistributionCenter__c = cd.Id
        );

        Test.startTest();
        insert freight;
        Test.stopTest();

        // Verify
        Freight__c inserted = [SELECT Id, Product__c, Value__c FROM Freight__c WHERE Id = :freight.Id];
        System.assertNotEquals(null, inserted.Id, 'Frete deve ter sido inserido');
    }

    @isTest
    static void testFreightTrigger_bulkInsert() {
        // Arrange
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        ProductHierarchy__c hierarchy = [SELECT Id FROM ProductHierarchy__c LIMIT 1];
        State__c state = [SELECT Id FROM State__c LIMIT 1];
        Country__c country = [SELECT Id FROM Country__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        List<Freight__c> freightList = new List<Freight__c>();
        for (Integer i = 0; i < 200; i++) {
            // Variar as localidades para não dar duplicidade
            if (i < 100) {
                freightList.add(new Freight__c(
                    Product__c = product.Id,
                    State__c = state.Id,
                    Value__c = 50 + i,
                    Status__c = 'Approved',
                    DistributionCenter__c = cd.Id
                ));
            } else {
                freightList.add(new Freight__c(
                    ProductHierarchy__c = hierarchy.Id,
                    Country__c = country.Id,
                    Value__c = 150 + i,
                    Status__c = 'Approved',
                    DistributionCenter__c = cd.Id
                ));
            }
        }

        Test.startTest();
        insert freightList;
        Test.stopTest();

        // Verify
        List<Freight__c> inserted = [SELECT Id FROM Freight__c];
        System.assertEquals(200, inserted.size(), 'Todos os 200 registros devem ter sido inseridos');
    }

    @isTest
    static void testFreightTrigger_updateRecord() {
        // Arrange
        Freight__c freight = [SELECT Id, Value__c FROM Freight__c LIMIT 1];
        Decimal newValue = 99.99;

        Test.startTest();
        freight.Value__c = newValue;
        update freight;
        Test.stopTest();

        // Verify
        Freight__c updated = [SELECT Value__c FROM Freight__c WHERE Id = :freight.Id];
        System.assertEquals(newValue, updated.Value__c, 'Valor deve ter sido atualizado');
    }

    // ===================================================================
    // TAX TRIGGER TESTS
    // ===================================================================

    @isTest
    static void testTaxTrigger_insertSingleRecord() {
        // Arrange
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        Country__c country = [SELECT Id FROM Country__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Tax__c tax = new Tax__c(
            Product__c = product.Id,
            Country__c = country.Id,
            TaxOnCost__c = 15,
            Status__c = 'Approved',
            DistributionCenter__c = cd.Id
        );

        Test.startTest();
        insert tax;
        Test.stopTest();

        // Verify
        Tax__c inserted = [SELECT Id, TaxOnCost__c FROM Tax__c WHERE Id = :tax.Id];
        System.assertNotEquals(null, inserted.Id, 'Imposto deve ter sido inserido');
        System.assertEquals(15, inserted.TaxOnCost__c, 'Valor de imposto deve estar correto');
    }

    @isTest
    static void testTaxTrigger_bulkInsert() {
        // Arrange
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        State__c state = [SELECT Id FROM State__c LIMIT 1];
        Country__c country = [SELECT Id FROM Country__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        List<Tax__c> taxList = new List<Tax__c>();
        for (Integer i = 0; i < 200; i++) {
            if (i < 100) {
                taxList.add(new Tax__c(
                    Product__c = product.Id,
                    State__c = state.Id,
                    TaxOnCost__c = 12 + (i * 0.01),
                    Status__c = 'Approved',
                    DistributionCenter__c = cd.Id
                ));
            } else {
                taxList.add(new Tax__c(
                    Product__c = product.Id,
                    Country__c = country.Id,
                    TaxOnCost__c = 8 + ((i - 100) * 0.01),
                    Status__c = 'Approved',
                    DistributionCenter__c = cd.Id
                ));
            }
        }

        Test.startTest();
        insert taxList;
        Test.stopTest();

        // Verify
        List<Tax__c> inserted = [SELECT Id FROM Tax__c];
        System.assertEquals(200, inserted.size(), 'Todos os 200 registros devem ter sido inseridos');
    }

    @isTest
    static void testTaxTrigger_updateRecord() {
        // Arrange
        Tax__c tax = [SELECT Id, TaxOnCost__c FROM Tax__c LIMIT 1];
        Decimal newTax = 18.50;

        Test.startTest();
        tax.TaxOnCost__c = newTax;
        update tax;
        Test.stopTest();

        // Verify
        Tax__c updated = [SELECT TaxOnCost__c FROM Tax__c WHERE Id = :tax.Id];
        System.assertEquals(newTax, updated.TaxOnCost__c, 'Alíquota de imposto deve ter sido atualizada');
    }

    // ===================================================================
    // MARGIN TRIGGER TESTS
    // ===================================================================

    @isTest
    static void testMarginTrigger_insertSingleRecord() {
        // Arrange
        Account account = [SELECT Id FROM Account LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        State__c state = [SELECT Id FROM State__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Margin__c margin = new Margin__c(
            Account__c = account.Id,
            Product__c = product.Id,
            State__c = state.Id,
            Value__c = 15,
            Status__c = 'Approved',
            DistributionCenter__c = cd.Id
        );

        Test.startTest();
        insert margin;
        Test.stopTest();

        // Verify
        Margin__c inserted = [SELECT Id, Value__c FROM Margin__c WHERE Id = :margin.Id];
        System.assertNotEquals(null, inserted.Id, 'Margem deve ter sido inserida');
        System.assertEquals(15, inserted.Value__c, 'Valor de margem deve estar correto');
    }

    @isTest
    static void testMarginTrigger_bulkInsert() {
        // Arrange
        Account account = [SELECT Id FROM Account LIMIT 1];
        AccountGroup__c accountGroup = [SELECT Id FROM AccountGroup__c LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        ProductHierarchy__c hierarchy = [SELECT Id FROM ProductHierarchy__c LIMIT 1];
        State__c state = [SELECT Id FROM State__c LIMIT 1];
        Country__c country = [SELECT Id FROM Country__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        List<Margin__c> marginList = new List<Margin__c>();
        for (Integer i = 0; i < 200; i++) {
            if (i < 100) {
                marginList.add(new Margin__c(
                    Account__c = account.Id,
                    Product__c = product.Id,
                    State__c = state.Id,
                    Value__c = 10 + (i * 0.01),
                    Status__c = 'Approved',
                    DistributionCenter__c = cd.Id
                ));
            } else {
                marginList.add(new Margin__c(
                    AccountGroup__c = accountGroup.Id,
                    ProductHierarchy__c = hierarchy.Id,
                    Country__c = country.Id,
                    Value__c = 5 + ((i - 100) * 0.01),
                    Status__c = 'Approved',
                    DistributionCenter__c = cd.Id
                ));
            }
        }

        Test.startTest();
        insert marginList;
        Test.stopTest();

        // Verify
        List<Margin__c> inserted = [SELECT Id FROM Margin__c];
        Assert.isTrue(inserted.size() >= 200, 'Devem haver pelo menos 200 registros');
    }

    @isTest
    static void testMarginTrigger_updateRecord() {
        // Arrange
        Margin__c margin = [SELECT Id, Value__c FROM Margin__c LIMIT 1];
        Decimal newValue = 20.5;

        Test.startTest();
        margin.Value__c = newValue;
        update margin;
        Test.stopTest();

        // Verify
        Margin__c updated = [SELECT Value__c FROM Margin__c WHERE Id = :margin.Id];
        System.assertEquals(newValue, updated.Value__c, 'Valor de margem deve ter sido atualizado');
    }

    // ===================================================================
    // ORDER TRIGGER TESTS
    // ===================================================================

    @isTest
    static void testOrderTrigger_insertSingleRecord() {
        // Arrange
        Account account = [SELECT Id FROM Account LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];
        Address__c address = [SELECT Id FROM Address__c LIMIT 1];
        PaymentTerm__c paymentTerm = [SELECT Id FROM PaymentTerm__c LIMIT 1];

        Order order = new Order(
            AccountId = account.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId(),
            DistributionCenter__c = cd.Id,
            Address__c = address.Id,
            PaymentTerm__c = paymentTerm.Id
        );

        Test.startTest();
        insert order;
        Test.stopTest();

        // Verify
        Order inserted = [SELECT Id, Status FROM Order WHERE Id = :order.Id];
        System.assertNotEquals(null, inserted.Id, 'Pedido deve ter sido inserido');
        System.assertEquals('Draft', inserted.Status, 'Status inicial deve ser Draft');
    }

    @isTest
    static void testOrderTrigger_changeAccountError() {
        // Arrange
        Account account1 = [SELECT Id FROM Account LIMIT 1];
        Account account2 = new Account(Name = 'Test Account 2');
        insert account2;

        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];
        Address__c address = [SELECT Id FROM Address__c LIMIT 1];
        PaymentTerm__c paymentTerm = [SELECT Id FROM PaymentTerm__c LIMIT 1];

        Order order = new Order(
            AccountId = account1.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId(),
            DistributionCenter__c = cd.Id,
            Address__c = address.Id,
            PaymentTerm__c = paymentTerm.Id
        );
        insert order;

        // Tentar trocar de conta
        order.AccountId = account2.Id;

        Test.startTest();
        try {
            update order;
            System.assert(false, 'Deveria ter bloqueado a troca de conta');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('alterar o Cliente'), 'Mensagem de erro esperada');
        }
        Test.stopTest();
    }

    @isTest
    static void testOrderTrigger_modifyActivatedOrderError() {
        // Arrange
        Order order = [SELECT Id, Status FROM Order LIMIT 1];
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

        // Ativar pedido
        order.Status = 'Activated';
        update order;

        // Tentar modificar
        order.Description = 'Test Description';

        Test.startTest();
        try {
            update order;
            System.assert(false, 'Deveria ter bloqueado a modificação de pedido ativo');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Active'), 'Mensagem de erro esperada');
        }
        Test.stopTest();
    }

    @isTest
    static void testOrderTrigger_deleteAndUndelete() {
        // Arrange
        Order order = [SELECT Id FROM Order LIMIT 1];
        String orderId = order.Id;

        Test.startTest();
        delete order;
        undelete order;
        Test.stopTest();

        // Verify
        Order restored = [SELECT Id FROM Order WHERE Id = :orderId];
        System.assertNotEquals(null, restored.Id, 'Pedido deve ter sido restaurado');
    }

    // ===================================================================
    // ORDER ITEM TRIGGER TESTS
    // ===================================================================

    @isTest
    static void testOrderItemTrigger_insertWithValidQuantity() {
        // Arrange
        Order order = [SELECT Id FROM Order LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :product.Id LIMIT 1];

        OrderItem item = new OrderItem(
            OrderId = order.Id,
            Product2Id = product.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 5,
            UnitPrice = 100
        );

        Test.startTest();
        insert item;
        Test.stopTest();

        // Verify
        OrderItem inserted = [SELECT Id, Quantity FROM OrderItem WHERE Id = :item.Id];
        System.assertNotEquals(null, inserted.Id, 'Item do pedido deve ter sido inserido');
    }

    @isTest
    static void testOrderItemTrigger_insertWithZeroQuantityError() {
        // Arrange
        Order order = [SELECT Id FROM Order LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :product.Id LIMIT 1];

        OrderItem item = new OrderItem(
            OrderId = order.Id,
            Product2Id = product.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 0, // Erro: quantidade zero
            UnitPrice = 100
        );

        Test.startTest();
        try {
            insert item;
            System.assert(false, 'Deveria ter bloqueado quantidade zero');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('maior que zero'), 'Mensagem de erro esperada');
        }
        Test.stopTest();
    }

    @isTest
    static void testOrderItemTrigger_updateActivatedOrderError() {
        // Arrange
        Order order = [SELECT Id FROM Order LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :product.Id LIMIT 1];

        OrderItem item = new OrderItem(
            OrderId = order.Id,
            Product2Id = product.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert item;

        // Ativar pedido
        order.Status = 'Activated';
        update order;

        // Tentar modificar item
        item.Quantity = 5;

        Test.startTest();
        try {
            update item;
            System.assert(false, 'Deveria ter bloqueado modificação de item em pedido ativo');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Active'), 'Mensagem de erro esperada');
        }
        Test.stopTest();
    }

    @isTest
    static void testOrderItemTrigger_bulkInsert() {
        // Arrange
        Order order = [SELECT Id FROM Order LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :product.Id LIMIT 1];

        List<OrderItem> itemList = new List<OrderItem>();
        for (Integer i = 0; i < 200; i++) {
            itemList.add(new OrderItem(
                OrderId = order.Id,
                Product2Id = product.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1 + Math.mod(i, 10),
                UnitPrice = 100 + i
            ));
        }

        Test.startTest();
        insert itemList;
        Test.stopTest();

        // Verify
        List<OrderItem> inserted = [SELECT Id FROM OrderItem WHERE OrderId = :order.Id];
        System.assertEquals(200, inserted.size(), 'Todos os 200 itens devem ter sido inseridos');
    }

    @isTest
    static void testOrderItemTrigger_delete() {
        // Arrange
        Order order = [SELECT Id FROM Order LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :product.Id LIMIT 1];

        OrderItem item = new OrderItem(
            OrderId = order.Id,
            Product2Id = product.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert item;
        String itemId = item.Id;

        Test.startTest();
        delete item;
        Test.stopTest();

        // Verify
        List<OrderItem> deleted = [SELECT Id FROM OrderItem WHERE Id = :itemId];
        System.assertEquals(0, deleted.size(), 'Item deve ter sido deletado');
    }
}
