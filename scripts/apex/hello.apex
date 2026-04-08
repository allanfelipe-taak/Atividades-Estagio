// ==========================================================
// 0. RESET DA ORG (LIMPEZA TOTAL)
// ==========================================================
delete [SELECT Id FROM Order];
delete [SELECT Id FROM Margem__c];
delete [SELECT Id FROM Frete__c];
delete [SELECT Id FROM Imposto__c];

// 1. PREPARAÇÃO DA INFRAESTRUTURA
Map<String, Id> mapaGrupos = new Map<String, Id>();
List<String> nomesGrupos = new List<String>{'VIP Agro', 'Ouro', 'Prata', 'Bronze'};
for(String nome : nomesGrupos) {
    try { mapaGrupos.put(nome, [SELECT Id FROM Grupo_de_Conta__c WHERE Name = :nome LIMIT 1].Id); } 
    catch (Exception e) { Grupo_de_Conta__c nG = new Grupo_de_Conta__c(Name = nome); insert nG; mapaGrupos.put(nome, nG.Id); }
}

Account accVIP = new Account(Name = 'Cliente VIP S/A', Grupo_de_Conta__c = mapaGrupos.get('VIP Agro'));
Account accOuro = new Account(Name = 'Fazenda Ouro', Grupo_de_Conta__c = mapaGrupos.get('Ouro'));
Account accPrata = new Account(Name = 'Sítio Prata', Grupo_de_Conta__c = mapaGrupos.get('Prata'));
Account accBronze = new Account(Name = 'Recanto Bronze', Grupo_de_Conta__c = mapaGrupos.get('Bronze'));
insert new List<Account>{accVIP, accOuro, accPrata, accBronze};

// Garantindo que a Hierarquia Master exista
Id hId; 
try { hId = [SELECT Id FROM Hierarquia_de_Produto__c WHERE Name = 'Maquinário Pesado' LIMIT 1].Id; } 
catch (Exception e) { Hierarquia_de_Produto__c nH = new Hierarquia_de_Produto__c(Name='Maquinário Pesado'); insert nH; hId = nH.Id; }

Id cdId; try { cdId = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1].Id; } catch (Exception e) { cdId = null; }
Id endId; try { endId = [SELECT Id FROM Endereco__c LIMIT 1].Id; } catch (Exception e) { Endereco__c nE = new Endereco__c(Name='Matriz SP'); insert nE; endId = nE.Id; }
Id condId; try { condId = [SELECT Id FROM Condicao_Pagamento__c LIMIT 1].Id; } catch (Exception e) { Condicao_Pagamento__c nC = new Condicao_Pagamento__c(Name='30 Dias'); insert nC; condId = nC.Id; }

Id estId; try { estId = [SELECT Id FROM Estado__c WHERE Name = 'Paraná' LIMIT 1].Id; } catch (Exception e) { Estado__c novoEst = new Estado__c(Name = 'Paraná'); insert novoEst; estId = novoEst.Id; }
Id cidId; try { cidId = [SELECT Id FROM Cidade__c WHERE Name = 'Curitiba' LIMIT 1].Id; } catch (Exception e) { Cidade__c novaCid = new Cidade__c(Name = 'Curitiba'); insert novaCid; cidId = novaCid.Id; }

Id pbId = [SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1].Id;

// ==========================================================
// 2. CRIAÇÃO DE PRODUTOS DISTINTOS (BASE MATEMÁTICA SIMPLIFICADA)
// ==========================================================
// Os custos foram pensados para somar com o frete e dar números redondos (100k, 200k, etc)
Product2 p1 = new Product2(Name = 'Trator de Esteira Max', ProductCode = 'TRT-001', Custo_Producao__c = 90000.00, Hierarquia_de_Produto__c = hId);
Product2 p2 = new Product2(Name = 'Colheitadeira Master', ProductCode = 'COL-002', Custo_Producao__c = 180000.00, Hierarquia_de_Produto__c = hId);
Product2 p3 = new Product2(Name = 'Pulverizador Pro', ProductCode = 'PUL-003', Custo_Producao__c = 270000.00, Hierarquia_de_Produto__c = hId);
Product2 p4 = new Product2(Name = 'Plantadeira Precision', ProductCode = 'PLA-004', Custo_Producao__c = 95000.00, Hierarquia_de_Produto__c = hId);
insert new List<Product2>{p1, p2, p3, p4};

