Projeto 03: 

Sincronização de Equipe da Conta (Account Team)
Este projeto faz parte do meu portfólio de desafios de estágio em Salesforce Apex. O objetivo principal é garantir que a Equipe da Conta (Account Team) esteja sempre em sincronia com os registros do objeto customizado Local Associado.

## Descrição do Desafio
Sempre que um registro de Local_Associado__c for inserido, alterado ou excluído, o sistema deve:

Inserir/Manter o Representante na Equipe da Conta com o papel de Gerente de Contas.

Atualizar o acesso caso o representante mude.

Remover o acesso imediatamente se o registro de Local Associado for deletado.

## Arquitetura Utilizada: Trigger Framework (Maestro)
Para garantir um código limpo (Clean Code) e escalável, utilizei o padrão de Trigger Framework:

ContratoTrigger (Interface): Define os métodos obrigatórios para todos os Handlers.

TriggerMaestroGatilho (Dispatcher): Centraliza a lógica de execução da Trigger, evitando que códigos complexos fiquem direto no arquivo .trigger.

LocalAssociadoHandler (Lógica): Onde reside a inteligência de sincronização e cálculos de membros.

##  Diferenciais Técnicos
Processamento em Lote (Bulkified): O código está preparado para processar centenas de registros simultaneamente sem atingir os Governor Limits.

Mapeamento de Chaves Únicas: Utilizei um Map<String, AccountTeamMember> combinando AccountId + UserId para evitar duplicidade de membros e garantir que o upsert funcione corretamente.

Sincronização Bidirecional: O código identifica quem deve entrar, quem deve ficar e, principalmente, quem deve sair (lógica de cleaning no after delete).