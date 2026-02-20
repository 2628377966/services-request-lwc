@IsTest
public class BillerMatchControllerTest  { 
    @TestSetup
    static void setupTestData() {
        Global_Settings__c settings = new Global_Settings__c();
        settings.SiteURL__c = 'https://ezidebit--ezifull.sandbox.my.salesforce-sites.com/online';
        insert settings;
        
        // Create an owner account and opportunity
        Account ownerAccount = new Account(
            Name = 'Owner Account',
            Software__c = 'Xestro',
            Account_Status__c = 'Active',
            Client_Code__c = '001002003',
            ABN__c = '123456789'
        );
        insert ownerAccount;

        Contact con = new Contact(FirstName = 'Owner Con1', LastName = 'last name', Email = 'test@email.com', AccountId = ownerAccount.Id);
        insert con;

        Opportunity ownerOpportunity = new Opportunity(
            Name = 'Owner Opportunity',
            StageName = 'Transacting',
            CloseDate = Date.today(),
            AccountId = ownerAccount.Id
        );
        insert ownerOpportunity;

        CSA__c ownerCSA = new CSA__c(
            Opportunity__c = ownerOpportunity.Id
        );
        insert ownerCSA;

        ownerOpportunity.CSA__c = ownerCSA.Id;
        update ownerOpportunity;

        // Create a test Lead
        Lead testLead = new Lead(
            LastName = 'Test Lead1',
            Company = 'Test Company',
            Status = 'Open - Not Contacted',
            Software__c = 'Xestro'
        );
        insert testLead;

        // Create test EFTPOS_User__c
        EFTPOS_User__c eftposUser = new EFTPOS_User__c(
            EFTPOS_Device_Owner_Account__c = ownerAccount.Id,
            EFTPOS_Device_Owner_Opportunity__c = ownerOpportunity.Id,
            EFTPOS_Device_User_Lead__c = testLead.Id
        );
        
        insert eftposUser;
    }

    @IsTest
    static void testNoExistingBiller() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        BillerMatchController.BillerMatchWrapper result = BillerMatchController.searchExistingBiller('NonExistingclientId', 'NonExistingBusinessNumber','', testLead.Id, '');
        Test.stopTest();

