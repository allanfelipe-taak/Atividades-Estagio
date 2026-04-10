// ==========================================================
// 0. RESET DA ORG (LIMPEZA TOTAL)
// ==========================================================
delete [SELECT Id FROM Order];
delete [SELECT Id FROM Margem__c];
delete [SELECT Id FROM Frete__c];
delete [SELECT Id FROM Imposto__c];

// ==========================================================
// 1. PREPARAÇÃO DA INFRAESTRUTURA
// ==========================================================
Map<String, Id> mapaGrupos = new Map<String, Id>();
List<String> nomesGrupos = new List<String>{'VIP Agro', 'Ouro', 'Prata', 'Bronze'};
for(String nome : nomesGrupos) {
    try { mapaGrupos.put(nome, [SELECT Id FROM Grupo_de_Conta__c WHERE Name = :nome LIMIT 1].Id); } 
    catch (Exception e) { Grupo_de_Conta__c nG = new Grupo_de_Conta__c(Name = nome); insert nG; mapaGrupos.put(nome, nG.Id); }
}

Account accVIP = new Account(Name = 'Cliente VIP S/A', Grupo_de_Conta__c = mapaGrupos.get('VIP Agro'), CNPJ__c = '11.111.111/0001-11');
Account accOuro = new Account(Name = 'Fazenda Ouro', Grupo_de_Conta__c = mapaGrupos.get('Ouro'), CNPJ__c = '22.222.222/0001-22');
Account accPrata = new Account(Name = 'Sítio Prata', Grupo_de_Conta__c = mapaGrupos.get('Prata'), CNPJ__c = '33.333.333/0001-33');
Account accBronze = new Account(Name = 'Recanto Bronze', Grupo_de_Conta__c = mapaGrupos.get('Bronze'), CNPJ__c = '44.444.444/0001-44');
insert new List<Account>{accVIP, accOuro, accPrata, accBronze};

Id hId; try { hId = [SELECT Id FROM Hierarquia_de_Produto__c WHERE Name = 'Maquinário Pesado' LIMIT 1].Id; } catch (Exception e) { Hierarquia_de_Produto__c nH = new Hierarquia_de_Produto__c(Name='Maquinário Pesado'); insert nH; hId = nH.Id; }
Id estId; try { estId = [SELECT Id FROM Estado__c WHERE Name = 'Paraná' LIMIT 1].Id; } catch (Exception e) { Estado__c nE = new Estado__c(Name='Paraná'); insert nE; estId = nE.Id; }
Id cidId; try { cidId = [SELECT Id FROM Cidade__c WHERE Name = 'Curitiba' LIMIT 1].Id; } catch (Exception e) { Cidade__c nC = new Cidade__c(Name='Curitiba'); insert nC; cidId = nC.Id; }
Id paisId; try { paisId = [SELECT Id FROM Pais__c WHERE Name = 'Brasil' LIMIT 1].Id; } catch (Exception e) { Pais__c nP = new Pais__c(Name='Brasil'); insert nP; paisId = nP.Id; }

// RECUPERANDO OS CAMPOS DO PEDIDO QUE EU TINHA TIRADO
Id cdId; try { cdId = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1].Id; } catch (Exception e) { cdId = null; }
Id endId; try { endId = [SELECT Id FROM Endereco__c LIMIT 1].Id; } catch (Exception e) { Endereco__c nE = new Endereco__c(Name='Matriz SP'); insert nE; endId = nE.Id; }
Id condId; try { condId = [SELECT Id FROM Condicao_Pagamento__c LIMIT 1].Id; } catch (Exception e) { Condicao_Pagamento__c nC = new Condicao_Pagamento__c(Name='30 Dias'); insert nC; condId = nC.Id; }

Id pbId = [SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1].Id;

// ==========================================================
// 2. CRIAÇÃO DE PRODUTOS P1 A P4
// ==========================================================
Product2 p1 = new Product2(Name = 'Trator de Esteira Max', ProductCode = 'TRT-001', Custo_Producao__c = 90000.00, Hierarquia_de_Produto__c = hId);
Product2 p2 = new Product2(Name = 'Colheitadeira Master', ProductCode = 'COL-002', Custo_Producao__c = 180000.00, Hierarquia_de_Produto__c = hId);
Product2 p3 = new Product2(Name = 'Pulverizador Pro', ProductCode = 'PUL-003', Custo_Producao__c = 270000.00, Hierarquia_de_Produto__c = hId);
Product2 p4 = new Product2(Name = 'Plantadeira Precision', ProductCode = 'PLA-004', Custo_Producao__c = 95000.00, Hierarquia_de_Produto__c = hId);
insert new List<Product2>{p1, p2, p3, p4};

List<PricebookEntry> pbes = new List<PricebookEntry>();
for(Product2 p : new List<Product2>{p1, p2, p3, p4}) { pbes.add(new PricebookEntry(Pricebook2Id = pbId, Product2Id = p.Id, UnitPrice = 0, IsActive = true)); }
insert pbes;

