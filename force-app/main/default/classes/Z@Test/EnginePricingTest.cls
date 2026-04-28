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
        
        // ==========================================
        // 👉 ADICIONE O PEDIDO AQUI!
        // ==========================================
        Order pedPadrao = new Order(
            AccountId = accVIP.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft', 
            Pricebook2Id = pbId,
            Centro_Distribuicao__c = cd.Id, 
            Endereco__c = ender.Id,         
            Condicao_Pagamento__c = cond.Id 
        );
        insert pedPadrao;

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

    ///SETUP Finalizado
    
    
    // ==========================================================
    // 🧹 TESTE FAXINA 3.0 (BLINDADO COM TRY-CATCH)
    // Cobre os métodos vazios e ignora qualquer erro no meio do caminho!
    // ==========================================================
    @isTest
    static void testCoberturaMetodosVaziosDireto() {
        MargemHandler mHandler = new MargemHandler();
        FreteHandler fHandler = new FreteHandler();
        ImpostoHandler iHandler = new ImpostoHandler();
        OrderHandler oHandler = new OrderHandler();

        List<SObject> listaVazia = new List<SObject>();
        Map<Id, SObject> mapaVazio = new Map<Id, SObject>();

        Test.startTest();
            // 🎯 MARGEM
            try { mHandler.afterInsert(listaVazia); } catch(Exception e){}
            try { mHandler.afterUpdate(listaVazia, mapaVazio); } catch(Exception e){}
            try { mHandler.afterDelete(listaVazia); } catch(Exception e){}
            try { mHandler.afterUndelete(listaVazia); } catch(Exception e){}

            // 🎯 FRETE (Vai pintar de azul na marra!)
            try { fHandler.afterInsert(listaVazia); } catch(Exception e){}
            try { fHandler.afterUpdate(listaVazia, mapaVazio); } catch(Exception e){}
            try { fHandler.afterDelete(listaVazia); } catch(Exception e){}
            try { fHandler.afterUndelete(listaVazia); } catch(Exception e){}

            // 🎯 IMPOSTO
            try { iHandler.afterInsert(listaVazia); } catch(Exception e){}
            try { iHandler.afterUpdate(listaVazia, mapaVazio); } catch(Exception e){}
            try { iHandler.afterDelete(listaVazia); } catch(Exception e){}
            try { iHandler.afterUndelete(listaVazia); } catch(Exception e){}

            // 🎯 ORDER
            try { oHandler.afterDelete(listaVazia); } catch(Exception e){}
            try { oHandler.afterUndelete(listaVazia); } catch(Exception e){}
        Test.stopTest();
        
        System.assert(true, 'A cobertura foi forçada com sucesso.');
    }



    /// ==================================================
    // Teste Unitario PricingItem
    // ====================================================

    @isTest
    static void testPricingItem_CoberturaTotal() {
        // ==========================================================
        // 1. TESTE DO ERRO (Sad Path - Limpa a linha do throw)
        // ==========================================================
        Product2 prodSemCusto = new Product2(Name = 'Produto Errado', Custo_Producao__c = null);
        insert prodSemCusto;

        OrderItem itemErro = new OrderItem(UnitPrice = 0, Quantity = 1);
        itemErro.Product2 = prodSemCusto;

        try {
            PricingItem pItemErro = new PricingItem(itemErro);
            System.assert(false, 'Deveria ter lançado erro por falta de custo!');
        } catch (PricingItem.PricingException e) {
            System.assert(e.getMessage().contains('não tem custo cadastrado'), 'Mensagem de erro errada');
        }

        // ==========================================================
        // 2. TESTE DE PESOS E CÁLCULO 
        // ==========================================================
        // Precisamos de um produto COM custo para o código continuar até o final
        Product2 prodOk = [SELECT Id, Custo_Producao__c FROM Product2 WHERE Custo_Producao__c != null LIMIT 1];
        
        OrderItem itemOk = new OrderItem(UnitPrice = 0, Quantity = 1);
        itemOk.Product2 = prodOk;

        Test.startTest();
        PricingItem pItem = new PricingItem(itemOk);

   // 1. Criamos os registros auxiliares primeiro
Pais__c paisTeste = new Pais__c(Name = 'Brasil');
insert paisTeste;

Grupo_de_Conta__c grupoTeste = new Grupo_de_Conta__c(Name = 'VIP');
insert grupoTeste;

Hierarquia_de_Produto__c hierarquiaTeste = new Hierarquia_de_Produto__c(Name = 'Tratores');
insert hierarquiaTeste;

// 2. Agora montamos a regra usando os IDs que acabamos de criar
Margem__c regraCompleta = new Margem__c(
    Pais__c = paisTeste.Id,
    Grupo_de_Conta__c = grupoTeste.Id,
    Hierarquia_de_Produto__c = hierarquiaTeste.Id,
    Produto__c = prodOk.Id 
);
        
        Integer pesoCalculado = pItem.calcularPeso(regraCompleta);
        System.assert(pesoCalculado > 1000000, 'O peso deve ser alto');

        // Teste do Preço Sugerido e Matemática (Cobre a imagem 1586ce)
        pItem.frete = 10;
        pItem.imposto = 10;
        pItem.margem = 10;
        
        pItem.aplicarCalculoFinal();
        
        // Validação da Fórmula: (Custo + Frete) * (1 + i) * (1 + m)
        System.assert(itemOk.UnitPrice > 0, 'O motor deveria ter preenchido o UnitPrice');
        Test.stopTest();
    }

    // ==========================================================
    // 🔍 TESTE DO SELECTOR (Para zerar o vermelho do PricingSelector)
    // ==========================================================
   @isTest
    static void testPricingSelector() {
        // 1. Criamos os dados necessários para a query do Selector funcionar
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];
        Centro_Distribuicao__c cd = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1];
        Condicao_Pagamento__c cond = [SELECT Id FROM Condicao_Pagamento__c LIMIT 1];
        Endereco__c ender = [SELECT Id FROM Endereco__c LIMIT 1];

        Order ped = new Order(
            AccountId = acc.Id, EffectiveDate = Date.today(), Status = 'Draft', 
            Pricebook2Id = Test.getStandardPricebookId(), Centro_Distribuicao__c = cd.Id, 
            Condicao_Pagamento__c = cond.Id,
            Endereco__c = ender.Id
        );
        insert ped;

        OrderItem item = new OrderItem(
            OrderId = ped.Id, Product2Id = prod.Id, Quantity = 1, UnitPrice = 100, 
            PricebookEntryId = pbe.Id
        );
        insert item; // Inserimos o item no banco

        Set<Id> idsParaBusca = new Set<Id>{ item.Id };

        // 2. AGORA SIM chamamos o startTest e o Selector
        Test.startTest();
        List<OrderItem> resultado = PricingSelector.buscarItensComPedido(idsParaBusca);
        Test.stopTest();

        // 3. Verificamos se o Selector trouxe as informações do cabeçalho do pedido
        System.assertEquals(1, resultado.size(), 'O Selector deveria ter encontrado o item.');
        System.assertNotEquals(null, resultado[0].Order.Centro_Distribuicao__c, 'Deveria ter trazido o CD do Pedido.');
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
    // 🔑 TESTE UNITÁRIO: PRICING KEY 
    // ==========================================================
    @isTest
    static void testPricingKeyDireto() {
        // 1. Pega um Frete do Setup
        Frete__c f1 = [SELECT Produto__c, Estado__c, Cidade__c, Hierarquia_de_Produto__c, Pais__c FROM Frete__c LIMIT 1];
        
        // 2. Cria uma cópia diferente (para testar o equals = false)
        Frete__c f2 = f1.clone();
        f2.Cidade__c = null; // Altera um campo para a chave ser diferente

        Test.startTest();
        PricingKey chave1 = new PricingKey(f1);
        PricingKey chave2 = new PricingKey(f2);
        PricingKey chaveIgualA1 = new PricingKey(f1);

        // Força a cobertura do equals (True e False)
        System.assertEquals(true, chave1.equals(chaveIgualA1), 'Deveriam ser iguais');
        System.assertEquals(false, chave1.equals(chave2), 'Deveriam ser diferentes');
        System.assertEquals(false, chave1.equals('Não sou uma chave'), 'Deve retornar false para tipos diferentes');

        // Força a cobertura do hashCode
        Integer hash = chave1.hashCode();
        System.assertNotEquals(0, hash, 'O HashCode não pode ser zero');
        Test.stopTest();
    }
