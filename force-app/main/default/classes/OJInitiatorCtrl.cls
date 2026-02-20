public without sharing class OJInitiatorCtrl {
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getRecords(String recordId, Map<String, List<String>> fields) {
    Map<String, Object> result = new Map<String, Object>();
    try {
        if (String.isEmpty(recordId) && UserInfo.getUserType() == 'PowerPartner') {
            List<User> currentUser = [SELECT Id, Name, Contact.AccountId FROM User WHERE Id =: UserInfo.getUserId()];
            If(currentUser.size() == 1){
                recordId = currentUser[0].Contact.AccountId;
            }
        }
        
        String objectName = SchemaUtil.getObjectNameById(recordId);
        List<String> objectFields = fields.get(objectName.toLowerCase() + 'Fields');
        String fieldString = String.join(objectFields, ', ');
        String query = 'SELECT ' + fieldString + ' FROM ' + objectName + ' WHERE Id = :recordId LIMIT 1';
        List<SObject> records = Database.query(query);

        SObject record = records[0];
        result.put(objectName, getFieldsData(record, objectFields));
            String brand = (String) record.get('Brand__c');
            if (String.isEmpty(brand)) {
                brand = 'Ezidebit';
            }

            List<String> themeFields = fields.get('themeFields');
            String themeFieldString = String.join(themeFields, ', ');
            String themeQuery = 'SELECT ' + themeFieldString + ' FROM Theme__c WHERE Name = :brand LIMIT 1';
            List<Theme__c> themes = Database.query(themeQuery);
            if (!themes.isEmpty()) {
                result.put('Theme', getFieldsData(themes[0], themeFields));
            }
        
    } catch (Exception ex) {
        throw new IllegalArgumentException(
            'An error occurred. Please contact support.' + ex.getMessage() + ', ' + ex.getStackTraceString()
        );
    }
    return result;
}

  private static Map<String, Object> getFieldsData(
    SObject theObject,
    List<String> fields
  ) {
    Map<String, Object> data = new Map<String, Object>();
    for (String field : fields) {
      data.put(field, theObject.get(field));
    }
    return data;
  }

   @AuraEnabled(cacheable=true)
    public static Map<String, String> getNewRequestUserData(String oppid,  String conid) {
    Map<String, String> resultMap = new Map<String, String>();
      Opportunity opp = [
          SELECT Id, Partner_Referred_Account__c, Account.Client_Code__c,	Account.ABN__c
          FROM Opportunity
          WHERE Id = :oppid
          LIMIT 1
      ];

      Contact con = [SELECT Id, Email FROM Contact WHERE Id = :conid];

      resultMap.put('requesterEmailAddress', con.Email);
      resultMap.put('businessNumber', opp.Account.ABN__c);
      resultMap.put('clientId', opp.Account.Client_Code__c);

      return resultMap;
    }
    
     /**
     * Retrieves Partner Configuration by Partner Account ID and optionally by Software
     * @param accountId The Partner Account ID
     * @param software The Software name (optional). If empty or null, only filters by accountId
     * @return Partner_Configuration__c record with Multi_MID_Enabled__c field, or null if not found
     */
    @AuraEnabled
    public static Partner_Configuration__c getPartnerConfigByAccountId(String accountId, String software){
        try {
            if (String.isBlank(accountId)) {
                return null;
            }
            
            List<Partner_Configuration__c> configList;
            
            if (String.isNotBlank(software) && software != 'Unknown') {
                // Filter by both accountId and software name
                configList = [
                    SELECT Id, Name, Multi_MID_Enabled__c, Partner_Account__r.Name, Partner_Account__r.Brand__c
                    FROM Partner_Configuration__c 
                    WHERE Partner_Account__c = :accountId 
                    AND Name = :software
                    LIMIT 1
                ];
            } 

            if(configList == null || configList.isEmpty()) {
                // Fallback: Filter only by accountId
                configList = [
                    SELECT Id, Name, Multi_MID_Enabled__c, Partner_Account__r.Name, Partner_Account__r.Brand__c
                    FROM Partner_Configuration__c 
                    WHERE Partner_Account__c = :accountId 
                    LIMIT 1
                ];
            }
            
            return configList.isEmpty() ? null : configList[0];
        } catch (Exception e) {
            System.debug('Error retrieving Partner Configuration for account: ' + accountId + ', software: ' + software + ' - ' + e.getMessage());
            throw new AuraHandledException('Unable to retrieve partner configuration: ' + e.getMessage());
        }
    }
}