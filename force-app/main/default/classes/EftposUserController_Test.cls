@isTest 
public class EftposUserController_Test  {
     @TestSetup
     static void setupdata() {
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
          EFTPOS_User__c usr = new EFTPOS_User__c();
          usr.Business_Name__c = 'Test Business';
          usr.First_Name__c = 'Test First';
          usr.Last_Name__c = 'Test Last';
          usr.Email__c = 'business@co.in';
          usr.Phone__c = '400000000';
          usr.EFTPOS_Device_Owner_Account__c = acc.Id;
          usr.EFTPOS_Device_Owner_Opportunity__c = opp.Id;
          insert usr;
     }
     
     @isTest
     static void testDeleteUser() {
          List<Account> acc = [SELECT Id, Name FROM Account LIMIT 1];
          List<Opportunity> opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
          List<CSA__c> csa = [SELECT Id, Name FROM CSA__c LIMIT 1];
          List<EFTPOS_User__c> usr = [
               SELECT
                    Id,
                    First_Name__c,
                    Last_Name__c,
                    Email__c,
                    Phone__c,
                    Business_Name__c,
                    EFTPOS_Device_Owner_Account__c
               FROM EFTPOS_User__c
               LIMIT 1
          ];
  		String eftposUserPayload = ' { ' 
                + ' "id": "' + usr[0].Id + '", '
                + ' "firstName": "' + usr[0].First_Name__c + '" , '
                + ' "lastName": "' + usr[0].Last_Name__c +'" , '
                + ' "tradingName": "'+ usr[0].Business_Name__c +'" , '
                + ' "email": "' + usr[0].Email__c + '" , '
                + ' "phone": "' + usr[0].Phone__c + '" , '
                + ' "csaId": "' + csa[0].Id + '" , '
                + ' "oppId": "' + opp[0].Id + '" , '
                + ' "acctId": "'+ acc[0].Id + '"'
     		    + ' } ';          
          Test.startTest();
          Boolean isDeleteSuccessful = EftposUserController.deleteEftposUser(
               eftposUserPayload
          );
          Test.stopTest();
          System.assert(isDeleteSuccessful);
     }


     @isTest
     static void testEditUser() {
          List<Account> acc = [SELECT Id, Name FROM Account LIMIT 1];
          List<Opportunity> opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
          List<CSA__c> csa = [SELECT Id, Name FROM CSA__c LIMIT 1];
          List<EFTPOS_User__c> usr = [
               SELECT
                    Id,
                    First_Name__c,
                    Last_Name__c,
                    Email__c,
                    Phone__c,
                    Business_Name__c,
                    EFTPOS_Device_Owner_Account__c
               FROM EFTPOS_User__c
               LIMIT 1
          ];
  		String eftposUserPayload = ' { ' 
                + ' "id": "' + usr[0].Id + '", '
                + ' "firstName": "' + usr[0].First_Name__c + ' Edit" , '
                + ' "lastName": "' + usr[0].Last_Name__c +' Edit" , '
                + ' "tradingName": "'+ usr[0].Business_Name__c +' Edit" , '
                + ' "email": "' + usr[0].Email__c + '" , '
                + ' "phone": "' + usr[0].Phone__c + '" , '
                + ' "csaId": "' + csa[0].Id + '" , '
                + ' "oppId": "' + opp[0].Id + '" , '
                + ' "acctId": "'+ acc[0].Id + '"'
     		    + ' } ';          
          Test.startTest();
          Boolean isEditSuccessful = EftposUserController.editEftposUser(
               eftposUserPayload
          );
          Test.stopTest();
         
          List<EFTPOS_User__c> editUsr = [
             SELECT
             Id,
             First_Name__c,
             Last_Name__c,
             Email__c,
             Phone__c,
             Business_Name__c,
             EFTPOS_Device_Owner_Account__c
             FROM EFTPOS_User__c
             LIMIT 1
          ];
          System.assert(isEditSuccessful);
          System.assertEquals('Test First Edit',editUsr[0].First_Name__c, 'Incorrect First Name');
          System.assertEquals('Test Last Edit',editUsr[0].Last_Name__c, 'Incorrect Last Name');
          System.assertEquals('Test Business Edit',editUsr[0].Business_Name__c, 'Incorrect Business Name');
     }

