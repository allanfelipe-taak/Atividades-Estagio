public with sharing class FAQController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getFAQs(String searchTerm, Integer pageNumber) {
        Integer pageSize = 10;
        Integer offset = (pageNumber - 1) * pageSize;
        
        String likeParam = '%' + (searchTerm != null ? searchTerm.trim() : '') + '%';
        
        List<FAQ__c> faqs;
        Integer totalRecords;

        try {
            if (String.isBlank(searchTerm)) {
                totalRecords = [SELECT COUNT() FROM FAQ__c];
                faqs = [
                    SELECT Id, Question__c, Answer__c
                    FROM FAQ__c
                    ORDER BY Question__c ASC
                    LIMIT :pageSize
                    OFFSET :offset
                ];
            } else {
                totalRecords = [SELECT COUNT() FROM FAQ__c WHERE Question__c LIKE :likeParam];
                faqs = [
                    SELECT Id, Question__c, Answer__c
                    FROM FAQ__c
                    WHERE Question__c LIKE :likeParam
                    ORDER BY Question__c ASC
                    LIMIT :pageSize
                    OFFSET :offset
                ];
            }

            return new Map<String, Object>{
                'records' => faqs,
                'totalRecords' => totalRecords,
                'pageSize' => pageSize,
                'pageNumber' => pageNumber
            };
        } catch (Exception e) {
            throw new AuraHandledException('Erro ao buscar FAQs: ' + e.getMessage());
        }
    }
}