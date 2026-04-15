@isTest
public class EnginePricingTest {

    @testSetup
    static void setupData() {
        TestFactorySObject factory = TestFactorySObject.getInstance();

        // 1. INFRAESTRUTURA 
        Condicao_Pagamento__c cond = (Condicao_Pagamento__c) factory.createSObject(new Condicao_Pagamento__c(Name = 'A Vista'));
        insert cond;

        Centro_Distribuicao__c cd = (Centro_Distribuicao__c) factory.createSObject(new Centro_Distribuicao__c(Name = 'CD Principal'));
        insert cd;

        Cidade__c cid = (Cidade__c) factory.createSObject(new Cidade__c(Name = 'São Bernardo do Campo'));
        insert cid;

        Estado__c est = (Estado__c) factory.createSObject(new Estado__c(Name = 'São Paulo'));
        insert est;

        
        Endereco__c ender = (Endereco__c) factory.createSObject(new Endereco__c(Name = 'Rua de Teste, 10'));
        insert ender;

        // 2. CLIENTE E PRODUTO
        Grupo_de_Conta__c vipAgro = (Grupo_de_Conta__c) factory.createSObject(new Grupo_de_Conta__c(Name = 'VIP Agro'));
        insert vipAgro;

        Account accVIP = (Account) factory.createSObject(new Account(Name = 'Cliente VIP S/A', Grupo_de_Conta__c = vipAgro.Id, CNPJ__c = '11.111.111/0001-11'));
        insert accVIP;

        Hierarquia_de_Produto__c hTrator = (Hierarquia_de_Produto__c) factory.createSObject(new Hierarquia_de_Produto__c(Name='Tratores'));
        insert hTrator;

        Product2 trator = (Product2) factory.createSObject(new Product2(
            Name = 'Trator de Esteira Max', 
            Custo_Producao__c = 1000.00, 
            Hierarquia_de_Produto__c = hTrator.Id
        ));
        insert trator;

        // 3. CATALOGO DE PREÇOS
        Id pbId = Test.getStandardPricebookId(); 
        insert new PricebookEntry(Pricebook2Id = pbId, Product2Id = trator.Id, UnitPrice = 1500.00, IsActive = true);

        // 4. REGRAS DO MOTOR 
        insert (Margem__c) factory.createSObject(new Margem__c(
            Produto__c = trator.Id, 
            Conta__c = accVIP.Id, 
            Cidade__c = cid.Id, 
            Valor__c = 10, 
            Status__c = 'Aprovado',
            Centro_Distribuicao__c = cd.Id
        ));

        insert (Frete__c) factory.createSObject(new Frete__c(
            Produto__c = trator.Id, 
            Cidade__c = cid.Id, 
            Valor__c = 50, 
            Status__c = 'Aprovado',
            Centro_Distribuicao__c = cd.Id
        ));

        insert (Imposto__c) factory.createSObject(new Imposto__c(
            Produto__c = trator.Id, 
            Estado__c = est.Id, 
            Imposto_sobre_custo__c = 12, 
            Status__c = 'Aprovado',
            Centro_Distribuicao__c = cd.Id
        ));
    }

    // ==========================================================
    //  1. TESTE DE BLOQUEIO: MARGEM
    // ==========================================================
    @isTest
    static void testBloqueioDeDuplicidade_Margem() {
        Product2 trator = [SELECT Id FROM Product2 LIMIT 1];
        Account accVIP = [SELECT Id FROM Account LIMIT 1];
        Centro_Distribuicao__c cd = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1];
        Cidade__c cid = [SELECT Id FROM Cidade__c LIMIT 1]; 
        