     @isTest
     static void testAddEftposUser() {
          List<Account> acc = [SELECT Id, Name FROM Account LIMIT 1];
          List<Opportunity> opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
          List<CSA__c> csa = [SELECT Id, Name FROM CSA__c LIMIT 1];
        String eftposUserPayload = ' { ' 
                + ' "id": "", '
                + ' "firstName": "Test AddFirst" , '
                + ' "lastName": "Test AddLast" , '
                + ' "tradingName": "Test Add TradingName" , '
                + ' "email": "testBusiness@test.com" , '
                + ' "phone": "400000000" , '
                + ' "csaId": "' + csa[0].Id + '" , '
                + ' "oppId": "' + opp[0].Id + '" , '
                + ' "acctId": "'+ acc[0].Id + '"'
     		    + ' } ';
          Test.startTest();
          String userId = EftposUserController.addEftposUser(eftposUserPayload);
          Test.stopTest();
          List<EFTPOS_User__c> usr = [
               SELECT
                    Id,
                    First_Name__c,
                    Last_Name__c,
                    Email__c,
                    Phone__c,
                    Business_Name__c,
                    EFTPOS_Device_Owner_Account__c
               FROM EFTPOS_User__c
               WHERE Business_Name__c = 'Test Add TradingName'
          ];
          System.assertEquals(userId, usr[0].Id, 'Incorrect User Id');
          System.assertEquals(
               'Test AddFirst',
               usr[0].First_Name__c,
               'Incorrect First Name'
          );
          System.assertEquals(
               'Test AddLast',
               usr[0].Last_Name__c,
               'Incorrect Last Name'
          );
          System.assertEquals(
               'Test Add TradingName',
               usr[0].Business_Name__c,
               'Incorrect Trading Name'
          );
          System.assertEquals(
               'testbusiness@test.com',
               usr[0].Email__c,
               'Incorrect Email'
          );
          System.assertEquals('400000000', usr[0].Phone__c, 'Incorrect Phone');
          System.assertEquals(
               acc[0].Id,
               usr[0].EFTPOS_Device_Owner_Account__c,
               'Incorrect Account Owner'
          );
     }

     @isTest
     static void testDeleteUserExcpetion() {
          List<Account> acc = [SELECT Id, Name FROM Account LIMIT 1];
          List<Opportunity> opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
          List<CSA__c> csa = [SELECT Id, Name FROM CSA__c LIMIT 1];
          List<EFTPOS_User__c> usr = [
               SELECT
                    Id,
                    First_Name__c,
                    Last_Name__c,
                    Email__c,
                    Phone__c,
                    Business_Name__c,
                    EFTPOS_Device_Owner_Account__c
               FROM EFTPOS_User__c
               LIMIT 1
          ];
          String eftposUserPayload = ' { ' 
                + ' "id": "' + csa[0].Id + '", '
                + ' "firstName": "' + usr[0].First_Name__c+ '" , '
                + ' "lastName": "' + usr[0].Last_Name__c + '" , '
                + ' "tradingName": "' + usr[0].Business_Name__c + '" , '
                + ' "email": "' + usr[0].Email__c + '" , '
                + ' "phone": "' + usr[0].Phone__c + '" , '
                + ' "csaId": "' + csa[0].Id + '" , '
                + ' "oppId": "' + opp[0].Id + '" , '
                + ' "acctId": "'+ acc[0].Id + '"'
     		    + ' } ';

          try {
               Boolean isDeleteSuccessful = EftposUserController.deleteEftposUser(
                    eftposUserPayload
               );
               System.assert(!isDeleteSuccessful);
          } catch (Exception e) {
               System.assertEquals(
                    'Please contact support.',
                    e.getMessage(),
                    'Expecting exception!!'
               );
          }
     }


     

