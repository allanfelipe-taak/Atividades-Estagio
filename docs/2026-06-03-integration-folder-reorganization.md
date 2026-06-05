# Integration Folder Reorganization

**Date:** 2026-06-03  
**Author:** Documentation Agent  
**Status:** Completed  
**Commit:** bd383da - "Reorganize Integration folder structure for better maintainability"  
**Deployment:** Successful (TaakProjetoPricing org)

---

## Overview

### Original Request
Reorganize the Integration folder structure to improve code maintainability by grouping related classes by responsibility and purpose, rather than having all 16 Apex classes in a single flat directory.

### Business Objective
Create a clear, hierarchical structure that makes it easier for developers to:
- Locate integration components by their purpose (outbound callouts, inbound APIs, data mapping, utilities, test support)
- Understand the responsibility of each class at a glance
- Maintain separation of concerns and reduce cognitive load
- Scale the integration layer as new integrations are added

### Summary
The Integration folder was reorganized from a flat structure into 5 responsibility-based subfolders, moving 16 Apex classes and all their metadata files. The restructuring maintains all functionality while improving code organization and developer experience.

---

## New Folder Structure

```
force-app/main/default/classes/Integration/
├── Callout/                          (3 classes)
│   ├── CalloutOrder.cls
│   ├── CalloutOrder.cls-meta.xml
│   ├── CalloutOrderTest.cls
│   ├── CalloutOrderTest.cls-meta.xml
│   ├── OrderRetryIntegrationAction.cls
│   └── OrderRetryIntegrationAction.cls-meta.xml
│
├── Inbound/                          (2 classes)
│   ├── IntegrationInboundOrder.cls
│   ├── IntegrationInboundOrder.cls-meta.xml
│   ├── IntegrationInboundOrderTest.cls
│   └── IntegrationInboundOrderTest.cls-meta.xml
│
├── DataMapping/                      (4 classes)
│   ├── DataIntegrationFields.cls
│   ├── DataIntegrationFields.cls-meta.xml
│   ├── TemplateDefaultFields.cls
│   ├── TemplateDefaultFields.cls-meta.xml
│   ├── FactoryDataIntegration.cls
│   ├── FactoryDataIntegration.cls-meta.xml
│   ├── FactoryDataIntegrationTest.cls
│   └── FactoryDataIntegrationTest.cls-meta.xml
│
├── Utils/                            (3 classes)
│   ├── IntegrationUtils.cls
│   ├── IntegrationUtils.cls-meta.xml
│   ├── IntegrationUtilsTest.cls
│   ├── IntegrationUtilsTest.cls-meta.xml
│   ├── IntegrationLog.cls
│   ├── IntegrationLog.cls-meta.xml
│   └── IntegrationLogTest.cls
│   └── IntegrationLogTest.cls-meta.xml
│
└── TestSupport/                      (4 classes - support utilities)
    ├── TestUtility.cls
    ├── TestUtility.cls-meta.xml
    ├── TestFactorySObject.cls
    ├── TestFactorySObject.cls-meta.xml
    ├── MockHttpResponse.cls
    └── MockHttpResponse.cls-meta.xml
```

---

## Folder Responsibilities

### 1. **Callout/** - Outbound Integration
**Purpose:** Handles outbound callouts to external ERP systems  
**Responsibility:** Managing HTTP requests, authorization, error handling, and response processing for Order-related integrations

**Classes:**
| Class Name | Type | Responsibility |
|-----------|------|-----------------|
| `CalloutOrder` | Service | Main service for executing outbound Order callouts to ERP; manages access tokens, headers, request serialization, and response parsing |
| `OrderRetryIntegrationAction` | Action | Invocable action for retry logic; handles failed integration attempts |
| `CalloutOrderTest` | Test | Unit tests for CalloutOrder service with mock responses and error scenarios |

**Key Features:**
- OAuth 2.0 token management (Client Credentials flow)
- Dynamic header generation with Bearer token authorization
- Order and OrderItem serialization for ERP payload
- Comprehensive error handling and status code management
- Integration logging for audit trail
- Flow integration via `@InvocableMethod`

**Data Flow:**
```
Flow (Invoke CalloutOrder.executeCalloutOrder)
  ↓
CalloutOrder (prepares request)
  ↓ (uses IntegrationSettings custom setting)
  ↓ (uses DataIntegrationFields for payload structure)
  ↓ (uses IntegrationUtils for HTTP execution)
  ↓
IntegrationLog (creates outbound log entry)
  ↓
Order updated with IntegrationLogOutbound__c reference
  ↓
Order Status changed to "Integrated" if successful
```

---

