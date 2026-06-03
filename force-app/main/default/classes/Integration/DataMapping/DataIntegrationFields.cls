global with sharing class DataIntegrationFields {
    // INTEGRATION INBOUND
    public interface FieldData {
        List<String> getRequiredFields();
        String getFieldKey();
        String getFieldId();
        String getExternalId();
        SObject deserialize();
    }

    public interface FieldDataChild {
        List<String> getRequiredFields();
        String getFieldId();
        String getFieldExternal();
        String getParentId();
        String getParentKey();
        SObject deserialize();
    }

    global class OrderINData implements FieldData { 
        public String id;
        public String externalId;
        public String status;
        public Date effectiveDate;
        public String accountExternalId;
        public String pricebook2ExternalId;
        public String paymentConditions; // 🌟 ATIVADO: Atendendo ao formato do JSON
        public String distributionCenter;
        public String freightType;

        public List<OrderItemINData> orderItemList {get; set;}

        public SObject deserialize() {
            return new Order(
                Id              = this.id,
                ExternalId__c   = this.externalId != null ? this.externalId.toUpperCase() : null,
                Status          = this.status,
                EffectiveDate   = this.effectiveDate,
                Pricebook2      = new Pricebook2(ExternalId__c = this.pricebook2ExternalId),
                Account         = new Account(ExternalId__c = this.accountExternalId),
                DistributionCenter__r = new DistributionCenter__c(ExternalId__c = this.distributionCenter),
                FreightType__c  = this.freightType, // 🌟 CORREÇÃO: Adicionada a vírgula obrigatória aqui
                PaymentTerm__r  = new PaymentTerm__c(ExternalId__c = this.paymentConditions) // 🌟 CORREÇÃO: Usa o objeto real da SUA Org (PaymentTerm__c)
            );
        }

        public List<String> getRequiredFields() {
            return new List<String>{
                'ExternalId__c',
                'EffectiveDate',
                'Status'
            };
        }
        public List<String> getRequiredLookups() {
            return new List<String>{
                'AccountId',
                'Pricebook2Id'
            };
        }

        public String getFieldKey() {
            return 'ExternalId__c';
        }
        public String getFieldId() {
            return 'Id';
        }
        public String getExternalId() {
            return this.externalId != null ? this.externalId.toUpperCase() : null;
        }
    }
    global class OrderItemINData implements FieldDataChild { 
        public String id;
        public String externalId;
        public Decimal quantity;
        public Decimal unitPrice;
        public String orderExternalId;
        public String productExternalId;
        public String pricebookEntryExternalId;

        public SObject deserialize() {
            OrderItem orderItem = new OrderItem(
                ExternalId__c   = this.externalId != null ? this.externalId.toUpperCase() : null,
                Quantity        = this.quantity,
                UnitPrice       = this.unitPrice
            );

            if (this.id == null || this.id == '') {
                orderItem.Order             = new Order(ExternalId__c = this.orderExternalId != null ? this.orderExternalId.toUpperCase() : null);
                orderItem.Product2          = new Product2(ExternalId__c = this.productExternalId);
                orderItem.PricebookEntry    = new PricebookEntry(ExternalId__c = this.pricebookEntryExternalId);
            }
            else orderItem.Id = this.id;

            return orderItem;
        }

        public List<String> getRequiredFields() {
            return new List<String>{
                'UnitPrice',
                'Quantity',
                'ExternalId__c'
            };
        }
        public List<String> getRequiredLookups() {
            return new List<String>{
                'OrderId',
                'Product2Id',
                'PricebookEntryId'
            };
        }

        public String getFieldId() {
            return 'Id';
        }
        public String getFieldExternal() {
            return 'ExternalId__c';
        }
        public String getParentId() {
            return 'OrderId';
        }
        public String getParentKey() {
            return this.orderExternalId != null ? this.orderExternalId.toUpperCase() : null;
        }
    }

    global virtual class Response {
        public Boolean hasError;
        public String errorMessage;

        public String salesforceId;
        public String externalId;
        public String sobjectType;

        public void success(String salesforceId, String externalId, String sobjectType){
            this.hasError       = false;
            this.errorMessage   = '';
            this.salesforceId   = salesforceId;
            this.externalId     = externalId;
            this.sobjectType    = sobjectType;
        }

        public void error(String externalId, String errorMessage, String sobjectType){
            this.hasError       = true;
            this.errorMessage   = errorMessage;
            this.externalId     = externalId;
            this.sobjectType    = sobjectType;
        }

        public void error(String salesforceId, String externalId, String errorMessage, String sobjectType){
            this.hasError       = true;
            this.errorMessage   = errorMessage;
            this.salesforceId   = salesforceId;
            this.externalId     = externalId;
            this.sobjectType    = sobjectType;
        }
    }
    global class ResponseParent extends Response {
        public List<DataIntegrationFields.Response> items;
    }

    // INTEGRATION OUTBOUND
    public class RequestResponseObject {
        public HttpResponse response;
        public Boolean success;
        public Exception exceptionObject;

        public RequestResponseObject(HttpResponse response) {
            this.success = true;
            this.response = response;
            this.exceptionObject = null;
        }

        public RequestResponseObject(Exception ex) {
            this.success = false;
            this.response = null;
            this.exceptionObject = ex;
        }
    }

    public class CalloutResponse {
        public Boolean hasError;
        public String errorMessage;

        public ResponseParametersWrapper parsedResponse;
        public List<ResponseParametersWrapper> parsedResponses;

        public CalloutResponse(String errorMessage) {
            this.hasError = true;
            this.errorMessage = errorMessage;
        }
        public CalloutResponse(ResponseParametersWrapper response, Boolean hasError) {
            this.hasError = hasError;
            this.errorMessage = '';
            this.parsedResponse = response;
        }
        public CalloutResponse(List<ResponseParametersWrapper> responseList, Boolean hasError) {
            this.hasError = hasError;
            this.errorMessage = '';
            this.parsedResponses = responseList;
        }
    }

    public class ResponseParametersWrapper {
        public Boolean hasError;
        public String errorMessage;
        public String salesforceId;
        public String externalId;
        public String sobjectType;

        public List<ResponseParametersWrapper> items;
    }

    public class RequestList {
        List<OrderParameters> orderRequestList;

        public RequestList(List<DataIntegrationFields.OrderParameters> orderRequestList) {
            this.orderRequestList = orderRequestList;
        }
    }
    public class Request {
        OrderParameters orderRequest;

        public Request(DataIntegrationFields.OrderParameters orderRequest) {
            this.orderRequest = orderRequest;
        }
    }

    public class OrderParameters {
        public String externalId;
        public String status;
        public Date effectiveDate;
        public Date deliveryDate;
        public String accountExternalId;
        public String pricebook2ExternalId;
        public String paymentConditions; 
        public String distributionCenter;
        public String freightType;
        public String address;

        public OrderItemParameters[] orderItemList;

        public OrderParameters(Order order) {
            this.externalId = order.ExternalId__c;
            this.status = 'New';
            this.effectiveDate = order.EffectiveDate;
            this.accountExternalId = order.Account.ExternalId__c;
            this.pricebook2ExternalId = order.Pricebook2.ExternalId__c;
            this.paymentConditions = order.PaymentTerm__r.ExternalId__c; // 🌟 Mapeia o campo correto da sua Org (PaymentTerm__r)
            this.distributionCenter = order.DistributionCenter__r.ExternalId__c;
            this.address = order.Address__r.ExternalId__c;
            this.freightType = 'CIF';
            this.deliveryDate = order.DeliveryDate__c;

            this.orderItemList = new List<OrderItemParameters>();

            if (order.OrderItems != null) {
                for (OrderItem orderItem : order.OrderItems) {
                    orderItemList.add(new OrderItemParameters(orderItem));
                }
            }
			System.debug(order.PaymentTerm__r.ExternalId__c);
        }
		
    }
    public class OrderItemParameters {
        public String externalId;
        public Decimal quantity;
        public Decimal unitPrice;
        public String orderExternalId;
        public String productExternalId;
        public String pricebookEntryExternalId;

        public OrderItemParameters(OrderItem orderItem) {
            this.externalId = orderItem.ExternalId__c;
            this.quantity = orderItem.Quantity;
            this.unitPrice = orderItem.UnitPrice;
            this.orderExternalId = orderItem.Order.ExternalId__c;
            this.productExternalId = orderItem.Product2.ExternalId__c;
            this.pricebookEntryExternalId = orderItem.PricebookEntry.ExternalId__c;
        }
    }

    public class ResponseAccessToken {
        public String access_token;
        public String instance_url;
        public String error;             
        public String error_description; 
    }
}