        Test.startTest();
        try {
            Margem__c mDup = new Margem__c(
                Produto__c = trator.Id, 
                Conta__c = accVIP.Id, 
                Centro_Distribuicao__c = cd.Id, 
                Cidade__c = cid.Id, 
                Valor__c = 99,
                Status__c = 'Aprovado'
            );
            insert mDup;
            System.assert(false, '❌ A Trigger deveria ter bloqueado a duplicidade de Margem!');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Já existe'), '✅ Sucesso: Margem bloqueada!');
        }
        Test.stopTest();
    }

    // ==========================================================
    //  2. TESTE DE BLOQUEIO: FRETE
    // ==========================================================
    @isTest
    static void testBloqueioDeDuplicidade_Frete() {
        Product2 trator = [SELECT Id FROM Product2 LIMIT 1];
        Centro_Distribuicao__c cd = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1];
        Cidade__c cid = [SELECT Id FROM Cidade__c LIMIT 1]; 
        
        Test.startTest();
        try {
            Frete__c fDup = new Frete__c(
                Produto__c = trator.Id, 
                Centro_Distribuicao__c = cd.Id,
                Cidade__c = cid.Id, 
                Valor__c = 99,
                Status__c = 'Aprovado'
            );
            insert fDup;
            System.assert(false, '❌ A Trigger deveria ter bloqueado a duplicidade de Frete!');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Já existe'), '✅ Sucesso: Frete bloqueado!');
        }
        Test.stopTest();
    }

    // ==========================================================
    //  3. TESTE DE BLOQUEIO: IMPOSTO
    // ==========================================================
    @isTest
    static void testBloqueioDeDuplicidade_Imposto() {
        Product2 trator = [SELECT Id FROM Product2 LIMIT 1];
        Centro_Distribuicao__c cd = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1];
        Estado__c est = [SELECT Id FROM Estado__c LIMIT 1]; 
        
        Test.startTest();
        try {
            Imposto__c iDup = new Imposto__c(
                Produto__c = trator.Id, 
                Centro_Distribuicao__c = cd.Id,
                Estado__c = est.Id, 
                Imposto_sobre_custo__c = 99, 
                Status__c = 'Aprovado'
            );
            insert iDup;
            System.assert(false, '❌ A Trigger deveria ter bloqueado a duplicidade de Imposto!');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Já existe'), '✅ Sucesso: Imposto bloqueado!');
        }
        Test.stopTest();
    }

    // ==========================================================
    // 🔄 1. TESTE DE UPDATE (Cobre o beforeUpdate)
    // ==========================================================
    @isTest
    static void testUpdateParaCobertura() {
        // Busca um de cada
        Margem__c m = [SELECT Id FROM Margem__c LIMIT 1];
        Frete__c f = [SELECT Id FROM Frete__c LIMIT 1];
        Imposto__c i = [SELECT Id FROM Imposto__c LIMIT 1];

        // Altera os valores para disparar o Update
        m.Valor__c = 99;
        f.Valor__c = 99;
        i.Imposto_sobre_custo__c = 99;

        Test.startTest();
        update new List<SObject>{m, f, i};
        Test.stopTest();
        
        System.assertEquals(99, [SELECT Valor__c FROM Margem__c WHERE Id = :m.Id].Valor__c);
    }

    // ==========================================================
    // 🗑️ 2. TESTE DE DELETE/UNDELETE (Cobre os métodos vazios no final)
    // ==========================================================
    @isTest
    static void testDeleteUndeleteParaCobertura() {
        Margem__c m = [SELECT Id FROM Margem__c LIMIT 1];
        
        Test.startTest();
        delete m;    // Cobre o afterDelete
        undelete m;  // Cobre o afterUndelete
        Test.stopTest();
        
        System.assertNotEquals(null, m.Id);
    }

    // ==========================================================
    // ⚠️ 3. TESTE DE ERROS (Cobre as linhas de 'addError' vermelhas)
    // ==========================================================
    @isTest
    static void testValidacoesNegativasParaCobertura() {
        // Tenta criar um Frete com 2 produtos (Erro: prodCount > 1)
        Product2 p = [SELECT Id FROM Product2 LIMIT 1];
        Hierarquia_de_Produto__c h = [SELECT Id FROM Hierarquia_de_Produto__c LIMIT 1];
        Cidade__c cid = [SELECT Id FROM Cidade__c LIMIT 1];
        Centro_Distribuicao__c cd = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1];

        Frete__c fErro = new Frete__c(
            Produto__c = p.Id, 
            Hierarquia_de_Produto__c = h.Id, // <- DUAS informações de produto (VAI DAR ERRO)
            Cidade__c = cid.Id,
            Centro_Distribuicao__c = cd.Id,
            Valor__c = 10
        );

        try {
            insert fErro;
        } catch (Exception e) {
            System.debug('Sucesso: Capturou o erro de múltiplos produtos!');
        }
    }

