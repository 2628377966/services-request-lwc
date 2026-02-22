/*
* Test Schema Util functions
 */
@IsTest
public class SchemaUtilTest {
    private static final String ACCOUNT_RECORD_TYPE_NAME = 'Merchant';
    /**
     * Test CreateObject function
     */
    @IsTest
    static void testCreateObject() {
        sObject testSObject;
        Test.startTest();
        testSObject = SchemaUtil.createObject('Account');
        Test.stopTest();
        System.assert(testSObject != null);
    }

    /**
     * Test CreateObjectType function
     */
    @IsTest
    static void testCreateObjectType() {
        SObjectType type;
        Test.startTest();
        type = SchemaUtil.createObjectType('Account');
        Test.stopTest();
        System.assertEquals('Account', type.getDescribe().getName());
    }

    /**
     * Test CreateDescribeSObjectResult function
     */
    @IsTest
    static void testCreateDescribeSObjectResult() {
        DescribeSObjectResult result;
        SObjectType type = SchemaUtil.createObjectType('Contact');
        Test.startTest();
        result = SchemaUtil.createDescribeSObjectResult(type);
        Test.stopTest();
        System.assertEquals('Contact', result.getName());
    }

    /**
     * Test GetDescribeSObjectResult function
     */
    @IsTest
    static void testGetDescribeSObjectResult() {
        DescribeSObjectResult result;
        Test.startTest();
        result = SchemaUtil.getDescribeSObjectResult('Account');
        Test.stopTest();
        System.assertEquals('Account', result.getName());
    }
    /**
     * Test GetSObjectTypeMap function
     */
    @IsTest
    static void testGetSObjectTypeMap() {
        Map<String,SObjectType> typeMap = new Map<String, SObjectType>();
        Test.startTest();
        typeMap = SchemaUtil.getSObjectTypeMap();
        Test.stopTest();
        System.assert(typeMap != null && !typeMap.isEmpty());
    }

    /**
     * Test GetSObjectFieldMap function
     */
    @IsTest
    static void testGetSObjectFieldMap() {
        Map<String, Schema.SObjectField> fieldMap;
        Test.startTest();
        fieldMap = SchemaUtil.getSObjectFieldMap(SchemaUtil.createObjectType('Account'));
        Test.stopTest();
        System.assert(fieldMap != null && !fieldMap.isEmpty());
        System.assert(fieldMap.containsKey('AccountNumber'));
    }

    /**
     * Test GetSObjectFieldNames function
     */
    @IsTest
    static void testGetSObjectFieldNames() {
        List<String> fieldNameList;
        Test.startTest();
        fieldNameList = SchemaUtil.getSObjectFieldNames(SchemaUtil.createObjectType('Account'));
        Test.stopTest();
        System.assert(fieldNameList != null && !fieldNameList.isEmpty());
    }

    /**
     * Test GetObjectTypeNames function
     */
    @IsTest
    static void testGetObjectTypeNames() {
        List<String> objectTypeNameList;
        Test.startTest();
        objectTypeNameList = SchemaUtil.getObjectTypeNames();
        Test.stopTest();
        System.assert(objectTypeNameList != null && !objectTypeNameList.isEmpty());
    }

    /**
     * Test FindAllFieldNames function
     */
    @IsTest
    static void testFindAllFieldNames() {
        String fieldNames;
        Test.startTest();
        fieldNames = SchemaUtil.findAllFieldNames(SchemaUtil.createObjectType('Contact'));
        Test.stopTest();
        System.assert(fieldNames != null && fieldNames.contains(', '));
    }

    /**
    * Test BuildGeneralDatabaseQuery function
    */
    @IsTest
    static void testBuildGeneralDatabaseQuery() {
        String query;
        Test.startTest();
        query = SchemaUtil.buildGeneralDatabaseQuery('Contact');
        Test.stopTest();
        System.assert(query != null && query.startsWith('select'));
    }

    @IsTest
    static void testIsFieldExist() {
        SObjectType sObjectType = Account.getSObjectType();
        String fieldName = 'Name';
        Test.startTest();
        Boolean isValid = SchemaUtil.isFieldExist(sObjectType, fieldName);
        Test.stopTest();
        System.assertEquals(true, isValid);
    }

