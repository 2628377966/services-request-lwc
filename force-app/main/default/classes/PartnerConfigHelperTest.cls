@isTest
private class PartnerConfigHelperTest { 

    @isTest
    static void testGetPartnerConfigsViaAccountId() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        List<Partner_Configuration__c> testConfigs = new List<Partner_Configuration__c>{
            new Partner_Configuration__c(Name = 'Software 1', Payment_Solutions__c = 'Direct Debit', Partner_Account__c = testAccount.Id),
            new Partner_Configuration__c(Name = 'Software 2', Payment_Solutions__c = 'EFTPOS', Partner_Account__c = testAccount.Id)
        };
        insert testConfigs;
        Test.startTest();
        List<Partner_Configuration__c> resultConfigs = PartnerConfigHelper.getPartnerConfigsViaAccountId(testAccount.Id);
        Test.stopTest();
        System.assertEquals(2, resultConfigs.size(), 'Expected 2 partner configurations');
        System.assertEquals('Software 1', resultConfigs[0].Name, 'Software 1 should match');
        System.assertEquals('Software 2', resultConfigs[1].Name, 'Software 2 should match');
    }

    @isTest
    static void testGetPartnerConfigsViaAccountId_NoConfigs() {
        Account testAccount = new Account(Name = 'Test Account No Configs');
        insert testAccount;
        Test.startTest();
        List<Partner_Configuration__c> resultConfigs = PartnerConfigHelper.getPartnerConfigsViaAccountId(testAccount.Id);
        Test.stopTest();
        System.assertEquals(0, resultConfigs.size(), 'Expected 0 partner configurations');
    }

    @isTest
    static void test_getPartnerAccountBySoftware() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Partner_Configuration__c testConfig = new Partner_Configuration__c(Name = 'Software Test', Payment_Solutions__c = 'Direct Debit', Partner_Account__c = testAccount.Id);
        insert testConfig;
        Test.startTest();
        Map<String, Partner_Configuration__c> resultConfigs = PartnerConfigHelper.getPartnerAccountBySoftware(new Set<String>{'Software Test'});
        Test.stopTest();
        System.assertEquals(1, resultConfigs.keySet().size(), 'Expected 1 partner configuration');
        System.assertEquals('Test Account', resultConfigs.get('Software Test').Partner_Account__r.Name, 'Patner Account should be Test Account');
    }
}