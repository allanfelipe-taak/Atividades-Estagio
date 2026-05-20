@IsTest
public with sharing class IntegrationLogTest {
	@IsTest
	public static void createLogTest() {
		Datetime datetimeNow = System.now();
		String integrationName = 'Order';
		List<String> externalIdList = new List<String>{ '1000', '1001' };
		String recordTypeName = 'Inbound';
		String payloadIN = 'Class Test';
		String payloadOUT = '';
		String endpoint = '';
		Boolean hasAnyErrors = false;
		Boolean hasDeleted = false;

		Test.startTest();
			IntegrationLog.createLog(
				integrationName, externalIdList, recordTypeName, payloadIN, payloadOUT, '', endpoint, 200, hasAnyErrors, hasDeleted
			);

			String logId = IntegrationLog.createLog(
				integrationName, externalIdList, recordTypeName, payloadIN, payloadOUT, '', endpoint, 200, hasAnyErrors, hasDeleted
			);

			IntegrationLog.createAttachment(logId, integrationName, recordTypeName, integrationName, String.valueOf(datetimeNow), payloadIN);
		Test.stopTest();
	}
}
