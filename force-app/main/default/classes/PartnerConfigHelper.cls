public inherited sharing class PartnerConfigHelper {
    @AuraEnabled
    public static List<Partner_Configuration__c> getPartnerConfigsViaAccountId(Id accountId){
        return [SELECT Id, Name, Payment_Solutions__c FROM Partner_Configuration__c WHERE Partner_Account__c = :accountId];
    }

    public static Map<String, Partner_Configuration__c> getPartnerAccountBySoftware(Set<String> softwareList){
        Map<String, Partner_Configuration__c> partnerAccountBySoftware = new Map<String, Partner_Configuration__c>();
        List<Partner_Configuration__c> configList = [SELECT Name, Multi_MID_Enabled__c, Partner_Account__r.Name FROM Partner_Configuration__c WHERE Name IN :softwareList];
        for(Partner_Configuration__c config : configList){
            partnerAccountBySoftware.put(config.Name, config);
        }
        return partnerAccountBySoftware;
    }
}