    @IsTest
    static void testBuildIdsString() {
        List<Contact> contactList = Database.query(SchemaUtil.buildGeneralDatabaseQuery(Contact.getSObjectType()));
        Set<Id> ids = new Set<Id>();
        String idsString;
        Test.startTest();
        if (contactList != null && !contactList.isEmpty()) {
            for(Contact contact : contactList) {
                ids.add(contact.Id);
            }
        }
        idsString = SchemaUtil.buildIdsString(ids);
        Test.stopTest();

        if (contactList != null && !contactList.isEmpty()) {
            System.assertEquals(true, (idsString.contains('(') && idsString.contains(')')));
        } else {
            System.assertEquals(true, String.isBlank(idsString));
        }
    }

    @IsTest
    static void testGetSelfSObjectRecord() {
        List<Account> accountList = Database.query(SchemaUtil.buildGeneralDatabaseQuery(Account.getSObjectType()));
        List<Contact> contactList = Database.query(SchemaUtil.buildGeneralDatabaseQuery(Contact.getSObjectType()));

        if (accountList != null && !accountList.isEmpty() && contactList != null && !contactList.isEmpty()) {
            Test.startTest();
            SObject selfSObject = SchemaUtil.getSelfSObjectRecord(accountList[0].Id, Account.getSObjectType());
            Test.stopTest();
            System.assertNotEquals(null, selfSObject);
            System.assertEquals(String.valueOf(accountList[0].Id), String.valueOf(selfSObject.get('Id')));
        }
    }

    @IsTest
    static void testGetParentSObjectRecord() {
        List<Account> accountList = Database.query(SchemaUtil.buildGeneralDatabaseQuery(Account.getSObjectType()));
        List<Contact> contactList = Database.query(SchemaUtil.buildGeneralDatabaseQuery(Contact.getSObjectType()));

        if (accountList != null && !accountList.isEmpty() && contactList != null && !contactList.isEmpty()) {
            Test.startTest();
            SObject parentSObject = SchemaUtil.getParentSObjectRecord(contactList[0].Id, Account.getSObjectType());
            Test.stopTest();
            System.assertNotEquals(null, parentSObject);
            System.assertEquals(String.valueOf(contactList[0].AccountId), String.valueOf(parentSObject.get('Id')));
        }
    }

    @IsTest
    static void testGetChildSObjectRecord() {
        List<Account> accountList = Database.query(SchemaUtil.buildGeneralDatabaseQuery(Account.getSObjectType()));
        List<Contact> contactList = Database.query(SchemaUtil.buildGeneralDatabaseQuery(Contact.getSObjectType()));

        if (accountList != null && !accountList.isEmpty() && contactList != null && !contactList.isEmpty()) {
            Test.startTest();
            List<SObject> childSObjects = SchemaUtil.getChildSObjectRecords(accountList[0].Id, Contact.getSObjectType(), '');
            Test.stopTest();
            System.assertNotEquals(true, childSObjects.isEmpty());
            System.assertEquals(String.valueOf(contactList[0].Id), String.valueOf(childSObjects[0].get('Id')));
        }
    }

    @IsTest
    static void testGetPickListTypeFieldEntries() {
        List<Schema.PickListEntry> picklistEntries = SchemaUtil.getPickListTypeFieldEntries(Case.getSObjectType(), 'Status');
        System.assertEquals(true, (picklistEntries != null && !picklistEntries.isEmpty()));
    }

    @IsTest
    static void testGetFieldDisplayType() {
        Test.startTest();
        String displayType = SchemaUtil.getFieldDisplayType(Account.getSObjectType(), 'BillingAddress');
        Test.stopTest();
        System.assertEquals('ADDRESS', displayType);
    }

    @IsTest
    static void testGetSObjectLabelAndNameFromId() {
        List<Account> accountList = Database.query(SchemaUtil.buildGeneralDatabaseQuery(Account.getSObjectType()));
        if (accountList != null && !accountList.isEmpty()) {
            Test.startTest();
            Account account = accountList[0];
            String label = SchemaUtil.getSObjectLabelFromId(account.Id);
            String name = SchemaUtil.getSObjectNameFromId(account.Id);
            String recordName = SchemaUtil.getRecordNameFromId(account.Id);
            Test.stopTest();
            System.assertEquals(true, String.isNotBlank(label));
            System.assertEquals(true, String.isNotBlank(name));
            System.assertEquals(true, String.isNotBlank(recordName));
        }
    }

    @IsTest
    static void testGetFieldLabels() {
        Test.startTest();
        Map<String, String> fieldLabels = SchemaUtil.getFieldLabels('Account');
        Test.stopTest();
        System.assertEquals(false, fieldLabels.isEmpty());
    }