### 2. **Inbound/** - Inbound REST API
**Purpose:** Handles inbound REST API requests from external systems  
**Responsibility:** Receiving Order data from ERP, validating, transforming, and persisting to Salesforce

**Classes:**
| Class Name | Type | Responsibility |
|-----------|------|-----------------|
| `IntegrationInboundOrder` | REST Service | REST endpoint handler (`/services/apexrest/upsertOrder/*`); manages request deserialization, validation, and upsert operations |
| `IntegrationInboundOrderTest` | Test | Unit tests for inbound Order processing with various payload scenarios |

**Key Features:**
- RESTful endpoint for Order upsert operations
- SavePoint transaction handling for rollback capability
- OrderItem lifecycle management (deletion vs. soft delete via `DeletedProduct__c`)
- Parent-child relationship handling during upsert
- Comprehensive response structure with error details
- Integration logging with success/error tracking

**Data Flow:**
```
ERP System (sends POST to /upsertOrder/*)
  ↓
IntegrationInboundOrder.doPost()
  ↓ (deserializes JSON to OrderINData)
  ↓
FactoryDataIntegration.convertSObject()
  ↓ (validates required fields)
  ↓
IntegrationUtils.upsertRecords()
  ↓ (executes Database.upsert)
  ↓
OrderItem processing (includes child records)
  ↓
IntegrationLog (creates inbound log entry)
  ↓
Order updated with IntegrationLogInbound__c reference
  ↓
HTTP Response sent to ERP (200 or 400 with error details)
```

---

### 3. **DataMapping/** - Data Structure & Transformation
**Purpose:** Defines data contracts and transformation logic between Salesforce and external systems  
**Responsibility:** Managing JSON serialization/deserialization, field mapping, and data validation rules

**Classes:**
| Class Name | Type | Responsibility |
|-----------|------|-----------------|
| `DataIntegrationFields` | Data Model | Central data structure definition; contains all request/response DTOs and inner classes for field interfaces |
| `TemplateDefaultFields` | Utility | Template class for default field values during data transformation |
| `FactoryDataIntegration` | Factory | Factory pattern implementation; converts raw API data to Salesforce SObjects with validation |
| `FactoryDataIntegrationTest` | Test | Unit tests for data transformation and validation logic |

**Key Features:**
- Interface-based field validation (`FieldData`, `FieldDataChild`)
- Response structure abstraction (`Response`, `ResponseParent`, `ResponseParametersWrapper`)
- Order/OrderItem request/response DTOs
- AccessToken response handling
- CalloutResponse wrapper for error scenarios
- Field mapping for ExternalId, lookups, and child relationships

**Data Structures:**
```
Request Side (Outbound):
- OrderParameters (contains Order fields + OrderItemParameters list)
- OrderItemParameters (child order line items)

Request Side (Inbound):
- OrderINData (implements FieldData interface)
- OrderItemINData (implements FieldDataChild interface)

Response Side:
- CalloutResponse (wraps ERP response with error handling)
- Response / ResponseParent (parent-child structure)
- ResponseParametersWrapper (detailed response info per record)
- ResponseAccessToken (OAuth token response)
```

---

### 4. **Utils/** - Shared Utilities & Logging
**Purpose:** Provides common utilities and logging infrastructure for all integration operations  
**Responsibility:** HTTP execution, DML validation, error handling, and integration activity logging

**Classes:**
| Class Name | Type | Responsibility |
|-----------|------|-----------------|
| `IntegrationUtils` | Utility | Core integration utilities: HTTP callout execution, upsert result validation, child record handling |
| `IntegrationLog` | Service | Integration log creation and persistence; tracks all inbound/outbound integration activities |
| `IntegrationUtilsTest` | Test | Unit tests for utility methods and error scenarios |
| `IntegrationLogTest` | Test | Unit tests for log creation and retrieval |

**Key Features - IntegrationUtils:**
- `executeCallout()` - Executes HTTP requests with timeout and error handling
- `upsertRecords()` - Validates Database.UpsertResult objects and builds response list
- `upsertChildRecords()` - Handles child record upsert with parent relationship mapping
- `checkEmptyString()` - Utility method for null/empty string validation

**Key Features - IntegrationLog:**
- Creates `IntegrationLog__c` custom object records
- Tracks request/response payloads for audit
- Records error messages for troubleshooting
- Supports both inbound and outbound logging
- Records soft-delete flag for OrderItem deletions