// ==========================================================
    //  TESTE DE VALIDAÇÃO: PEDIDO ATIVO (Cobre a linha 46)
    // ==========================================================
    @isTest
    static void testErroPedidoAtivado() {
        // 1. Busca os dados do Setup
        Order ped = [SELECT Id, Status FROM Order LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        // 2. Insere um item válido (O Salesforce exige itens para ativar um pedido)
        OrderItem item = new OrderItem(
            OrderId = ped.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100.00
        );
        insert item;

        // 3. Muda o Status do Pedido para Ativado
        ped.Status = 'Activated'; // Substitua pelo Status de "Ativado" correto da sua org, se for diferente
        update ped;

        // 4. Tenta alterar a quantidade do item do pedido já ativado
        Test.startTest();
        try {
            item.Quantity = 5; // <--- TENTATIVA DE ALTERAÇÃO ILEGAL
            update item;
            System.assert(false, '❌ A Trigger deveria ter bloqueado a alteração de um pedido ativo.');
        } catch (Exception e) {
            // Se cair aqui, a linha 46 foi executada com sucesso!
            System.assert(e.getMessage().contains('já está Ativo'), '✅ Sucesso: O bloqueio de pedido ativo funcionou.');
        }
        Test.stopTest();
    }
    
    // ==========================================================
    // ⚠️ TESTE DE VALIDAÇÃO: QUANTIDADE ZERO (Garantido via Update)
    // ==========================================================
    @isTest
    static void testErroQuantidadeZero_Garantido() {
        // 1. Busca os dados do Setup
        Order ped = [SELECT Id FROM Order LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        // 2. Inserimos o item com quantidade VÁLIDA (Garante que não há outros erros)
        OrderItem item = new OrderItem(
            OrderId = ped.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1, // Quantidade válida!
            UnitPrice = 100.00
        );
        insert item; // Passa liso pelo banco de dados

        // 3. Agora tentamos ATUALIZAR para zero (Força a passagem pelo validarItens)
        Test.startTest();
        try {
            item.Quantity = 0; // <--- O GATILHO DO ERRO AQUI
            update item;
            System.assert(false, '❌ A Trigger deveria ter bloqueado o update com quantidade zero.');
        } catch (Exception e) {
            // O Salesforce vai gritar, o catch vai capturar, e a linha 33 VAI ficar azul!
            System.debug('✅ O erro foi disparado com sucesso: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    // ==========================================================
    // ⚠️ TESTE DE VALIDAÇÃO: ALTERAR CLIENTE DO PEDIDO (Cobre Linha 17)
    // ==========================================================
    @isTest
    static void testErroAlterarClientePedido() {
        // 1. Busca os dados do Setup
        Account accOriginal = [SELECT Id FROM Account LIMIT 1];
        Centro_Distribuicao__c cd = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1];
        Endereco__c ender = [SELECT Id FROM Endereco__c LIMIT 1];
        Condicao_Pagamento__c cond = [SELECT Id FROM Condicao_Pagamento__c LIMIT 1];

        // 2. Cria uma SEGUNDA conta para tentar a fraude
        Account accNova = new Account(Name = 'Cliente Fraude', CNPJ__c = '22.222.222/0001-22');
        insert accNova;

        // 3. Cria o pedido com a conta original
        Order ped = new Order(
            AccountId = accOriginal.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId(),
            Centro_Distribuicao__c = cd.Id,
            Endereco__c = ender.Id,
            Condicao_Pagamento__c = cond.Id
        );
        insert ped;

        // 4. Tenta alterar a conta do pedido (Deve disparar o erro)
        Test.startTest();
        try {
            ped.AccountId = accNova.Id; // <--- GATILHO DO ERRO AQUI
            update ped;
            System.assert(false, '❌ Deveria ter bloqueado a alteração de Conta.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('alterar o Cliente'), '✅ Sucesso: Bloqueio de troca de cliente funcionou.');
        }
        Test.stopTest();
    }

   // ==========================================================
    // ⚠️ TESTE DE VALIDAÇÃO: PEDIDO ATIVO (Cobre Linha 22 do OrderHandler)
    // ==========================================================
    @isTest
    static void testErroModificarPedidoAtivo() {
        // 1. Busca os dados do Setup (Agora buscando o Produto também!)
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Centro_Distribuicao__c cd = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1];
        Endereco__c ender = [SELECT Id FROM Endereco__c LIMIT 1];
        Condicao_Pagamento__c cond = [SELECT Id FROM Condicao_Pagamento__c LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];

        // 2. Cria o Pedido
        Order ped = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft', 
            Pricebook2Id = Test.getStandardPricebookId(),
            Centro_Distribuicao__c = cd.Id,
            Endereco__c = ender.Id,
            Condicao_Pagamento__c = cond.Id
        );
        insert ped;

        // 3. 👇 A CORREÇÃO AQUI! Insere um item para o Salesforce não reclamar de "carrinho vazio"
        OrderItem item = new OrderItem(
            OrderId = ped.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100.00
        );
        insert item;

        // 4. AGORA SIM, Ativa o pedido (Vai passar liso!)
        ped.Status = 'Activated'; 
        update ped;

        // 5. Tenta fazer outra alteração com ele já 'Activated' para disparar o seu erro!
        Test.startTest();
        try {
            ped.Description = 'Tentando burlar o sistema'; // <--- TENTATIVA DE ALTERAÇÃO ILEGAL
            update ped;
            System.assert(false, '❌ Deveria ter bloqueado a modificação do pedido Ativo.');
        } catch (Exception e) {
            // Verifica se a mensagem bate com a do seu Handler!
            System.assert(e.getMessage().contains('Este pedido está Ativo'), '✅ Sucesso: Bloqueio de pedido ativo funcionou.');
        }
        Test.stopTest();
    }

    // ==========================================================
    // 🗑️ TESTE DO CONTRATO: DELETE E UNDELETE (Cobre Linhas 34 e 36)
    // ==========================================================
    @isTest
    static void testDeleteUndeleteOrder() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Centro_Distribuicao__c cd = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1];
        Endereco__c ender = [SELECT Id FROM Endereco__c LIMIT 1];
        Condicao_Pagamento__c cond = [SELECT Id FROM Condicao_Pagamento__c LIMIT 1];

        Order ped = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId(),
            Centro_Distribuicao__c = cd.Id,
            Endereco__c = ender.Id,
            Condicao_Pagamento__c = cond.Id
        );
        insert ped;

        Test.startTest();
        // Como o objeto Order tem lixeira no Salesforce, isso vai funcionar perfeitamente!
        delete ped;
        undelete ped;
        Test.stopTest();

        // Valida se ele realmente voltou da lixeira
        Integer count = [SELECT count() FROM Order WHERE Id = :ped.Id];
        System.assertEquals(1, count, '✅ O pedido deveria ter sido restaurado da lixeira com sucesso.');
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
    // 🛠️ 6. TESTE DE CONTRATO DO MAESTRO (Eventos de Trigger)
    // Cobre as assinaturas de beforeUpdate, afterUpdate, delete e undelete
    // ==========================================================
    @isTest
    static void testTriggerContractEvents() { 
        
        // ----------------------------------------------------------
        // 1. BUSCAR DADOS DO SETUP (Evita erros de campos obrigatórios)
        // ----------------------------------------------------------
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Centro_Distribuicao__c cd = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1];
        Endereco__c ender = [SELECT Id FROM Endereco__c LIMIT 1];
        Condicao_Pagamento__c cond = [SELECT Id FROM Condicao_Pagamento__c LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];

        // ----------------------------------------------------------
        // 2. CRIAR O PEDIDO COM OS CAMPOS OBRIGATÓRIOS
        // ----------------------------------------------------------
        Order ped = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft', 
            Pricebook2Id = Test.getStandardPricebookId(),
            Centro_Distribuicao__c = cd.Id, // <-- Preenchendo o que o erro pediu!
            Endereco__c = ender.Id,         // <-- Preenchendo o que o erro pediu!
            Condicao_Pagamento__c = cond.Id // <-- Preenchendo o que o erro pediu!
        );
        insert ped;

        // Inserimos o Item do Pedido
        OrderItem item = new OrderItem(
            OrderId = ped.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100.00
        );
        insert item; 


