public without sharing class OjdbMainCtrl {
    @AuraEnabled(cacheable=false)
    public static void saveApplication(String payload, String accountId) {
        Map<String, Object> applicationMap = (Map<String, Object>) JSON.deserializeUntyped(payload);
        Application__c newApplication = new Application__c();
        newApplication.Application_Type__c = 'Change of Bank Details';
        newApplication.Application_Status__c = 'Submitted';
        newApplication.Account__c = accountId;
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id =: accountId LIMIT 1];
        List<Application__c> lastApplication = [SELECT Id, Name FROM Application__c WHERE Application_Type__c = 'Change of Bank Details' AND Account__c = :accountId ORDER BY Id DESC LIMIT 1];
        User apiUser = [SELECT Id FROM User WHERE Username LIKE '%apiuser@ezidebit.com.au%' AND Name = 'APIUSER' LIMIT 1];

        Integer applicationNumber = 1;
        if(lastApplication.size() > 0){
            applicationNumber = extractNumber(lastApplication[0].Name) + 1;
        }
        newApplication.Name = trimStringToMaxLength('Change of Bank Details - ' + accounts[0].Name) + ' - ' + applicationNumber;
        for (String fieldName : applicationMap.keySet()) {
            newApplication.put(fieldName, applicationMap.get(fieldName));
        }
        newApplication.OwnerId = apiUser.Id;
        
        insert newApplication;
    }

    private static Integer extractNumber(String inputString) {
        List<String> parts = inputString.split(' - ');
        if (parts.size() > 2) {
            try {
                return Integer.valueOf(parts[2]);
            } catch (Exception e) {
                System.debug('Error converting to Integer: ' + e.getMessage());
            }
        }
        return null;
    }

    public static String trimStringToMaxLength(String input) {
        if (input.length() <= 70) {
            return input;
        }
        return input.substring(0, 70);
    }

    /**
     * Retrieves Partner Configuration by software name 
     * @param softwareName The software name (e.g., 'Xero', 'MYOB')
     * @return Partner_Configuration__c record with Multi_MID_Enabled__c field, or null if not found
     */
    @AuraEnabled
    public static Partner_Configuration__c getPartnerConfigBySoftware(String softwareName){
        try {
            if (String.isBlank(softwareName)) {
                return null;
            }
            
            List<Partner_Configuration__c> configList = [
                SELECT Id, Name, Multi_MID_Enabled__c, Partner_Account__r.Name, Partner_Account__r.Brand__c
                FROM Partner_Configuration__c 
                WHERE Name = :softwareName 
                LIMIT 1
            ];
            return configList.isEmpty() ? null : configList[0];
        } catch (Exception e) {
            System.debug('Error retrieving Partner Configuration for software: ' + softwareName + ' - ' + e.getMessage());
            throw new AuraHandledException('Unable to retrieve partner configuration: ' + e.getMessage());
        }
    }
}