**Integration Log Fields Tracked:**
| Field | Value | Purpose |
|-------|-------|---------|
| `SObjectType__c` | "Order" | Type of object being integrated |
| `ExternalIds__c` | Comma-separated list | External references for audit |
| `IntegrationType__c` | "Inbound" or "Outbound" | Direction of integration |
| `Request__c` | JSON payload | Original request for troubleshooting |
| `Response__c` | JSON/text response | System response for validation |
| `ErrorMessage__c` | Error text | Failure details if applicable |
| `Endpoint__c` | URL | Integration endpoint used |
| `StatusCode__c` | HTTP status | Response status code |
| `HasError__c` | Boolean | Error flag for filtering |
| `HasDeletedItems__c` | Boolean | Soft-delete flag for OrderItems |

---

### 5. **TestSupport/** - Test Utilities & Mocks
**Purpose:** Provides shared test infrastructure and mock objects  
**Responsibility:** Supporting unit test execution with factory methods and HTTP mocking

**Classes:**
| Class Name | Type | Responsibility |
|-----------|------|-----------------|
| `TestUtility` | Test Support | Utility methods for test setup and assertions |
| `TestFactorySObject` | Test Factory | Factory for creating test SObjects with realistic data |
| `MockHttpResponse` | Mock Class | Mock implementation of HttpResponse for testing HTTP integrations |

**Key Features:**
- Reduces test boilerplate by centralizing common setup
- Provides realistic test data generation
- Enables testing of HTTP callouts without actual external calls
- Supports testing both success and failure scenarios
- Reusable across all integration test classes

---

## Component Details

### Callout Folder Components

#### CalloutOrder.cls
**Type:** Service Class (with sharing)  
**Main Method:** `executeCalloutOrder(List<String> orderIdList)`  
**Invocable:** Yes (can be called from Flows)

**Key Methods:**
```apex
+ executeCalloutOrder(List<String>) : List<FlowOutput>    // Main invocable entry point
- handlerAccessToken(AccessTokenLog) : IntegrationSettings
- getAccessToken(IntegrationSettings, AccessTokenLog) : IntegrationSettings
- fillHeader(IntegrationSettings) : Map<String, String>
- getOrders(List<String>) : List<Order>
- fillOrderRequestList(List<Order>) : List<OrderParameters>
- fillCalloutResponse(HttpResponse) : CalloutResponse
- handlerError(CalloutResponse) : String
- updateSObjectWithIntegrationLogId(List<SObject>, String, String) : void
- updateIntegrationSetting(IntegrationSettings) : void
- createTokenLog(...) : void
```

**Order Update Logic:**
- Sets `Status = 'Integrated'` only when callout succeeds with no errors
- Updates `IntegrationLogOutbound__c` with log reference
- Updates access token in custom setting if refresh occurred

**Authorization:**
- Uses OAuth 2.0 Client Credentials flow
- Retrieves access token from `IntegrationSetting__c` custom setting
- Caches tokens with configurable expiry time
- Automatic token refresh when expired

---

#### OrderRetryIntegrationAction.cls
**Type:** Invocable Action  
**Purpose:** Provides retry mechanism for failed integration attempts

**Integration:** Works with Flow for manual or automated retry logic

---

### Inbound Folder Components

#### IntegrationInboundOrder.cls
**Type:** REST Service (with sharing)  
**Endpoint:** `/services/apexrest/upsertOrder/*`  
**Method:** POST

**Key Methods:**
```apex
+ doPost(List<OrderINData>) : void                        // @HttpPost endpoint handler
- fillOrderItemListToUpsert(...) : List<OrderItemINData>
- upsertOrderItem(...) : void
- deletedOrderItem(...) : Boolean                         // Soft-delete OrderItems
- fillResponseList(...) : Boolean
- getErrors(List<Response>) : String
- updateOrderWithIntegrationLogId(...) : void
```

**Processing Flow:**
1. Receives JSON payload with Order and OrderItem data
2. Sets SavePoint for transaction safety
3. Converts OrderINData to Order SObjects via factory
4. Performs Database.upsert on Orders (external ID: `ExternalId__c`)
5. Handles OrderItem upsert with parent relationship
6. Soft-deletes orphaned OrderItems (sets `DeletedProduct__c = true`)
7. Builds response structure with success/error details
8. Creates integration log record
9. Returns HTTP 200 (success) or 400 (errors)

**OrderItem Soft Delete Logic:**
- Finds OrderItems with external IDs not in current payload
- Marks them with `DeletedProduct__c = true` instead of deletion
- Preserves audit trail and prevents cascading deletes

---

### DataMapping Folder Components

#### DataIntegrationFields.cls
**Type:** Data Model Class (global with sharing)  
**Purpose:** Single source of truth for all integration data structures

**Inner Classes & Interfaces:**

**Interfaces:**
- `FieldData` - Contract for order-level data objects
- `FieldDataChild` - Contract for child record objects (OrderItem)