    @IsTest
    static void testSObjectFieldList() {
        Test.startTest();
        List<Schema.SObjectField> fieldList = SchemaUtil.getSObjectFieldList(Account.getSObjectType());
        Test.stopTest();
        System.assertEquals(false, fieldList.isEmpty());
    }

    @IsTest
    static void testIsFieldContainedBySObject() {
        Test.startTest();
        Boolean isFieldContainedBySObject = SchemaUtil.isFieldContainedBySObject(Account.getSObjectType(), 'Name');
        Test.stopTest();
        System.assertEquals(true, isFieldContainedBySObject);
    }

    @IsTest
    static void testIsFieldEditable() {
        Test.startTest();
        Boolean isFieldEditable = SchemaUtil.isFieldEditable(Account.getSObjectType(), 'Name');
        Test.stopTest();
        System.assertEquals(true, isFieldEditable);
    }

    @IsTest
    static void testIsFieldUpdateable() {
        Test.startTest();
        Boolean isFieldUpdateable = SchemaUtil.isFieldUpdateable(Account.getSObjectType(), 'Name');
        Test.stopTest();
        System.assertEquals(true, isFieldUpdateable);
    }

    @IsTest
    static void testConvertStringBasedOnFieldDisplayType() {
        List<Account> accountList = Database.query(SchemaUtil.buildGeneralDatabaseQuery(Account.getSObjectType()));
        List<Contact> contactList = Database.query(SchemaUtil.buildGeneralDatabaseQuery(Contact.getSObjectType()));
        List<String> accountFieldNameList = SchemaUtil.getSObjectFieldNames(Account.getSObjectType());
        List<String> contactFieldNameList = SchemaUtil.getSObjectFieldNames(Contact.getSObjectType());
        if (accountList != null && !accountList.isEmpty() && contactList != null && !contactList.isEmpty()) {
            Test.startTest();
            for (String  fieldName : accountFieldNameList) {
                String fieldValueString = SchemaUtil.convertObjectToStringBasedOnFieldDisplayType(Account.getSObjectType(), fieldName, accountList[0].get(fieldName));
                Object castedFieldValue = SchemaUtil.convertStringBasedOnFieldDisplayType(Account.getSObjectType(),fieldName, fieldValueString);
                if (String.isNotBlank(fieldValueString)) {
                    System.assertEquals(true, castedFieldValue != null);
                }
            }

            for (String  fieldName : contactFieldNameList) {
                String fieldValueString = SchemaUtil.convertObjectToStringBasedOnFieldDisplayType(Contact.getSObjectType(), fieldName, contactList[0].get(fieldName));
                Object castedFieldValue = SchemaUtil.convertStringBasedOnFieldDisplayType(Contact.getSObjectType(),fieldName, fieldValueString);
                if (String.isNotBlank(fieldValueString)) {
                    System.assertEquals(true, castedFieldValue != null);
                }
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testBuildInQueryString() {
        List<Contact> contactList = Database.query(SchemaUtil.buildGeneralDatabaseQuery(Contact.getSObjectType()));
        Set<String> ids = new Set<String>();
        String idsString;
        Test.startTest();
        if (contactList != null && !contactList.isEmpty()) {
            for(Contact contact : contactList) {
                ids.add(String.valueOf(contact.Id));
            }
        }
        idsString = SchemaUtil.buildInQueryString(ids);
        Test.stopTest();

        if (contactList != null && !contactList.isEmpty()) {
            System.assertEquals(true, (idsString.contains('(') && idsString.contains(')')));
        } else {
            System.assertEquals(true, String.isBlank(idsString));
        }
    }

    @IsTest
    static void testCheckIfStringIsId() {
        List<Contact> contactList = Database.query(SchemaUtil.buildGeneralDatabaseQuery(Contact.getSObjectType()));

        if (contactList != null && !contactList.isEmpty()) {
            Test.startTest();
            Boolean isId = SchemaUtil.checkIfStringIsId((String)contactList[0].Id);
            System.assertEquals(true, isId);
            isId = SchemaUtil.checkIfStringIsId((String)contactList[0].Name);
            System.assertEquals(false, isId);
            Test.stopTest();
        }
    }

    @IsTest
    static void testClearFields() {
        List<Contact> contactList = Database.query(SchemaUtil.buildGeneralDatabaseQuery(Contact.getSObjectType()));

        if (contactList != null && !contactList.isEmpty()) {
            Test.startTest();
            List<String> fieldNames = new List<String>{'Id', 'AccountId'};
            SchemaUtil.clearFields(contactList[0], fieldNames);
            Test.stopTest();
            System.assertEquals(null, contactList[0].Id);
            System.assertEquals(null, contactList[0].AccountId);
        }
    }

    @IsTest
    static void testBuildRecordTypeMapWithNameAsKey() {
        Test.startTest();
        Map<String, String> recordTypeMap = SchemaUtil.buildRecordTypeMapWithNameAsKey(Account.getSObjectType());
        Test.stopTest();
        System.assertEquals(false, recordTypeMap.isEmpty());
    }

    @IsTest
    static void testBuildRecordTypeMapWithIdAsKey() {
        Test.startTest();
        Map<Id, String> recordTypeMap = SchemaUtil.buildRecordTypeMapWithIdAsKey(Account.getSObjectType());
        Test.stopTest();
        System.assertEquals(false, recordTypeMap.isEmpty());
    }

    @IsTest
    static void testRetrieveRecordTypeInfoById() {
        Test.startTest();
        Id recordTypeId = SchemaUtil.retrieveRecordTypeId(Account.getSObjectType(), ACCOUNT_RECORD_TYPE_NAME);
        RecordTypeInfo recordTypeInfo = SchemaUtil.retrieveRecordTypeInfoById(Account.getSObjectType(),recordTypeId);
        Test.stopTest();
        System.assertEquals(false, recordTypeInfo != null);
    }

    @TestSetup
    static void createMockObjects() {
        Id accountRecordTypeId = SchemaUtil.retrieveRecordTypeId(Account.getSObjectType(), ACCOUNT_RECORD_TYPE_NAME);
        String accountString = '{"attributes":{"type":"Account"},"Name":"Andrew Wallace","Type":"Person","RecordTypeId":"' + accountRecordTypeId + '","BillingStreet":"10 MONKEY MOUNTAIN RD","BillingCity":"TERMEIL","BillingState":"New South Wales","BillingPostalCode":"2539","BillingCountry":"AUSTRALIA","BillingLatitude":-35.470055970000000,"BillingLongitude":150.342408730000000,"BillingAddress":{"city":"TERMEIL","country":"AUSTRALIA","geocodeAccuracy":null,"latitude":-35.47005597,"longitude":150.34240873,"postalCode":"2539","state":"NSW","street":"10 MONKEY MOUNTAIN RD"},"ShippingStreet":"45 GABAGONG RD","ShippingCity":"HORSFIELD BAY","ShippingState":"New South Wales","ShippingPostalCode":"2256","ShippingCountry":"AUSTRALIA","ShippingLatitude":-33.490981190000000,"ShippingLongitude":151.301764980000000,"ShippingAddress":{"city":"HORSFIELD BAY","country":"AUSTRALIA","geocodeAccuracy":null,"latitude":-33.49098119,"longitude":151.30176498,"postalCode":"2256","state":"NSW","street":"45 GABAGONG RD"},"ABN__c":"58615316526","Legal_Name__c":"WE ARE EXAMPLE PTY LTD","BillingAddress_Gnaf_Id__c":"GANSW716999182","BillingAddress_MeshBlock__c":"10707300000","BillingAddress_MeshBlock2016__c":"10707300000","ShippingAddress_Gnaf_Id__c":"GANSW704992875","ShippingAddress_MeshBlock__c":"10301790000","ShippingAddress_MeshBlock2016__c":"10301790000","ABR_Verification_Date__c":"2019-12-10","Primary_Approved_Auditor__c":false,"Entity_Status__c":"Active","Update_From_Future_Method__c":true,"GST_Registered__c":"Yes","Entity_Trust_Flag__c":false,"ABN_Validated__c":true,"ACN__c":"118725081"}';
        Account acc = (Account)JSON.deserialize(accountString, Account.class);
        insert acc;

        Contact rawContact = new Contact();
        rawContact.AccountId = acc.Id;
        rawContact.FirstName = 'Test';
        rawContact.LastName = 'Contact';
        rawContact.Salutation = 'Mr.';
        rawContact.Title = '';
        rawContact.MailingCountry = 'Australia';
        rawContact.MailingStreet = '45 Exhibition Street';
        rawContact.MailingCity = 'Melbourne';
        rawContact.MailingState = 'Victoria';
        rawContact.MailingPostalCode = '3000';
        rawContact.Email = 'test@smartapps.com.au';
        rawContact.Phone = '+61312345678';
        rawContact.MobilePhone = '+61412345678';
        rawContact.OtherPhone = '+61412345678';
        insert rawContact;
    }

    @isTest
    static void testGetObjectNameById() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        System.assertEquals('Account', SchemaUtil.getObjectNameById(acc.Id), 'The object name should be Account');
    }
}