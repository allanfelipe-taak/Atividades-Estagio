// 1. Limpeza de Suporte e Vendas (O que trava o delete das Contas)
delete [SELECT Id FROM OrderItem];
delete [SELECT Id FROM Order];
delete [SELECT Id FROM Case];
delete [SELECT Id FROM Opportunity];
delete [SELECT Id FROM Contract];

// --- NOVIDADE: Apagando os Direitos de Suporte (Entitlements) ---
delete [SELECT Id FROM Entitlement]; 

// 2. Apaga as suas regras customizadas
delete [SELECT Id FROM Margem__c];
delete [SELECT Id FROM Frete__c];
delete [SELECT Id FROM Imposto__c];
delete [SELECT Id FROM Endereco__c];
delete [SELECT Id FROM Hierarquia_de_Produto__c];

// 3. Agora sim, as Contas devem estar livres
delete [SELECT Id FROM Account];

// 4. Limpeza da Base (Grupos e Localidades)
delete [SELECT Id FROM Grupo_de_Conta__c];
delete [SELECT Id FROM Cidade__c];
delete [SELECT Id FROM Estado__c];
delete [SELECT Id FROM Pais__c];

System.debug('✨ AGORA SIM! Org limpa como um espelho.');
System.debug('✨ Org limpa para o teste final matemático!');

// 1. INFRAESTRUTURA
Id paisId; try { paisId = [SELECT Id FROM Pais__c WHERE Name='Brasil' LIMIT 1].Id; } catch(Exception e){ Pais__c p = new Pais__c(Name='Brasil'); insert p; paisId = p.Id; }
Id estId;  try { estId = [SELECT Id FROM Estado__c WHERE Name='São Paulo' LIMIT 1].Id; } catch(Exception e){ Estado__c es = new Estado__c(Name='São Paulo'); insert es; estId = es.Id; }
Id cidId;  try { cidId = [SELECT Id FROM Cidade__c WHERE Name='São Bernardo do Campo' LIMIT 1].Id; } catch(Exception e){ Cidade__c c = new Cidade__c(Name='São Bernardo do Campo'); insert c; cidId = c.Id; }

Grupo_de_Conta__c grupoVip = new Grupo_de_Conta__c(Name = 'VIP Agro'); insert grupoVip;
Account accWebSM = new Account(Name='WEBSM', Grupo_de_Conta__c = grupoVip.Id, CNPJ__c='11.111.111/0001-11'); insert accWebSM;

Hierarquia_de_Produto__c hTrator = new Hierarquia_de_Produto__c(Name='Tratores'); insert hTrator;

// 👇 ATENÇÃO: 
Product2 p1 = new Product2(Name = 'Trator', Hierarquia_de_Produto__c = hTrator.Id, Custo_Producao__c = 1000); insert p1;

Id cdId; Id endId; Id condId;
try { cdId = [SELECT Id FROM Centro_Distribuicao__c LIMIT 1].Id; } catch (Exception e) { Centro_Distribuicao__c cd = new Centro_Distribuicao__c(Name='Mercado-Livre'); insert cd; cdId = cd.Id; }
try { endId = [SELECT Id FROM Endereco__c LIMIT 1].Id; } catch (Exception e) { Endereco__c ed = new Endereco__c(Name='Matriz'); insert ed; endId = ed.Id; }
try { condId = [SELECT Id FROM Condicao_Pagamento__c LIMIT 1].Id; } catch (Exception e) { Condicao_Pagamento__c cp = new Condicao_Pagamento__c(Name='30D'); insert cp; condId = cp.Id; }

Id pbId = [SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1].Id;
try { insert new PricebookEntry(Pricebook2Id=pbId, Product2Id=p1.Id, UnitPrice=0, IsActive=true); } catch(Exception e){}

// ==========================================================
// 2. REGRAS DO MOTOR (RESPEITANDO OS HANDLERS E EXCLUSIVIDADE)
// ==========================================================


