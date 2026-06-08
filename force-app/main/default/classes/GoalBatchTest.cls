/**
 * GoalBatchTest
 * -------------
 * Cobre os cenários principais do GoalBatch:
 *   1. Meta atingida  → PorcentagemAtingida deve ser preenchida
 *   2. Meta não atingida → PorcentagemAtingida deve ser zero
 *   3. Scheduler → job deve ser agendado com o CRON correto
 */
@isTest
public class GoalBatchTest {

    // ---------------------------------------------------------------
    // SETUP – cria os dados de teste uma única vez para todos os métodos
    // ---------------------------------------------------------------
    @TestSetup
    static void setup() {
        // Cria a Meta (Goal__c) para o usuário logado
        Goal__c goal = new Goal__c(
            Vendedor__c          = UserInfo.getUserId(),
            Ano__c               = 2026,
            Valor_de_Vendas__c   = 10000
        );
        insert goal;

        // Item 1 – meta ATINGIDA (ValorRealizado >= ValorMeta)
        GoalItem__c itemAtingido = new GoalItem__c(
            Meta__c                    = goal.Id,
            Valor_da_Meta__c               = 5000,
            Valor_Realizado__c          = 6000,
            Porcentagem_de_Comissao_da_Meta__c = 5
        );

        // Item 2 – meta NÃO ATINGIDA (ValorRealizado < ValorMeta)
        GoalItem__c itemNaoAtingido = new GoalItem__c(
            Meta__c                    = goal.Id,
            Valor_da_Meta__c               = 5000,
            Valor_Realizado__c          = 1000,
            Porcentagem_de_Comissao_da_Meta__c = 3
        );

        // Item 3 – ValorRealizado exatamente igual ao ValorMeta (limite)
        GoalItem__c itemLimite = new GoalItem__c(
            Meta__c                    = goal.Id,
            Valor_da_Meta__c               = 3000,
            Valor_Realizado__c          = 3000,
            Porcentagem_de_Comissao_da_Meta__c = 2
        );

        insert new List<GoalItem__c>{ itemAtingido, itemNaoAtingido, itemLimite };
    }

    // ---------------------------------------------------------------
    // TESTE 1 – meta atingida deve preencher PorcentagemAtingida
    // ---------------------------------------------------------------
    @isTest
    static void testMetaAtingida() {
        GoalItem__c item = [
            SELECT Id, Porcentagem_de_Comissao_da_Meta__c
            FROM GoalItem__c
            WHERE Valor_Realizado__c > 6000
            LIMIT 1
        ];

        Test.startTest();
        Database.executeBatch(new GoalBatch(), 200);
        Test.stopTest();

        GoalItem__c atualizado = [
            SELECT Porcentagem_Atingida__c
            FROM GoalItem__c
            WHERE Id = :item.Id
        ];

        System.assertEquals(
            item.Porcentagem_de_Comissao_da_Meta__c,
            atualizado.Porcentagem_Atingida__c,
            'Meta atingida: PorcentagemAtingida deve ser igual à PorcentagemComissaoMeta'
        );
    }

    // ---------------------------------------------------------------
    // TESTE 2 – meta não atingida deve zerar PorcentagemAtingida
    // ---------------------------------------------------------------
    @isTest
    static void testMetaNaoAtingida() {
        GoalItem__c item = [
            SELECT Id
            FROM GoalItem__c
            WHERE Valor_Realizado__c < 6000
            LIMIT 1
        ];

        Test.startTest();
        Database.executeBatch(new GoalBatch(), 200);
        Test.stopTest();

        GoalItem__c atualizado = [
            SELECT Porcentagem_Atingida__c
            FROM GoalItem__c
            WHERE Id = :item.Id
        ];

        System.assertEquals(
            0,
            atualizado.Porcentagem_Atingida__c,
            'Meta não atingida: PorcentagemAtingida deve ser 0'
        );
    }

    // ---------------------------------------------------------------
    // TESTE 3 – valor realizado igual ao valor meta (caso limite)
    // ---------------------------------------------------------------
    @isTest
    static void testMetaNoLimite() {
        GoalItem__c item = [
            SELECT Id, Porcentagem_de_Comissao_da_Meta__c
            FROM GoalItem__c
            WHERE Valor_Realizado__c = 3000
            LIMIT 1
        ];

        Test.startTest();
        Database.executeBatch(new GoalBatch(), 200);
        Test.stopTest();

        GoalItem__c atualizado = [
            SELECT Porcentagem_Atingida__c
            FROM GoalItem__c
            WHERE Id = :item.Id
        ];

        System.assertEquals(
            item.Porcentagem_de_Comissao_da_Meta__c,
            atualizado.Porcentagem_Atingida__c,
            'ValorRealizado = ValorMeta: deve ser considerado atingido'
        );
    }

    // ---------------------------------------------------------------
    // TESTE 4 – scheduler deve ser agendado com o CRON correto
    // ---------------------------------------------------------------
    @isTest
    static void testScheduler() {
        Test.startTest();
        String cron = '0 0 9 ? * MON-FRI';
        System.schedule('GoalBatch Test', cron, new GoalBatchScheduler());
        Test.stopTest();

        CronTrigger ct = [
            SELECT Id, CronExpression
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'GoalBatch Test'
        ];

        System.assertEquals(
            '0 0 9 ? * MON-FRI',
            ct.CronExpression,
            'Expressão CRON deve estar correta'
        );
    }
}