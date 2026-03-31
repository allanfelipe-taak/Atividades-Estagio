// -------------------------------------------------------------------------
// 1. PREPARAÇÃO DA INFRAESTRUTURA (VERIFICA OU CRIA)
// -------------------------------------------------------------------------
Account acc;
try {
    acc = [SELECT Id FROM Account WHERE Name = 'AgroFazenda S/A' LIMIT 1];
} catch (Exception e) {
    acc = new Account(Name = 'AgroFazenda S/A'); insert acc;
}

Id cdId;
try { cdId = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1].Id; } 
catch (Exception e) { 
    Centro_Distribuicao__c novoCD = new Centro_Distribuicao__c(Name = 'CD Central'); 
    insert novoCD; cdId = novoCD.Id; 
}

Id endId;
try { endId = [SELECT Id FROM Endereco__c LIMIT 1].Id; } 
catch (Exception e) { 
    Endereco__c novoEnd = new Endereco__c(Name = 'Matriz SP'); 
    insert novoEnd; endId = novoEnd.Id; 
}

Id condId;
try { condId = [SELECT Id FROM Condicao_Pagamento__c LIMIT 1].Id; } 
catch (Exception e) { 
    Condicao_Pagamento__c novaCond = new Condicao_Pagamento__c(Name = '30 Dias'); 
    insert novaCond; condId = novaCond.Id; 
}

Id pbId = [SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1].Id;

// 2. CRIAÇÃO DO PRODUTO
String nomeProd = 'Trator Titan Pro v' + DateTime.now().format('mmSS');
Product2 p = new Product2(Name = nomeProd, ProductCode = 'TRT-PRO', Custo_Producao__c = 1200.00);
insert p;
insert new PricebookEntry(Pricebook2Id = pbId, Product2Id = p.Id, UnitPrice = 0, IsActive = true);

// -------------------------------------------------------------------------
// TESTES DE SEGURANÇA E ESPECIFICIDADE
// -------------------------------------------------------------------------
System.debug('--- VALIDANDO SEGURANÇA: DUPLICIDADES ---');

Id hId; try { hId = [SELECT Id FROM Hierarquia_de_Produto__c LIMIT 1].Id; } catch (Exception e) { hId = null; }
Id paisId; try { paisId = [SELECT Id FROM Pais__c WHERE Name = 'Brasil' LIMIT 1].Id; } catch (Exception e) { paisId = null; }
Id estId; try { estId = [SELECT Id FROM Estado__c WHERE Name = 'Paraná' LIMIT 1].Id; } catch (Exception e) { estId = null; }

// INSERINDO A MARGEM (ESPECIFICIDADE: CONTA)
insert new Margem__c(
    Produto__c = p.Id, 
    Conta__c = acc.Id, 
    Valor__c = 25.0, 
    Status__c = 'Aprovado',
    Hierarquia_de_Produto__c = hId,
    Pais__c = paisId
); 

// TESTE DE DUPLICIDADE: TENTANDO INSERIR MARGEM IGUAL
try { 
    insert new Margem__c(Produto__c = p.Id, Conta__c = acc.Id, Valor__c = 40.0, Status__c = 'Aprovado'); 
} catch (Exception e) { 
    System.debug('✅ SUCESSO: Margem duplicada para AgroFazenda bloqueada!'); 
}
   
insert new Imposto__c(Produto__c = p.Id, Imposto_sobre_custo__c = 10.0, Status__c = 'Aprovado');

// FRETES: Criando Localidade Curitiba
Cidade__c cid = new Cidade__c(Name = 'Curitiba'); insert cid;

insert new Frete__c(
    Produto__c = p.Id, 
    Cidade__c = cid.Id, 
    Estado__c = estId,
    Valor__c = 350.0, 
    Status__c = 'Aprovado'
);

// -------------------------------------------------------------------------
// 3. PROCESSO DE VENDA
// -------------------------------------------------------------------------
Order ped = new Order(
    AccountId = acc.Id, EffectiveDate = Date.today(), Status = 'Draft', Pricebook2Id = pbId,
    Endereco__c = endId, Centro_Distribuicao__c = cdId, Condicao_Pagamento__c = condId,
    Tipo_Frete__c = 'CIF', ShippingCity = 'Curitiba'
);
insert ped;

OrderItem item = new OrderItem(
    OrderId = ped.Id, Product2Id = p.Id, Quantity = 1, UnitPrice = 0, 
    PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id = :p.Id LIMIT 1].Id
);
insert item;

// -------------------------------------------------------------------------
// 4. TESTE DE SEGURANÇA (NOMES REAIS)
// -------------------------------------------------------------------------
System.debug('--- VALIDANDO SEGURANÇA: REGRAS DO REPRESENTANTE ---');
try {
    Account produtorRural = new Account(Name = 'José de Oliveira - Produtor Meação'); 
    insert produtorRural;
    ped.AccountId = produtorRural.Id;
    update ped; 
} catch (Exception e) {
    System.debug('✅ SUCESSO: Bloqueada tentativa de transferir preço VIP para José de Oliveira!');
}

// -------------------------------------------------------------------------
// 5. RELATÓRIO FINAL DE AUDITORIA
// -------------------------------------------------------------------------
OrderItem res = [SELECT UnitPrice, Custo_Producao__c, Valor_Frete__c, 
                        Porcentagem_Imposto__c, Porcentagem_Margem__c,
                        Preco_Final__c, Preco_sem_Margem__c, Desconto__c,
                        Order.Account.Name, Product2.Name
                 FROM OrderItem WHERE Id = :item.Id];

System.debug('==========================================================');
System.debug('RELATÓRIO DE AUDITORIA - AGRO IMPLEMENTS');
System.debug('==========================================================');
System.debug(' CLIENTE: ' + res.Order.Account.Name);
System.debug('PRODUTO: ' + res.Product2.Name);
System.debug('CUSTO: R$ ' + res.Custo_Producao__c);
System.debug('FRETE APLICADO: R$ ' + res.Valor_Frete__c);
System.debug('IMPOSTO: ' + res.Porcentagem_Imposto__c + '%');
System.debug('MARGEM: ' + res.Porcentagem_Margem__c + '%');
System.debug('----------------------------------------------------------');
System.debug('PREÇO FINAL SUGERIDO: R$ ' + res.Preco_Final__c);
System.debug('PREÇO PRATICADO: R$ ' + res.UnitPrice);
System.debug('==========================================================');