// ==========================================================
// 3. REGRAS DE ESPECIFICIDADE (VALORES REDONDOS)
// ==========================================================
insert new List<Margem__c>{
    new Margem__c(Produto__c=p1.Id, Grupo_de_Conta__c=mapaGrupos.get('VIP Agro'), Cidade__c=cidId, Valor__c=5, Status__c='Aprovado'),
    new Margem__c(Produto__c=p2.Id, Grupo_de_Conta__c=mapaGrupos.get('Ouro'), Cidade__c=cidId, Valor__c=10, Status__c='Aprovado'),
    new Margem__c(Produto__c=p3.Id, Grupo_de_Conta__c=mapaGrupos.get('Prata'), Cidade__c=cidId, Valor__c=15, Status__c='Aprovado'),
    new Margem__c(Produto__c=p4.Id, Grupo_de_Conta__c=mapaGrupos.get('Bronze'), Cidade__c=cidId, Valor__c=20, Status__c='Aprovado')
};
insert new List<Frete__c>{
    new Frete__c(Produto__c=p1.Id, Cidade__c=cidId, Valor__c=10000, Status__c='Aprovado'),
    new Frete__c(Produto__c=p2.Id, Cidade__c=cidId, Valor__c=20000, Status__c='Aprovado'),
    new Frete__c(Produto__c=p3.Id, Cidade__c=cidId, Valor__c=30000, Status__c='Aprovado'),
    new Frete__c(Produto__c=p4.Id, Cidade__c=cidId, Valor__c=5000, Status__c='Aprovado')
};
insert new List<Imposto__c>{
    new Imposto__c(Produto__c=p1.Id, Estado__c=estId, Imposto_sobre_custo__c=10, Status__c='Aprovado'),
    new Imposto__c(Produto__c=p2.Id, Estado__c=estId, Imposto_sobre_custo__c=10, Status__c='Aprovado'),
    new Imposto__c(Produto__c=p3.Id, Estado__c=estId, Imposto_sobre_custo__c=10, Status__c='Aprovado'),
    new Imposto__c(Produto__c=p4.Id, Estado__c=estId, Imposto_sobre_custo__c=20, Status__c='Aprovado')
};

// REGRAS GENÉRICAS (A BUCHA DE CANHÃO)
insert new Margem__c(Hierarquia_de_Produto__c=hId, Valor__c=50, Status__c='Aprovado');
insert new Frete__c(Hierarquia_de_Produto__c=hId, Estado__c=estId, Valor__c=50000, Status__c='Aprovado');
insert new Imposto__c(Produto__c=p1.Id, Pais__c=paisId, Imposto_sobre_custo__c=30, Status__c='Aprovado');

// ==========================================================
// 4. TESTE DE SEGURANÇA (DUPLICIDADE E XOR) - P1 a P4
// ==========================================================
System.debug('🛡️ TESTANDO BLOQUEIOS DE SEGURANÇA...');

// "Caderninhos" para guardar se o sistema conseguiu bloquear ou não
Map<Id, Boolean> bloqueouMargem = new Map<Id, Boolean>();
Map<Id, Boolean> bloqueouFrete = new Map<Id, Boolean>();
Map<Id, Boolean> bloqueouImposto = new Map<Id, Boolean>();

for(Product2 p : new List<Product2>{p1, p2, p3, p4}) {
    try { insert new Margem__c(Produto__c=p.Id, Grupo_de_Conta__c=mapaGrupos.get('VIP Agro'), Cidade__c=cidId, Valor__c=99); bloqueouMargem.put(p.Id, false); } catch (Exception e) { bloqueouMargem.put(p.Id, true); }
    try { insert new Frete__c(Produto__c=p.Id, Cidade__c=cidId, Valor__c=1); bloqueouFrete.put(p.Id, false); } catch (Exception e) { bloqueouFrete.put(p.Id, true); }
    try { insert new Imposto__c(Produto__c=p.Id, Estado__c=estId, Imposto_sobre_custo__c=1); bloqueouImposto.put(p.Id, false); } catch (Exception e) { bloqueouImposto.put(p.Id, true); }
}

// // BULKIFICATION: Apenas 3 DMLs para tentar salvar os 12 testes. "false" não deixa o script quebrar.
// Database.SaveResult[] srMargens = Database.insert(margensTeste, false);
// Database.SaveResult[] srFretes = Database.insert(fretesTeste, false);
// Database.SaveResult[] srImpostos = Database.insert(impostosTeste, false);