     @isTest
     static void testAddUserExcpetion() {
          List<Account> acc = [SELECT Id, Name FROM Account LIMIT 1];
          List<Opportunity> opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
          List<CSA__c> csa = [SELECT Id, Name FROM CSA__c LIMIT 1];
          List<EFTPOS_User__c> usr = [
               SELECT
                    Id,
                    First_Name__c,
                    Last_Name__c,
                    Email__c,
                    Phone__c,
                    Business_Name__c,
                    EFTPOS_Device_Owner_Account__c
               FROM EFTPOS_User__c
               LIMIT 1
          ];
          String eftposUserPayload = ' { ' 
                + ' "id": "", '
                + ' "firstName": "' + usr[0].First_Name__c+ '" , '
                + ' "lastName": "' + usr[0].Last_Name__c +'" , '
                + ' "tradingName": "' + usr[0].Business_Name__c +'" , '
                + ' "email": "' + usr[0].Email__c + '" , '
                + ' "phone": "' + usr[0].Phone__c + '" , '
                + ' "csaId": "' + csa[0].Id + '" , '
                + ' "oppId": "' + opp[0].Id + '" , '
                + ' "acctId": "' + opp[0].Id + '"'
     		    + ' } ';

          try {
               String userId = EftposUserController.addEftposUser(
                    eftposUserPayload
               );
          } catch (Exception e) {
               System.assertEquals(
                    'Please contact support.',
                    e.getMessage(),
                    'Expecting exception!!'
               );
          }
     }
    
     @isTest
     static void testgetEftposUsers() {
          List<Account> acc = [SELECT Id, Name FROM Account LIMIT 1];
          List<Opportunity> opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
          List<CSA__c> csa = [SELECT Id, Name FROM CSA__c LIMIT 1];
          Test.startTest();
          List<EftposUserController.userObject> usrList = EftposUserController.getEftposUsers(
                    acc[0].Id , opp[0].Id, csa[0].Id
               );
          Test.stopTest();
         system.assert(usrList.size() > 0);
     }
    
    
     @isTest
     static void testAddUserExisting() {
          List<Account> acc = [SELECT Id, Name FROM Account LIMIT 1];
          List<Opportunity> opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
          List<CSA__c> csa = [SELECT Id, Name FROM CSA__c LIMIT 1];
          List<EFTPOS_User__c> usr = [
               SELECT
                    Id,
                    First_Name__c,
                    Last_Name__c,
                    Email__c,
                    Phone__c,
                    Business_Name__c,
                    EFTPOS_Device_Owner_Account__c
               FROM EFTPOS_User__c
               LIMIT 1
          ];
          String eftposUserPayload = ' { ' 
                + ' "id": "", '
                + ' "firstName": "' + usr[0].First_Name__c+ '" , '
                + ' "lastName": "' + usr[0].Last_Name__c +'" , '
                + ' "tradingName": "' + usr[0].Business_Name__c +'" , '
                + ' "email": "' + usr[0].Email__c + '" , '
                + ' "phone": "' + usr[0].Phone__c + '" , '
                + ' "csaId": "' + csa[0].Id + '" , '
                + ' "oppId": "' + opp[0].Id + '" , '
                + ' "acctId": "' + acc[0].Id + '"'
     		    + ' } ';
   
          Test.startTest();
          String userId = EftposUserController.addEftposUser(
                    eftposUserPayload
               );
          Test.stopTest();
          System.assertEquals(usr[0].Id, userId, 'Expecting Existing User details to be pulled.');
         
     }

