/**
 * GoalValueBatch
 * --------------
 * Batch que popula os campos ProjectedValue__c, NegotiatedValue__c e RealizedValue__c
 * em GoalItem__c a partir de agregações de Opportunity e Order, filtradas por
 * Salesperson (OwnerId) e Year (CALENDAR_YEAR da data de fechamento/vigência).
 *
 * Fluxo:
 * 1. start(): QueryLocator que itera todos os GoalItem__c
 * 2. execute(): Coleta pares únicos (Salesperson, Year), executa agregações e replica
 *    totais em todos os itens do mesmo par
 * 3. finish(): Registra conclusão com JobId
 */
public with sharing class GoalValueBatch implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, ' +
            '       ProjectedValue__c, ' +
            '       NegotiatedValue__c, ' +
            '       RealizedValue__c, ' +
            '       Goal__r.Salesperson__c, ' +
            '       Goal__r.Year__c ' +
            'FROM GoalItem__c'
        );
    }

    public void execute(Database.BatchableContext bc, List<GoalItem__c> scope) {
        // 1. Colete pares únicos (Salesperson, Year) e agrupe GoalItems
        Map<String, List<GoalItem__c>> itemsByPair = new Map<String, List<GoalItem__c>>();
        Set<String> ownerIds = new Set<String>();
        Set<Integer> years = new Set<Integer>();

        for (GoalItem__c item : scope) {
            // Valida se o item possui Salesperson e Year preenchidos
            if (item.Goal__r.Salesperson__c == null || item.Goal__r.Year__c == null) {
                continue;
            }

            String key = item.Goal__r.Salesperson__c + '#' + item.Goal__r.Year__c;
            if (!itemsByPair.containsKey(key)) {
                itemsByPair.put(key, new List<GoalItem__c>());
            }
            itemsByPair.get(key).add(item);

            ownerIds.add(item.Goal__r.Salesperson__c);
            years.add((Integer) item.Goal__r.Year__c);
        }

        if (ownerIds.isEmpty() || years.isEmpty()) {
            System.debug('GoalValueBatch: Nenhum par (Salesperson, Year) válido encontrado no scope.');
            return;
        }

        // 2. Executa agregações de Opportunity (ProjectedValue)
        Map<String, Decimal> projectedMap = aggregateOpportunities(ownerIds, years);

        // 3. Executa agregações de Order - Negotiated (NegotiatedValue)
        Map<String, Decimal> negotiatedMap = aggregateOrdersNegotiated(ownerIds, years);

        // 4. Executa agregações de Order - Realized (RealizedValue)
        Map<String, Decimal> realizedMap = aggregateOrdersRealized(ownerIds, years);

        // 5. Replica totais em todos os GoalItems e coleta mudanças
        List<GoalItem__c> recordsToUpdate = new List<GoalItem__c>();

        for (String key : itemsByPair.keySet()) {
            // Aplica default 0 para valores não encontrados nos mapas
            Decimal projectedValue = projectedMap.containsKey(key) ? projectedMap.get(key) : 0;
            Decimal negotiatedValue = negotiatedMap.containsKey(key) ? negotiatedMap.get(key) : 0;
            Decimal realizedValue = realizedMap.containsKey(key) ? realizedMap.get(key) : 0;

            for (GoalItem__c item : itemsByPair.get(key)) {
                Boolean changed = false;

                if (item.ProjectedValue__c != projectedValue) {
                    item.ProjectedValue__c = projectedValue;
                    changed = true;
                }
                if (item.NegotiatedValue__c != negotiatedValue) {
                    item.NegotiatedValue__c = negotiatedValue;
                    changed = true;
                }
                if (item.RealizedValue__c != realizedValue) {
                    item.RealizedValue__c = realizedValue;
                    changed = true;
                }

                if (changed) {
                    recordsToUpdate.add(item);
                }
            }
        }

        // 6. Update em bulk com tratamento de erros
        if (!recordsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(recordsToUpdate, false);
            logUpdateErrors(results);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('GoalValueBatch concluído. JobId: ' + bc.getJobId());
    }

    /**
     * Agrega valores de Opportunity por (OwnerId, Year)
     * Filtra: IsClosed = false
     */
    private Map<String, Decimal> aggregateOpportunities(Set<String> ownerIds, Set<Integer> years) {
        Map<String, Decimal> resultMap = new Map<String, Decimal>();

        List<AggregateResult> results = [
            SELECT OwnerId,
                   CALENDAR_YEAR(CloseDate) yr,
                   SUM(Amount) total
            FROM Opportunity
            WHERE IsClosed = false
              AND OwnerId IN :ownerIds
              AND CALENDAR_YEAR(CloseDate) IN :years
            GROUP BY OwnerId, CALENDAR_YEAR(CloseDate)
        ];

        for (AggregateResult ar : results) {
            String ownerId = (String) ar.get('OwnerId');
            Integer year = (Integer) ar.get('yr');
            Decimal total = (Decimal) ar.get('total');
            String key = ownerId + '#' + year;
            resultMap.put(key, total);
        }

        return resultMap;
    }

    /**
     * Agrega valores de Order (Status IN ('New','In Approval')) por (OwnerId, Year)
     * Filtra: Status = 'New' or 'In Approval'
     */
    private Map<String, Decimal> aggregateOrdersNegotiated(Set<String> ownerIds, Set<Integer> years) {
        Map<String, Decimal> resultMap = new Map<String, Decimal>();

        List<AggregateResult> results = [
            SELECT OwnerId,
                   CALENDAR_YEAR(EffectiveDate) yr,
                   SUM(TotalAmount) total
            FROM Order
            WHERE Status IN ('New', 'In Approval')
              AND OwnerId IN :ownerIds
              AND CALENDAR_YEAR(EffectiveDate) IN :years
            GROUP BY OwnerId, CALENDAR_YEAR(EffectiveDate)
        ];

        for (AggregateResult ar : results) {
            String ownerId = (String) ar.get('OwnerId');
            Integer year = (Integer) ar.get('yr');
            Decimal total = (Decimal) ar.get('total');
            String key = ownerId + '#' + year;
            resultMap.put(key, total);
        }

        return resultMap;
    }

    /**
     * Agrega valores de Order (Status IN ('Approved','Integrated')) por (OwnerId, Year)
     * Filtra: Status = 'Approved' or 'Integrated'
     */
    private Map<String, Decimal> aggregateOrdersRealized(Set<String> ownerIds, Set<Integer> years) {
        Map<String, Decimal> resultMap = new Map<String, Decimal>();

        List<AggregateResult> results = [
            SELECT OwnerId,
                   CALENDAR_YEAR(EffectiveDate) yr,
                   SUM(TotalAmount) total
            FROM Order
            WHERE Status IN ('Approved', 'Integrated')
              AND OwnerId IN :ownerIds
              AND CALENDAR_YEAR(EffectiveDate) IN :years
            GROUP BY OwnerId, CALENDAR_YEAR(EffectiveDate)
        ];

        for (AggregateResult ar : results) {
            String ownerId = (String) ar.get('OwnerId');
            Integer year = (Integer) ar.get('yr');
            Decimal total = (Decimal) ar.get('total');
            String key = ownerId + '#' + year;
            resultMap.put(key, total);
        }

        return resultMap;
    }

    /**
     * Log de erros do Database.update
     */
    private void logUpdateErrors(Database.SaveResult[] results) {
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                System.debug('Erro ao atualizar GoalItem: ' + sr.getId());
                for (Database.Error err : sr.getErrors()) {
                    System.debug('  Mensagem: ' + err.getMessage());
                    System.debug('  Campos: ' + err.getFields());
                    System.debug('  Código: ' + err.getStatusCode());
                }
            }
        }
    }
}
