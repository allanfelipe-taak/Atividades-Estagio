public with sharing class ProductHandler implements ContratoTrigger {
    
    // Métodos obrigatórios da Interface
    public void beforeInsert(List<SObject> newRecords) {}
    public void beforeUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {}
    public void afterUpdate(List<SObject> newRecords, Map<Id, SObject> oldRecords) {}

    // ESTE MÉTODO PRECISA SER PUBLIC para o Maestro enxergar
    public void afterInsert(List<SObject> newRecords) {
        // Faz o cast e chama a lógica
        createStandardPricebookEntries((List<Product2>) newRecords);
    }

    // pode deixar este como public também para garantir a visibilidade
    public void createStandardPricebookEntries(List<Product2> newProducts) {
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        
        Id stdPricebookId = Test.isRunningTest() ? Test.getStandardPricebookId() : [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

        for (Product2 p : newProducts) {
            pbeList.add(new PricebookEntry(
                Pricebook2Id = stdPricebookId,
                Product2Id = p.Id,
                UnitPrice = 0,
                IsActive = true
            ));
        }

        if (!pbeList.isEmpty()) {
            insert pbeList;
        }
    }
}