@IsTest(SeeAllData=true)
public class OJInitiatorCtrlTest { 
  @isTest
  static void testGetRecords_Success() {
    Partner_Configuration__c spm01 = new Partner_Configuration__c(
      Name = 'Glofox',
      API_Integration_Method__c = 'Single API',
      Brand__c = 'Ezidebit',
      Partner_Logo_URL__c = 'https://ezidebit--ezifull.sandbox.file.force.com/servlet/servlet.ImageServer?id=0158s000005BwozAAC&oid=00D8s000005vB8j'
    );
    insert spm01;

    Account testAccount = new Account(
      Name = 'Test Account',
      Brand__c = 'Ezidebit',
      Industry = 'Technology',
      Software__c = 'Glofox'
    );
    insert testAccount;

    Theme__c testTheme = new Theme__c(
      Name = 'Ezidebit',
      Button1__c = 'border-radius: 4px; border: 1px solid #58B947; color: #58B947;',
      Button2__c = 'border-radius: 4px; background: #58B947; color: #FFFFFF;'
      );
      insert testTheme;

    Map<String, List<String>> fields = new Map<String, List<String>>{
      'accountFields' => new List<String>{ 'Name', 'Brand__c', 'Industry' },
      'themeFields' => new List<String>{ 'Button1__c', 'Button2__c', 'Name' }
    };

    Test.startTest();
    Map<String, Object> result = OJInitiatorCtrl.getRecords(
      testAccount.Id,
      fields
    );
    Test.stopTest();

    System.assertNotEquals(
      null,
      result.get('Account'),
      'Account data should not be null'
    );

    System.assertNotEquals(
      null,
      result.get('Theme'),
      'Theme data should not be null'
    );

    Map<String, Object> accountData = (Map<String, Object>) result.get(
      'Account'
    );

    System.assertEquals(
      'Test Account',
      accountData.get('Name'),
      'Account name should match'
    );

    System.assertEquals(
      'Technology',
      accountData.get('Industry'),
      'Account industry should match'
    );

    Map<String, Object> themeData = (Map<String, Object>) result.get('Theme');

    System.assertEquals(
      'border-radius: 4px; border: 1px solid #58B947; color: #58B947;',
      themeData.get('Button1__c'),
      'Theme Field 1 should match'
    );

    System.assertEquals(
      'border-radius: 4px; background: #58B947; color: #FFFFFF;',
      themeData.get('Button2__c'),
      'Theme Field 2 should match'
    );
  }

  @isTest
  static void testGetRecords_AccountNotFound() {
    Map<String, List<String>> fields = new Map<String, List<String>>{
      'accountFields' => new List<String>{ 'Name', 'Industry', 'Brand__c' },
      'themeFields' => new List<String>{ 'Button1__c', 'Button2__c' }
    };

    try {
      Test.startTest();
      OJInitiatorCtrl.getRecords('invalidAccountId', fields);
      Test.stopTest();
      System.assert(
        false,
        'Exception should have been thrown for invalid account Id'
      );
    } catch (Exception e) {
      System.assert(
        e.getMessage().contains('An error occurred'),
        'Exception message should contain "An error occurred" but it the error message was: ' + e.getMessage()
      );
    }
  }

  @isTest
static void testGetNewRequestUserData() {
    Account acc = new Account( Name = 'Test Account', Client_Code__c = 'C12345', ABN__c = '123456789' );
    insert acc;
    
    Contact con = new Contact( LastName = 'Test Contact', Email = 'test@example.com', AccountId = acc.Id );
    insert con;
    
    Opportunity opp = new Opportunity( Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today().addDays(10), AccountId = acc.Id );
    insert opp;
    
    Test.startTest();
    Map<String, String> result = OJInitiatorCtrl.getNewRequestUserData(opp.Id, con.Id);
    Test.stopTest();
    
    System.assertEquals('test@example.com', result.get('requesterEmailAddress'), 'Email should match');
    System.assertEquals('123456789', result.get('businessNumber'), 'ABN should match');
    System.assertEquals('C12345', result.get('clientId'), 'Client Code should match');
}

  @isTest
  static void testGetPartnerConfigBySoftware_Success() {
    Account partnerAccount = new Account(
      Name = 'Test Partner Account',
      Brand__c = 'Ezidebit',
      Software__c = 'TestSoftware'
    );
    insert partnerAccount;

    Partner_Configuration__c partnerConfig = new Partner_Configuration__c(
      Name = 'TestSoftware',
      Multi_MID_Enabled__c = true,
      Partner_Account__c = partnerAccount.Id,
      API_Integration_Method__c = 'Single API',
      Brand__c = 'Ezidebit'
    );
    insert partnerConfig;

    Test.startTest();
    Partner_Configuration__c result = OJInitiatorCtrl.getPartnerConfigByAccountId(partnerAccount.Id, partnerAccount.Software__c);
    Test.stopTest();

    System.assertNotEquals(null, result, 'Partner Configuration should be found');
    System.assertEquals('TestSoftware', result.Name, 'Software name should match');
    System.assertEquals(true, result.Multi_MID_Enabled__c, 'Multi MID Enabled should be true');
    System.assertEquals('Test Partner Account', result.Partner_Account__r.Name, 'Partner Account name should match');
    System.assertEquals('Ezidebit', result.Partner_Account__r.Brand__c, 'Partner Account brand should match');
  }

  @isTest
  static void testGetPartnerConfigBySoftware_NotFound() {
    Account partnerAccount = new Account(
      Name = 'Test Partner Account',
      Brand__c = 'Ezidebit',
      Software__c = 'TestSoftware'
    );
    insert partnerAccount;

    Test.startTest();
    Partner_Configuration__c resultInvalidAccount = OJInitiatorCtrl.getPartnerConfigByAccountId('001000000000000AAA', 'NonExistentSoftware');
    Partner_Configuration__c resultNullAccount = OJInitiatorCtrl.getPartnerConfigByAccountId(null, 'TestSoftware');
    Test.stopTest();
    
    System.assertEquals(null, resultInvalidAccount, 'Result should be null when account has no configuration');
    System.assertEquals(null, resultNullAccount, 'Result should be null for null account ID');
  }

}