        System.assert(result != null, 'Result should not be null');
        System.assertEquals(BillerMatchController.msgIfNoAcctMatch, result.message, 'Unexpected message returned');
    }

    @IsTest
    static void testSearchExistingBillerMulti() {
        // Create test Accounts with the same Client ID and Business Number
        Account account1 = new Account(
            Name = 'Account 1',
            Client_Code__c = '123',
            ABN__c = '456',
            Software__c = 'Xestro',
            Account_Status__c = 'Active'
        );
        Account account2 = new Account(
            Name = 'Account 2',
            Client_Code__c = '123',
            ABN__c = '456',
            Software__c = 'Xestro',
            Account_Status__c = 'Active'
        );
        insert new List<Account>{account1, account2};

        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        BillerMatchController.BillerMatchWrapper result = BillerMatchController.searchExistingBiller('123', '456', 'test@email.com', testLead.Id, '');
        Test.stopTest();

        System.assert(result != null, 'Result should not be null');
        System.assertEquals(BillerMatchController.msgIfMultiAcctsMatch, result.message, 'Unexpected message returned');
    }

    @IsTest
    static void testOneExistingBillerWithMatchingSoftware() {
        // Create test Account
        Account validAccount = new Account(
            Name = 'Valid Account',
            Client_Code__c = '789',
            ABN__c = '012',
            Software__c = 'Xestro',
            Account_Status__c = 'Active'
        );
        insert validAccount;

        Contact con = new Contact(FirstName = 'Con2', LastName = 'last name', Email = 'test2@email.com', AccountId = validAccount.Id);
        insert con;

        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        BillerMatchController.BillerMatchWrapper result = BillerMatchController.searchExistingBiller('789', '012', 'test2@email.com', testLead.Id, '');
        Test.stopTest();

        System.assert(result != null, 'Result should not be null');
        System.assertEquals(BillerMatchController.msgIfAcctMatch, result.message, 'Unexpected message returned');
        System.assertEquals('ProdAdd', result.proceedTo, 'Expected proceedTo to be ProdAdd');
    }

    @IsTest
    static void testOneExistingBillerWithNonMatchingSoftware() {
        // Create test Account with different software
        Account account = new Account(
            Name = 'Account with Different Software',
            Client_Code__c = '345',
            ABN__c = '678',
            Software__c = 'DifferentSoftware',
            Account_Status__c = 'Active'
        );
        insert account;

        Contact con = new Contact(FirstName = 'Con2', LastName = 'last name', Email = 'test2@email.com', AccountId = account.Id);
        insert con;

        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        BillerMatchController.BillerMatchWrapper result = BillerMatchController.searchExistingBiller('345', '678', 'test2@email.com', testLead.Id, '');
        Test.stopTest();

        System.assert(result != null, 'Result should not be null');
        System.assertEquals(BillerMatchController.msgIfSoftwareUnmatch, result.message, 'Unexpected message returned');
        System.assertEquals('NormalCSA', result.proceedTo, 'Expected proceedTo to be NormalCSA');
    }

    @IsTest
    static void testOneExistingBillerInvalidStatus() {
        // Create test Account with invalid status
        Account invalidStatusAccount = new Account(
            Name = 'Invalid Status Account',
            Client_Code__c = '901',
            ABN__c = '234',
            Software__c = 'Xestro',
            Account_Status__c = 'Inactive'
        );
        insert invalidStatusAccount;

        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        BillerMatchController.BillerMatchWrapper result = BillerMatchController.searchExistingBiller('901', '234', 'test@email.com', testLead.Id, '');
        Test.stopTest();

        System.assert(result != null, 'Result should not be null');
        System.assertEquals(BillerMatchController.msgIfInvalidStatus, result.message, 'Unexpected message returned');
        System.assertEquals('NormalCSA', result.proceedTo, 'Expected proceedTo to be NormalCSA');
    }

    @IsTest
    static void testProceedToNormalCSAWithInvalidLead() {
        Test.startTest();
        try {
            BillerMatchController.proceedToNormalCSA('NonExistingLeadId');
        } catch (Exception ex) {
            System.assertEquals('Invalid id: NonExistingLeadId', ex.getMessage(), 'Expected error message when lead conversion fails');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testProceedToNormalCSAExceptionHandling() {
        Test.startTest();
        try {
            BillerMatchController.proceedToNormalCSA('');
        } catch (Exception ex) {
            System.assertEquals('Lead ID cannot be blank.', ex.getMessage(), 'Expected error message when lead conversion fails');
        }
        Test.stopTest();
    }

    @IsTest
    static void testProceedToNormalCSA() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Opportunity ownerOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        CSA__c ownerCSA = [SELECT Id FROM CSA__c LIMIT 1];

        Test.startTest();
        String result1 = BillerMatchController.proceedToNormalCSA(testLead.Id);
        Test.stopTest();

        System.assert(result1.contains('https://ezidebit--ezifull.sandbox.my.salesforce-sites.com/online/kyc_yourbusiness?'), 'Unexpected result from ProceedToNormalCSA');
        String result2 = BillerMatchController.proceedToNormalCSA(testLead.Id);
        System.assertEquals(result1, result2);
    }

    @IsTest
    static void testProceedToNormalCSA_PrefillProcess() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Opportunity ownerOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        CSA__c ownerCSA = [SELECT Id FROM CSA__c LIMIT 1];
        EFTPOS_User__c eftposUser = [SELECT Id, Prefill_User_CSA__c FROM EFTPOS_User__c WHERE EFTPOS_Device_User_Lead__c = :testLead.Id LIMIT 1];
        eftposUser.Prefill_User_CSA__c = true;
        eftposUser.Status__c = 'Referred';
        eftposUser.Signup_ID__c = 'test_signup_id';
        update eftposUser;

        Test.startTest();
        String result1 = BillerMatchController.proceedToNormalCSA(testLead.Id);
        Test.stopTest();

        System.assert(result1.contains('https://ezidebit--ezifull.sandbox.my.salesforce-sites.com/online/kyc_yourbusiness?'), 'Unexpected result from ProceedToNormalCSA');
        System.assert(result1.contains('signupId'), 'Unexpected result from ProceedToNormalCSA');
        String result2 = BillerMatchController.proceedToNormalCSA(testLead.Id);
        System.assertEquals(result1, result2);
    }

    @IsTest
    static void testProceedToNormalCSA_PrefillCompleted() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Opportunity ownerOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        CSA__c ownerCSA = [SELECT Id FROM CSA__c LIMIT 1];
        EFTPOS_User__c eftposUser = [SELECT Id, Prefill_User_CSA__c FROM EFTPOS_User__c WHERE EFTPOS_Device_User_Lead__c = :testLead.Id LIMIT 1];
        eftposUser.Prefill_User_CSA__c = true;
        eftposUser.Status__c = 'Owner Prefill Completed';
        eftposUser.Signup_ID__c = 'test_signup_id';
        update eftposUser;

        Test.startTest();
        String result1 = BillerMatchController.proceedToNormalCSA(testLead.Id);
        Test.stopTest();

        System.assert(result1.contains('thank-you'), 'Unexpected result from ProceedToNormalCSA');
        String result2 = BillerMatchController.proceedToNormalCSA(testLead.Id);
        System.assertEquals(result1, result2);
    }

    @IsTest
    static void testProceedToProdAdd() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Opportunity ownerOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        CSA__c ownerCSA = [SELECT Id FROM CSA__c LIMIT 1];

        Test.startTest();
        String result = BillerMatchController.proceedToProdAdd(testLead.Id);
        Test.stopTest();

        System.assertEquals('Proceed to ProdAdd (TBA)', result, 'Unexpected result from proceedToProdAdd');
    }

    @IsTest
    static void testExistingBillerContactMatch() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        Test.startTest();
        BillerMatchController.BillerMatchWrapper result = BillerMatchController.searchExistingBiller('001002003', '123456789', 'test@email.com', testLead.Id, '');
        Test.stopTest();

        System.assert(result != null, 'Result should not be null');
        System.assertEquals(BillerMatchController.msgIfAcctMatch, result.message, 'Unexpected message returned');
        System.assertEquals('ProdAdd', result.proceedTo, 'Expected proceedTo to be ProdAdd');
    }
}