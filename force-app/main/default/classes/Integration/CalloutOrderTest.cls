@IsTest
public with sharing class CalloutOrderTest {
	@TestSetup
	static void makeData() {
		TestFactorySObject sobjectFactory = TestFactorySObject.getInstance();

		Account newAccount = (Account)sobjectFactory.createSObject(new Account());
		insert newAccount;

		Product2 newProduct = (Product2)sobjectFactory.createSObject(new Product2());
		insert newProduct;

		PricebookEntry newPricebookEntry = (PricebookEntry)sobjectFactory.createSObject(
			new PricebookEntry(product2Id = newProduct.Id, Pricebook2Id = Test.getStandardPricebookId())
		);
		insert newPricebookEntry;

		Order newOrder = (Order)sobjectFactory.createSObject(
			new Order(AccountId = newAccount.Id, Pricebook2Id = Test.getStandardPricebookId(), ExternalId__c = 'CalloutOrder')
		);
		Order newOrderError = (Order)sobjectFactory.createSObject(
			new Order(AccountId = newAccount.Id, Pricebook2Id = Test.getStandardPricebookId(), ExternalId__c = 'CalloutOrderError')
		);
		insert (new List<Order>{ newOrder, newOrderError });

		OrderItem newOrderItem = (OrderItem)sobjectFactory.createSObject(
			new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
		);
		OrderItem newOrderItem2 = (OrderItem)sobjectFactory.createSObject(
			new OrderItem(OrderId = newOrder.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
		);
		insert (new List<OrderItem>{ newOrderItem, newOrderItem2 });

		OrderItem newOrderItemError = (OrderItem)sobjectFactory.createSObject(
			new OrderItem(OrderId = newOrderError.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
		);
		OrderItem newOrderItemError2 = (OrderItem)sobjectFactory.createSObject(
			new OrderItem(OrderId = newOrderError.Id, Product2Id = newProduct.Id, PricebookEntryId = newPricebookEntry.Id)
		);
		insert (new List<OrderItem>{ newOrderItemError, newOrderItemError2 });

		IntegrationSetting__c integration = (IntegrationSetting__c)sobjectFactory.createSObject(
			new IntegrationSetting__c(Name = 'IntegrationOutUsername')
		);
		insert integration;
	}

	@IsTest
	public static void processIntegrationTest() {
		List<String> orderIdList = new List<String>();
		for (Order order : [SELECT Id FROM Order LIMIT 2]) {
			orderIdList.add(order.Id);
		}

		Test.startTest();
			Test.setMock(
				HttpCalloutMock.class,
				new MockHttpResponse(true, TestUtility.getBodyResponse(), TestUtility.getBodyResponse())
			);
			CalloutOrder.executeCalloutOrder(orderIdList);
		Test.stopTest();
	}

	@IsTest
	public static void processIntegrationErrorTest() {
		List<String> orderIdList = new List<String>();
		Order updateOrder;
		for (Order order : [SELECT Id FROM Order LIMIT 2]) {
			orderIdList.add(order.Id);
			updateOrder = order;
		}

		Test.startTest();
			Test.setMock(
				HttpCalloutMock.class,
				new MockHttpResponse(false, TestUtility.getBodyResponse(), TestUtility.getBodyResponse())
			);
			update updateOrder;
			CalloutOrder.executeCalloutOrder(orderIdList);
		Test.stopTest();
	}

	@IsTest
	public static void processIntegrationExceptionTest() {
		List<String> orderIdList = new List<String>();
		for (Order order : [SELECT Id FROM Order LIMIT 2]) {
			orderIdList.add(order.Id);
		}

		Test.startTest();
			Test.setMock(
				HttpCalloutMock.class,
				new MockHttpResponse(true, TestUtility.getBodyResponseError(), TestUtility.getBodyResponseError())
			);
			CalloutOrder.executeCalloutOrder(orderIdList);
		Test.stopTest();
	}

	@IsTest
	public static void handlerAccessTokenTest() {
		Test.startTest();
			Test.setMock(
				HttpCalloutMock.class,
				new MockHttpResponse(true, TestUtility.getBodyAccessToken(), TestUtility.getBodyAccessToken())
			);

			CalloutOrder.handlerAccessToken(new CalloutOrder.AccessTokenLog());
		Test.stopTest();
	}

	@IsTest
	public static void getAccessTokenTest() {
		IntegrationSetting__c integrationSetting = getIntegrationSetting();
		integrationSetting.LastAccessTokenTime__c = null;
		update integrationSetting;

		Test.startTest();
			Test.setMock(
				HttpCalloutMock.class,
				new MockHttpResponse(true, TestUtility.getBodyAccessToken(), TestUtility.getBodyAccessToken())
			);
			CalloutOrder.handlerAccessToken(new CalloutOrder.AccessTokenLog());

			Test.setMock(
				HttpCalloutMock.class,
				new MockHttpResponse(false, TestUtility.getBodyAccessToken(), TestUtility.getBodyAccessToken())
			);
			try {
				CalloutOrder.handlerAccessToken(new CalloutOrder.AccessTokenLog());
			}
			catch (Exception ex) {}
		Test.stopTest();
	}

	@IsTest
	public static void treatmentMethodsTest() {
		CalloutOrder.callErrorTreatment();
		CalloutOrder.callSuccessTreatment();
	}

	@IsTest
	public static void updateIntegrationSettingTest() {
		IntegrationSetting__c currentIntegrationSetting = getIntegrationSetting();
		CalloutOrder.IntegrationSettings integrationSetting = new CalloutOrder.IntegrationSettings(currentIntegrationSetting);

		CalloutOrder.updateIntegrationSetting(integrationSetting);
	}

	public static IntegrationSetting__c getIntegrationSetting() {
		return [
			SELECT Id,
				   User__c,
				   Password__c,
				   ClientId__c,
				   ClientSecret__c,
				   Timeout__c,
				   AccessTokenTime__c,
				   LastAccessTokenTime__c,
				   EndpointAccessToken__c,
				   AccessToken__c,
				   Endpoint__c,
				   Method__c
			  FROM IntegrationSetting__c
			 LIMIT 1
		];
	}
}
