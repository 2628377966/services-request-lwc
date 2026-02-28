public without sharing class BillerMatchController {
    public final static Set<String> validStatuses = new Set<String>{'Active', 'Application Incomplete', 'Suspended'};

    public final static String msgIfMultiAcctsMatch = 'More than one existing account found, please call our support team to assist you ';
    public final static String msgIfNoAcctMatch = 'Sorry, we could not find a valid client record for you, please review the ID you entered or call our support team to assist you ';
    public final static String msgIfErrorOut = 'Technical issue encountered, please call our support team to assist you ';
    public final static String msgIfInvalidStatus = 'The account nominated is currently inactive, please return to the previous screen and sign up for a new account, or contact our support team for assistance.';
    public final static String msgIfSoftwareUnmatch = 'Your existing account seems to be associated with a different Software partner, please return to the previous screen and sign up for a new account, or contact our support team for assistance.';
    public final static String msgIfAcctMatch = 'Existing Account is found, please proceed to add product (TBA).';
    public final static String msgIfNoUserFound = 'No such EFTPOS User is found, please call our support team to assist you ';
    public final static String msgIfNoContactFound = 'Sorry, we could not find a valid client record for you. Please recheck the information provided above, or contact our friendly local team on ';
    public static String tempRequesterConId = '';
    @AuraEnabled
    public static BillerMatchWrapper searchExistingBiller(String clientId, String businessNumber, String requesterEmailAddress, String leadId, String supportPhoneNumber) {
        try {
            businessNumber = businessNumber.deleteWhitespace();
            // Query accounts matching clientId and businessNumber
            List<Account> existingAccounts = [
                SELECT Id, Name, Unformatted_ABN__c, Client_Code__c, Software__c, Account_Status__c, API_Capability__c
                FROM Account
                WHERE Client_Code__c = :clientId AND Unformatted_ABN__c = :businessNumber
            ];

            System.debug(existingAccounts);
            if (existingAccounts.size() == 0) {
                System.debug('0 accounts');
                return new BillerMatchWrapper(msgIfNoAcctMatch + supportPhoneNumber);
            }

            Map<String,String> productsByAccountIdMap = new Map<String,String>();

            // Filter accounts with valid statuses
            List<Account> validAccounts = new List<Account>();
            for (Account account : existingAccounts) {
                if (validStatuses.contains(account.Account_Status__c)) {
                    validAccounts.add(account);
                    productsByAccountIdMap.put(account.Id, getMostRecentClosedOppField(account.Id, 'Product_Requested__c'));
                }
            }

            if (validAccounts.size() > 1) {
                return new BillerMatchWrapper(msgIfMultiAcctsMatch + supportPhoneNumber);
            }
            Id merchantAccountId = null;
            if(validAccounts.size() == 1){
                merchantAccountId = validAccounts[0].Id;
                List<Contact> contacts = [SELECT Id, Email FROM Contact WHERE AccountId = :validAccounts[0].Id AND Email =: requesterEmailAddress];
                
                if(contacts.size() == 0){
                    return new BillerMatchWrapper(msgIfNoContactFound + supportPhoneNumber + '.').withMerchantAccountId(merchantAccountId);
                }else {
                    tempRequesterConId = contacts[0].Id;
                }
            }
            System.debug('##>>>leadId: ' + leadId);
            // Query EFTPOS_User__c according to leadId
            List<EFTPOS_User__c> eftposUser = new List<EFTPOS_User__c>();
            if(String.isNotEmpty(leadId)){
                eftposUser = [SELECT  EFTPOS_Device_Owner_Account__r.Software__c,
                                    EFTPOS_Device_Owner_Opportunity__c,
                                    EFTPOS_Device_Owner_Opportunity__r.CSA__c
                                FROM    EFTPOS_User__c
                                WHERE   EFTPOS_Device_User_Lead__c = :leadId
                                LIMIT   1];
            }
            
            if (String.isEmpty(leadId) && validAccounts.size() == 1) {
                Boolean isMultiMidEnabled = PartnerConfigHelper.getPartnerAccountBySoftware(new Set<String> {validAccounts[0].Software__c})
                                                                .get(validAccounts[0].Software__c)?.Multi_MID_Enabled__c;
                Boolean hasEFTPOS = productsByAccountIdMap.get(validAccounts[0].Id)?.contains('EFTPOS');
                return new BillerMatchWrapper(msgIfAcctMatch, 'ProdAdd', isMultiMidEnabled, hasEFTPOS, getCSAId(validAccounts[0].Id), getOppId(validAccounts[0].Id))
                    .withMerchantAccountId(validAccounts[0].Id);
            }else if (String.isnotEmpty(leadId) && eftposUser.size() > 0) {
                if (validAccounts.size() == 1) {
                    if (validAccounts[0].Software__c == eftposUser[0].EFTPOS_Device_Owner_Account__r.Software__c) {
                        Boolean isMultiMidEnabled = PartnerConfigHelper.getPartnerAccountBySoftware(new Set<String> {validAccounts[0].Software__c})
                            .get(validAccounts[0].Software__c)?.Multi_MID_Enabled__c;
                        Boolean hasEFTPOS = productsByAccountIdMap.get(validAccounts[0].Id)?.contains('EFTPOS');
                        return new BillerMatchWrapper(msgIfAcctMatch, 'ProdAdd', isMultiMidEnabled, hasEFTPOS).withMerchantAccountId(merchantAccountId);
                    } else {
                        return new BillerMatchWrapper(msgIfSoftwareUnmatch, 'NormalCSA').withMerchantAccountId(merchantAccountId);
                    }
                }
    
                // If no accounts with valid statuses
                return new BillerMatchWrapper(msgIfInvalidStatus, 'NormalCSA');
            }else if (String.isnotEmpty(leadId) && eftposUser.size() == 0) {
                return new BillerMatchWrapper(msgIfNoUserFound + supportPhoneNumber);
            }

            // In future, change the following code to cater for partner referred leads
            // For now just return an error message
            return new BillerMatchWrapper(msgIfNoAcctMatch + supportPhoneNumber);
        } catch (Exception ex) {
            System.debug(ex);
            return new BillerMatchWrapper(msgIfErrorOut + supportPhoneNumber);
        }
    }

    @AuraEnabled
    public static String proceedToNormalCSA(String leadId) {
        Id ownerOppId;
        Id ownerCsaId;
        String eftposProvider;
        String ownerAccountName;
        // Validate input parameters
        if (String.isBlank(leadId)) {
            throw new BillerMatchException('Lead ID cannot be blank.');
        }

        try {
            List<EFTPOS_User__c> eftposUser = [
                SELECT  EFTPOS_Device_Owner_Opportunity__c,
                        EFTPOS_Device_Owner_Opportunity__r.CSA__c,
                        EFTPOS_Device_Owner_Account__r.EFTPOS_Provider__c,
                        EFTPOS_Device_Owner_Account__r.Name,
                        EFTPOS_Device_User_Opportunity__c,
                        EFTPOS_Device_User_Opportunity__r.CSA__c,
                        Prefill_User_CSA__c,
                        Status__c,
                        Signup_ID__c
                FROM    EFTPOS_User__c
                WHERE   EFTPOS_Device_User_Lead__c = :leadId
                LIMIT   1
            ];
			
            if ( eftposUser.size() > 0 ){
                // If EFTPOS_Device_User_Opportunity__c is set, it's already converted - just return existing CSA
                if (String.isNotBlank(eftposUser[0].EFTPOS_Device_User_Opportunity__c)) {
                    return getKYCUrl(eftposUser[0], eftposUser[0].EFTPOS_Device_User_Opportunity__c, eftposUser[0].EFTPOS_Device_User_Opportunity__r.CSA__c);
                }
                 ownerOppId = eftposUser[0].EFTPOS_Device_Owner_Opportunity__c;
                 ownerCsaId = eftposUser[0].EFTPOS_Device_Owner_Opportunity__r.CSA__c;
                 eftposProvider = eftposUser[0].EFTPOS_Device_Owner_Account__r.EFTPOS_Provider__c;
                 ownerAccountName = eftposUser[0].EFTPOS_Device_Owner_Account__r.Name;
            }

            // Convert Lead
            Database.LeadConvertResult leadConvert = AutoConvertLeads.ConvertLeadsWithoutOpp(leadId);
            
            if (!leadConvert.isSuccess()) {
                throw new BillerMatchException(msgIfErrorOut);
            }

            // If conversion successful, clone the Owner Opp & CSA
            Map<String, Schema.SObjectField> oppFieldsMap = Opportunity.SObjectType.getDescribe().fields.getMap();
            String oppFieldNames = String.join(new List<String>(oppFieldsMap.keySet()), ',');
            String oppQuery = 'SELECT ' + oppFieldNames + ' FROM Opportunity WHERE Id = \'' + ownerOppId + '\'';
            Opportunity ownerOpp = Database.query(oppQuery);

            // Query Owner CSA
            Map<String, Schema.SObjectField> csaFieldsMap = CSA__c.SObjectType.getDescribe().fields.getMap();
            String csaFieldNames = String.join(new List<String>(csaFieldsMap.keySet()), ',');
            String csaQuery = 'SELECT ' + csaFieldNames + ' FROM CSA__c WHERE Id = \'' + ownerCsaId + '\'';
            CSA__c ownerCSA = Database.query(csaQuery);
            Opportunity billerOpp = ownerOpp.clone(false, true, false, false);
            CSA__c billerCSA = ownerCSA.clone(false, true, false, false);

            Account billerAccount = [SELECT Name
                                    FROM Account 
                                    WHERE Id = :leadConvert.getAccountId()
                                    LIMIT 1];

            billerAccount.EFTPOS_Relationship__c = 'EFTPOS User';
            billerAccount.EFTPOS_Owner_Name__c = ownerAccountName;
            billerAccount.EFTPOS_Provider__c = eftposProvider;
            billerAccount.Trading_Name__c = billerAccount.Name;
            update billerAccount;

            billerOpp.AccountId = billerAccount.Id;
            billerOpp.Name = billerAccount.Name + '-';
            billerOpp.StageName = 'Proposal Stage';
            billerOpp.Multiple_EFTPOS_Users__c = false;
            billerOpp.isClosedCSA__c = false;
            billerOpp.isClosedAddProduct__c = false;
            billerOpp.IsClosed_CSA_Date__c = null;
            billerOpp.EF_Number_of_terminals__c = 0;
            // blank out risk values
            billerOpp.Client_Average_Transaction_Value__c = null;
            billerOpp.Client_Largest_Transaction_Value__c = null;
            billerOpp.Client_Number_of_Customers__c = null;
            billerOpp.Client_Payment_Frequency__c = null;
            billerOpp.Client_Average_Transaction_per_month__c = null;
            billerOpp.Client_Transactions_Near_Max_Amt__c =  null;
            billerOpp.Payments_way__c = null;
            billerOpp.Client_Average_days__c = null;
            billerOpp.Client_Maximum_days__c = null;
            billerOpp.Public_Contact__c = null;// resetting public contact option

            insert billerOpp;

            billerCSA.Opportunity__c = billerOpp.Id;
            billerCSA.Terminal_Rental_Fee_Waived__c = true;
            billerCSA.AMEX_MID_Hidden__c = true;
            insert billerCSA;

            billerOpp.CSA__c = billerCSA.Id;
            update billerOpp;

            //update contact
            Contact con = [
                        SELECT Id, Is_Primary_Contact__c, Is_Preferred_Contact__c
                        FROM Contact
                        WHERE Id = :leadConvert.getContactId()
                        LIMIT 1
                    ];
            con.Is_Primary_Contact__c = true;
            con.Is_Preferred_Contact__c = true;
            update con;

            // Remove any auto-created contact roles from the cloned opportunity
            List<OpportunityContactRole> existingRoles = [
                SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :billerOpp.Id
            ];
            if (!existingRoles.isEmpty()) {
                delete existingRoles;
            }

            OpportunityContactRole billerContactRole = new OpportunityContactRole();
            billerContactRole.contactId = con.Id;
            billerContactRole.opportunityId = billerOpp.Id;
            billerContactRole.Role = 'Decision Maker';
            billerContactRole.isPrimary = true;
            insert billerContactRole;

            if ( eftposUser.size() > 0 ){
                // Update EFTPOS User
                eftposUser[0].EFTPOS_Device_User_Account__c = billerAccount.Id;
                eftposUser[0].EFTPOS_Device_User_Opportunity__c = billerOpp.Id;
                update eftposUser[0];
            }

            return getKYCUrl(eftposUser[0], billerOpp.Id, billerCSA.Id);
        } catch (BillerMatchException ex) {
            System.debug('Unexpected exception: ' + ex.getMessage());
            throw new BillerMatchException(msgIfErrorOut);
        }
    }

    // TBA
    @AuraEnabled
    public static String proceedToProdAdd(String leadId) {
        // Q: How to handle the Lead if existing Account matches, TBA

        // Proceed to ProdAdd Page TBA
        return 'Proceed to ProdAdd (TBA)';
    }

    private static String getKYCUrl(EFTPOS_User__c eftposUser, String oppId, String csaId) {
        String kycUrl = '';
        if(eftposUser.Prefill_User_CSA__c){
            if(eftposUser.Status__c == 'Referred' && String.isNotBlank(eftposUser.Signup_ID__c)){
                return Global_Settings__c.getOrgDefaults().SiteURL__c + '/kyc_yourbusiness?signupId='+ eftposUser.Signup_ID__c;
            }else{
                return 'https://www.ezidebit.com/en-au/thank-you-au';
            }
        }else{
            kycUrl = Global_Settings__c.getOrgDefaults().SiteURL__c + '/kyc_yourbusiness?oppId='+ oppId + '&csa=' + csaId;
        }
        return kycUrl;
    }

    private static String getMostRecentClosedOppField(Id accountId, String fieldName) {
    // Query for closed opportunities under the given account that contain "EFTPOS" in Product_Requested__c
        List<Opportunity> opps = [
            SELECT Id, CreatedDate, Product_Requested__c, CSA__c
            FROM Opportunity 
            WHERE AccountId = :accountId 
            AND IsClosed = true AND IsWon = true
            AND Product_Requested__c INCLUDES ('EFTPOS')
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        // Return the field value or null if no opportunities are found
        if (!opps.isEmpty()) {
            return (String) opps[0].get(fieldName);
        }
        return null;
    }

    private static String getOppId(Id accountId) {
        return getMostRecentClosedOppField(accountId, 'Id');
}

    private static String getCSAId(Id accountId) {
        return getMostRecentClosedOppField(accountId, 'CSA__c');
    }

    public class BillerMatchWrapper {
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public String proceedTo { get; set; }
        @AuraEnabled public Boolean isMultiMidEnabled { get; set; }
        @AuraEnabled public Boolean hasEFTPOS { get; set; }
        @AuraEnabled public String csaId { get; set; }
        @AuraEnabled public String oppId { get; set; }
        @AuraEnabled public String siteURL { get; set; }
        @AuraEnabled public String requesterContactId { get; set; }
        @AuraEnabled public String merchantAccountId { get; set; }

        public BillerMatchWrapper withMerchantAccountId(String merchantAccountId) {
            this.merchantAccountId = merchantAccountId;
            return this;
        }

        public BillerMatchWrapper(String message) {
            this.message = message;
        }

        public BillerMatchWrapper(String message, String proceedTo) {
            this.message = message;
            this.proceedTo = proceedTo;
        }

        public BillerMatchWrapper(String message, String proceedTo, Boolean isMultiMidEnabled, Boolean hasEFTPOS) {
            this.message = message;
            this.proceedTo = proceedTo;
            this.isMultiMidEnabled = isMultiMidEnabled;
            this.hasEFTPOS = hasEFTPOS;
        }

        public BillerMatchWrapper(String message, String proceedTo, Boolean isMultiMidEnabled, Boolean hasEFTPOS, Id csaId, Id oppId) {
            this.message = message;
            this.proceedTo = proceedTo;
            this.isMultiMidEnabled = isMultiMidEnabled;
            this.hasEFTPOS = hasEFTPOS;
            this.csaId = csaId;
            this.oppId = oppId;
            this.siteURL = Global_Settings__c.getOrgDefaults().SiteURL__c;
            this.requesterContactId = String.isNotBlank(tempRequesterConId) ? tempRequesterConId : '';
        }
    }

    public class BillerMatchException extends Exception {}
}