global with sharing class DataIntegrationFields {
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

		public List<OrderItemINData> orderItemList {get; set;}

		public Order deserialize() {
			return new Order(
				Id				= this.id,
				ExternalId__c	= this.externalId,
				Status			= this.status,
				EffectiveDate	= this.effectiveDate,
				Pricebook2		= new Pricebook2(ExternalId__c = this.pricebook2ExternalId),
				Account			= new Account(ExternalId__c = this.accountExternalId)
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
		public String salesforceId;
		public String externalId;
		public String sobjectType;
		public Boolean hasError;
		public String errorMessage;

		public void success(String salesforceId, String externalId, String sobjectType){
			this.salesforceId	= salesforceId;
			this.externalId		= externalId;
			this.sobjectType	= sobjectType;
			this.hasError		= false;
		}

		public void error(String externalId, String errorMessage, String sobjectType){
			this.externalId		= externalId;
			this.sobjectType	= sobjectType;
			this.hasError		= true;
			this.errorMessage	= errorMessage;
		}

		public void error(String salesforceId, String externalId, String errorMessage, String sobjectType){
			this.salesforceId	= salesforceId;
			this.externalId		= externalId;
			this.sobjectType	= sobjectType;
			this.hasError		= true;
			this.errorMessage	= errorMessage;
		}
	}
	global class ResponseParent extends Response {
		public List<DataIntegrationFields.Response> items;
	}
}
