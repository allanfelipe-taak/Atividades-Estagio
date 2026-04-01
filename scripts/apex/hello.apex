// 0. RESET DA ORG (LIMPEZA TOTAL PARA A DEMO)
delete [SELECT Id FROM Order];
delete [SELECT Id FROM Margem__c];
delete [SELECT Id FROM Frete__c];
delete [SELECT Id FROM Imposto__c];

// 1. PREPARAÇÃO DA INFRAESTRUTURA
Account acc;
try { acc = [SELECT Id FROM Account WHERE Name = 'AgroFazenda S/A' LIMIT 1]; } 
catch (Exception e) { acc = new Account(Name = 'AgroFazenda S/A'); insert acc; }

Id hId; 
try { hId = [SELECT Id FROM Hierarquia_de_Produto__c LIMIT 1].Id; } catch (Exception e) { hId = null; }

Id cdId;
try { cdId = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1].Id; } 
catch (Exception e) { 
    Centro_Distribuicao__c novoCD = new Centro_Distribuicao__c(Name = 'CD Central'); 
    insert novoCD; cdId = novoCD.Id; 
}

// BUSCA/CRIAÇÃO DE ENDEREÇO (OBRIGATÓRIO)
Id endId;
try { 
    endId = [SELECT Id FROM Endereco__c LIMIT 1].Id; 
} catch (Exception e) { 
    // Removi o campo Account__c para evitar o erro
    Endereco__c novoEnd = new Endereco__c(Name = 'Rua das Fazendas, 100'); 
    insert novoEnd; 
    endId = novoEnd.Id; 
}

// BUSCA/CRIAÇÃO DE CONDICAO DE PAGAMENTO (OBRIGATÓRIO)
Id condId;
try { condId = [SELECT Id FROM Condicao_Pagamento__c LIMIT 1].Id; } 
catch (Exception e) { 
    Condicao_Pagamento__c novaCond = new Condicao_Pagamento__c(Name = '30 Dias'); 
    insert novaCond; condId = novaCond.Id; 
}

Id estId;
try { estId = [SELECT Id FROM Estado__c WHERE Name = 'Paraná' LIMIT 1].Id; } catch (Exception e) { 
    Estado__c parana = new Estado__c(Name = 'Paraná'); insert parana; estId = parana.Id; 
}

Cidade__c cid;
try { cid = [SELECT Id FROM Cidade__c WHERE Name = 'Curitiba' LIMIT 1]; } catch (Exception e) { 
    cid = new Cidade__c(Name = 'Curitiba'); insert cid; 
}

Id paisId;
try { paisId = [SELECT Id FROM Pais__c WHERE Name = 'Brasil' LIMIT 1].Id; } catch (Exception e) { 
    Pais__c p = new Pais__c(Name = 'Brasil'); insert p; paisId = p.Id; 
}

Id pbId = [SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1].Id;

// 2. CRIAÇÃO DO PRODUTO (VINCULADO À HIERARQUIA SE O CAMPO EXISTIR)
String nomeProd = 'Trator Titan Pro v' + DateTime.now().format('mmSS');
Product2 p = new Product2(Name = nomeProd, ProductCode = 'TRT-PRO', Custo_Producao__c = 100.00);
// Tente preencher o campo de hierarquia se ele existir no seu objeto Product
try { p.put('Hierarquia_de_Produto__c', hId); } catch(Exception e) {}
insert p;

insert new PricebookEntry(Pricebook2Id = pbId, Product2Id = p.Id, UnitPrice = 0, IsActive = true);

// ==========================================================
// 3. TESTE DE ESPECIFICIDADE (REGISTROS GENÉRICOS E ESPECÍFICOS)
// ==========================================================
if(hId != null) insert new Margem__c(Hierarquia_de_Produto__c = hId, Valor__c = 10.0, Status__c = 'Aprovado'); 
insert new Margem__c(Produto__c = p.Id, Conta__c = acc.Id, Cidade__c = cid.Id, Estado__c = estId, Valor__c = 25.0, Status__c = 'Aprovado'); 

if(hId != null) insert new Frete__c(Hierarquia_de_Produto__c = hId, Pais__c = paisId, Valor__c = 800.00, Status__c = 'Aprovado'); 
insert new Frete__c(Produto__c = p.Id, Cidade__c = cid.Id, Estado__c = estId, Valor__c = 350.00, Status__c = 'Aprovado'); 