**Request DTOs (Outbound):**
- `OrderParameters` - Maps Order to ERP payload
- `OrderItemParameters` - Maps OrderItem to ERP payload
- `RequestList` - Wraps list of OrderParameters
- `Request` - Wraps single OrderParameters

**Request DTOs (Inbound):**
- `OrderINData` - Deserializes inbound Order JSON (implements FieldData)
- `OrderItemINData` - Deserializes inbound OrderItem JSON (implements FieldDataChild)

**Response DTOs:**
- `CalloutResponse` - Wraps outbound HTTP responses
- `Response` - Base class for inbound responses
- `ResponseParent` - Parent response with items collection
- `ResponseParametersWrapper` - Individual record response details
- `RequestResponseObject` - Generic request/response wrapper

**AccessToken DTOs:**
- `ResponseAccessToken` - OAuth token response structure

**Required Fields for Orders:**
```
Outbound: ExternalId__c, EffectiveDate, Status, Account, Pricebook2
Inbound:  ExternalId__c, EffectiveDate, Status, Account, Pricebook2
```

**Required Lookups:**
```
Order:
  - AccountId (via Account.ExternalId__c)
  - Pricebook2Id (via Pricebook2.ExternalId__c)
  - PaymentTerm__r.ExternalId__c (PaymentConditions)
  - DistributionCenter__r.ExternalId__c
  - Address__r.ExternalId__c

OrderItem:
  - OrderId (via Order.ExternalId__c)
  - Product2Id (via Product2.ExternalId__c)
  - PricebookEntryId (via PricebookEntry.ExternalId__c)
```

---

#### FactoryDataIntegration.cls
**Type:** Factory Pattern Implementation  
**Purpose:** Converts raw API data to validated Salesforce SObjects

**Key Methods:**
```apex
+ convertSObject(SObject, String, List<FieldData>, List<Response>, List<SObject>, List<String>) : void
+ convertSObjectChild(SObject, String, List<FieldDataChild>, Map<String, List<Response>>, List<SObject>) : void
```

**Validation Process:**
1. Checks required fields are present and non-empty
2. Validates lookup field references can be resolved
3. Handles ExternalId normalization (uppercase conversion)
4. Maps child objects to parent via external ID
5. Builds comprehensive response with error details

**Error Handling:**
- Missing required field → Validation error in response
- Invalid lookup reference → Relationship error
- Empty external ID → Validation error

---

#### TemplateDefaultFields.cls
**Type:** Utility Class  
**Purpose:** Provides default values for fields during transformation

**Use Cases:**
- Setting default status values
- Providing standard field values for partial updates
- Template-based field mapping

---

### Utils Folder Components

#### IntegrationUtils.cls
**Type:** Utility Service (with sharing)  
**Purpose:** Shared integration utilities

**Key Methods:**
```apex
+ checkEmptyString(Object) : Boolean
+ executeCallout(String, String, Map<String,String>, String, Integer) : HttpResponse
+ upsertRecords(List<UpsertResult>, List<Response>, List<SObject>, SObjectField) : Boolean
+ upsertChildRecords(List<UpsertResult>, Map<String,List<Response>>, List<SObject>, Map<String,String>, SObjectField) : void
```

**executeCallout() Details:**
```apex
Parameters:
  - endpoint: String (target URL)
  - body: String (JSON payload)
  - headers: Map<String, String> (HTTP headers)
  - method: String ('GET', 'POST', etc.)
  - timeout: Integer (milliseconds)

Returns:
  - HttpResponse with status and body

Behavior:
  - Creates HttpRequest with provided parameters
  - Executes via Http.send()
  - Returns response or throws exception on network failure
```

**upsertRecords() Details:**
- Validates each UpsertResult
- Maps results to original SObjects
- Builds Response objects with Salesforce IDs
- Handles error messages for failed records
- Supports external ID tracking

**upsertChildRecords() Details:**
- Similar to upsertRecords but handles parent relationships
- Maps child records to parent via external ID mapping
- Stores responses in Map keyed by parent ID
- Enables parent-child response hierarchies

---

#### IntegrationLog.cls
**Type:** Service Class (with sharing)  
**Purpose:** Creates and manages integration audit logs

**Key Method:**
```apex
+ createLog(
    String sObjectType,
    List<String> externalIds,
    String integrationType,        // 'Inbound' or 'Outbound'
    String request,
    String response,
    String errorMessage,
    String endpoint,
    Integer statusCode,
    Boolean hasError,
    Boolean hasDeletedItems
  ) : String  // Returns log ID
```

