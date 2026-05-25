/**
 * @description Testes abrangentes para os Handlers (FreightHandler, TaxHandler, MarginHandler)
 * @author Unit Testing Agent
 */
@isTest
private class HandlersTest {

    @testSetup
    static void setupData() {
        TestFactorySObject factory = TestFactorySObject.getInstance();

        // Infra
        DistributionCenter__c cd = (DistributionCenter__c) factory.createSObject(new DistributionCenter__c(Name = 'CD Test'));
        insert cd;

        City__c city = (City__c) factory.createSObject(new City__c(Name = 'Test City'));
        insert city;

        State__c state = (State__c) factory.createSObject(new State__c(Name = 'Test State'));
        insert state;

        Country__c country = (Country__c) factory.createSObject(new Country__c(Name = 'Test Country'));
        insert country;

        // Products
        ProductHierarchy__c hierarchy = (ProductHierarchy__c) factory.createSObject(new ProductHierarchy__c(Name = 'Test Hierarchy'));
        insert hierarchy;

        Product2 product = (Product2) factory.createSObject(new Product2(
            Name = 'Test Product',
            ProductionCost__c = 100.00,
            ProductHierarchy__c = hierarchy.Id
        ));
        insert product;

        // Accounts
        AccountGroup__c accountGroup = (AccountGroup__c) factory.createSObject(new AccountGroup__c(Name = 'Test Group'));
        insert accountGroup;

        Account account = (Account) factory.createSObject(new Account(Name = 'Test Account'));
        insert account;
    }

    // ===================================================================
    // MARGIN HANDLER TESTS
    // ===================================================================

