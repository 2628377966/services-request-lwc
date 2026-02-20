@isTest
private class OnboardingCaseCtrlTest  {
    @testSetup
    static void setupData() {
        // Create an Account that matches the clientId and businessNumber filters
        Account acc = new Account(
            Name = 'Test Business',
            Client_Code__c = 'C123',
            ABN__c = '12345678901',
            Industry = 'Retail',
            Software__c = 'POS',
            Account_Status__c = 'Active'
        );
        insert acc;
    }

    @isTest
    static void testCreateAddEftposCase() {
        Test.startTest();
        OnboardingCaseCtrl.createAddEftposCase(
            'C123',
            '12345678901',
            'test@email.com',
            '2'
        );
        Test.stopTest();

        List<Case> createdCases = [
            SELECT Id, Subject, Description 
            FROM Case 
            WHERE Subject LIKE 'New Request -%'
        ];

        System.assertEquals(1, createdCases.size(), 'One case should be created for add device.');
        System.assert(
            createdCases[0].Description.contains('Number of devices to be added: 2'),
            'Case description should contain number of devices.'
        );
        System.assert(
            createdCases[0].Description.contains('test@email.com'),
            'Case description should contain email.'
        );
    }

    @isTest
    static void testCreateRemoveEftposDevicesCase() {
        // Prepare device JSON
        List<Map<String, Object>> devices = new List<Map<String, Object>>();
        devices.add(new Map<String, Object>{
            'serialNo' => 'SN123456',
            'reasonToRemoveOpt' => 'Damaged',
            'reasonToRemoveDesc' => 'Broken screen',
            'isValid' => true
        });

        String jsonDevices = JSON.serialize(devices);

        Test.startTest();
        OnboardingCaseCtrl.createRemoveEftposDevicesCase(
            'C123',
            '12345678901',
            'test@email.com',
            jsonDevices
        );
        Test.stopTest();

        List<Case> createdCases = [
            SELECT Id, Subject, Description 
            FROM Case 
            WHERE Subject LIKE 'New Request -%'
        ];

        System.assertEquals(1, createdCases.size(), 'One case should be created for remove device.');
        System.assert(
            createdCases[0].Description.contains('Serial No: SN123456'),
            'Case description should contain device serial number.'
        );
        System.assert(
            createdCases[0].Description.contains('test@email.com'),
            'Case description should contain email.'
        );
    }

@IsTest
    static void testCreateCaseToRemoveMultipleMerchant() {
        Account acc = new Account(
            Name = 'Test Account 02-05-2025',
            Industry = 'Retail',
            Client_Code__c = '000-000-000',
            ABN__c = '52149901477'
        );
        insert acc;

        // Add required Contact for email sending
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@email.com'
        );
        insert testContact;
        // Prepare merchant JSON
        List<Map<String, Object>> merchants = new List<Map<String, Object>>();
        merchants.add(new Map<String, Object>{
            'tradingName' => 'Merchant 1',
            'email' => 'merchant1@example.com',
            'clientId' => '000-000-001',
            'isValid' => true
        });
        merchants.add(new Map<String, Object>{
            'tradingName' => 'Merchant 2',
            'email' => 'merchant2@example.com',
            'clientId' => '000-000-002',
            'isValid' => true
        });

        String jsonMerchants = JSON.serialize(merchants);

        // Call the method
        Test.startTest();
        OnboardingCaseCtrl.createCaseToRemoveMultipleMerchant('000-000-000', '52149901477', 'test@email.com', jsonMerchants);
        Test.stopTest();

        // Verify that a Case has been created with the expected details
        List<Case> createdCases = [SELECT Id, Subject, Description FROM Case];
        System.assertEquals(1, createdCases.size());
        System.assertEquals('New Request - Retail - Existing Merchant (Multi MID)', createdCases[0].Subject);
        System.assert(createdCases[0].Description.contains('Remove Multiple Merchants'));
        System.assert(createdCases[0].Description.contains('Trading Name: Test Account 02-05-2025'));
        System.assert(createdCases[0].Description.contains('Payments ID: 000-000-000'));
        System.assert(createdCases[0].Description.contains('ABN: 52149901477'));
        System.assert(createdCases[0].Description.contains('Requesters email address: '));
        System.assert(createdCases[0].Description.contains('tradingName: Merchant 1'));
        System.assert(createdCases[0].Description.contains('email: merchant1@example.com'));
        System.assert(createdCases[0].Description.contains('clientId: 000-000-001'));
        System.assert(createdCases[0].Description.contains('tradingName: Merchant 2'));
        System.assert(createdCases[0].Description.contains('email: merchant2@example.com'));
        System.assert(createdCases[0].Description.contains('clientId: 000-000-002'));
        System.assert(createdCases[0].Description.contains('test@email.com'));
    }
    
}