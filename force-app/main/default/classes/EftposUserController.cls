public without sharing class EftposUserController {

    public class userObject {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String firstName { get; set; }
        @AuraEnabled public String lastName { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String tradingName { get; set; }
        @AuraEnabled public String accountId { get; set; }
        @AuraEnabled public String oppId { get; set; }
        @AuraEnabled public String csaId { get; set; }
        @AuraEnabled public Boolean prefillChecked { get; set; }
    }

    @AuraEnabled
    public static string getOwnerContactEmail(String accountId) {
        List<Contact> conList = [
        SELECT Id, Email
        FROM Contact
        WHERE AccountId = :accountId
            AND Email != null
            AND Is_Preferred_Contact__c = true
        ];
        if (!conList.isEmpty()) {
            return conList[0].Email;
        }
        return null;
    }

    @AuraEnabled
    public static String addEftposUser(String eftposUserPayload) {
        Object parsedUsers = (Object) JSON.deserializeUntyped(eftposUserPayload);
        System.debug('parsedUsers ' + parsedUsers);

        String csaId;
        String oppId;
        String usrId;

        try {
            Map<String, Object> eachUserMap = (Map<String, Object>) parsedUsers;
            String firstName = eachUserMap.get('firstName')?.toString();
            String lastName = eachUserMap.get('lastName')?.toString();
            String tradingName = eachUserMap.get('tradingName')?.toString();
            String email = eachUserMap.get('email')?.toString();
            String phone = eachUserMap.get('phone')?.toString();
            Id accountId = eachUserMap.get('acctId')?.toString();
            String prefillChecked = eachUserMap.get('prefillChecked')?.toString();
            csaId = eachUserMap.get('csaId')?.toString();
            oppId = eachUserMap.get('oppId')?.toString();
            Eftpos_User__c existingUser ;
            List<EFTPOS_User__c> isExistingUser = [
                SELECT Id, Business_Name__c, Email__c, Signup_ID__c, Status__c
                FROM EFTPOS_User__c
                WHERE EFTPOS_Device_Owner_Account__c = :accountId
                // For future, consider if we need to check Owner Opp/CSA for dedupe
            ];

            for (EFTPOS_User__c u : isExistingUser) {
                if(u.Email__c != null && u.Email__c.equalsIgnoreCase(email)) {
                    if(u.business_name__c == tradingName) {
                        // if trading name also matches, consider as existing user
                        existingUser = u;
                        break;
                    } else{
                        // if trading name does not match, consider as new user
                        existingUser = null;
                        break;
                    }
                }
            }

            if (existingUser != null) {
                return existingUser.Id;
            } else {
                EFTPOS_User__c newUser = new EFTPOS_User__c();
                newUser.First_Name__c = firstName;
                newUser.Last_Name__c = lastName;
                newUser.Business_Name__c = tradingName;
                newUser.Email__c = email;
                newUser.Phone__c = phone;
                newUser.Status__c = 'Referred';
                newUser.EFTPOS_Device_Owner_Account__c = accountId;
                newUser.EFTPOS_Device_Owner_Opportunity__c = oppId; // create owner opp field for now, query csa from CSA__c field on Owner Opp
                newUser.Prefill_User_CSA__c = (prefillChecked == 'true') ? true : false;
                newUser.Signup_ID__c = (prefillChecked == 'true') ? UUID.randomUUID().toString() : null;
                insert newUser;
                usrId = newUser.Id;
                eachUserMap.put('id', usrId);
            }

            String usrPayload = JSON.serialize(eachUserMap);
            System.debug('Result : ' + usrPayload);
            return usrId;
        } catch (Exception ex) {
            OJErrorLogger.sendMail(
                'Error while saving EFTPOS User: ' + eftposUserPayload,
                ex.getLineNumber() + ', ' + ex.getStackTraceString() + ', ' + ex.getMessage()
            );
            throw new CustomException('Please contact support.');
        }
    }

    @AuraEnabled
    public static Boolean deleteEftposUser(String eftposUserPayload) {
        Object parsedUsers = (Object) JSON.deserializeUntyped(eftposUserPayload);
        System.debug('parsedUsers ' + parsedUsers);

        try {
            Map<String, Object> eachUserMap = (Map<String, Object>) parsedUsers;
            EFTPOS_User__c newUser = new EFTPOS_User__c();
            newUser.Id = eachUserMap.get('id')?.toString();
            // optional: validate Id format
            delete newUser;
        } catch (Exception ex) {
            OJErrorLogger.sendMail(
                'Error while deleting EFTPOS User: ' + eftposUserPayload,
                ex.getLineNumber() + ', ' + ex.getStackTraceString() + ', ' + ex.getMessage()
            );
            throw new CustomException('Please contact support.');
        }
        return true;
    }
    
    @AuraEnabled
    public static Boolean editEftposUser(String eftposUserPayload) {
        Object parsedUsers = (Object) JSON.deserializeUntyped(eftposUserPayload);
        System.debug('parsedUsers ' + parsedUsers);
        try {
            Map<String, Object> eachUserMap = (Map<String, Object>) parsedUsers;
            String userId = eachUserMap.get('id')?.toString();
            String firstName = eachUserMap.get('firstName')?.toString();
            String lastName = eachUserMap.get('lastName')?.toString();
            String tradingName = eachUserMap.get('tradingName')?.toString();
            String email = eachUserMap.get('email')?.toString();
            String phone = eachUserMap.get('phone')?.toString();
            Id accountId = eachUserMap.get('acctId')?.toString();
            String prefillChecked = eachUserMap.get('prefillChecked')?.toString();
            EFTPOS_User__c usr = new EFTPOS_User__c(Id = userId);
            usr.First_Name__c = firstName;
            usr.Last_Name__c = lastName;
            usr.Business_Name__c = tradingName;
            usr.Email__c = email;
            usr.Phone__c = phone;
            usr.Status__c = 'Referred';
            usr.Prefill_User_CSA__c = (prefillChecked == 'true') ? true : false;
            usr.Signup_ID__c = (prefillChecked == 'true') ? UUID.randomUUID().toString() : null;
            update usr;
        } catch (Exception ex) {
            OJErrorLogger.sendMail(
                'Error on saving EFTPOS User: ' + eftposUserPayload,
                ex.getLineNumber() + ', ' + ex.getStackTraceString() + ', ' + ex.getMessage()
            );
            throw new CustomException('Please contact support.');
        }
        return true;
    }


    @AuraEnabled
    public static List<userObject> getEftposUsers(String accountId, String oppId, String csaId) {
        List<EFTPOS_User__c> usrList = [
            SELECT Id,
                   First_Name__c,
                   Last_Name__c,
                   Email__c,
                   Phone__c,
                   Business_Name__c,
                   Prefill_User_CSA__c,
                   EFTPOS_Device_Owner_Account__c,
                   EFTPOS_Device_Owner_Opportunity__c
            FROM EFTPOS_User__c
            WHERE EFTPOS_Device_Owner_Account__c = :accountId
              AND EFTPOS_Device_User_Lead__c = null
        ];

        List<userObject> usrObjList = new List<userObject>();
        for (EFTPOS_User__c usr : usrList) {
            userObject usrObj = new userObject();
            usrObj.id = usr.Id;
            usrObj.firstName = usr.First_Name__c;
            usrObj.lastName = usr.Last_Name__c;
            usrObj.email = usr.Email__c;
            usrObj.phone = usr.Phone__c;
            usrObj.tradingName = usr.Business_Name__c;
            usrObj.accountId = usr.EFTPOS_Device_Owner_Account__c;
            usrObj.oppId = usr.EFTPOS_Device_Owner_Opportunity__c;
            usrObj.csaId = csaId;
            usrObj.prefillChecked = usr.Prefill_User_CSA__c;
            usrObjList.add(usrObj);
        }
        System.debug('usersPayload :' + usrObjList);
        return usrObjList;
    }

    @AuraEnabled(cacheable = true)
    public static Multi_MID_Biller_Terminology__mdt getMultiMidMetadata() {
        Multi_MID_Biller_Terminology__mdt terminology = [
            SELECT AB_Add_Title__c,
                   AB_Add_Info__c,
                   AB_Title__c,
                   AB_Info__c,
                   AB_Next_Button_Label__c,
                   AB_Add_Biller_Label__c,
                   AB_Capture_Prefill_CSA_Title__c,
                   AB_Add_Disclaimer__c,
                   AB_Add_Info_Additional__c,
                   AB_Capture_Prefill_CSA_Note__c
            FROM Multi_MID_Biller_Terminology__mdt
            WHERE DeveloperName = 'Biller_Terminology'
            LIMIT 1
        ];
        return terminology;
    }

    @AuraEnabled
    public static void createLeadForEftposUser(String accountId) {
        List<EFTPOS_User__c> ownerList = [
            SELECT Id,
                   Business_Name__c,
                   EFTPOS_Device_Owner_Account__c,
                   EFTPOS_Device_Owner_Account__r.OwnerId,
                   EFTPOS_Device_Owner_Account__r.Software__c,
                   EFTPOS_Device_Owner_Account__r.Industry,
                   EFTPOS_Device_Owner_Account__r.Brand__c,
                   EFTPOS_Device_Owner_Account__r.Name,
                   Email__c,
                   First_Name__c,
                   Last_Name__c,
                   Phone__c,
                   Status__c
            FROM EFTPOS_User__c
            WHERE EFTPOS_Device_Owner_Account__c = :accountId
              AND Status__c = 'Referred'
              AND EFTPOS_Device_User_Lead__c = null
        ];

        Set<String> softwareList = new Set<String>();
        for (EFTPOS_User__c user : ownerList) {
            if (String.isNotEmpty(user.EFTPOS_Device_Owner_Account__r.Software__c))
                softwareList.add(user.EFTPOS_Device_Owner_Account__r.Software__c);
        }

        Map<String, Partner_Configuration__c> configMap = PartnerConfigHelper.getPartnerAccountBySoftware(softwareList);
        List<Lead> leads = new List<Lead>();
        List<EFTPOS_User__c> usersToBeUpdated = new List<EFTPOS_User__c>();
        List<Task> tasks = new List<Task>();
        Map<Id, Lead> eftposUserIdToLeadMap = new Map<Id, Lead>();

        for (EFTPOS_User__c user : ownerList) {
            Lead lead = new Lead();
            lead.FirstName = user.First_Name__c;
            lead.LastName = user.Last_Name__c;
            lead.Email = user.Email__c;
            lead.Phone = user.Phone__c;
            lead.Company = user.Business_Name__c;
            lead.LeadSource = 'Partner - ISV';
            lead.Status = 'Marketing Qualified Lead';
            lead.Date_Marketing_Qualified__c = System.today();
            lead.OwnerId = user.EFTPOS_Device_Owner_Account__r.OwnerId;
            lead.Software__c = user.EFTPOS_Device_Owner_Account__r.Software__c;
            lead.Industry = user.EFTPOS_Device_Owner_Account__r.Industry;
            lead.Brand__c = user.EFTPOS_Device_Owner_Account__r.Brand__c;
            lead.Terminal_Owner__c = user.EFTPOS_Device_Owner_Account__r.Name;
            lead.EFTPOS_Relationship__c = 'EFTPOS User';
            lead.Enquiry_Type__c = 'Inbound Partner Lead';
            String partnerAccountName = configMap != null && configMap.keySet().size() > 0
                ? configMap.get(user.EFTPOS_Device_Owner_Account__r.Software__c)?.Partner_Account__r?.Name
                : '';
            lead.Company_Referred_By__c = partnerAccountName;
            leads.add(lead);
            eftposUserIdToLeadMap.put(user.Id, lead);
        }

        if (!leads.isEmpty()) {
            insert leads;
            createTasksForLeads(leads);
            sendEmail(leads);
        }

        for (EFTPOS_User__c user : ownerList) {
            user.EFTPOS_Device_User_Lead__c = eftposUserIdToLeadMap.get(user.Id).Id;
            usersToBeUpdated.add(user);
        }

        if (!usersToBeUpdated.isEmpty()) {
            update usersToBeUpdated;
        }
    }

    public static void sendEmail(List<Lead> leads) {
        EmailTemplate emailTemplate = [
            SELECT Id,
                   HtmlValue,
                   Subject,
                   RelatedEntityType,
                   EnhancedLetterheadId,
                   EnhancedLetterhead.LetterheadHeader,
                   EnhancedLetterhead.LetterheadFooter
            FROM EmailTemplate
            WHERE Name = 'CSA Link email - EFTPOS User'
            LIMIT 1
        ];

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        for (Lead lead : leads) {
            Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();
            sem.toAddresses = new String[] { lead.email };
            sem.setSubject(emailTemplate.Subject);
            String header = '<html> <head>' + emailTemplate.EnhancedLetterhead.LetterheadHeader + '</head> ';
            String body = emailTemplate.HtmlValue
                .replace('<html>', '')
                .replace('</html>', '')
                .replace('<head>', '')
                .replace('</head>', '')
                .replace('<title>', '')
                .replace('</title>', '');
            String footer = ' <footer> ' + emailTemplate.EnhancedLetterhead.LetterheadFooter + ' <footer> </html>';
            String htmlBody = OJErrorLogger.processEmailBody((header + body + footer).replace('Recipient', 'Lead'), emailTemplate.RelatedEntityType, lead.Id);
            if (htmlBody != null) {
                sem.setHtmlBody(htmlBody);
            }
            mails.add(sem);
        }

        Messaging.sendEmail(mails);
    }

    public static void createTasksForLeads(List<Lead> leads) {
        List<Task> tasksToInsert = new List<Task>();
        User owner = [SELECT Id, Username FROM User WHERE Alias = 'mrktg' AND LastName = 'Marketing' ORDER BY CreatedDate ASC LIMIT 1];

        for (Lead lead : leads) {
            Task t = new Task();
            t.OwnerId = owner.Id;
            t.Subject = 'Email with sign up link has been sent';
            t.Type = 'Email';
            t.Priority = 'Low';
            t.Status = 'Completed';
            t.WhoId = lead.Id;
            Schema.RecordTypeInfo rtInfo = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Task');
            if (rtInfo != null) {
                t.RecordTypeId = rtInfo.getRecordTypeId();
            }
            tasksToInsert.add(t);
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }

    @AuraEnabled
    public static String getOjThankYouPageURL(String oppId, String conid) {
        String applicationURL = Global_Settings__c.getOrgDefaults().ApplicationURL__c;
        Opportunity opp = [
            SELECT Id, Partner_Referred_Account__c
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];

        if (String.isNotBlank(opp.Partner_Referred_Account__c)) {
            String tempAppURL = applicationURL + '/signup?pId=' + opp.Partner_Referred_Account__c + '&oppid=' + opp.Id + '&conid=' + conid;
            System.debug('>> tempAppURL : ' + tempAppURL);
            return tempAppURL;
        } else {
            return null;
        }
    }

    @AuraEnabled
    public static void updatePrefillDetails(Id oppId, Boolean prefill) {
        if (oppId == null) return;
        try {

            List<EFTPOS_User__c> usersToUpdate = [
                SELECT Id, Signup_ID__c, Prefill_User_CSA__c
                FROM EFTPOS_User__c
                WHERE EFTPOS_Device_Owner_Opportunity__c = :oppId
            ];

            if (!usersToUpdate.isEmpty()) {
                for (EFTPOS_User__c user : usersToUpdate) {
                    if(prefill) {
                        user.Signup_ID__c = UUID.randomUUID().toString();
                        user.Prefill_User_CSA__c = true;
                    } else {
                        user.Signup_ID__c = null;
                        user.Prefill_User_CSA__c = false;
                    }
                }
                update usersToUpdate;
            }

        } catch (Exception e) {
            System.debug('updateOpportunityPrefill error: ' + e.getMessage());
        }
    }
}