// --- MARGEM (Respeitando a validação: Apenas 1 de Produto, 1 de Cliente, 1 de Local) ---
// --- MARGEM (Com valores diferentes para testar a Especificidade) ---
List<Margem__c> piramide = new List<Margem__c>();

// 🥉 NÍVEL BRONZE: Hierarquia + Grupo (As regras mais genéricas)
piramide.add(new Margem__c(Name='H-G-Pais',   Hierarquia_de_Produto__c=hTrator.Id, Grupo_de_Conta__c=grupoVip.Id, Pais__c=paisId,   Valor__c=30.0, Status__c='Aprovado', Centro_Distribuicao__c=cdId)); // 10%
piramide.add(new Margem__c(Name='H-G-Estado', Hierarquia_de_Produto__c=hTrator.Id, Grupo_de_Conta__c=grupoVip.Id, Estado__c=estId, Valor__c=30.0, Status__c='Aprovado', Centro_Distribuicao__c=cdId)); // 15%
piramide.add(new Margem__c(Name='H-G-Cidade', Hierarquia_de_Produto__c=hTrator.Id, Grupo_de_Conta__c=grupoVip.Id, Cidade__c=cidId, Valor__c=25.0, Status__c='Aprovado', Centro_Distribuicao__c=cdId)); // 20%

// 🥈 NÍVEL PRATA: Produto + Conta com geografia mais ampla
piramide.add(new Margem__c(Name='P-C-Pais',   Produto__c=p1.Id, Conta__c=accWebSM.Id, Pais__c=paisId,   Valor__c=15.0, Status__c='Aprovado', Centro_Distribuicao__c=cdId)); // 25%
piramide.add(new Margem__c(Name='P-C-Estado', Produto__c=p1.Id, Conta__c=accWebSM.Id, Estado__c=estId, Valor__c=20.0, Status__c='Aprovado', Centro_Distribuicao__c=cdId)); // 30%

// 🥇 NÍVEL OURO: Produto Exato + Conta Exata + Cidade Exata (A CAMPEÃ)
piramide.add(new Margem__c(Name='P-C-Cidade', Produto__c=p1.Id, Conta__c=accWebSM.Id, Cidade__c=cidId, Valor__c=10.0, Status__c='Aprovado', Centro_Distribuicao__c=cdId)); // 45%

insert piramide;


// --- FRETE (Com valores diferentes para provar a Especificidade) ---
List<Frete__c> farao = new List<Frete__c>();

// 🥉 NÍVEL BRONZE: Hierarquia (Fretes genéricos e mais caros)
farao.add(new Frete__c(Name='H-Pais',   Hierarquia_de_Produto__c=hTrator.Id, Pais__c=paisId,   Valor__c=300.0, Status__c='Aprovado', Centro_Distribuicao__c=cdId)); // R$ 300
farao.add(new Frete__c(Name='H-Estado', Hierarquia_de_Produto__c=hTrator.Id, Estado__c=estId, Valor__c=250.0, Status__c='Aprovado', Centro_Distribuicao__c=cdId)); // R$ 250
farao.add(new Frete__c(Name='H-Cidade', Hierarquia_de_Produto__c=hTrator.Id, Cidade__c=cidId, Valor__c=200.0, Status__c='Aprovado', Centro_Distribuicao__c=cdId)); // R$ 200

// 🥈 NÍVEL PRATA: Produto Exato (Fretes mais direcionados)
farao.add(new Frete__c(Name='P-Pais',   Produto__c=p1.Id, Pais__c=paisId,   Valor__c=150.0, Status__c='Aprovado', Centro_Distribuicao__c=cdId)); // R$ 150
farao.add(new Frete__c(Name='P-Estado', Produto__c=p1.Id, Estado__c=estId, Valor__c=100.0, Status__c='Aprovado', Centro_Distribuicao__c=cdId)); // R$ 100

