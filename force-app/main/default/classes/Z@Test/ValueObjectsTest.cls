/**
 * @description Testes para ValueObjects (PricingKey)
 * @author Unit Testing Agent
 */
@isTest
private class ValueObjectsTest {

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

        // Produtos
        ProductHierarchy__c hierarchy = (ProductHierarchy__c) factory.createSObject(new ProductHierarchy__c(Name = 'Test Hierarchy'));
        insert hierarchy;

        Product2 product = (Product2) factory.createSObject(new Product2(
            Name = 'Test Product',
            ProductionCost__c = 100.00,
            ProductHierarchy__c = hierarchy.Id
        ));
        insert product;

        // Contas
        AccountGroup__c accountGroup = (AccountGroup__c) factory.createSObject(new AccountGroup__c(Name = 'Test Group'));
        insert accountGroup;

        Account account = (Account) factory.createSObject(new Account(Name = 'Test Account'));
        insert account;
    }

    // ===================================================================
    // PRICING KEY TESTS
    // ===================================================================

    @isTest
    static void testPricingKey_equalsWithIdenticalKeys() {
        // Arrange
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        City__c city = [SELECT Id FROM City__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Freight__c freight1 = new Freight__c(
            Product__c = product.Id,
            City__c = city.Id,
            Value__c = 50,
            Status__c = 'Approved',
            DistributionCenter__c = cd.Id
        );

        Freight__c freight2 = new Freight__c(
            Product__c = product.Id,
            City__c = city.Id,
            Value__c = 50,
            Status__c = 'Approved',
            DistributionCenter__c = cd.Id
        );

        Test.startTest();
        PricingKey key1 = new PricingKey(freight1);
        PricingKey key2 = new PricingKey(freight2);

        Boolean areEqual = key1.equals(key2);
        Test.stopTest();

        // Verify
        System.assertEquals(true, areEqual, 'Chaves com mesmos valores devem ser iguais');
    }

    @isTest
    static void testPricingKey_equalsWithDifferentKeys() {
        // Arrange
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        City__c city = [SELECT Id FROM City__c LIMIT 1];
        State__c state = [SELECT Id FROM State__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Freight__c freight1 = new Freight__c(
            Product__c = product.Id,
            City__c = city.Id,
            Value__c = 50,
            Status__c = 'Approved',
            DistributionCenter__c = cd.Id
        );

        Freight__c freight2 = new Freight__c(
            Product__c = product.Id,
            State__c = state.Id, // Localidade diferente
            Value__c = 50,
            Status__c = 'Approved',
            DistributionCenter__c = cd.Id
        );

        Test.startTest();
        PricingKey key1 = new PricingKey(freight1);
        PricingKey key2 = new PricingKey(freight2);

        Boolean areEqual = key1.equals(key2);
        Test.stopTest();

        // Verify
        System.assertEquals(false, areEqual, 'Chaves com valores diferentes devem ser diferentes');
    }

    @isTest
    static void testPricingKey_equalsWithDifferentTypes() {
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
        PricingKey key = new PricingKey(freight);

        Boolean areEqual = key.equals('Not a PricingKey');
        Test.stopTest();

        // Verify
        System.assertEquals(false, areEqual, 'PricingKey deve retornar false ao comparar com tipo diferente');
    }

    @isTest
    static void testPricingKey_hashCodeConsistency() {
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
        PricingKey key1 = new PricingKey(freight);
        Integer hash1 = key1.hashCode();

        PricingKey key2 = new PricingKey(freight);
        Integer hash2 = key2.hashCode();
        Test.stopTest();

        // Verify
        System.assertEquals(hash1, hash2, 'HashCode deve ser consistente para chaves equivalentes');
    }

    @isTest
    static void testPricingKey_withMarginAllFields() {
        // Arrange
        Account account = [SELECT Id FROM Account LIMIT 1];
        AccountGroup__c accountGroup = [SELECT Id FROM AccountGroup__c LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        ProductHierarchy__c hierarchy = [SELECT Id FROM ProductHierarchy__c LIMIT 1];
        City__c city = [SELECT Id FROM City__c LIMIT 1];
        State__c state = [SELECT Id FROM State__c LIMIT 1];
        Country__c country = [SELECT Id FROM Country__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Margin__c margin1 = new Margin__c(
            Product__c = product.Id,
            Account__c = account.Id,
            City__c = city.Id,
            Value__c = 10,
            Status__c = 'Approved',
            DistributionCenter__c = cd.Id
        );

        Margin__c margin2 = new Margin__c(
            Product__c = product.Id,
            Account__c = account.Id,
            City__c = city.Id,
            Value__c = 10,
            Status__c = 'Approved',
            DistributionCenter__c = cd.Id
        );

        Test.startTest();
        PricingKey key1 = new PricingKey(margin1);
        PricingKey key2 = new PricingKey(margin2);

        Boolean areEqual = key1.equals(key2);
        Test.stopTest();

        // Verify
        System.assertEquals(true, areEqual, 'Margens com mesmas combinações devem ter chaves iguais');
    }

    @isTest
    static void testPricingKey_withTaxAllowingNull() {
        // Arrange
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        State__c state = [SELECT Id FROM State__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Tax__c tax1 = new Tax__c(
            Product__c = product.Id,
            State__c = state.Id,
            TaxOnCost__c = 12,
            Status__c = 'Approved',
            DistributionCenter__c = cd.Id
            // Account__c is null
        );

        Tax__c tax2 = new Tax__c(
            Product__c = product.Id,
            State__c = state.Id,
            TaxOnCost__c = 12,
            Status__c = 'Approved',
            DistributionCenter__c = cd.Id
            // Account__c is null
        );

        Test.startTest();
        PricingKey key1 = new PricingKey(tax1);
        PricingKey key2 = new PricingKey(tax2);

        Boolean areEqual = key1.equals(key2);
        System.assertNotEquals(0, key1.hashCode(), 'HashCode não deve ser zero mesmo com campos nulos');
        Test.stopTest();

        // Verify
        System.assertEquals(true, areEqual, 'Impostos com mesmas combinações devem ter chaves iguais');
    }

    @isTest
    static void testPricingKey_inSetForDuplicateDetection() {
        // Arrange
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        City__c city = [SELECT Id FROM City__c LIMIT 1];
        DistributionCenter__c cd = [SELECT Id FROM DistributionCenter__c LIMIT 1];

        Freight__c freight1 = new Freight__c(
            Product__c = product.Id,
            City__c = city.Id,
            Value__c = 50,
            Status__c = 'Approved',
            DistributionCenter__c = cd.Id
        );

        Freight__c freight2 = new Freight__c(
            Product__c = product.Id,
            City__c = city.Id,
            Value__c = 60, // Valor diferente, mas chave é igual
            Status__c = 'Approved',
            DistributionCenter__c = cd.Id
        );

        Test.startTest();
        Set<PricingKey> keySet = new Set<PricingKey>();
        keySet.add(new PricingKey(freight1));

        Boolean isDuplicate = keySet.contains(new PricingKey(freight2));
        Test.stopTest();

        // Verify
        System.assertEquals(true, isDuplicate, 'Chaves equivalentes devem ser detectadas como duplicatas em Sets');
    }
}
