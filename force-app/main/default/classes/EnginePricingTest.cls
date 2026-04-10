@isTest
public class EnginePricingTest {

    @testSetup
    static void setupData() {
        TestFactorySObject factory = TestFactorySObject.getInstance();

        // 1. Criando registros para Lookups obrigatórios
        Condicao_Pagamento__c cond = new Condicao_Pagamento__c(Name = 'A Vista');
        insert cond;

        Centro_Distribuicao__c cd = new Centro_Distribuicao__c(Name = 'CD Principal');
        insert cd;

        Grupo_de_Conta__c vipAgro = (Grupo_de_Conta__c) factory.createSObject(new Grupo_de_Conta__c(Name = 'VIP Agro'));
        insert vipAgro;

        Account accVIP = (Account) factory.createSObject(new Account(Name = 'Cliente VIP S/A', Grupo_de_Conta__c = vipAgro.Id));
        insert accVIP;

        Product2 trator = (Product2) factory.createSObject(new Product2(Name = 'Trator de Esteira Max', Custo_Producao__c = 90000.00));
        insert trator;
        // Adicione isso no seu setupData:
        Endereco__c ender = new Endereco__c(Name = 'Rua de Teste, 10');
        insert ender;

        Id pbId = Test.getStandardPricebookId(); 
        insert new PricebookEntry(Pricebook2Id = pbId, Product2Id = trator.Id, UnitPrice = 0, IsActive = true);

        // Criando a Margem inicial que será a "duplicada"
        Margem__c margemEsp = new Margem__c(
            Produto__c = trator.Id, 
            Conta__c = accVIP.Id, 
            Valor__c = 5,
            Status__c = 'Aprovado'
        );
        insert margemEsp;

        insert new Frete__c(Produto__c = trator.Id, Valor__c = 10000, Status__c = 'Aprovado');
        insert new Imposto__c(Produto__c = trator.Id, Imposto_sobre_custo__c = 10, Status__c = 'Aprovado');
    }

    @isTest
    static void testBloqueioDeDuplicidade() {
        Product2 trator = [SELECT Id FROM Product2 LIMIT 1];
        Account accVIP = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        try {
            // Tentando inserir exatamente o que a Trigger vigia
            Margem__c mDup = new Margem__c(
                Produto__c = trator.Id, 
                Conta__c = accVIP.Id, 
                Valor__c = 99,
                Status__c = 'Aprovado'
            );
            insert mDup;
            System.assert(false, 'A Trigger deveria ter bloqueado a duplicidade, mas o insert passou!');
        } catch (DmlException e) {
            System.debug('Sucesso: Trigger bloqueou!');
        }
        Test.stopTest();
    }

    @isTest
    static void testMotorPrecosClienteVIP() {
        TestFactorySObject factory = TestFactorySObject.getInstance();
        Account accVIP = [SELECT Id FROM Account LIMIT 1];
        Product2 trator = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :trator.Id LIMIT 1];
        Condicao_Pagamento__c cond = [SELECT Id FROM Condicao_Pagamento__c LIMIT 1];
        Centro_Distribuicao__c cd = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1];
        Endereco__c ender = [SELECT Id FROM Endereco__c LIMIT 1]; // BUSQUE O ENDEREÇO

        Order ped1 = new Order(
            AccountId = accVIP.Id, 
            EffectiveDate = Date.today(), 
            Status = 'Draft', 
            Pricebook2Id = Test.getStandardPricebookId(),
            Centro_Distribuicao__c = cd.Id, 
            Endereco__c = ender.Id, 
            Condicao_Pagamento__c = cond.Id
        );
        insert ped1;

        OrderItem itemVIP = (OrderItem) factory.createSObject(new OrderItem(
            OrderId = ped1.Id, 
            Product2Id = trator.Id, 
            Quantity = 1, 
            UnitPrice = 0, 
            PricebookEntryId = pbe.Id
        ));

        Test.startTest();
        insert itemVIP;
        Test.stopTest();

        OrderItem resultado = [SELECT Valor_Frete__c, Porcentagem_Imposto__c, Porcentagem_Margem__c FROM OrderItem WHERE Id = :itemVIP.Id];

        System.assertEquals(10000, resultado.Valor_Frete__c);
        System.assertEquals(5, resultado.Porcentagem_Margem__c);
    }
}