// 🥇 NÍVEL OURO: Produto Exato + Cidade Exata (A CAMPEÃ 🏆)
farao.add(new Frete__c(Name='P-Cidade', Produto__c=p1.Id, Cidade__c=cidId, Valor__c=50.0, Status__c='Aprovado', Centro_Distribuicao__c=cdId)); // R$ 50

insert farao;


// --- IMPOSTO (Sem restrição geográfica: Combo Máximo para especificidade) ---
insert new Imposto__c(
    Name = 'Imposto SP Combo Máximo', 
    Produto__c = p1.Id,
    Pais__c = paisId, 
    Estado__c = estId, 
    Centro_Distribuicao__c = cdId,
    Imposto_sobre_custo__c = 12.0,
    Status__c = 'Aprovado'
);

// ==========================================================
// 3. TESTE DE BLOQUEIO (HANDLERS) - Provando a Segurança
// ==========================================================
// 1º passo: CRIAR as variáveis (Onde o erro estava acontecendo)
Boolean bloqueouMargem = false;
Boolean bloqueouFrete = false;
Boolean bloqueouImposto = false;

// 2º passo: TENTAR inserir duplicado (O Handler deve barrar)
try {
    insert new List<Margem__c>{
        new Margem__c(Name='M1', Produto__c=p1.Id, Valor__c=30, Status__c='Aprovado'),
        new Margem__c(Name='M2', Produto__c=p1.Id, Valor__c=99, Status__c='Aprovado')
    };
    
} catch(Exception e) { 
    bloqueouMargem = true; // Se der erro, a variável vira true
}

try {
    insert new List<Frete__c>{
        new Frete__c(Name='F1', Produto__c=p1.Id, Valor__c=150, Status__c='Aprovado'),
        new Frete__c(Name='F2', Produto__c=p1.Id, Valor__c=99, Status__c='Aprovado')
    };
} catch(Exception e) { 
    bloqueouFrete = true; // Se der erro, a variável vira true
}

try {
    insert new List<Imposto__c>{
        new Imposto__c(Name='P1', Produto__c=p1.Id, 	Imposto_sobre_custo__c=100, Status__c='Aprovado'),
        new Imposto__c(Name='P2', Produto__c=p1.Id, 	Imposto_sobre_custo__c=90, Status__c='Aprovado')
    };
} catch(Exception e) { 
    bloqueouImposto = true; // Se der erro, a variável vira true
}

// ==========================================================
// 4. EXECUÇÃO: SIMULANDO UMA VENDA COM DESCONTO
// ==========================================================
Order ped = new Order(
    AccountId = accWebSM.Id, EffectiveDate = Date.today(), Status = 'Draft', Pricebook2Id = pbId,
    ShippingCity = 'São Bernardo do Campo', ShippingState = 'São Paulo', ShippingCountry = 'Brasil',
    Centro_Distribuicao__c = cdId, Endereco__c = endId, Condicao_Pagamento__c = condId
);
insert ped;

// O vendedor preenche UnitPrice = 1500 na tela (Ele deu um desconto sobre o valor sugerido)
OrderItem item = new OrderItem(
    OrderId = ped.Id, 
    Product2Id = p1.Id, 
    Quantity = 1, 
    UnitPrice = 1500.00, // <--- PREÇO UNITÁRIO FINAL
    PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Product2Id=:p1.Id].Id
);
insert item;

// ==========================================================
// 5. AUDITORIA: PROVANDO A FÓRMULA MATEMÁTICA
// ==========================================================
// Puxamos APENAS os campos de valores que sabemos que existem!
OrderItem res = [SELECT 
                    Product2.Custo_Producao__c,
                    Porcentagem_Margem__c, 
                    Valor_Frete__c, 
                    Porcentagem_Imposto__c,
                    Preco_Final__c,
                    UnitPrice
                 FROM OrderItem 
                 WHERE Id = :item.Id];

