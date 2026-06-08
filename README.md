
Taak
Desafio Batch








Desafio
Criar um sistema de Metas a ser utilizado pelo time de Vendas, que servirá para registrar quanto das metas foi atingida, e caso seja atingida, adicionar certa porcentagem à comissão do vendedor. Por conta da grande quantidade de records relacionados a esse tipo de sistema, iremos utilizar Batch para mantê-lo flexível quanto aos Governor Limits.

O sistema irá ter 2 objetos:
Legenda: 
* = Obrigatório na criação do record
Meta (Goal__c):
Vendedor [Lookup para tabela User]*
Ano [Campo Número]*
Porcentagem de comissão (Sumarização das porcentagens atingidas)[Roll-up Summary] 
Valor de comissão (Comissão referente ao valor realizado) [Campo Currency/Fórmula]
Valor de vendas (Valor total vendido pelo vendedor naquele ano) [Campo Currency]


Item da Meta (GoalItem__c):
Meta [Lookup Master-Detail para tabela Goal__c]*
Tipo (Performance, Produto, Família de produto, Condição de pagamento)[Record Type]*
Valor meta [Campo Currency]*
Valor projetado (Oportunidade) [Campo Currency]
Valor negociado (Pedidos não concluídos e não finalizados) [Campo Currency]
Valor realizado (Pedidos concluídos) [Campo Currency]
Porcentagem de comissão da meta(Porcentagem de comissão caso a meta seja atingida) [Campo Percent]*
Porcentagem atingida  (Quando Valor realizado >= Valor meta, atualizar o campo com a porcentagem em Porcentagem de comissão da meta)[Campo Percent]
Produto da meta (Quando for uma meta para Produto)[Lookup para tabela Product2]
 (Quando for uma meta para Família de produto)[Lookup para tabela de Família de produto]
Condição de pagamento da meta (Quando for uma meta para Condição de pagamento)[Lookup para tabela de Condição de pagamento]

E: Gerente de vendas
Q: Um sistema que permita a criação e monitoramento de Metas de vendas
P: Facilitar na gestão de meu time de Vendas, também os permitindo ver como estão indo em suas metas
A: 
Cada meta é específica a um único vendedor
Cada meta podendo ter vários Itens, como R$2.000 reais em vendas de Chinelo, e R$5.000 em vendas utilizando Dinheiro
Cada meta tem que ser atualizada antes dos vendedores começarem a vender (Todo dia da semana, às 9h)