insert new List<PricebookEntry>{
    new PricebookEntry(Pricebook2Id = pbId, Product2Id = p1.Id, UnitPrice = 0, IsActive = true),
    new PricebookEntry(Pricebook2Id = pbId, Product2Id = p2.Id, UnitPrice = 0, IsActive = true),
    new PricebookEntry(Pricebook2Id = pbId, Product2Id = p3.Id, UnitPrice = 0, IsActive = true),
    new PricebookEntry(Pricebook2Id = pbId, Product2Id = p4.Id, UnitPrice = 0, IsActive = true)
};

// ==========================================================
// 3. REGRAS DE ESPECIFICIDADE (VALORES REDONDOS PARA A DEMO)
// ==========================================================
insert new List<Margem__c>{
    new Margem__c(Produto__c=p1.Id, Grupo_de_Conta__c=mapaGrupos.get('VIP Agro'), Cidade__c=cidId, Estado__c=estId, Valor__c=5, Status__c='Aprovado'),
    new Margem__c(Produto__c=p2.Id, Grupo_de_Conta__c=mapaGrupos.get('Ouro'), Cidade__c=cidId, Estado__c=estId, Valor__c=10, Status__c='Aprovado'),
    new Margem__c(Produto__c=p3.Id, Grupo_de_Conta__c=mapaGrupos.get('Prata'), Cidade__c=cidId, Estado__c=estId, Valor__c=15, Status__c='Aprovado'),
    new Margem__c(Produto__c=p4.Id, Grupo_de_Conta__c=mapaGrupos.get('Bronze'), Cidade__c=cidId, Estado__c=estId, Valor__c=20, Status__c='Aprovado')
};
insert new List<Frete__c>{
    new Frete__c(Produto__c=p1.Id, Cidade__c=cidId, Estado__c=estId, Valor__c=10000, Status__c='Aprovado'),
    new Frete__c(Produto__c=p2.Id, Cidade__c=cidId, Estado__c=estId, Valor__c=20000, Status__c='Aprovado'),
    new Frete__c(Produto__c=p3.Id, Cidade__c=cidId, Estado__c=estId, Valor__c=30000, Status__c='Aprovado'),
    new Frete__c(Produto__c=p4.Id, Cidade__c=cidId, Estado__c=estId, Valor__c=5000, Status__c='Aprovado')
};
insert new List<Imposto__c>{
    new Imposto__c(Produto__c=p1.Id, Estado__c=estId, Imposto_sobre_custo__c=10, Status__c='Aprovado'),
    new Imposto__c(Produto__c=p2.Id, Estado__c=estId, Imposto_sobre_custo__c=10, Status__c='Aprovado'),
    new Imposto__c(Produto__c=p3.Id, Estado__c=estId, Imposto_sobre_custo__c=10, Status__c='Aprovado'),
    new Imposto__c(Produto__c=p4.Id, Estado__c=estId, Imposto_sobre_custo__c=20, Status__c='Aprovado')
};

// --- REGRAS GENÉRICAS PARA TESTAR ESPECIFICIDADE (A BUCHA DE CANHÃO) ---
// Regras com valores absurdamente altos para você provar que o sistema não pegou elas
insert new Margem__c(Hierarquia_de_Produto__c=hId, Valor__c=50, Status__c='Aprovado');
insert new Frete__c(Estado__c=estId, Valor__c=50000, Status__c='Aprovado');
insert new Imposto__c(Estado__c=estId, Imposto_sobre_custo__c=30, Status__c='Aprovado');