// --- FAZENDO A MATEMÁTICA NO APEX SÓ PARA O LOG ---
Decimal custo = res.Product2.Custo_Producao__c != null ? res.Product2.Custo_Producao__c : 0;
Decimal frete = res.Valor_Frete__c != null ? res.Valor_Frete__c : 0;
Decimal imposto = res.Porcentagem_Imposto__c != null ? res.Porcentagem_Imposto__c : 0;
Decimal margem = res.Porcentagem_Margem__c != null ? res.Porcentagem_Margem__c : 0;

// Fórmula: (Custo + Frete) * (1 + Imposto%)
Decimal precoSemMargemCalc = (custo + frete) * (1 + (imposto / 100));
// Fórmula: Preço sem Margem * (1 + Margem%)
Decimal precoCalculadoCalc = precoSemMargemCalc * (1 + (margem / 100));

// Cálculo do Desconto
Decimal descontoCalc = 0;
if (precoCalculadoCalc > 0) {
    descontoCalc = ((precoCalculadoCalc - res.UnitPrice) / precoCalculadoCalc) * 100;
}


// ==========================================================
// 5. RELATÓRIO DE SEGURANÇA (HANDLERS) - Final do Script
// ==========================================================
System.debug('----------------------------------------------------------');
System.debug('🛡️ STATUS DE PROTEÇÃO CONTRA DUPLICIDADE:');

// Agora o código vai reconhecer as variáveis abaixo!
System.debug(' BLOQUEIO MARGEM:  ' + (bloqueouMargem ? '✅ BARRADO COM SUCESSO' : '❌ FALHOU (Aceitou duplicidade)'));
System.debug(' BLOQUEIO FRETE:   ' + (bloqueouFrete  ? '✅ BARRADO COM SUCESSO' : '❌ FALHOU (Aceitou duplicidade)'));
System.debug(' BLOQUEIO Imposto:   ' + (bloqueouImposto  ? '✅ BARRADO COM SUCESSO' : '❌ FALHOU (Aceitou duplicidade)'));

System.debug('----------------------------------------------------------');

// ==========================================================
// 5. RELATÓRIO DE ESPECIFICIDADE (O CÉREBRO DO MOTOR 🧠)
// ==========================================================
System.debug('\n' + 
    '###########################################################\n' +
    '🎯 TESTE DE ESPECIFICIDADE (REGRA DO SNIPER)\n' +
    '###########################################################\n' +
    '✔️ EXPECTATIVA MARGEM (Ouro P-C-Cidade) : 10.0%\n' +
    '👉 REALIDADE MARGEM APLICADA            : ' + margem + '%\n' +
    '-----------------------------------------------------------\n' +
    '✔️ EXPECTATIVA FRETE (Ouro P-Cidade)    : R$ 50.00\n' +
    '👉 REALIDADE FRETE APLICADO             : R$ ' + frete + '\n' +
    '###########################################################\n');



System.debug('\n' + 
    '###########################################################\n' +
    '🛡️  AUDITORIA DE PRICING COMPLETA (MATEMÁTICA)\n' +
    '###########################################################\n' +
    '📝 DADOS RESGATADOS E SALVOS PELO MOTOR:\n' +
    '   [1] Custo Base: R$ ' + custo + '\n' +
    '   [2] Frete Aplicado: R$ ' + frete + '\n' +
    '   [3] Imposto Aplicado: ' + imposto + '%\n' + 
    '   [4] Margem Aplicada: ' + margem + '%\n' +
    '-----------------------------------------------------------\n' +
    '🧮 MEMÓRIA DE CÁLCULO (A FÓRMULA DO NEGÓCIO):\n' +
    '   => Preço sem Margem: R$ ' + precoSemMargemCalc.setScale(2) + '\n' +
    '   => Preço Calculado : R$ ' + precoCalculadoCalc.setScale(2) + '\n' +
    '-----------------------------------------------------------\n' +
    '💰 NEGOCIAÇÃO FINAL:\n' +
    '   => Preço Fechado (UnitPrice): R$ ' + res.UnitPrice + '\n' +
    '   => Desconto Realizado: ' + descontoCalc.setScale(2) + '%\n' +
    '###########################################################\n');


