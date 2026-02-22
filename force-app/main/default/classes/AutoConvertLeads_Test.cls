@IsTest
public class AutoConvertLeads_Test { 
    
    public static final String RESPONSE_BODY =
                '{' +
                ' "result": {' +
                '     "_id": "111111111111" ,' +
                '     "partnerId": "111111111112" ,' +
                '     "incrementalId": "111111111111" ,' +        
                '     "location": null, ' +
                '     "customerCompanyName" : "Test FN LN Pref", ' +
                '     "name": "Test FN LN Pref ", ' +
                '     "email": "test.test+140620221@ezidebit.com.au", ' +
                '     "phone": "+61412345678", ' +
                '     "gkOrders": [], ' +
                '     "clientData": {}, ' +
                '     "customerData":{ ' +
                '	      "accountName": "Test Act Name", ' +
                '          "tradingAs": "THE TEST PERSONAL TRAINER"' +
                '	  }, ' +
                '	  "offerStatus": "Customer Completing", ' +
                '     "offerStage": "Customer Forms", ' +
                '	  "offerType": "Onboard", ' +
                '     "OrderStatus": "Customer Forms", ' +
                '     "currentStepItem": {    ' +
                '        "statusDescription": "Not Accessed", ' +
                '        "percentageComplete": "10"      '+
                '        } ' +
                '} ' +
                '}';

    @IsTest
    static void testConvertLeadWithoutOpp() {

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
        User user = new User(Alias = 'newUsr', Email = 'newUsr@testorg.com',
            EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles', UserName = 'newUsr@testorg.com');
        insert user;

        Lead leadToCreate = new Lead();
        leadToCreate.ownerid = user.id;
        leadToCreate.LastName = 'Test Last Name';
        leadToCreate.Company = 'Test NB RFP';
        leadToCreate.LeadSource = 'Partner Referral';
        leadToCreate.Status = 'Marketing Qualified Lead';
        insert leadToCreate;

        Test.startTest();
        Database.LeadConvertResult successResult = AutoConvertLeads.ConvertLeadsWithoutOpp(leadToCreate.id);
        Database.LeadConvertResult failedResult = AutoConvertLeads.ConvertLeadsWithoutOpp(leadToCreate.id);
        Test.stopTest();

        Account convertedAccount = [SELECT Name, OwnerId FROM Account LIMIT 1];
        System.assert(convertedAccount != null);
        System.assertEquals(leadToCreate.Company, convertedAccount.Name);
        System.assertEquals(leadToCreate.OwnerId, convertedAccount.OwnerId);

        Contact convertedContact = [SELECT LastName, OwnerId, AccountId FROM Contact LIMIT 1];
        System.assert(convertedContact != null);
        System.assertEquals(leadToCreate.LastName, convertedContact.LastName);
        System.assertEquals(convertedAccount.Id, convertedContact.AccountId);
        System.assertEquals(leadToCreate.OwnerId, convertedContact.OwnerId);

        List<Opportunity> convertedOpportunity = [SELECT Name, OwnerId, AccountId FROM Opportunity];
        System.assert(convertedOpportunity.size() == 0);

        System.assert(failedResult == null, 'Result should be null because an exception should have been caught');
    }
}