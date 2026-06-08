/**
 * GoalBatch
 * ---------
 * Percorre todos os GoalItem__c e, quando ValorRealizado__c >= ValorMeta__c,
 * popula PorcentagemAtingida__c com o valor de PorcentagemComissaoMeta__c.
 * Caso contrário, mantém (ou zera) o campo.
 *
 * Tamanho de lote recomendado: 200 (padrão).
 * Execute manualmente:
 *   Database.executeBatch(new GoalBatch(), 200);
 */
public with sharing class GoalBatch implements Database.Batchable<SObject> {

    // ---------------------------------------------------------------
    // START – define o escopo da query
    // ---------------------------------------------------------------
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, ' +
            '       Valor_da_Meta__c, ' +
            '       Valor_Realizado__c, ' +
            '       Porcentagem_de_Comissao_da_Meta__c, ' +
            '       Porcentagem_Atingida__c ' +
            'FROM GoalItem__c'
        );
    }

    // ---------------------------------------------------------------
    // EXECUTE – processa cada lote
    // ---------------------------------------------------------------
    public void execute(Database.BatchableContext bc, List<GoalItem__c> scope) {
        List<GoalItem__c> recordsToUpdate = new List<GoalItem__c>();

        for (GoalItem__c item : scope) {
            Boolean metaAtingida = item.Valor_Realizado__c != null
                                && item.Valor_da_Meta__c        != null
                                && item.Valor_Realizado__c  >= item.Valor_da_Meta__c;

            Decimal novaPorcentagem = metaAtingida
                ? (item.Porcentagem_de_Comissao_da_Meta__c != null ? item.Porcentagem_de_Comissao_da_Meta__c : 0)
                : 0;

            // Só enfileira update se o valor realmente mudou (evita DML desnecessário)
            if (item.Porcentagem_Atingida__c != novaPorcentagem) {
                item.Porcentagem_Atingida__c = novaPorcentagem;
                recordsToUpdate.add(item);
            }
        }

        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
            // O Roll-up Summary em Goal__c (PorcentagemComissao__c)
            // é recalculado automaticamente pelo Salesforce após o update.
        }
    }

    // ---------------------------------------------------------------
    // FINISH – pós-processamento (opcional)
    // ---------------------------------------------------------------
    public void finish(Database.BatchableContext bc) {
        // Adicione notificações ou chamadas encadeadas aqui, se necessário.
        System.debug('GoalBatch concluído. JobId: ' + bc.getJobId());
    }
}