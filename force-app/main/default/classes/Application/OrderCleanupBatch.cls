public class OrderCleanupBatch implements Database.Batchable<sObject> {
    
    // 1. START: Busca o metadado e filtra os pedidos antigos
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        // Busca o registro do metadado que acabou de criar
        Development_Parameter__mdt parameter = [
            SELECT Value__c 
            FROM Development_Parameter__mdt 
            WHERE DeveloperName = 'MaxNumberMonthsOrder' 
            LIMIT 1
        ];
        
        // Converte o valor "6" (que está em texto) para número inteiro
        Integer months = Integer.valueOf(parameter.Value__c);
        
        // Calcula a data limite: Hoje menos a quantidade de meses (ex: Hoje - 6 meses)
        DateTime limitDate = DateTime.now().addMonths(-months);
        
        // Retorna a lista de todos os pedidos criados ANTES dessa data limite
        return Database.getQueryLocator([
            SELECT Id FROM Order WHERE CreatedDate < :limitDate
        ]);
    }
    
    //  2. EXECUTE: Onde a mágica da limpeza vai acontecer
    public void execute(Database.BatchableContext bc, List<Order> scope) {
        //  programar a exclusão dos anexos e dos pedidos
    }
    
    // FINISH: Fim do processo
    public void finish(Database.BatchableContext bc) {
        // Nenhuma ação necessária conforme o enunciado
    }
}