    @isTest
    static void testMarginHandler_validateExclusiveFields_accountAndGroupError() {
        // Arrange
        Account account = [SELECT Id FROM Account LIMIT 1];
        AccountGroup__c accountGroup = [SELECT Id FROM AccountGroup__c LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        City__c city = [SELECT Id FROM City__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Margin__c margin = new Margin__c(
            Account__c = account.Id,
            AccountGroup__c = accountGroup.Id, // Este vai gerar erro
            Product__c = product.Id,
            City__c = city.Id,
            DistributionCenter__c = cd.Id,
            Value__c = 10,
            Status__c = 'Approved'
        );

        Test.startTest();
        try {
            insert margin;
            System.assert(false, 'Deveria ter bloqueado: Conta + Grupo de Conta juntos');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Conta OU Grupo'), 'Mensagem de erro esperada para Conta + Grupo');
        }
        Test.stopTest();
    }

    @isTest
    static void testMarginHandler_validateExclusiveFields_productAndHierarchyError() {
        // Arrange
        Account account = [SELECT Id FROM Account LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        ProductHierarchy__c hierarchy = [SELECT Id FROM ProductHierarchy__c LIMIT 1];
        City__c city = [SELECT Id FROM City__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Margin__c margin = new Margin__c(
            Account__c = account.Id,
            Product__c = product.Id,
            ProductHierarchy__c = hierarchy.Id, // Este vai gerar erro
            City__c = city.Id,
            DistributionCenter__c = cd.Id,
            Value__c = 10,
            Status__c = 'Approved'
        );

        Test.startTest();
        try {
            insert margin;
            System.assert(false, 'Deveria ter bloqueado: Produto + Hierarquia juntos');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Produto OU Hierarquia'), 'Mensagem de erro esperada');
        }
        Test.stopTest();
    }

    @isTest
    static void testMarginHandler_validateExclusiveFields_multipleGeographyError() {
        // Arrange
        Account account = [SELECT Id FROM Account LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        City__c city = [SELECT Id FROM City__c LIMIT 1];
        State__c state = [SELECT Id FROM State__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Margin__c margin = new Margin__c(
            Account__c = account.Id,
            Product__c = product.Id,
            City__c = city.Id,
            State__c = state.Id, // Este vai gerar erro (2 localidades)
            DistributionCenter__c = cd.Id,
            Value__c = 10,
            Status__c = 'Approved'
        );

        Test.startTest();
        try {
            insert margin;
            System.assert(false, 'Deveria ter bloqueado: Múltiplas localidades');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('apenas um nível'), 'Mensagem de erro esperada');
        }
        Test.stopTest();
    }

    @isTest
    static void testMarginHandler_checkDuplicates_singleInsert() {
        // Arrange
        Account account = [SELECT Id FROM Account LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        City__c city = [SELECT Id FROM City__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Margin__c margin1 = new Margin__c(
            Account__c = account.Id,
            Product__c = product.Id,
            City__c = city.Id,
            DistributionCenter__c = cd.Id,
            Value__c = 10,
            Status__c = 'Approved'
        );
        insert margin1;

        Margin__c margin2 = new Margin__c(
            Account__c = account.Id,
            Product__c = product.Id,
            City__c = city.Id,
            DistributionCenter__c = cd.Id,
            Value__c = 20, // Mesmo que seja valor diferente, é duplicada
            Status__c = 'Approved'
        );

        Test.startTest();
        try {
            insert margin2;
            System.assert(false, 'Deveria ter bloqueado: Margem duplicada');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Já existe'), 'Mensagem de erro de duplicidade esperada');
        }
        Test.stopTest();
    }

    @isTest
    static void testMarginHandler_checkDuplicates_bulkInsert() {
        // Arrange
        Account account = [SELECT Id FROM Account LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        City__c city = [SELECT Id FROM City__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        List<Margin__c> marginList = new List<Margin__c>();
        for (Integer i = 0; i < 200; i++) {
            marginList.add(new Margin__c(
                Account__c = account.Id,
                Product__c = product.Id,
                City__c = city.Id,
                DistributionCenter__c = cd.Id,
                Value__c = 10 + i,
                Status__c = 'Approved'
            ));
        }

        Test.startTest();
        try {
            insert marginList;
            System.assert(false, 'Deveria ter bloqueado: Múltiplas duplicatas no bulk');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Já existe'), 'Mensagem de erro esperada em bulk');
        }
        Test.stopTest();
    }

    // ===================================================================
    // FREIGHT HANDLER TESTS
    // ===================================================================

    @isTest
    static void testFreightHandler_validateFields_noProductError() {
        // Arrange
        City__c city = [SELECT Id FROM City__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Freight__c freight = new Freight__c(
            // Sem Product__c nem ProductHierarchy__c
            City__c = city.Id,
            DistributionCenter__c = cd.Id,
            Value__c = 50,
            Status__c = 'Approved'
        );

        Test.startTest();
        try {
            insert freight;
            System.assert(false, 'Deveria ter bloqueado: Sem Produto ou Hierarquia');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Defina um Produto'), 'Mensagem de erro esperada');
        }
        Test.stopTest();
    }

    @isTest
    static void testFreightHandler_validateFields_bothProductsError() {
        // Arrange
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        ProductHierarchy__c hierarchy = [SELECT Id FROM ProductHierarchy__c LIMIT 1];
        City__c city = [SELECT Id FROM City__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Freight__c freight = new Freight__c(
            Product__c = product.Id,
            ProductHierarchy__c = hierarchy.Id, // Erro: ambos preenchidos
            City__c = city.Id,
            DistributionCenter__c = cd.Id,
            Value__c = 50,
            Status__c = 'Approved'
        );

        Test.startTest();
        try {
            insert freight;
            System.assert(false, 'Deveria ter bloqueado: Produto + Hierarquia juntos');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Escolha apenas'), 'Mensagem de erro esperada');
        }
        Test.stopTest();
    }

    @isTest
    static void testFreightHandler_validateFields_noGeographyError() {
        // Arrange
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Freight__c freight = new Freight__c(
            Product__c = product.Id,
            // Sem City, State ou Country
            DistributionCenter__c = cd.Id,
            Value__c = 50,
            Status__c = 'Approved'
        );

        Test.startTest();
        try {
            insert freight;
            System.assert(false, 'Deveria ter bloqueado: Sem Localidade');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Defina uma Localidade'), 'Mensagem de erro esperada');
        }
        Test.stopTest();
    }

    @isTest
    static void testFreightHandler_validateFields_multipleGeographyError() {
        // Arrange
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        City__c city = [SELECT Id FROM City__c LIMIT 1];
        State__c state = [SELECT Id FROM State__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Freight__c freight = new Freight__c(
            Product__c = product.Id,
            City__c = city.Id,
            State__c = state.Id, // Erro: 2 localidades
            DistributionCenter__c = cd.Id,
            Value__c = 50,
            Status__c = 'Approved'
        );

        Test.startTest();
        try {
            insert freight;
            System.assert(false, 'Deveria ter bloqueado: Múltiplas localidades');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('apenas um nível'), 'Mensagem de erro esperada');
        }
        Test.stopTest();
    }

    @isTest
    static void testFreightHandler_checkDuplicates() {
        // Arrange
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        City__c city = [SELECT Id FROM City__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Freight__c freight1 = new Freight__c(
            Product__c = product.Id,
            City__c = city.Id,
            DistributionCenter__c = cd.Id,
            Value__c = 50,
            Status__c = 'Approved'
        );
        insert freight1;

        Freight__c freight2 = new Freight__c(
            Product__c = product.Id,
            City__c = city.Id,
            DistributionCenter__c = cd.Id,
            Value__c = 60,
            Status__c = 'Approved'
        );

        Test.startTest();
        try {
            insert freight2;
            System.assert(false, 'Deveria ter bloqueado: Frete duplicado');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Já existe'), 'Mensagem de erro de duplicidade esperada');
        }
        Test.stopTest();
    }

    @isTest
    static void testFreightHandler_bulkInsert() {
        // Arrange
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        City__c city = [SELECT Id FROM City__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        List<Freight__c> freightList = new List<Freight__c>();
        for (Integer i = 0; i < 200; i++) {
            freightList.add(new Freight__c(
                Product__c = product.Id,
                City__c = city.Id,
                DistributionCenter__c = cd.Id,
                Value__c = 50 + i,
                Status__c = 'Approved'
            ));
        }

        Test.startTest();
        try {
            insert freightList;
            System.assert(false, 'Deveria ter bloqueado em bulk');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Já existe'), 'Mensagem de erro esperada');
        }
        Test.stopTest();
    }

    // ===================================================================
    // TAX HANDLER TESTS
    // ===================================================================

    @isTest
    static void testTaxHandler_checkDuplicates_singleInsert() {
        // Arrange
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        State__c state = [SELECT Id FROM State__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Tax__c tax1 = new Tax__c(
            Product__c = product.Id,
            State__c = state.Id,
            DistributionCenter__c = cd.Id,
            TaxOnCost__c = 12,
            Status__c = 'Approved'
        );
        insert tax1;

        Tax__c tax2 = new Tax__c(
            Product__c = product.Id,
            State__c = state.Id,
            DistributionCenter__c = cd.Id,
            TaxOnCost__c = 15,
            Status__c = 'Approved'
        );

        Test.startTest();
        try {
            insert tax2;
            System.assert(false, 'Deveria ter bloqueado: Imposto duplicado');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Já existe'), 'Mensagem de erro de duplicidade esperada');
        }
        Test.stopTest();
    }

    @isTest
    static void testTaxHandler_checkDuplicates_bulkInsert() {
        // Arrange
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        State__c state = [SELECT Id FROM State__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        List<Tax__c> taxList = new List<Tax__c>();
        for (Integer i = 0; i < 200; i++) {
            taxList.add(new Tax__c(
                Product__c = product.Id,
                State__c = state.Id,
                DistributionCenter__c = cd.Id,
                TaxOnCost__c = 12 + (i * 0.01),
                Status__c = 'Approved'
            ));
        }

        Test.startTest();
        try {
            insert taxList;
            System.assert(false, 'Deveria ter bloqueado em bulk');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Já existe'), 'Mensagem de erro esperada');
        }
        Test.stopTest();
    }

    @isTest
    static void testTaxHandler_updateDuplicateCheck() {
        // Arrange
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        State__c state = [SELECT Id FROM State__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Tax__c tax1 = new Tax__c(
            Product__c = product.Id,
            State__c = state.Id,
            DistributionCenter__c = cd.Id,
            TaxOnCost__c = 12,
            Status__c = 'Approved'
        );
        insert tax1;

        Tax__c tax2 = new Tax__c(
            Product__c = product.Id,
            State__c = state.Id,
            DistributionCenter__c = cd.Id,
            TaxOnCost__c = 15,
            Status__c = 'Approved'
        );
        insert tax2;

        // Tentar atualizar tax2 para ter a mesma combinação de tax1
        tax2.Product__c = tax1.Product__c;
        tax2.State__c = tax1.State__c;

        Test.startTest();
        try {
            update tax2;
            System.assert(false, 'Deveria ter bloqueado na atualização');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Já existe'), 'Mensagem de erro esperada na atualização');
        }
        Test.stopTest();
    }

    // ===================================================================
    // MARGIN HANDLER UPDATE TESTS
    // ===================================================================

    @isTest
    static void testMarginHandler_updateFields() {
        // Arrange
        Account account = [SELECT Id FROM Account LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        City__c city = [SELECT Id FROM City__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Margin__c margin = new Margin__c(
            Account__c = account.Id,
            Product__c = product.Id,
            City__c = city.Id,
            DistributionCenter__c = cd.Id,
            Value__c = 10,
            Status__c = 'Approved'
        );
        insert margin;

        // Atualizar valor
        margin.Value__c = 15;

        Test.startTest();
        update margin; // Deve funcionar sem erro
        Test.stopTest();

        Margin__c updated = [SELECT Value__c FROM Margin__c WHERE Id = :margin.Id];
        System.assertEquals(15, updated.Value__c, 'Valor deve ter sido atualizado');
    }

    // ===================================================================
    // FREIGHT HANDLER UPDATE TESTS
    // ===================================================================

    @isTest
    static void testFreightHandler_updateFields() {
        // Arrange
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        City__c city = [SELECT Id FROM City__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Freight__c freight = new Freight__c(
            Product__c = product.Id,
            City__c = city.Id,
            DistributionCenter__c = cd.Id,
            Value__c = 50,
            Status__c = 'Approved'
        );
        insert freight;

        // Atualizar valor
        freight.Value__c = 60;

        Test.startTest();
        update freight; // Deve funcionar sem erro
        Test.stopTest();

        Freight__c updated = [SELECT Value__c FROM Freight__c WHERE Id = :freight.Id];
        System.assertEquals(60, updated.Value__c, 'Valor deve ter sido atualizado');
    }
}