     @isTest
     static void Test_GetMultiMidMetadata() {
          Test.startTest();
          Multi_MID_Biller_Terminology__mdt result = EftposUserController.getMultiMidMetadata();
          Test.stopTest();
          System.assert(result != null);
     }

    @isTest
	static void sendEmailToLead_Test() {
		Account ownerAccount = TestFactory_Account.insertAccount();
		ownerAccount.Software__c = 'Xestro';
		ownerAccount.Brand__c = 'Eway';
		ownerAccount.Partner_Logo_URL__c = 'https://ezidebit--ezifull.sandbox.file.force.com/servlet/servlet.ImageServer?id=0158s000005BwozAAC&oid=00D8s000005vB8j';
		update ownerAccount;

		Partner_Configuration__c partnerConfig =new Partner_Configuration__c(Name = 'Xestro', Partner_Account__c = ownerAccount.Id);
		insert partnerConfig;

		Opportunity myOpportunity = TestFactory_Opportunity.insertOpportunity(ownerAccount);

		List<EFTPOS_User__c> eftposUsers = new List<EFTPOS_User__c>();
		EFTPOS_User__c eftposUserA = new EFTPOS_User__c(First_Name__c = 'Francis',
																					Last_Name__c = 'A',
																					Email__c = 'francis.li+a@globalpay.com',
																					Phone__c = '222222222',
																					Business_Name__c = 'Francis Test',
																					EFTPOS_Device_Owner_Account__c = ownerAccount.Id, 
																					Status__c = 'Referred', 
																					EFTPOS_Device_User_Lead__c = null);
		eftposUsers.add(eftposUserA);

		EFTPOS_User__c eftposUserB = new EFTPOS_User__c(First_Name__c = 'Francis',
																					Last_Name__c = 'B',
																					Email__c = 'francis.li+b@globalpay.com',
																					Phone__c = '222222222',
																					Business_Name__c = 'Francis Test',
																					EFTPOS_Device_Owner_Account__c = ownerAccount.Id, 
																					Status__c = 'Referred', 
																					EFTPOS_Device_User_Lead__c = null);

		myOpportunity.isClosedCSA__c = true;
		update myOpportunity;

          eftposUsers.add(eftposUserB);
		insert eftposUsers;

        try {EftposUserController.createLeadForEftposUser(ownerAccount.Id);} catch (Exception ex) {}	
    }

    @isTest
    static void testGetOwnerContactEmail() {
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        Contact con = [SELECT Id, Email FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        Test.startTest();
        String email = EftposUserController.getOwnerContactEmail(acc.Id);
        Test.stopTest();
        System.assertEquals(con.Email, email);
    }

    @isTest
    static void testUpdatePrefillDetailsTrue() {
        List<Opportunity> opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        Test.startTest();
        EftposUserController.updatePrefillDetails(opp[0].Id, true);
        Test.stopTest();
        List<EFTPOS_User__c> usr = [
               SELECT
                    Id,
                    Prefill_User_CSA__c,
                    Signup_ID__c
               FROM EFTPOS_User__c
               WHERE EFTPOS_Device_Owner_Opportunity__c = :opp[0].Id
          ];
        System.assert(usr[0].Prefill_User_CSA__c);
        System.assertNotEquals(null, usr[0].Signup_ID__c);
    }

    @isTest
    static void testUpdatePrefillDetailsFalse() { 
            List<Opportunity> opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
            Test.startTest();
            EftposUserController.updatePrefillDetails(opp[0].Id, false);
            Test.stopTest();
            List<EFTPOS_User__c> usr = [
                    SELECT
                      Id,
                      Prefill_User_CSA__c,
                      Signup_ID__c
                    FROM EFTPOS_User__c
                    WHERE EFTPOS_Device_Owner_Opportunity__c = :opp[0].Id
           ];
            System.assert(!usr[0].Prefill_User_CSA__c);
            System.assertEquals(null, usr[0].Signup_ID__c);
      }
}