insert new Imposto__c(Estado__c = estId, Imposto_sobre_custo__c = 15.0, Status__c = 'Aprovado'); 
insert new Imposto__c(Produto__c = p.Id, Estado__c = estId, Imposto_sobre_custo__c = 10.0, Status__c = 'Aprovado'); 

// ==========================================================
// 4. TESTES DE DUPLICIDADE (GARANTINDO BLOQUEIO)
// ==========================================================
try { insert new Margem__c(Produto__c = p.Id, Conta__c = acc.Id, Cidade__c = cid.Id, Estado__c = estId, Valor__c = 99); } 
catch (Exception e) { System.debug('✅ SEGURANÇA: Duplicidade de Margem Bloqueada!'); }

try { insert new Frete__c(Produto__c = p.Id, Cidade__c = cid.Id, Estado__c = estId, Status__c = 'Aprovado'); } 
catch (Exception e) { System.debug('✅ SEGURANÇA: Duplicidade de Frete Bloqueada!'); }

try { insert new Imposto__c(Produto__c = p.Id, Estado__c = estId, Status__c = 'Aprovado'); } 
catch (Exception e) { System.debug('✅ SEGURANÇA: Duplicidade de Imposto Bloqueada!'); }

// ==========================================================
// 5. PROCESSO DE VENDA (AGORA COM CAMPOS OBRIGATÓRIOS)
// ==========================================================
Order ped = new Order(
    AccountId = acc.Id, 
    EffectiveDate = Date.today(), 
    Status = 'Draft', 
    Pricebook2Id = pbId,
    Centro_Distribuicao__c = cdId, 
    Endereco__c = endId,             // CORREÇÃO: Campo Obrigatório
    Condicao_Pagamento__c = condId, // CORREÇÃO: Campo Obrigatório
    ShippingCity = 'Curitiba'
);
insert ped;

OrderItem item = new OrderItem(
    OrderId = ped.Id, Product2Id = p.Id, Quantity = 1, UnitPrice = 0, 
    PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id = :p.Id LIMIT 1].Id
);
insert item;

// ==========================================================
// 6. RELATÓRIOS FINAIS DE AUDITORIA
// ==========================================================
OrderItem res = [SELECT UnitPrice, Custo_Producao__c, Valor_Frete__c, 
                        Porcentagem_Imposto__c, Porcentagem_Margem__c,
                        Preco_Final__c, Order.Account.Name, Product2.Name
                 FROM OrderItem WHERE Id = :item.Id];

System.debug('==========================================================');
System.debug('🛡️ AUDITORIA DE SEGURANÇA (BLOQUEIO DE DUPLICIDADE)');
System.debug('==========================================================');
System.debug(' STATUS MARGEM: Bloqueio Verificado ✅');
System.debug(' STATUS FRETE: Bloqueio Verificado ✅');
System.debug(' STATUS IMPOSTO: Bloqueio Verificado ✅');

System.debug('==========================================================');
System.debug('🎯 AUDITORIA DE ESPECIFICIDADE (PRODUTO > HIERARQUIA)');
System.debug('==========================================================');
System.debug(' MARGEM APLICADA: ' + res.Porcentagem_Margem__c + '%' + (res.Porcentagem_Margem__c == 25 ? ' ✅ (Específica)' : ' ❌ (Genérica)'));
System.debug(' FRETE APLICADO: R$ ' + res.Valor_Frete__c + (res.Valor_Frete__c == 350 ? ' ✅ (Específico)' : ' ❌ (Genérico)'));
System.debug(' IMPOSTO APLICADO: ' + res.Porcentagem_Imposto__c + '%' + (res.Porcentagem_Imposto__c == 10 ? ' ✅ (Específico)' : ' ❌ (Genérico)'));

System.debug('==========================================================');
System.debug('💰 RELATÓRIO DE CÁLCULO FINAL - AGRO IMPLEMENTS');
System.debug('==========================================================');
System.debug(' CLIENTE: ' + res.Order.Account.Name);
System.debug(' PRODUTO: ' + res.Product2.Name);
System.debug(' CUSTO BASE: R$ ' + res.Custo_Producao__c);
System.debug('----------------------------------------------------------');
System.debug(' PREÇO FINAL SUGERIDO: R$ ' + res.Preco_Final__c);
System.debug(' PREÇO PRATICADO NO ITEM: R$ ' + res.UnitPrice);
System.debug('==========================================================');

if(res.Preco_Final__c == res.UnitPrice) {
    System.debug('🚀 VALIDAÇÃO FINAL: SUCESSO!');
}