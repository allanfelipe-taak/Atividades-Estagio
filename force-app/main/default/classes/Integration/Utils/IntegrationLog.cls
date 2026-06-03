public with sharing class IntegrationLog {
    public static Id createLog(
        String integrationName,
        List<String> externalIdList,
        String recordTypeName,
        String payloadIN,
        String payloadOUT,
        String errorMessage,
        String endpoint,
        Integer statusCode,
        Boolean hasAnyErrors,
        Boolean hasDeleted
    ){
        Boolean attachmentIN = (payloadIN.length() > 130000);
        Boolean attachmentOUT = (payloadOUT.length() > 130000);
        Datetime datetimeNow = System.now();

        // Pega Id do log de integração (IN ou OUT)
        Id recordTypeId = Schema.SObjectType.IntegrationLog__c.getRecordTypeInfosByDeveloperName().containsKey(recordTypeName) ?
            Schema.SObjectType.IntegrationLog__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId() : null;

        if (recordTypeId == null) System.debug('Falha ao pegar o recordTypeId do log de integração => ' + recordTypeId);

        IntegrationLog__c log = createIntegrationLogRecord(
            integrationName,
            convertExternalIdList(externalIdList),
            recordTypeId,
            recordTypeName,
            attachmentIN,
            attachmentOUT,
            payloadIN,
            payloadOUT,
            errorMessage,
            endpoint,
            statusCode,
            hasAnyErrors,
            datetimeNow,
            hasDeleted
        );

        insert log;

        if (attachmentIN) createAttachment(log.Id, integrationName, 'IN', log.Name, String.valueOf(datetimeNow), payloadIN);
        if (attachmentOUT) createAttachment(log.Id, integrationName, 'OUT', log.Name, String.valueOf(datetimeNow), payloadOUT);

        return log.Id;
    }

    public static String convertExternalIdList(List<String> externalIdList) {
        String allExternalId = '';

        for (String externalId : externalIdList) {
            if (allExternalId == '') allExternalId = externalId;
            else allExternalId += ', ' + externalId;
        }

        return allExternalId;
    }

    public static IntegrationLog__c createIntegrationLogRecord(
        String integrationName,
        String externalIdList,
        Id recordTypeId,
        String recordTypeName,
        Boolean attachmentIN,
        Boolean attachmentOUT,
        String payloadIN,
        String payloadOUT,
        String errorMessage,
        String endpoint,
        Integer statusCode,
        Boolean hasAnyErrors,
        Datetime datetimeNow,
        Boolean hasDeleted
    ) {

        return new IntegrationLog__c(
            Name = integrationName + ' ' + recordTypeName,
            Endpoint__c = endpoint,
            // Proteção 1: Se o statusCode for nulo, salva nulo
            StatusCode__c = statusCode != null ? Decimal.valueOf(statusCode) : null,
            
            ExternalIdList__c = (externalIdList != null && externalIdList.length() > 255) ? externalIdList.substring(0, 255) : externalIdList,
            RecordTypeId = recordTypeId,
            Attachment__c = (attachmentIN || attachmentOUT),
            PayloadIN__c = (attachmentIN ? '' : payloadIN),
            PayloadOUT__c = (attachmentOUT ? '' : payloadOUT),
            ExecutionDate__c = datetimeNow,
            IntegrationStatus__c = (hasAnyErrors ? 'Error' : 'Success'),
            
            // 🛡️ PROTEÇÃO AQUI: Só compara se o statusCode não for nulo, evitando o erro de null object
            Status__c = (statusCode != null && (statusCode == 200 || statusCode == 201)) ? 'Success' : 'Error',
            
            ErrorMessage__c = (errorMessage != null && errorMessage.length() > 130000) ? errorMessage.substring(0, 130000) : errorMessage,
            HasDeleted__c = hasDeleted
        );
    }

    @TestVisible
    private static Id createAttachment(
        String recordId,
        String integrationName,
        String inOrOut,
        String logName,
        String timeAsString,
        String payload
    ) {
        Attachment attachment = new Attachment(
            Name = 'LOG-' + integrationName + '-' + inOrOut + '-' + timeAsString + '.txt',
            Body = Blob.valueOf(payload),
            ParentId = recordId
        );

        insert attachment;

        return attachment.Id;
    }
}