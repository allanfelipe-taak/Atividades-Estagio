public with sharing class CalloutOrder {
    
    // 👇 CLASSE NOVA EXCLUSIVA PARA O FLOW ENTENDER A RESPOSTA 👇
    public class FlowOutput {
        @InvocableVariable(label='Teve Erro?')
        public Boolean hasError;
        
        @InvocableVariable(label='Mensagem de Erro')
        public String errorMessage;
    }

    // A assinatura do método agora retorna a nossa nova lista FlowOutput
    @InvocableMethod(label='Enviar Pedido para ERP' description='Faz o callout do pedido via Flow' callout=true)
    public static List<FlowOutput> executeCalloutOrder(List<String> orderIdList) {
        
        List<FlowOutput> flowResponseList = new List<FlowOutput>();
        FlowOutput result = new FlowOutput();

        if (orderIdList.isEmpty()) {
            result.hasError = true;
            result.errorMessage = 'Lista de Order Id Vazia!';
            flowResponseList.add(result);
            return flowResponseList;
        }

        List<Order> sendOrderList;
        DataIntegrationFields.CalloutResponse calloutResponse;
        AccessTokenLog accessTokenLog = new AccessTokenLog();
        IntegrationSettings integrationSetting;
        HttpResponse response;
        String payload;
        
        try {
            integrationSetting = handlerAccessToken(accessTokenLog);

            Map<String, String> headersMap = fillHeader(integrationSetting);
            sendOrderList = getOrders(orderIdList);
            payload = JSON.serialize(new DataIntegrationFields.RequestList( fillOrderRequestList(sendOrderList) ));

            response = IntegrationUtils.executeCallout(
                integrationSetting.endpoint,
                payload,
                headersMap,
                'POST',
                Integer.valueOf(integrationSetting.timeout)
            );

            calloutResponse = fillCalloutResponse(response);
        }
        catch (Exception ex) {
            System.debug('Exception Integration => ' + ex.getMessage());
            // CORREÇÃO: Simula a falha no calloutResponse em vez de dar "return" antecipado
            calloutResponse = new DataIntegrationFields.CalloutResponse(
                ex.getMessage() + ' - ' + ex.getStackTraceString()
            );
            calloutResponse.hasError = true;
            response = new HttpResponse(); 
            response.setBody('Falha antes de enviar: ' + ex.getMessage());
            response.setStatusCode(400);
        }

        try {
            List<String> externalIdList = new List<String>();
            if (sendOrderList != null) {
                for (Order order : sendOrderList) {
                    if (order.ExternalId__c != null) externalIdList.add(order.ExternalId__c);
                }
            }

            String errorMessage = handlerError(calloutResponse);
            
            // Garantir que endpoint não fica nulo no log se falhou antes
            String logEndpoint = integrationSetting != null ? integrationSetting.endpoint : 'Endpoint não configurado';

            String integrationLogId = IntegrationLog.createLog(
                'Order',
                externalIdList,
                'Outbound',
                response != null ? response.getBody() : '',
                payload,
                errorMessage,
                logEndpoint,
                response != null ? response.getStatusCode() : 400,
                calloutResponse != null ? calloutResponse.hasError : true,
                false
            );

            if (accessTokenLog != null && !String.isBlank(accessTokenLog.response)) {
                createTokenLog(accessTokenLog.response, accessTokenLog.payload, accessTokenLog.endpoint, 200, '');
            }

            if (integrationSetting != null && integrationSetting.hasUpdateAccessToken) {
                updateIntegrationSetting(integrationSetting);
            }

            if (sendOrderList != null) {
    updateSObjectWithIntegrationLogId(sendOrderList, integrationLogId, 'OUT');
    
    // 🌟 NOVA TRAVA COLOQUER AQUI: Se a integração deu sucesso total, força o Status a virar Integrated!
    if (calloutResponse != null && !calloutResponse.hasError) {
        List<Order> ordersToUpdateStatus = new List<Order>();
        for (Order ord : sendOrderList) {
            ordersToUpdateStatus.add(new Order(Id = ord.Id, Status = 'Integrated'));
        }
        update ordersToUpdateStatus;
    }
}
        }
        catch (Exception ex) {
            System.debug('Exception Integration Log => ' + ex.getMessage() + ' - ' + ex.getStackTraceString());
        }

        // 👇 PREENCHE O RESULTADO FINAL PARA DEVOLVER AO FLOW 👇
        result.errorMessage = handlerError(calloutResponse);
        
        // REGRA DE OURO: Se a mensagem de erro estiver preenchida, é porque falhou!
        if (String.isNotBlank(result.errorMessage)) {
            result.hasError = true;
        } else {
            result.hasError = calloutResponse != null ? calloutResponse.hasError : false;
        }
        
        flowResponseList.add(result);
        return flowResponseList;
    }

    public static List<Order> getOrders(List<String> orderIdList) {
        return [
            SELECT  Id, ExternalId__c, Account.ExternalId__c, Pricebook2.ExternalId__c,
            Address__r.ExternalId__c,FreightType__c,
                               DistributionCenter__r.ExternalId__c,PaymentTerm__r.ExternalId__c,
                               EffectiveDate,DeliveryDate__c,
                               Status,
                    (
                        SELECT Id, ExternalId__c, Quantity, UnitPrice,
                               Order.ExternalId__c, Product2.ExternalId__c, PricebookEntry.ExternalId__c
                               
                          FROM OrderItems
                         WHERE DeletedProduct__c = false 
                    )
              FROM  Order
             WHERE  Id IN: orderIdList

        ];
    }

  

    public static IntegrationSettings handlerAccessToken(AccessTokenLog accessTokenLog) {
        IntegrationSettings integrationSetting = new IntegrationSettings(IntegrationSetting__c.getValues('GustavoOrg'));
        Decimal lastTime = integrationSetting.lastAccessTokenTime;

        if (lastTime != null && datetime.now().getTime() < (lastTime + integrationSetting.accessTokenTime)) {
            return integrationSetting;
        }

        return getAccessToken(integrationSetting, accessTokenLog);
    }

    public static IntegrationSettings getAccessToken(IntegrationSettings integrationSetting, AccessTokenLog accessTokenLog) {
        
        String body = 
            'grant_type=client_credentials' +
            '&client_id=' + integrationSetting.clientId +
            '&client_secret=' + integrationSetting.clientSecret;
        String endpoint = integrationSetting.endpointAccessToken + '?' + body;
        

        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setTimeout(Integer.valueOf(integrationSetting.timeout));
        request.setEndpoint(endpoint);

        HttpResponse response = (new Http()).send(request);
        DataIntegrationFields.ResponseAccessToken responseAccessToken = (DataIntegrationFields.ResponseAccessToken)JSON.deserialize(
            response.getBody(), DataIntegrationFields.ResponseAccessToken.class
        );

        if (response.getStatusCode() != 200 && response.getStatusCode() != 201) {
            String errorMessage = ''         +
                'Get Access Token Error => ' +
                response.getStatusCode()     + ' | ' +
                response.getStatus()         + ' | ' +
                responseAccessToken.error    + ' | ' +
                responseAccessToken.error_description;

            createTokenLog(response.getBody(), '', endpoint, response.getStatusCode(), errorMessage);

            throw new CustomException(errorMessage);
        }

        integrationSetting.changeAccessTokenTime(datetime.now().getTime(), responseAccessToken.access_token);
        accessTokenLog.response = response.getBody();
        accessTokenLog.payload = endpoint;
        accessTokenLog.endpoint = integrationSetting.endpointAccessToken;
        accessTokenLog.statusCode = 200;

        return integrationSetting;
    }

    public static void createTokenLog(String response, String payload, String endpoint, Integer statusCode, String errorMessage) {
        IntegrationLog.createLog(
            'Order Access Token',
            new List<String>(),
            'Outbound',
            response,
            payload,
            errorMessage,
            endpoint,
            statusCode,
            (statusCode != 200),
            false
        );
    }

    public static Map<String, String> fillHeader(IntegrationSettings integrationSetting) {
        return new Map<String, String>{
            'Content-Type' => 'application/json',
            'Authorization' => 'Bearer ' + integrationSetting.accessToken
        };
    }

    public static List<DataIntegrationFields.OrderParameters> fillOrderRequestList(List<Order> orderList) {
        List<DataIntegrationFields.OrderParameters> orderRequestList = new List<DataIntegrationFields.OrderParameters>();

        for (Order order : orderList) {
            orderRequestList.add(new DataIntegrationFields.OrderParameters(order));
        }

        return orderRequestList;
    }

   public static DataIntegrationFields.CalloutResponse fillCalloutResponse(HttpResponse response) {
        try {
            if (response.getStatusCode() != 200 && response.getStatusCode() != 201) {
                throw new CustomException('Request Failled');
            }

            Boolean hasError = false;
            List<DataIntegrationFields.ResponseParametersWrapper> responseParameters =
            (List<DataIntegrationFields.ResponseParametersWrapper>)JSON.deserialize(
                response.getBody(), List<DataIntegrationFields.ResponseParametersWrapper>.class
            );

            for (DataIntegrationFields.ResponseParametersWrapper responseParameter : responseParameters) {
                if (responseParameter.hasError) hasError = true;
            }

            return new DataIntegrationFields.CalloutResponse(responseParameters, hasError);
        }
        catch (Exception ex) {
            // 👇 AQUI ESTAVA O CULPADO! Ele criava o erro mas não marcava a checkbox hasError = true.
            DataIntegrationFields.CalloutResponse cr = new DataIntegrationFields.CalloutResponse(
                'Exception ' + response.getStatus() + '. ' + ex.getMessage() + '. \n' + response.getBody()
            );
            cr.hasError = true; // <--- A NOSSA VACINA!
            
            return cr;
        }
    }

    public static String handlerError(DataIntegrationFields.CalloutResponse calloutResponse) {
        if (calloutResponse == null || !calloutResponse.hasError) return '';

        String errorMessage = '';

        if (calloutResponse.parsedResponses != null) {
            for (DataIntegrationFields.ResponseParametersWrapper response : calloutResponse.parsedResponses) {
                if (response.hasError) {
                    errorMessage += (response.externalId != null ? response.externalId + ' => ' : '') + response.errorMessage + '\n';
                }

                if (response.items != null) {
                    for (DataIntegrationFields.ResponseParametersWrapper item : response.items) {
                        if (item.hasError) {
                            errorMessage += (item.externalId != null ? item.externalId + ' => ' : '') + item.errorMessage + '\n';
                        }
                    }
                }
            }
        }
        else errorMessage = calloutResponse.errorMessage;

        return errorMessage;
    }

    public static void callErrorTreatment() {
        System.debug('callErrorTreatment');
    }
    public static void callSuccessTreatment() {
        System.debug('callSuccessTreatment');
    }

    public static void updateSObjectWithIntegrationLogId(List<SObject> sobjectList, String integrationLogId, String integrationType) {
        if (sobjectList.isEmpty()) return;

        List<SObject> sobjectUpdateList = new List<SObject>();
        String sobjectName = sobjectList[0].getSObjectType().getDescribe().getName();

        String query = 'SELECT Id, IntegrationLogInbound__c, IntegrationLogOutbound__c FROM ' + sobjectName + ' WHERE Id IN: sobjectList';

        for (SObject sobj : Database.query(query)) {
            if (integrationType == 'IN') sobj.put('IntegrationLogInbound__c', integrationLogId);
            else sobj.put('IntegrationLogOutbound__c', integrationLogId);

            sobjectUpdateList.add(sobj);
        }

        if (!sobjectUpdateList.isEmpty()) update sobjectUpdateList;
    }

    public static void updateIntegrationSetting(IntegrationSettings integrationSetting) {
        IntegrationSetting__c updateIntegrationSetting = new IntegrationSetting__c(
            Id = integrationSetting.id,
            AccessToken__c = integrationSetting.accessToken,
            LastAccessTokenTime__c = integrationSetting.lastAccessTokenTime
        );

        update updateIntegrationSetting;
    }

    public class CustomException extends Exception {}

    public class AccessTokenLog {
        public String response = '';
        public String payload = '';
        public String endpoint = '';
        public Integer statusCode = 400;

        public AccessTokenLog() {}
    }

    public class IntegrationSettings {
        public String id;

        public Decimal lastAccessTokenTime;
        public Decimal accessTokenTime;
        public Decimal timeout;

        public String endpointAccessToken;
        public String accessToken;

        public String endpoint;
        public String clientId;
        public String clientSecret;
        public String user;
        public String password;
        public String method;

        public Boolean hasUpdateAccessToken;

        public IntegrationSettings(IntegrationSetting__c integrationSetting) {
            this.id = integrationSetting.Id;

            this.lastAccessTokenTime = integrationSetting.LastAccessTokenTime__c;
            this.accessTokenTime = integrationSetting.AccessTokenTime__c;
            this.timeout = integrationSetting.Timeout__c;

            this.endpointAccessToken = integrationSetting.EndpointAccessToken__c;
            this.accessToken = integrationSetting.AccessToken__c;

            this.endpoint = integrationSetting.Endpoint__c;
            this.clientId = integrationSetting.ClientId__c;
            this.clientSecret = integrationSetting.ClientSecret__c;
            this.user = integrationSetting.User__c;
            this.password = integrationSetting.Password__c;
            this.method = integrationSetting.Method__c;

            this.hasUpdateAccessToken = false;
        }
        public void changeAccessTokenTime(Decimal newAccessTokenTime, String accessToken) {
            this.hasUpdateAccessToken = true;
            this.lastAccessTokenTime = newAccessTokenTime;
            this.accessToken = accessToken;
        }
    }
}