public with sharing class FAQController {

    @AuraEnabled(cacheable=true)
    public static List<FAQ__c> getFAQs(String searchTerm) {
        String likeParam = '%' + (searchTerm != null ? searchTerm.trim() : '') + '%';

        if (String.isBlank(searchTerm)) {
            return [
                SELECT Id, Question__c, Answer__c
                FROM FAQ__c
                ORDER BY Question__c ASC
                LIMIT 200
            ];
        }

        return [
            SELECT Id, Question__c, Answer__c
            FROM FAQ__c
            WHERE Question__c LIKE :likeParam
            ORDER BY Question__c ASC
            LIMIT 200
        ];
    }
}