**Log Structure:**
Creates a record in custom object `IntegrationLog__c` with:
- Type of object being integrated
- External IDs for traceability
- Full request/response payloads (stored as text)
- Error messages if applicable
- HTTP endpoint and status codes
- Error flag for quick filtering
- Soft-delete indicator for OrderItem operations

**Query Capabilities:**
- Filter by SObjectType__c
- Filter by IntegrationType__c ('Inbound'/'Outbound')
- Find errors via HasError__c = true
- Trace via ExternalIds__c

---

### TestSupport Folder Components

#### TestUtility.cls
**Type:** Test Utility  
**Purpose:** Common test setup and assertion methods

**Typical Methods:**
- Test data creation helpers
- Mock setup utilities
- Common assertion methods
- Test context initialization

---

#### TestFactorySObject.cls
**Type:** Test Factory  
**Purpose:** Factory for creating realistic test SObjects

**Capabilities:**
- Creates Orders with all required fields
- Creates OrderItems with parent references
- Generates external IDs
- Provides customizable test data

**Benefits:**
- Reduces test boilerplate
- Ensures consistency across tests
- Easy to maintain when object structure changes
- Supports parameterized test data creation

---

#### MockHttpResponse.cls
**Type:** Mock Class  
**Purpose:** Simulates HTTP responses for testing

**Features:**
- Implements HttpResponse interface behavior
- Allows setting custom status codes
- Supports custom response bodies
- Enables testing error scenarios
- Used by all Callout tests

**Example Usage:**
```apex
MockHttpResponse mockResponse = new MockHttpResponse();
mockResponse.setStatusCode(200);
mockResponse.setBody('{"success": true}');
// Use in test context for HTTP callout testing
```

---

## How to Add New Integration Components

### Scenario 1: Adding a New Outbound Integration (e.g., ShipmentCallout)

1. **Create the Service Class** in `Callout/`:
   ```apex
   // force-app/main/default/classes/Integration/Callout/ShipmentCallout.cls
   public with sharing class ShipmentCallout {
       @InvocableMethod(label='Send Shipment to ERP')
       public static List<FlowOutput> executeCallout(List<String> shipmentIdList) {
           // Implementation using IntegrationUtils.executeCallout()
       }
   }
   ```

2. **Add Data Structures** to `DataMapping/DataIntegrationFields.cls`:
   ```apex
   global class ShipmentParameters {
       public String externalId;
       public String trackingNumber;
       // ... other fields
   }
   ```

3. **Create Tests** in `Callout/`:
   ```apex
   @IsTest
   public class ShipmentCalloutTest {
       // Test methods using TestFactorySObject for test data
   }
   ```

4. **Update IntegrationLog** calls to track shipment integrations:
   ```apex
   IntegrationLog.createLog('Shipment', externalIds, 'Outbound', ...);
   ```

---

### Scenario 2: Adding a New Inbound Integration (e.g., InvoiceInbound)

1. **Create the REST Service** in `Inbound/`:
   ```apex
   // force-app/main/default/classes/Integration/Inbound/InvoiceInbound.cls
   @RestResource(urlMapping='/upsertInvoice/*')
   global with sharing class InvoiceInbound {
       @HttpPost
       global static void doPost(List<InvoiceINData> invoiceRequestList) {
           // Follow IntegrationInboundOrder pattern
       }
   }
   ```

2. **Add Data Structures** to `DataMapping/DataIntegrationFields.cls`:
   ```apex
   global class InvoiceINData implements FieldData {
       // Implement interface methods
   }
   ```

3. **Create Tests** in `Inbound/`:
   ```apex
   @IsTest
   public class InvoiceInboundTest {
       // REST endpoint test using MockHttpResponse
   }
   ```

---

### Scenario 3: Adding Test Utilities

1. Add helper methods to `TestSupport/TestUtility.cls`:
   ```apex
   public static Order createTestOrder(String externalId) {
       // Reusable test order creation
   }
   ```

2. Add factory methods to `TestSupport/TestFactorySObject.cls`:
   ```apex
   public static Invoice__c createTestInvoice() {
       // Factory for new custom objects
   }
   ```

---

## Folder Navigation Guide

### For Developers Adding Features

**Adding Outbound Integration?** → Go to `Callout/`
- Review `CalloutOrder.cls` for pattern
- Use `DataIntegrationFields.cs` for request/response structure
- Use `IntegrationUtils.executeCallout()` for HTTP
- Log with `IntegrationLog.createLog()`

**Adding Inbound Integration?** → Go to `Inbound/`
- Review `IntegrationInboundOrder.cls` for pattern
- Define DTOs in `DataMapping/DataIntegrationFields.cls`
- Use `FactoryDataIntegration` for validation/conversion
- Use `IntegrationUtils.upsertRecords()` for DML
- Log with `IntegrationLog.createLog()`