// ==========================================================
// 4. TESTE DE DUPLICIDADE TOTAL (PENTE FINO P1 A P4)
// ==========================================================
System.debug('🛡️ TESTANDO BLOQUEIOS DE DUPLICIDADE...');
// Testando Margens
try { insert new Margem__c(Produto__c=p1.Id, Grupo_de_Conta__c=mapaGrupos.get('VIP Agro'), Valor__c=99); } catch (Exception e) { System.debug('✅ MARGEM P1: Bloqueada!'); }
try { insert new Margem__c(Produto__c=p2.Id, Grupo_de_Conta__c=mapaGrupos.get('Ouro'), Valor__c=99); } catch (Exception e) { System.debug('✅ MARGEM P2: Bloqueada!'); }
try { insert new Margem__c(Produto__c=p3.Id, Grupo_de_Conta__c=mapaGrupos.get('Prata'), Valor__c=99); } catch (Exception e) { System.debug('✅ MARGEM P3: Bloqueada!'); }
try { insert new Margem__c(Produto__c=p4.Id, Grupo_de_Conta__c=mapaGrupos.get('Bronze'), Valor__c=99); } catch (Exception e) { System.debug('✅ MARGEM P4: Bloqueada!'); }
// Testando Fretes
try { insert new Frete__c(Produto__c=p1.Id, Cidade__c=cidId, Valor__c=1); } catch (Exception e) { System.debug('✅ FRETE P1: Bloqueado!'); }
try { insert new Frete__c(Produto__c=p2.Id, Cidade__c=cidId, Valor__c=1); } catch (Exception e) { System.debug('✅ FRETE P2: Bloqueado!'); }
try { insert new Frete__c(Produto__c=p3.Id, Cidade__c=cidId, Valor__c=1); } catch (Exception e) { System.debug('✅ FRETE P3: Bloqueado!'); }
try { insert new Frete__c(Produto__c=p4.Id, Cidade__c=cidId, Valor__c=1); } catch (Exception e) { System.debug('✅ FRETE P4: Bloqueado!'); }
// Testando Impostos
try { insert new Imposto__c(Produto__c=p1.Id, Estado__c=estId, Imposto_sobre_custo__c=1); } catch (Exception e) { System.debug('✅ IMPOSTO P1: Bloqueado!'); }
try { insert new Imposto__c(Produto__c=p2.Id, Estado__c=estId, Imposto_sobre_custo__c=1); } catch (Exception e) { System.debug('✅ IMPOSTO P2: Bloqueado!'); }
try { insert new Imposto__c(Produto__c=p3.Id, Estado__c=estId, Imposto_sobre_custo__c=1); } catch (Exception e) { System.debug('✅ IMPOSTO P3: Bloqueado!'); }
try { insert new Imposto__c(Produto__c=p4.Id, Estado__c=estId, Imposto_sobre_custo__c=1); } catch (Exception e) { System.debug('✅ IMPOSTO P4: Bloqueado!'); }


// ==========================================================
// 5. PROCESSO DE VENDA (BULK - 40 ITENS)
// ==========================================================
Order ped1 = new Order(AccountId=accVIP.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=pbId, Centro_Distribuicao__c=cdId, Endereco__c=endId, Condicao_Pagamento__c=condId, ShippingCity='Curitiba');
Order ped2 = new Order(AccountId=accOuro.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=pbId, Centro_Distribuicao__c=cdId, Endereco__c=endId, Condicao_Pagamento__c=condId, ShippingCity='Curitiba');
Order ped3 = new Order(AccountId=accPrata.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=pbId, Centro_Distribuicao__c=cdId, Endereco__c=endId, Condicao_Pagamento__c=condId, ShippingCity='Curitiba');
Order ped4 = new Order(AccountId=accBronze.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=pbId, Centro_Distribuicao__c=cdId, Endereco__c=endId, Condicao_Pagamento__c=condId, ShippingCity='Curitiba');
List<Order> peds = new List<Order>{ped1, ped2, ped3, ped4};
insert peds;

List<OrderItem> itensBulk = new List<OrderItem>();
Id pbe1 = [SELECT Id FROM PricebookEntry WHERE Product2Id = :p1.Id LIMIT 1].Id;
Id pbe2 = [SELECT Id FROM PricebookEntry WHERE Product2Id = :p2.Id LIMIT 1].Id;
Id pbe3 = [SELECT Id FROM PricebookEntry WHERE Product2Id = :p3.Id LIMIT 1].Id;
Id pbe4 = [SELECT Id FROM PricebookEntry WHERE Product2Id = :p4.Id LIMIT 1].Id;

