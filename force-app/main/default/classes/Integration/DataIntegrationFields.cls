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

	global class OrderINData implements FieldData { // extends OrderBase
		public String id;
		public String externalId;
		public String status;
		public Date effectiveDate;
		public String accountExternalId;
		public String pricebook2ExternalId;
		public String condicaoPagamento;
		public String centroDistribuicao;
		public String tipoFrete;

		public List<OrderItemINData> orderItemList {get; set;}

		public Order deserialize() {
			return new Order(
				Id				= this.id,
				ExternalId__c	= this.externalId,
				Status			= this.status,
				EffectiveDate	= this.effectiveDate,
				Pricebook2		= new Pricebook2(ExternalId__c = this.pricebook2ExternalId),
				Account			= new Account(ExternalId__c = this.accountExternalId),
				Centro_Distribuicao__r = new Centro_Distribuicao__c(ExternalId__c = this.centroDistribuicao),
				Tipo_Frete__c = this.tipoFrete,
				Condicao_Pagamento__r = new Condicao_Pagamento__c(ExternalId__c = this.condicaoPagamento)
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
			return this.externalId;
		}
	}
	global class OrderItemINData implements FieldDataChild { // extends OrderItemBase
		public String id;
		public String externalId;
		public Decimal quantity;
		public Decimal unitPrice;
		public String orderExternalId;
		public String productExternalId;
		public String pricebookEntryExternalId;

		public OrderItem deserialize() {
			OrderItem orderItem = new OrderItem(
				ExternalId__c	= this.externalId,
				Quantity		= this.quantity,
				UnitPrice		= this.unitPrice
			);

			if (this.id == null || this.id == '') {
				orderItem.Order				= new Order(ExternalId__c = this.orderExternalId);
				orderItem.Product2			= new Product2(ExternalId__c = this.productExternalId);
				orderItem.PricebookEntry	= new PricebookEntry(ExternalId__c = this.pricebookEntryExternalId);
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
			return this.orderExternalId;
		}
	}

	global virtual class Response {
		public Boolean hasError;
		public String errorMessage;

		public String salesforceId;
		public String externalId;
		public String sobjectType;

		public void success(String salesforceId, String externalId, String sobjectType){
			this.hasError		= false;
			this.errorMessage	= '';
			this.salesforceId	= salesforceId;
			this.externalId		= externalId;
			this.sobjectType	= sobjectType;
		}

		public void error(String externalId, String errorMessage, String sobjectType){
			this.hasError		= true;
			this.errorMessage	= errorMessage;
			this.externalId		= externalId;
			this.sobjectType	= sobjectType;
		}

		public void error(String salesforceId, String externalId, String errorMessage, String sobjectType){
			this.hasError		= true;
			this.errorMessage	= errorMessage;
			this.salesforceId	= salesforceId;
			this.externalId		= externalId;
			this.sobjectType	= sobjectType;
		}
	}
	global class ResponseParent extends Response {
		public List<DataIntegrationFields.Response> items;
	}

	// INTEGRATION OUTBOUND
	// Standard Http Request response
	public class RequestResponseObject {
		// Response object, in case the callout was successful.
		public HttpResponse response;
		// Boolean that determines if there is an exception or a HttpResponse.
		public Boolean success;
		// Exception object, in case there is any.
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

	// CALLOUT STANDARD RESPONSE OUTTER CLASS
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

	public class ResponseParametersWrapper { // Adaptar Esta Class Para os Campos que Virá de Resposta da Integração OUT
		public Boolean hasError;
		public String errorMessage;
		public String salesforceId;
		public String externalId;
		public String sobjectType;

		public List<ResponseParametersWrapper> items;
	}

	public class RequestList { // Alterar o Nome das Variaveis Se Necessário
		List<OrderParameters> orderRequestList;

		public RequestList(List<DataIntegrationFields.OrderParameters> orderRequestList) {
			this.orderRequestList = orderRequestList;
		}
	}
	public class Request { // Alterar o Nome das Variaveis Se Necessário
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
			this.status = order.Status;
			this.effectiveDate = order.EffectiveDate;
			this.accountExternalId = order.Account.ExternalId__c;
			this.pricebook2ExternalId = order.Pricebook2.ExternalId__c;
			this.paymentConditions = order.Condicao_Pagamento__r.ExternalId__c;
			this.distributionCenter = order.Centro_Distribuicao__r.ExternalId__c;
			this.address = order.Endereco__r.ExternalId__c;
			this.freightType = order.Tipo_Frete__c;
			this.deliveryDate = order.DeliveryDate__c;
			

			this.orderItemList = new List<OrderItemParameters>();

			for (OrderItem orderItem : Order.OrderItems)
				orderItemList.add(new OrderItemParameters(orderItem));
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
    public String error;             // <--- Linha adicionada
    public String error_description; // <--- Linha adicionada
}
}