**Need Shared Data Structures?** → Go to `DataMapping/`
- Add DTOs to `DataIntegrationFields.cls`
- Add factory methods to `FactoryDataIntegration.cls`
- Add templates to `TemplateDefaultFields.cls` if needed

**Need Utilities?** → Go to `Utils/`
- Add methods to `IntegrationUtils.cls` for HTTP/DML
- Use `IntegrationLog` for all logging

**Writing Tests?** → Go to `TestSupport/`
- Use `TestFactorySObject` for test data
- Use `MockHttpResponse` for HTTP mocking
- Add reusable methods to `TestUtility`

---

## Code Organization Principles

### 1. Single Responsibility
Each folder has a clear, single responsibility:
- `Callout/` → Outbound integrations only
- `Inbound/` → REST endpoints only
- `DataMapping/` → Data transformation only
- `Utils/` → Shared utilities only
- `TestSupport/` → Test infrastructure only

### 2. No Cross-Folder Imports (Best Practice)
- `Callout/` imports from: `DataMapping/`, `Utils/`, optionally `TestSupport/`
- `Inbound/` imports from: `DataMapping/`, `Utils/`, optionally `TestSupport/`
- `DataMapping/` is standalone (no folder imports)
- `Utils/` imports from: `DataMapping/` only
- `TestSupport/` is standalone (no folder imports)

### 3. Naming Conventions
- **Services:** Verb + Noun (e.g., `CalloutOrder`, `IntegrationInboundOrder`)
- **Data Models:** Noun + Type (e.g., `DataIntegrationFields`, `OrderINData`)
- **Utilities:** Noun (e.g., `IntegrationUtils`, `IntegrationLog`)
- **Factories:** Factory + Noun (e.g., `FactoryDataIntegration`)
- **Tests:** Class + Test (e.g., `CalloutOrderTest`)
- **Mocks:** Mock + Type (e.g., `MockHttpResponse`)

### 4. File Location Rules
```
Classes + Tests Stay Together:
  Callout/
    ├── CalloutOrder.cls
    ├── CalloutOrderTest.cls
    ├── OrderRetryIntegrationAction.cls
    └── (OrderRetryTest.cls if it has tests)

All Metadata Lives with Class:
  ├── CalloutOrder.cls
  └── CalloutOrder.cls-meta.xml
```

---