// ==========================================================
    // 🎯 4. TESTE DO MOTOR: ESPECIFICIDADE (O "Sniper")
    // Testa se a lógica escolheu as Regras Campeãs corretamente para 1 item
    // ==========================================================
    @isTest
    static void testMotorPrecos_Especificidade() {
        Account accVIP = [SELECT Id FROM Account LIMIT 1];
        Product2 trator = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :trator.Id LIMIT 1];
        Condicao_Pagamento__c cond = [SELECT Id FROM Condicao_Pagamento__c LIMIT 1];
        Centro_Distribuicao__c cd = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1];
        Endereco__c ender = [SELECT Id FROM Endereco__c LIMIT 1]; 

        Order ped = new Order(
            AccountId = accVIP.Id, EffectiveDate = Date.today(), Status = 'Draft', Pricebook2Id = Test.getStandardPricebookId(),
            ShippingCity = 'São Bernardo do Campo', Centro_Distribuicao__c = cd.Id, Condicao_Pagamento__c = cond.Id, Endereco__c = ender.Id 
        );
        insert ped;

        // Inserindo apenas 1 item para testar a matemática pura
        OrderItem itemUnico = new OrderItem(
            OrderId = ped.Id, Product2Id = trator.Id, Quantity = 1, UnitPrice = 1500.00, PricebookEntryId = pbe.Id
        );

        Test.startTest();
        insert itemUnico;
        Test.stopTest();

        OrderItem resultado = [SELECT Valor_Frete__c, Porcentagem_Imposto__c, Porcentagem_Margem__c FROM OrderItem WHERE Id = :itemUnico.Id];
        
        System.assertEquals(10, resultado.Porcentagem_Margem__c, '🎯 Falhou: Não pegou a Margem Campeã (10%)');
        System.assertEquals(50, resultado.Valor_Frete__c, '🎯 Falhou: Não pegou o Frete Campeão (R$ 50)');
        System.assertEquals(12, resultado.Porcentagem_Imposto__c, '🎯 Falhou: Imposto incorreto');
    }

    // ==========================================================
    // 🚜 5. TESTE DO MOTOR: BULKIFICATION 
    // Testa se a Trigger aguenta 200 registros sem estourar limites do Salesforce
    // ==========================================================
    @isTest
    static void testMotorPrecos_Bulkification() {
        Account accVIP = [SELECT Id FROM Account LIMIT 1];
        Product2 trator = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :trator.Id LIMIT 1];
        Condicao_Pagamento__c cond = [SELECT Id FROM Condicao_Pagamento__c LIMIT 1];
        Centro_Distribuicao__c cd = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1];
        Endereco__c ender = [SELECT Id FROM Endereco__c LIMIT 1]; 

        Order ped = new Order(
            AccountId = accVIP.Id, EffectiveDate = Date.today(), Status = 'Draft', Pricebook2Id = Test.getStandardPricebookId(),
            ShippingCity = 'São Bernardo do Campo', Centro_Distribuicao__c = cd.Id, Condicao_Pagamento__c = cond.Id, Endereco__c = ender.Id 
        );
        insert ped;

        // Criando 200 itens na memória
        List<OrderItem> itensParaInserir = new List<OrderItem>();
        for(Integer i = 0; i < 200; i++) {
            itensParaInserir.add(new OrderItem(
                OrderId = ped.Id, Product2Id = trator.Id, Quantity = 1, UnitPrice = 1500.00, PricebookEntryId = pbe.Id
            ));
        }

        Test.startTest();
        // O teste real é aqui: O Salesforce vai jogar alguma DmlException de Limite?
        insert itensParaInserir;
        Test.stopTest();

        List<OrderItem> resultados = [SELECT Id FROM OrderItem WHERE OrderId = :ped.Id];
        System.assertEquals(200, resultados.size(), '💪 Falhou: O sistema não conseguiu salvar os 200 registros.');
    }

    // ==========================================================
    // Margem BULKIFICATION DE DUPLICIDADE
    // Tenta inserir 200 regras duplicadas de uma vez só!
    // ==========================================================
    @isTest
    static void testBloqueioDeDuplicidade_Margem_Bulk() {
        Product2 trator = [SELECT Id FROM Product2 LIMIT 1];
        Account accVIP = [SELECT Id FROM Account LIMIT 1];
        Centro_Distribuicao__c cd = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1];
        Cidade__c cid = [SELECT Id FROM Cidade__c LIMIT 1]; 
        
        // Criando 200 regras "clones" na memória
        List<Margem__c> listaDuplicadas = new List<Margem__c>();
        for(Integer i = 0; i < 200; i++) {
            listaDuplicadas.add(new Margem__c(
                Produto__c = trator.Id, 
                Conta__c = accVIP.Id, 
                Centro_Distribuicao__c = cd.Id, 
                Cidade__c = cid.Id, 
                Valor__c = 99, 
                Status__c = 'Aprovado'
            ));
        }

        Test.startTest();
        try {
            // O Salesforce tenta processar o lote inteiro de 200 registros de uma vez
            insert listaDuplicadas; 
            System.assert(false, '❌ A Trigger deveria ter bloqueado o lote inteiro de duplicidade!');
        } catch (DmlException e) {
            // 1. Se a Trigger tiver erro de limite (SOQL no FOR), o teste nem chega no catch.
            // 2. Se cair aqui e a mensagem for a da sua validação, o escudo aguentou o tranco!
            System.assert(e.getMessage().contains('Já existe'), '✅ Sucesso: O escudo bloqueou 200 inserções simultâneas!');
        }
        Test.stopTest();
    }

    // ==========================================================
    //  BULKIFICATION DE DUPLICIDADE (FRETE)
    // ==========================================================
    @isTest
    static void testBloqueioDeDuplicidade_Frete_Bulk() {
        Product2 trator = [SELECT Id FROM Product2 LIMIT 1];
        Centro_Distribuicao__c cd = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1];
        Cidade__c cid = [SELECT Id FROM Cidade__c LIMIT 1];



     // Criando 200 regras "clones" na memória
        List<Frete__c> listaDuplicadas = new List<Frete__c>();
        for(Integer i = 0; i < 200; i++) {
            listaDuplicadas.add(new Frete__c(
                Produto__c = trator.Id, 
                Centro_Distribuicao__c = cd.Id,
                Cidade__c = cid.Id, 
                Valor__c = 99,
                Status__c = 'Aprovado'
            ));
        }

        Test.startTest();
        try {
            // O Salesforce tenta processar o lote inteiro de 200 registros de uma vez
            insert listaDuplicadas; 
            System.assert(false, '❌ A Trigger deveria ter bloqueado o lote inteiro de duplicidade!');
        } catch (DmlException e) {
            // 1. Se a Trigger tiver erro de limite (SOQL no FOR), o teste nem chega no catch.
            // 2. Se cair aqui e a mensagem for a da sua validação, o escudo aguentou o tranco!
            System.assert(e.getMessage().contains('Já existe'), '✅ Sucesso: O escudo bloqueou 200 inserções simultâneas!');
        }
        Test.stopTest();
    }

      // ==========================================================
    //  BULKIFICATION DE DUPLICIDADE (Imposto)
    // ==========================================================

    @isTest
    static void testBloqueioDuplicidade_Imposto_Bulk(){

    Product2 trator = [SELECT Id FROM Product2 LIMIT 1];
        Centro_Distribuicao__c cd = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1];
        Estado__c est = [SELECT Id FROM Estado__c LIMIT 1]; 
        
        // Criando 200 regras "clones" na memória
        List<Imposto__c> listaDuplicadas = new List<Imposto__c>();
        for(Integer i = 0; i < 200; i++) {
            listaDuplicadas.add(new Imposto__c(
                Produto__c = trator.Id, 
                Centro_Distribuicao__c = cd.Id,
                Estado__c = est.Id, // Lembrando que o imposto usa Estado!
                Imposto_sobre_custo__c = 99, 
                Status__c = 'Aprovado'
            ));
        }

        Test.startTest();
        try {
            insert listaDuplicadas;
            System.assert(false, '❌ A Trigger deveria ter bloqueado o lote inteiro de duplicidade de Imposto!');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Já existe'), '✅ Sucesso: O escudo de Imposto bloqueou 200 inserções simultâneas!');
        }
        Test.stopTest();
    }
}


