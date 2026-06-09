/**
 * GoalBatch
 * ---------
 * Percorre todos os GoalItem__c e, quando RealizedValue__c >= TargetValue__c,
 * popula AchievedPercentage__c com o valor de GoalCommissionPercentage__c.
 * Caso contrário, zera o campo.
 */
public with sharing class GoalBatch implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, ' +
            '       TargetValue__c, ' +
            '       RealizedValue__c, ' +
            '       GoalCommissionPercentage__c, ' +
            '       AchievedPercentage__c ' +
            'FROM GoalItem__c'
        );
    }

    public void execute(Database.BatchableContext bc, List<GoalItem__c> scope) {
        List<GoalItem__c> recordsToUpdate = new List<GoalItem__c>();

        for (GoalItem__c item : scope) {
            Boolean metaAtingida = item.RealizedValue__c != null
                                && item.TargetValue__c   != null
                                && item.RealizedValue__c >= item.TargetValue__c;

            Decimal novaPorcentagem = metaAtingida
                ? (item.GoalCommissionPercentage__c != null ? item.GoalCommissionPercentage__c : 0)
                : 0;

            if (item.AchievedPercentage__c != novaPorcentagem) {
                item.AchievedPercentage__c = novaPorcentagem;
                recordsToUpdate.add(item);
            }
        }

        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('GoalBatch concluído. JobId: ' + bc.getJobId());
    }
}