## Integration Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    SALESFORCE ORGANIZATION                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────┐      ┌──────────────────────────┐ │
│  │   OUTBOUND FLOW          │      │   INBOUND FLOW           │ │
│  ├──────────────────────────┤      ├──────────────────────────┤ │
│  │                          │      │                          │ │
│  │  1. Flow triggers        │      │  1. ERP sends POST req   │ │
│  │     CalloutOrder         │      │     to /upsertOrder/*    │ │
│  │     @InvocableMethod     │      │                          │ │
│  │            │             │      │         ▼                │ │
│  │            ▼             │      │                          │ │
│  │  2. Gets OAuth token     │      │  2. IntegrationInbound   │ │
│  │     from custom setting  │      │     Order.doPost() fires │ │
│  │            │             │      │         ▼                │ │
│  │            ▼             │      │                          │ │
│  │  3. Queries Orders       │      │  3. Factory validates    │ │
│  │     (with all lookups)   │      │     & converts to SObj   │ │
│  │            │             │      │         ▼                │ │
│  │            ▼             │      │                          │ │
│  │  4. DataIntegrationFields│      │  4. IntegrationUtils     │ │
│  │     builds OrderParams   │      │     upserts Records      │ │
│  │     payload              │      │         ▼                │ │
│  │            │             │      │                          │ │
│  │            ▼             │      │  5. IntegrationLog       │ │
│  │  5. IntegrationUtils     │      │     creates audit record │ │
│  │     .executeCallout()    │      │         ▼                │ │
│  │            │             │      │                          │ │
│  │            ▼             │      │  6. Updates Order with   │ │
│  │ ┌────────────────────┐   │      │     IntegrationLogInb... │ │
│  │ │ EXTERNAL ERP SYSTEM│   │      │         ▼                │ │
│  │ └────────────────────┘   │      │                          │ │
│  │            │             │      │  7. Returns 200 or 400   │ │
│  │            ▼             │      │     with response details│ │
│  │  6. IntegrationLog       │      │                          │ │
│  │     creates audit record │      └──────────────────────────┘ │
│  │            │             │                                   │
│  │            ▼             │                                   │
│  │  7. Updates Order with   │                                   │
│  │     IntegrationLogOutb.. │                                   │
│  │            │             │                                   │
│  │            ▼             │                                   │
│  │  8. Order Status →       │                                   │
│  │     "Integrated"         │                                   │
│  │                          │                                   │
│  └──────────────────────────┘                                   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  SHARED INFRASTRUCTURE (Utils/ & TestSupport/)           │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │  • IntegrationUtils - HTTP & DML operations              │  │
│  │  • IntegrationLog - Audit trail for all integrations     │  │
│  │  • TestFactorySObject - Test data generation             │  │
│  │  • MockHttpResponse - HTTP mocking for tests             │  │
│  │  • TestUtility - Common test utilities                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  DATA STRUCTURES (DataMapping/)                          │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │  • DataIntegrationFields - All DTOs & interfaces         │  │
│  │  • FactoryDataIntegration - Validation & conversion      │  │
│  │  • TemplateDefaultFields - Default field values          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Testing Strategy

### Test Class Locations
- **Callout Tests** → `Integration/Callout/CalloutOrderTest.cls`
- **Inbound Tests** → `Integration/Inbound/IntegrationInboundOrderTest.cls`
- **Factory Tests** → `Integration/DataMapping/FactoryDataIntegrationTest.cls`
- **Utility Tests** → `Integration/Utils/IntegrationUtilsTest.cls`, `IntegrationLogTest.cls`

### Test Coverage Guidelines
- **Service Classes (Callout, Inbound):** Minimum 80% coverage
- **Utilities:** Minimum 75% coverage
- **Data Models:** Minimum 70% coverage

### Testing Approach
1. Use `TestFactorySObject` to create test data
2. Use `MockHttpResponse` for HTTP response simulation
3. Test both success and failure scenarios
4. Test error message handling and response structures
5. Verify IntegrationLog creation and updates

### Example Test Pattern
```apex
@IsTest
public class CalloutOrderTest {
    @IsTest
    static void testSuccessfulCallout() {
        // Setup
        Order testOrder = TestFactorySObject.createTestOrder();
        MockHttpResponse mockResponse = new MockHttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"success": true}');
        
        // Execute
        Test.setMock(HttpCalloutMock.class, mockResponse);
        List<CalloutOrder.FlowOutput> results = 
            CalloutOrder.executeCalloutOrder(new List<String>{testOrder.Id});
        
        // Verify
        Assert.isFalse(results[0].hasError);
    }
}
```

---

## File Locations Summary

| Component | Location |
|-----------|----------|
| Outbound Services | `force-app/main/default/classes/Integration/Callout/` |
| Outbound Tests | `force-app/main/default/classes/Integration/Callout/*Test.cls` |
| Inbound Services | `force-app/main/default/classes/Integration/Inbound/` |
| Inbound Tests | `force-app/main/default/classes/Integration/Inbound/*Test.cls` |
| Data Models | `force-app/main/default/classes/Integration/DataMapping/` |
| Data Tests | `force-app/main/default/classes/Integration/DataMapping/*Test.cls` |
| Utilities | `force-app/main/default/classes/Integration/Utils/` |
| Utility Tests | `force-app/main/default/classes/Integration/Utils/*Test.cls` |
| Test Support | `force-app/main/default/classes/Integration/TestSupport/` |
| Metadata Files | Same folder as `.cls` file with `.cls-meta.xml` extension |

---

## Migration Notes

### What Changed
- Flat structure (16 files in root) → Organized structure (5 subfolders)
- No functional changes to any integration logic
- All class names and public methods remain unchanged
- All imports and references remain valid (folder structure is internal)

### What Stayed the Same
- Public API of all classes unchanged
- Method signatures unchanged
- Custom object references unchanged
- Flow integration unchanged
- REST endpoint URLs unchanged

### Deployment
- Successful deployment to TaakProjetoPricing org (2026-06-03)
- No breaking changes
- All existing integrations continue to work
- No configuration changes required

---

## Future Enhancements

### Potential Additions to Callout/
- Batch job for retry queue processing
- Webhook-based retry notification
- Callout timeout/retry configuration UI
- Multi-endpoint support for A/B testing

### Potential Additions to Inbound/
- Webhook signature validation
- Request rate limiting
- Duplicate payload detection
- Async processing for large payloads

### Potential Additions to DataMapping/
- Version management for data contracts
- Field mapping configuration UI
- Custom validation rule engine
- Transformation template library

### Potential Additions to Utils/
- Encryption for sensitive fields in logs
- Log retention/cleanup automation
- Integration dashboard with KPIs
- Retry queue management

### Potential Additions to TestSupport/
- Performance testing utilities
- Load testing data generators
- Contract testing support
- Integration environment setup helpers

---

## Dependencies & Related Objects

### Custom Objects
- **Order** (Standard object with custom fields):
  - `ExternalId__c` - External identifier for ERP
  - `IntegrationLogOutbound__c` - Reference to outbound log
  - `IntegrationLogInbound__c` - Reference to inbound log
  - `DeliveryDate__c` - Delivery date
  - `FreightType__c` - Freight classification
  - Other custom fields (DistributionCenter__c, PaymentTerm__c, Address__c)

- **OrderItem** (Standard object with custom fields):
  - `ExternalId__c` - External identifier for ERP
  - `DeletedProduct__c` - Soft-delete flag

- **IntegrationLog__c** (Custom object):
  - Tracks all integration activities
  - Stores request/response payloads
  - Records errors and status codes

- **IntegrationSetting__c** (Custom Setting):
  - Stores ERP endpoint configuration
  - Stores OAuth credentials
  - Stores access tokens and expiry times

### Custom Settings
- **IntegrationSetting__c:**
  - `Endpoint__c` - ERP API endpoint
  - `EndpointAccessToken__c` - OAuth token endpoint
  - `ClientId__c` - OAuth client ID
  - `ClientSecret__c` - OAuth client secret
  - `AccessToken__c` - Current access token
  - `LastAccessTokenTime__c` - Token issuance timestamp
  - `AccessTokenTime__c` - Token TTL in milliseconds
  - `Timeout__c` - HTTP request timeout

### Related Metadata
- REST Endpoint: `/services/apexrest/upsertOrder/*`
- Flow: Outbound order integration flow (uses CalloutOrder)

---

## Support & Troubleshooting

### Common Issues

**Issue: Integration fails with "Endpoint not configured"**
- Check IntegrationSetting__c custom setting exists
- Verify Endpoint__c and EndpointAccessToken__c are populated
- Verify ClientId__c and ClientSecret__c are set

**Issue: OAuth token refresh fails**
- Verify EndpointAccessToken__c is correct OAuth endpoint
- Verify ClientId__c and ClientSecret__c are current
- Check API credentials haven't been revoked in ERP

**Issue: Order upsert fails with lookup errors**
- Verify Account.ExternalId__c matches ERP data
- Verify Pricebook2.ExternalId__c is populated
- Verify DistributionCenter__c and PaymentTerm__c lookups exist
- Check field-level security on lookup fields

**Issue: Missing required fields error**
- Review IntegrationLog__c.ErrorMessage__c for details
- Verify DataIntegrationFields requires list vs. actual payload
- Ensure external system is sending all required fields

### Debugging Steps

1. **Check IntegrationLog records:**
   ```
   - Filter by SObjectType__c = 'Order'
   - Filter by IntegrationType__c = 'Outbound' or 'Inbound'
   - Review ErrorMessage__c for specific failures
   - Review Request__c and Response__c fields for payload issues
   ```

2. **Monitor Token Refresh:**
   ```
   - Check IntegrationSetting__c.LastAccessTokenTime__c
   - Verify token is being refreshed before expiry
   - Monitor token endpoint response in logs
   ```

3. **Test Callout Directly:**
   ```apex
   // In Apex Execute window
   List<String> orderIds = new List<String>{'001XXXXXXXXXXXXXXX'};
   List<CalloutOrder.FlowOutput> results = 
       CalloutOrder.executeCalloutOrder(orderIds);
   System.debug('Results: ' + results);
   ```

4. **Test REST Endpoint:**
   ```
   - Use cURL or Postman to test /upsertOrder/*
   - Send sample OrderINData JSON payload
   - Verify 200 or 400 response with details
   ```

---

## Change History

| Date | Author | Change | Scope |
|------|--------|--------|-------|
| 2026-06-03 | Integration Team | Reorganized Integration folder into 5 subfolders by responsibility | Structure only |
| | | Moved 16 classes from flat to hierarchical structure | Code organization |
| | | Created clear separation: Callout, Inbound, DataMapping, Utils, TestSupport | Best practices |
| | | Updated documentation for new structure | Guidance |

---

## Additional Resources

### Related Documentation
- Order Integration API: `/services/apexrest/upsertOrder/*`
- IntegrationSetting__c Custom Setting Setup
- Order Object Field Reference
- Salesforce API Version 65.0 Docs

### Team Communication
- Questions about structure → Review "Folder Responsibilities" section
- Adding new integration → Review "How to Add New Integration Components"
- Troubleshooting issues → Review "Support & Troubleshooting" section

---

**Documentation Completed:** 2026-06-03  
**Last Updated:** 2026-06-03  
**Status:** Active and Current
