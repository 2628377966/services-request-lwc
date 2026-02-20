@IsTest
public class OjdbMainCtrlTest { 
    static String jsonString = '{"Settlement_Account_Number__c": "44448888", "Settlement_Bank_Name__c": "ANZ", "Settlement_BSB__c": "012012", "Settlement_Account_Holder_Name__c": "Jack Doe"}';

    @isTest
    static void testInsertApplication() {        
        Account acc = new Account(Name='Acme Corp', ABN__c='123456789');
        insert acc;

        Test.startTest();
        OjdbMainCtrl.saveApplication(jsonString, acc.Id);
        OjdbMainCtrl.saveApplication(jsonString, acc.Id);
        Test.stopTest();
        
        List<Application__c> applications = [SELECT Id, Name FROM Application__c];
        System.debug(applications);
        System.assertEquals(2, applications.size());
    }

    @isTest
    static void testInsertApplicationWithLongCompanyName() {
        Account acc = new Account(Name='Acme Corp pty ltd is the name of a company which is longer than expected', ABN__c='123456789');
        insert acc;

        Test.startTest();
        // Long company name is being test
        OjdbMainCtrl.saveApplication(jsonString, acc.Id);
        Test.stopTest();
        
        List<Application__c> applications = [SELECT Id, Name FROM Application__c];
        System.debug(applications);
        System.assertEquals(1, applications.size());
    }

    @isTest
    static void testInsertApplicationWithIntegerException() {
        Account acc = new Account(Name='Acme - bad - compnay - name', ABN__c='123456789');
        insert acc;

        //Exception part of the code is being tested
        Test.startTest();
        try {
            OjdbMainCtrl.saveApplication(jsonString, acc.Id);
            OjdbMainCtrl.saveApplication(jsonString, acc.Id);
            // The code should throw an exception
            System.Assert.isTrue(false);
        } catch (Exception ex) {
            System.Assert.isTrue(true);
        }
        Test.stopTest();
        
        List<Application__c> applications = [SELECT Id, Name FROM Application__c];
        System.debug(applications);
        //Only 1 application should be created due to error exception
        System.assertEquals(1, applications.size());
    }
}