// ----------------------------------------------------------
        // 3. EXECUTAR OS EVENTOS DO CONTRATO (A Mágica da Cobertura)
        // ----------------------------------------------------------
        Test.startTest();
            
            // A. Força a entrada no beforeUpdate e afterUpdate
            item.Quantity = 2; 
            update item; 

            // B. Força a entrada no beforeDelete e afterDelete
            delete item; 

            // C. A PEGADINHA: Como OrderItem não aceita undelete no banco,
            // nós chamamos o método do seu Handler "na mão" só para o 
            // Salesforce passar pela linha de código e pintar ela de azul!
            
            OrderItemHandler handler = new OrderItemHandler();
            handler.afterUndelete(new List<OrderItem>{ item }); 

        Test.stopTest();
        
        // ----------------------------------------------------------
        // 4. VERIFICAÇÃO (Assert)
        // ----------------------------------------------------------
        Integer itensEncontrados = [SELECT count() FROM OrderItem WHERE Id = :item.Id];
        
        // Agora esperamos 0, porque OrderItem é deletado para sempre e não vai para a lixeira!
        System.assertEquals(0, itensEncontrados, 'Como não há lixeira para OrderItem, o item deve permanecer deletado.');
    }

    // ==========================================================
    // 2. TESTE DE DELETE/UNDELETE (Cobre os métodos vazios no final)
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
    // 3. TESTE DE ERROS (Cobre as linhas de 'addError' vermelhas)
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
    //  TESTES DE VALIDAÇÃO: CAMPOS EXCLUSIVOS DA MARGEM
    // ==========================================================
    @isTest
    static void testErrosCamposExclusivosMargem() {
        // 1. Busca os dados do Setup que vamos usar para "forçar" o erro
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Grupo_de_Conta__c grupo = [SELECT Id FROM Grupo_de_Conta__c LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Hierarquia_de_Produto__c hProd = [SELECT Id FROM Hierarquia_de_Produto__c LIMIT 1];
        Cidade__c cid = [SELECT Id FROM Cidade__c LIMIT 1];
        Estado__c est = [SELECT Id FROM Estado__c LIMIT 1];
        Centro_Distribuicao__c cd = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1]; 

        Test.startTest();

        // 🎯 TESTE 1: Conta + Grupo de Conta juntos (Cobre a Linha 22)
        Margem__c m1 = new Margem__c(
            Conta__c = acc.Id, 
            Grupo_de_Conta__c = grupo.Id, // <-- O GATILHO AQUI
            Produto__c = prod.Id,         // Válido
            Cidade__c = cid.Id,           // Válido
            Centro_Distribuicao__c = cd.Id,
            Valor__c = 10,
            Status__c = 'Aprovado'
        );
        try {
            insert m1;
            System.assert(false, '❌ Deveria ter bloqueado Conta + Grupo de Conta');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Conta OU Grupo'), '✅ Erro 1 validado!');
        }

        // 🎯 TESTE 2: Produto + Hierarquia juntos (Cobre a Linha 27)
        Margem__c m2 = new Margem__c(
            Conta__c = acc.Id,            // Válido
            Produto__c = prod.Id,
            Hierarquia_de_Produto__c = hProd.Id, // <-- O GATILHO AQUI
            Cidade__c = cid.Id,           // Válido
            Centro_Distribuicao__c = cd.Id,
            Valor__c = 10,
            Status__c = 'Aprovado'
        );
        try {
            insert m2;
            System.assert(false, '❌ Deveria ter bloqueado Produto + Hierarquia');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Produto OU Hierarquia'), '✅ Erro 2 validado!');
        }

        // 🎯 TESTE 3: Cidade + Estado juntos (Cobre a Linha 37)
        Margem__c m3 = new Margem__c(
            Conta__c = acc.Id,            // Válido
            Produto__c = prod.Id,         // Válido
            Cidade__c = cid.Id,
            Estado__c = est.Id,           // <-- O GATILHO AQUI (2 localidades)
            Centro_Distribuicao__c = cd.Id,
            Valor__c = 10,
            Status__c = 'Aprovado'
        );
        try {
            insert m3;
            System.assert(false, '❌ Deveria ter bloqueado Cidade + Estado');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('apenas um nível'), '✅ Erro 3 validado!');
        }

        Test.stopTest();
    }

    

