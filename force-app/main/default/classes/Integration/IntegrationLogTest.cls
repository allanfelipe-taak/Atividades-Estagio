@IsTest
public with sharing class IntegrationLogTest {
	@IsTest
	public static void createLogTest() {
		Datetime datetimeNow = System.now();
		String integrationName = 'Order';
		String externalIdList = '1000';
		String recordTypeName = 'Inbound';
		String payloadIN = 'Class Test';
		String payloadOUT = '';
		String endpoint = '';
		Boolean hasAnyErrors = false;
		Boolean hasDeleted = false;

		Test.startTest();
			IntegrationLog.createLog('', externalIdList, '', payloadIN, payloadOUT, endpoint, hasAnyErrors, hasDeleted);
			String logId = IntegrationLog.createLog(integrationName, externalIdList, recordTypeName, payloadIN, payloadOUT, endpoint, hasAnyErrors, hasDeleted);
			IntegrationLog.createAttachment(logId, integrationName, recordTypeName, integrationName, String.valueOf(datetimeNow), payloadIN);
		Test.stopTest();
	}
}
