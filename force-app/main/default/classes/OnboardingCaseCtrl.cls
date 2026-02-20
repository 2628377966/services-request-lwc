public without sharing class OnboardingCaseCtrl  {
    @AuraEnabled(cacheable = false)
    public static void createAddEftposCase(String clientId, String businessNumber, String requesterEmailAddress, String selectedEftposDevices) {
        try {
            Group owner = [
                SELECT Id 
                FROM Group 
                WHERE DeveloperName = 'Onboarding' AND Type = 'Queue' 
                LIMIT 1
            ];

            Id caseRecordTypeId = Schema.SObjectType.Case
                .getRecordTypeInfosByDeveloperName()
                .get('Onboarding')
                .getRecordTypeId();

            businessNumber = businessNumber.deleteWhitespace();
            List<Account> existingAccounts = getexistingAccountRecords(clientId, businessNumber);

            Case c = new Case();
            c.RecordTypeId = caseRecordTypeId;
            c.OwnerId = owner.Id;
            c.AccountId = existingAccounts.get(0).Id;
            c.Category__c = 'Service (multi-MID)';
            c.Sub_Category__c = 'Add Device';
            c.Status = 'New';
            c.Subject = 'New Request - ' + existingAccounts.get(0).Industry + ' - Existing Merchant (Multi MID)';
            c.Description = 
                'EFTPOS Device Request\n' +
                '---------------------------\n' +
                'Business Name: ' + existingAccounts.get(0).Name + '\n' +
                'Payments ID: ' + clientId + '\n' +
                'ABN: ' + businessNumber + '\n' +
                'Requesters email address: '+ requesterEmailAddress +' \n' +
                '-------- Devices to Add --------\n' +
                'Number of devices to be added: ' + selectedEftposDevices;

            insert c;
            
            //Send Confirmation email
            sendConfirmationEmail(c.Id, requesterEmailAddress);

        } catch (Exception ex) {
            System.debug('Exception: ' + ex);
        }
    }

    @AuraEnabled
    public static void createCaseToRemoveMultipleMerchant(String clientId, String businessNumber, String requesterEmailAddress, String merchants) {
        businessNumber = businessNumber.deleteWhitespace();
        RecordType rc = [SELECT Id FROM RecordType WHERE SobjectType = 'Case' AND DeveloperName = 'Onboarding' LIMIT 1];
        Group owner = [SELECT Id FROM Group WHERE DeveloperName = 'Onboarding' AND Type = 'Queue' LIMIT 1];
        List<Account> existingAccounts = [
            SELECT Id, Name, Industry
            FROM Account
            WHERE Client_Code__c = :clientId 
              AND Unformatted_ABN__c = :businessNumber
        ];

        List<Object> merchantRecords = (List<Object>) JSON.deserializeUntyped(merchants);
        System.debug(merchantRecords);
        
        String formattedMerchants = '';
        for (Integer i = 0; i < merchantRecords.size(); i++) {
            Map<String, Object> eachMerchant = (Map<String, Object>)merchantRecords[i];
            if ((Boolean)eachMerchant.get('isValid') == true) {
                String formattedString = 'tradingName: ' + (String)eachMerchant.get('tradingName') + ',\n' +
                                         'email: ' + (String)eachMerchant.get('email') + ',\n' +
                                         'clientId: ' + (String)eachMerchant.get('clientId') + ';';
                
                if (i < merchantRecords.size() - 1) {
                    formattedMerchants += formattedString + '\n';
                } else {
                    formattedMerchants += formattedString;
                }
            }
        }

        Case c = new Case();
        c.RecordTypeId = rc.Id;
        c.OwnerId = owner.Id;
        c.AccountId = existingAccounts.get(0).Id;
        c.Category__c = 'Service (multi-MID)';
        c.Sub_Category__c = 'Remove User';
        c.Status = 'New';
        c.Subject = 'New Request - ' + existingAccounts.get(0).Industry + ' - Existing Merchant (Multi MID)';
        c.Origin = 'Web';
        c.Description =
            'Remove Multiple Merchants\n' +
            '---------------------------\n' +
            'Trading Name: ' + existingAccounts.get(0).Name + '\n' +
            'Payments ID: ' + clientId + '\n' +
            'ABN: ' + businessNumber + '\n' +
            'Requesters email address: ' + requesterEmailAddress + '\n' +
            '-------- Merchants to Remove --------\n'
            + formattedMerchants;

        insert c;
      
        //Send Confirmation email
        sendConfirmationEmail(c.Id, requesterEmailAddress);
    }

    @AuraEnabled(cacheable = false)
    public static void createRemoveEftposDevicesCase(String clientId, String businessNumber, String requesterEmailAddress, String selectedEftposDevices) {
        try {
            List<Object> deviceRecords = (List<Object>) JSON.deserializeUntyped(selectedEftposDevices);
            String formattedDevices = '';

            for (Integer i = 0; i < deviceRecords.size(); i++) {
                Map<String, Object> eachMerchant = (Map<String, Object>) deviceRecords[i];

                if ((Boolean) eachMerchant.get('isValid') == true) {
                    String serialNo = (String) eachMerchant.get('serialNo');
                    String reasonToRemoveOpt = (String) eachMerchant.get('reasonToRemoveOpt');
                    String reasonToRemoveDesc = (String) eachMerchant.get('reasonToRemoveDesc');

                    if (String.isNotBlank(serialNo)) {
                        formattedDevices += 'Device ' + (i + 1) + ':\n';
                        formattedDevices += 'Serial No: ' + serialNo + '\n';
                        formattedDevices += 'Reason to Remove: ' + (reasonToRemoveOpt != null ? reasonToRemoveOpt : '') + '\n';

                        if (String.isNotBlank(reasonToRemoveDesc)) {
                            formattedDevices += 'Remove Reason Details: ' + reasonToRemoveDesc + '\n';
                        }

                        formattedDevices += '\n';
                    }
                }
            }

            Group owner = [
                SELECT Id 
                FROM Group 
                WHERE DeveloperName = 'Onboarding' AND Type = 'Queue' 
                LIMIT 1
            ];

            Id caseRecordTypeId = Schema.SObjectType.Case
                .getRecordTypeInfosByDeveloperName()
                .get('Onboarding')
                .getRecordTypeId();

            businessNumber = businessNumber.deleteWhitespace();
            List<Account> existingAccounts = getexistingAccountRecords(clientId, businessNumber);

            Case c = new Case();
            c.RecordTypeId = caseRecordTypeId;
            c.OwnerId = owner.Id;
            c.AccountId = existingAccounts.get(0).Id;
            c.Category__c = 'Service (multi-MID)';
            c.Sub_Category__c = 'Remove Device';
            c.Status = 'New';
            c.Subject = 'New Request - ' + existingAccounts.get(0).Industry + ' - Existing Merchant (Multi MID)';
            c.Description = 
                'Remove Multiple EFTPOS Devices Request\n' +
                '---------------------------\n' +
                'Business Name: ' + existingAccounts.get(0).Name + '\n' +
                'Payments ID: ' + clientId + '\n' +
                'ABN: ' + businessNumber + '\n' +
                'Requesters email address: '+ requesterEmailAddress +' \n' +
                '-------- Devices to Remove --------\n' +
                formattedDevices;

            insert c;

            //Send Confirmation email
            sendConfirmationEmail(c.Id, requesterEmailAddress);

        } catch (Exception ex) {
            System.debug('Exception: ' + ex);
        }
    }

    public static List<Account> getexistingAccountRecords(String clientId, String businessNumber) {
        return [
            SELECT Id, Name, Unformatted_ABN__c, Client_Code__c, Industry, 
                   Software__c, Account_Status__c, API_Capability__c, 
                   Opportunity_ID__r.Product_Requested__c
            FROM Account
            WHERE Client_Code__c = :clientId 
              AND Unformatted_ABN__c = :businessNumber
        ];
    }

    public static void sendConfirmationEmail(Id caseId, String requesterEmailAddress) {

    String templateDevName = 'Auto_Confirmation_Email_for_New_Service_Ext_Requests';
    if (String.isBlank(requesterEmailAddress) || caseId == null) {
        throw new AuraHandledException('Invalid parameters: requester email or case ID is missing.');
    }

    try {
        Contact recipient = [
            SELECT Id, FirstName, Email 
            FROM Contact 
            WHERE Email = :requesterEmailAddress 
            LIMIT 1
        ];

        EmailTemplate template = [
            SELECT Id 
            FROM EmailTemplate 
            WHERE DeveloperName = :templateDevName 
            LIMIT 1
        ];
        
        // Prepare the email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(recipient.Id); 
        mail.setWhatId(caseId);         
        mail.setTemplateId(template.Id);
        mail.setSaveAsActivity(true);

        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

    } catch (Exception ex) {
        System.debug('Email Sending Error: ' + ex);
        throw new AuraHandledException('Failed to send confirmation email: ' + ex.getMessage());
    }
}

}