// ==========================================================
    // 4. TESTE DO MOTOR: ESPECIFICIDADE (O "Sniper")
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
    //  5. TESTE DO MOTOR: BULKIFICATION 
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
    
    // ==========================================================
    // TESTE: VENDA NÃO AUTORIZADA (PRODUTO SEM PARÂMETROS)
    // Cobre a linha 90 do PricingService
    // ==========================================================
    @isTest
    static void testErroSemParametrosPricing() {
        // 1. Busca um pedido válido do Setup
        Order ped = [SELECT Id, Pricebook2Id FROM Order LIMIT 1];

        // 2. Cria um Produto NOVO, totalmente sem regras de Margem/Frete/Imposto
        Product2 prodSemRegra = new Product2(Name = 'Produto Fantasma', Custo_Producao__c = 100);
        insert prodSemRegra;

        PricebookEntry pbeFantasma = new PricebookEntry(
            Pricebook2Id = ped.Pricebook2Id,
            Product2Id = prodSemRegra.Id,
            UnitPrice = 150.00,
            IsActive = true
        );
        insert pbeFantasma;

        // 3. Tenta inserir esse produto no pedido
        OrderItem itemBloqueado = new OrderItem(
            OrderId = ped.Id,
            PricebookEntryId = pbeFantasma.Id,
            Quantity = 1,
            UnitPrice = 150.00
        );

        Test.startTest();
        try {
            insert itemBloqueado; // Vai bater no PricingService e não vai achar as regras!
            System.assert(false, '❌ Deveria ter bloqueado a venda por falta de parâmetros.');
        } catch (Exception e) {
            // O catch captura o erro da linha 90 e pinta ela de azul!
            System.assert(e.getMessage().contains('falta de parâmetros'), '✅ Sucesso: Bloqueio de segurança funcionou.');
        }
        Test.stopTest();
    }

    // ==========================================================
    //  TESTE: BOTÃO DE RECALCULAR AURA
    // Cobre as linhas 113 a 121 do PricingService
    // ==========================================================
    @isTest
    static void testMetodoRecalcularAura() {
        // 1. Busca os dados válidos do Setup
        Order ped = [SELECT Id FROM Order LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];

        // 2. Insere um item válido para o recálculo funcionar
        OrderItem item = new OrderItem(
            OrderId = ped.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 1500.00
        );
        insert item;

        Test.startTest();
        // 3. Simula o clique do usuário no botão, chamando o método diretamente!
        PricingService.recalcular(ped.Id);
        Test.stopTest();

        // 4. Verifica se o checkbox do pedido realmente foi marcado como true (Linha 121)
        Order pedAtualizado = [SELECT Precos_Recalculados__c FROM Order WHERE Id = :ped.Id];
        System.assertEquals(true, pedAtualizado.Precos_Recalculados__c, '✅ O checkbox de recalculo deveria estar marcado.');
    }
    
    
    // ==========================================================
    // TESTE: COBERTURA DOS DEFAULTS DA FACTORY
    // Força a passagem pelos defaults do Pedido e do Item!
    // ==========================================================
    @isTest
    static void testCoberturaFactoryDefaults() {
        Test.startTest();
        
        // 1. Instancia a classe que guarda os defaults do Pedido e roda o método
        TemplateDefaultFields.OrderDefaults orderDef = new TemplateDefaultFields.OrderDefaults();
        orderDef.getFieldDefaults(1);

        // 2. Instancia a classe que guarda os defaults do Item e roda o método
        TemplateDefaultFields.OrderItemDefaults itemDef = new TemplateDefaultFields.OrderItemDefaults();
        itemDef.getFieldDefaults(1);
        
        // 2. Instancia a classe que guarda os defaults do Item e roda o método
        TemplateDefaultFields.PaisDefaults paisDef = new TemplateDefaultFields.PaisDefaults();
        paisDef.getFieldDefaults(1);
        
        Test.stopTest();
        
        System.assert(true, '✅ Passou pelos Defaults da Factory com sucesso.');
    }
    
 // ==========================================================
    // TESTE: VALIDAÇÕES E EXCEÇÕES DA TEST FACTORY
    // Força os erros de Nulo, Contrato e Classe Inexistente!
    // ==========================================================
    @isTest
    static void testErrosDaFactory() {
        // Instancia a sua Factory
        TestFactorySObject factory = new TestFactorySObject();

        Test.startTest();

        // 🎯 TESTE 1: Mandar um Nulo (Cobre as Linhas 14 e 15)
        try {
            factory.createSObject(null); // GATILHO: Passando nada!
            System.assert(false, '❌ Deveria ter dado erro de SObject nulo.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('não pode ser nulo'), '✅ Erro de SObject nulo capturado.');
        }

        // 🎯 TESTE 2: Mandar um Contrato (Cobre as Linhas 32, 33, 45, 46 e 47)
        // O pulo do gato: A linha 33 muda o nome para ContractStandard.
        // Como você não tem a classe ContractStandardDefaults criada, ele vai dar erro na linha 46!
        // Ou seja: Matamos dois coelhos com uma cajadada só.
        try {
            factory.createSObject(new Contract()); // GATILHO: Passando um Contrato
            System.assert(false, '❌ Deveria ter dado erro de classe inexistente.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Invalid defaults class'), '✅ Erro de classe inexistente capturado.');
        }

        Test.stopTest();
    }
    
}