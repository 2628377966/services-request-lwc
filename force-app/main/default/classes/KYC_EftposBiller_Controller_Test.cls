@isTest
public class KYC_EftposBiller_Controller_Test  {
     @TestSetup
     static void setupData() {
          Partner_Configuration__c spm03 = new Partner_Configuration__c(
               Name = 'Glofox',
               API_Integration_Method__c = 'Single API',
               Brand__c = 'Eway',
               Partner_Logo_URL__c = 'https://ezidebit--ezifull.sandbox.file.force.com/servlet/servlet.ImageServer?id=0158s000005BwozAAC&oid=00D8s000005vB8j'
          );
          insert spm03;
          Account acc = (Account) TestDataFactory.createSObject(
               new Account(),
               'TestDataFactory.AccountDefaults',
               true
          );
          Contact con = (Contact) TestDataFactory.createSObject(
               new Contact(accountid = acc.Id),
               'TestDataFactory.ContactDefaults',
               true
          );
          Opportunity opp = (Opportunity) TestDataFactory.createSObject(
               new Opportunity(accountid = acc.Id),
               'TestDataFactory.OpportunityDefaults',
               true
          );
          CSA__c csa = (CSA__C) TestDataFactory.createSObject(
               new CSA__c(Opportunity__c = opp.id)
          );
          acc.Entity_types__c = 'Australian Private Company';
          acc.Software__c = 'Glofox';
          update acc;
          csa.Use_Partner_Logo__c = true;
          insert csa;
     }

     @isTest
     private static void Test_LoadData() {
          Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
          CSA__c csa = [SELECT Id FROM CSA__c LIMIT 1];
          Account acc = [SELECT Id, Entity_types__c FROM Account LIMIT 1];

          ApexPages.currentPage().getParameters().put('oppid', opp.Id);
          ApexPages.currentPage().getParameters().put('csa', csa.Id);

          Test.startTest();
          KYC_EftposBiller_Controller controller = new KYC_EftposBiller_Controller();
          String supportPhoneNo = controller.supportPhoneNo;
          String software = controller.software;
          String nextPage = controller.nextPageName;
          String logo = controller.logo;
          Test.stopTest();
          system.assertEquals('Glofox', software, 'Incorrect software');
          system.assertEquals(
               '1800 106 565',
               supportPhoneNo,
               'Incorrect support phone number'
          );
          system.assertEquals(
               'KYC_CompanyOfficers',
               nextPage,
               'Incorrect next page'
          );
          system.assertEquals(
               'https://ezidebit--ezifull.sandbox.file.force.com/servlet/servlet.ImageServer?id=0158s000005BwozAAC&oid=00D8s000005vB8j',
               logo,
               'Incorrect logo'
          );
     }

     @isTest
     private static void Test_Init() {
          CSA__c csa = [SELECT Id FROM CSA__c LIMIT 1];
          Opportunity opp = [
               SELECT Id, isClosedCSA__c, isClosedAddProduct__c
               FROM Opportunity
               LIMIT 1
          ];
          opp.isClosedCSA__c = true;
          opp.isClosedAddProduct__c = true;
          update opp;

          ApexPages.currentPage().getParameters().put('oppid', opp.Id);
          ApexPages.currentPage().getParameters().put('csa', csa.Id);

          Test.startTest();
          KYC_EftposBiller_Controller controller = new KYC_EftposBiller_Controller();
          Pagereference result = controller.init();
          Test.stopTest();
          PageReference pageExcept = new PageReference(
               'https://www.ezidebit.com/en-au/application-in-progress'
          );
          System.assertEquals(pageExcept.getUrl(), result.getUrl());
     }
     
}