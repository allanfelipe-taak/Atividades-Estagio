public with sharing class TemplateDefaultFields {
	public interface FieldDefaults {
		Map<String, Object> getFieldDefaults(Decimal countSObjectCreated);
	}

	public class UserDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>{
				'ExternalId__c' => '10' + countSObjectCreated,
				'Username' => 'test' + Datetime.now().getTime() +'@test.com',
				'LastName' => 'inquima',
				'Email' => 'inquima@inquima.com',
				'Alias' => 'inquima',
				'CommunityNickname' => 'inquima',
				'TimeZoneSidKey' => 'America/Sao_Paulo',
				'LocaleSidKey' => 'pt_BR',
				'EmailEncodingKey' => 'ISO-8859-1',
				'LanguageLocaleKey' => 'pt_BR'
			};
		}
	}

	public class AccountDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>{
				'Name' => 'Account - Teste',
				'CNPJ__c' => '12345678000100'
			};
		}
	}

	public class Product2Defaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>{
				'Name' => 'TA35',
				'ExternalId__c' => 'Product2' + countSObjectCreated
			};
		}
	}

	public class Pricebook2Defaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>{
				'Name' => 'Pricebook2 - Teste',
				'ExternalId__c' => 'Pricebook2' + countSObjectCreated
			};
		}
	}

	public class PricebookEntryDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>{
				'UnitPrice' => 100,
				'ExternalId__c' => 'PricebookEntry' + countSObjectCreated
			};
		}
	}

	public class OrderDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>{
				'EffectiveDate' => Date.today().addDays(2),
				'Status' => 'Draft',
				'ExternalId__c' => 'OrderExternalId' + countSObjectCreated
			};
		}
	}

	public class OrderItemDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>{
				'Quantity' => 10,
				'UnitPrice' => 100.00,
				'ExternalId__c' => 'OrderItemExternalId' + countSObjectCreated
			};
		}
	}

	public class IntegrationSettingDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>{
				'Name' => 'IntegrationSettingName',
				'Method__c' => 'POST',
				'Endpoint__c' => 'Endpoint',
				'User__c' => UserInfo.getUserName(),
				'Password__c' => UserInfo.getUserName(),
				'Timeout__c' => 110000,
				'AccessToken__c' => 'AccessToken' + String.valueOf(Datetime.now()),
				'ClientId__c' => String.valueOf(Datetime.now()),
				'ClientSecret__c' => UserInfo.getUserName() + String.valueOf(Datetime.now()),
				'EndpointAccessToken__c' => 'EndpointAccessToken',
				'AccessTokenTime__c' => 360000,
				'LastAccessTokenTime__c' => Decimal.valueOf(Datetime.now().getTime())
			};
		}
	}

	public class PaymentTermDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>{
				'Name' => 'Payment Term ' + countSObjectCreated,
				'ExternalId__c' => 'PaymentTerm' + countSObjectCreated
			};
		}
	}

	public class DistributionCenterDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>{
				'Name' => 'Distribution Center ' + countSObjectCreated,
				'ExternalId__c' => 'DistributionCenter' + countSObjectCreated
			};
		}
	}

	public class CityDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>{
				'Name' => 'City ' + countSObjectCreated
			};
		}
	}

	public class CountryDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>{
				'Name' => 'Country ' + countSObjectCreated
			};
		}
	}

	public class PaisDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>{
				'Name' => 'Pais ' + countSObjectCreated
			};
		}
	}

	public class StateDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>{
				'Name' => 'State ' + countSObjectCreated
			};
		}
	}

	public class MarginDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>();
		}
	}

	public class FreightDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>();
		}
	}

	public class TaxDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>();
		}
	}

	public class ProductHierarchyDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>{
				'Name' => 'Product Hierarchy ' + countSObjectCreated
			};
		}
	}

	public class AccountGroupDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>{
				'Name' => 'Account Group ' + countSObjectCreated
			};
		}
	}

	public class IntegrationLogDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>{
				'Name' => 'Integration Log ' + countSObjectCreated
			};
		}
	}

	public class AddressDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults(Decimal countSObjectCreated) {
			return new Map<String, Object>{
				'Name' => 'Address ' + countSObjectCreated
			};
		}
	}
}