// for(Integer i=0; i<10; i++) {
    // 1. VIP (Trator) -> O Preço Motor será R$ 121.000 (Venda no Preço Sugerido)
    itensBulk.add(new OrderItem(OrderId=ped1.Id, Product2Id=p1.Id, Quantity=1, UnitPrice=0, PricebookEntryId=pbe1));

    // 2. OURO (Colheitadeira) -> O Preço Motor será R$ 264.000 (Desconto: Vendido por R$ 250.000)
    itensBulk.add(new OrderItem(OrderId=ped2.Id, Product2Id=p2.Id, Quantity=1, UnitPrice=250000, PricebookEntryId=pbe2));

    // 3. PRATA (Pulverizador) -> O Preço Motor será R$ 363.000 (Ágio: Vendido por R$ 400.000)
    itensBulk.add(new OrderItem(OrderId=ped3.Id, Product2Id=p3.Id, Quantity=1, UnitPrice=400000, PricebookEntryId=pbe3));

    // 4. BRONZE (Plantadeira) -> O Preço Motor será R$ 132.000 (Venda no Preço Sugerido)
    itensBulk.add(new OrderItem(OrderId=ped4.Id, Product2Id=p4.Id, Quantity=1, UnitPrice=0, PricebookEntryId=pbe4));
//}
insert itensBulk; 

// ==========================================================
// 6. RELATÓRIO DETALHADO: ESPECIFICIDADE, FÓRMULA E DESCONTO
// ==========================================================
List<OrderItem> resultados = [SELECT UnitPrice, Custo_Producao__c, Valor_Frete__c, 
                                     Porcentagem_Imposto__c, Porcentagem_Margem__c,
                                     Preco_sem_Margem__c, Preco_Final__c, Desconto__c,
                                     Order.Account.Name, Product2.Name
                              FROM OrderItem 
                              WHERE OrderId IN :peds];

for(OrderItem res : resultados) {
    System.debug('==========================================================');
    System.debug('🎯 AUDITORIA DE ESPECIFICIDADE: ' + res.Product2.Name);
    System.debug('==========================================================');
    
    // Atualizado para bater com as novas porcentagens
    Boolean isEspecifica = (res.Porcentagem_Margem__c == 10 || res.Porcentagem_Margem__c == 20);

    System.debug(' MARGEM APLICADA: ' + res.Porcentagem_Margem__c + '%' + (isEspecifica ? ' ✅ (Produto + Grupo - Peso > 1 Milhão)' : ' ❌ (Genérica)'));
    System.debug(' FRETE APLICADO: R$ ' + res.Valor_Frete__c + (res.Valor_Frete__c != 50000 ? ' ✅ (Produto + Localidade - Específico)' : ' ❌ (Padrão)'));
    System.debug(' IMPOSTO APLICADO: ' + res.Porcentagem_Imposto__c + '%' + (res.Porcentagem_Imposto__c != 30 ? ' ✅ (Produto + Estado - Específico)' : ' ❌ (Padrão)'));

    System.debug('----------------------------------------------------------');
    System.debug('📊 MEMÓRIA DE CÁLCULO (FÓRMULA MULTIPLICATIVA)');
    System.debug('----------------------------------------------------------');
    System.debug(' FÓRMULA: (Custo + Frete) * (1 + Imposto) * (1 + Margem) ');
    System.debug(' 1. CUSTO + FRETE: R$ ' + (res.Custo_Producao__c + res.Valor_Frete__c));
    System.debug(' 2. PREÇO C/ IMPOSTO: R$ ' + res.Preco_sem_Margem__c);
    System.debug(' 3. PREÇO FINAL SUGERIDO (MOTOR): R$ ' + res.Preco_Final__c);
    
    System.debug('----------------------------------------------------------');
    System.debug('💰 RESULTADO DA VENDA - ' + res.Order.Account.Name);
    System.debug('----------------------------------------------------------');
    System.debug(' PREÇO PRATICADO (UNIT PRICE): R$ ' + res.UnitPrice);
    
    Decimal percentualDesc = (res.Desconto__c != null) ? res.Desconto__c.setScale(2) : 0;
    System.debug(' 📉 DESCONTO APLICADO: ' + percentualDesc + '%');

    if(res.Preco_Final__c == res.UnitPrice && res.UnitPrice > 0) {
        System.debug('🚀 STATUS: SUCESSO NO CÁLCULO AUTOMÁTICO!');
    } else if(res.UnitPrice < res.Preco_Final__c) {
        System.debug('🚀 STATUS: PREÇO COM DESCONTO COMERCIAL MANUAL!');
    }
    System.debug('==========================================================\n');
}
System.debug('🏆 DEMO FINALIZADA: ' + resultados.size() + ' itens auditados com a nova arquitetura do Matheus.');