// for(Integer i = 0; i < margensTeste.size(); i++) {
//     Id prodId = margensTeste[i].Produto__c;
//     bloqueouMargem.put(prodId, !srMargens[i].isSuccess());
//     bloqueouFrete.put(prodId, !srFretes[i].isSuccess());
//     bloqueouImposto.put(prodId, !srImpostos[i].isSuccess());
// }
// ==========================================================
// 5. PROCESSO DE VENDA (Criação dos Itens)
// ==========================================================
// RECUPERANDO OS CAMPOS DO SEU PROJETO AQUI!
List<Order> peds = new List<Order>{
    new Order(AccountId=accVIP.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=pbId, Centro_Distribuicao__c=cdId, Endereco__c=endId, Condicao_Pagamento__c=condId, ShippingCity='Curitiba'),
    new Order(AccountId=accOuro.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=pbId, Centro_Distribuicao__c=cdId, Endereco__c=endId, Condicao_Pagamento__c=condId, ShippingCity='Curitiba'),
    new Order(AccountId=accPrata.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=pbId, Centro_Distribuicao__c=cdId, Endereco__c=endId, Condicao_Pagamento__c=condId, ShippingCity='Curitiba'),
    new Order(AccountId=accBronze.Id, EffectiveDate=Date.today(), Status='Draft', Pricebook2Id=pbId, Centro_Distribuicao__c=cdId, Endereco__c=endId, Condicao_Pagamento__c=condId, ShippingCity='Curitiba')
};
insert peds;

List<OrderItem> itens = new List<OrderItem>();
itens.add(new OrderItem(OrderId=peds[0].Id, Product2Id=p1.Id, Quantity=1, UnitPrice=0, PricebookEntryId=[SELECT Id FROM PricebookEntry WHERE Product2Id=:p1.Id].Id));
itens.add(new OrderItem(OrderId=peds[1].Id, Product2Id=p2.Id, Quantity=1, UnitPrice=0, PricebookEntryId=[SELECT Id FROM PricebookEntry WHERE Product2Id=:p2.Id].Id));
itens.add(new OrderItem(OrderId=peds[2].Id, Product2Id=p3.Id, Quantity=1, UnitPrice=0, PricebookEntryId=[SELECT Id FROM PricebookEntry WHERE Product2Id=:p3.Id].Id));
itens.add(new OrderItem(OrderId=peds[3].Id, Product2Id=p4.Id, Quantity=1, UnitPrice=0, PricebookEntryId=[SELECT Id FROM PricebookEntry WHERE Product2Id=:p4.Id].Id));
insert itens;

// ==========================================================
// 6. RELATÓRIO DETALHADO
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

    // --- NOVO BLOCO DE SEGURANÇA ---
    System.debug('🛡️ STATUS DE PROTEÇÃO CONTRA DUPLICIDADE (HANDLERS):');
    System.debug(' BLOQUEIO MARGEM:  ' + (bloqueouMargem.get(res.Product2Id) ? '✅ BARRADO COM SUCESSO' : '❌ FALHOU (Aceitou lixo)'));
    System.debug(' BLOQUEIO FRETE:   ' + (bloqueouFrete.get(res.Product2Id) ? '✅ BARRADO COM SUCESSO' : '❌ FALHOU (Aceitou lixo)'));
    System.debug(' BLOQUEIO IMPOSTO: ' + (bloqueouImposto.get(res.Product2Id) ? '✅ BARRADO COM SUCESSO' : '❌ FALHOU (Aceitou lixo)'));
    System.debug('----------------------------------------------------------');
    
    Boolean isMargemEspecifica = (res.Porcentagem_Margem__c != 50);
    Boolean isFreteEspecifico = (res.Valor_Frete__c != 50000);
    Boolean isImpostoEspecifico = (res.Porcentagem_Imposto__c != 30);

    System.debug(' MARGEM APLICADA: ' + res.Porcentagem_Margem__c + '%' + (isMargemEspecifica ? ' ✅ (Específica)' : ' ❌ (Genérica)'));
    System.debug(' FRETE APLICADO: R$ ' + res.Valor_Frete__c + (isFreteEspecifico ? ' ✅ (Específico)' : ' ❌ (Padrão/Bucha)'));
    System.debug(' IMPOSTO APLICADO: ' + res.Porcentagem_Imposto__c + '%' + (isImpostoEspecifico ? ' ✅ (Específico)' : ' ❌ (Padrão/Bucha)'));

    System.debug('----------------------------------------------------------');
    System.debug('📊 MEMÓRIA DE CÁLCULO (FÓRMULA MULTIPLICATIVA)');
    System.debug('----------------------------------------------------------');
    System.debug(' FÓRMULA: (Custo + Frete) * (1 + Imposto) * (1 + Margem) ');
    System.debug(' 1. CUSTO + FRETE: R$ ' + (res.Custo_Producao__c + (res.Valor_Frete__c != null ? res.Valor_Frete__c : 0)));
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
    } else if(res.UnitPrice < res.Preco_Final__c && res.UnitPrice > 0) {
        System.debug('🚀 STATUS: PREÇO COM DESCONTO COMERCIAL MANUAL!');
    } else {
        System.debug('⚠️ STATUS: AGUARDANDO PROCESSAMENTO DO MOTOR (PRICINGSERVICE)');
    }
    System.debug('==========================================================\n');
}
System.debug('🏆 DEMO FINALIZADA: ' + resultados.size() + ' itens auditados com a nova arquitetura.');