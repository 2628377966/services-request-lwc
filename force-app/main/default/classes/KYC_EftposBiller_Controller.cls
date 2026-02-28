public without sharing class KYC_EftposBiller_Controller {
     private Account acc;
     private Opportunity opp { get; set; }
     public String oppid { get; set; }
     public String csaid { get; set; }
     public String accid { get; set; }
     public String origin { get; set; }
     public String nextPageName { get; set; }
     public String conid { get; set; }

     public String logo { get; set; }
     public String supportPhoneNo { get; set; }
     public String software { get; set; }
     public Boolean isEzidebitBrand { get; set; }
     public String brandType { get; set; }

     public KYC_EftposBiller_Controller() {
          oppid = system.currentPageReference().getParameters().get('oppId');
          csaid = system.currentPageReference().getParameters().get('csa');
          origin = system.currentPageReference().getParameters().get('origin');
          conid = system.currentPageReference().getParameters().get('conid');
          logo = getLogo(oppId);

          opp = getOpp(oppId);
          accid = opp.Accountid;

          acc = [
               SELECT
                    software__c,
                    Brand__c,
                    Support_phone_number__c,
                    EFTPOS_Provider__c,
                    Entity_types__c
               FROM Account
               WHERE Id = :opp.AccountId
          ];
          software = acc.software__c;
          isEzidebitBrand =
               String.isBlank(acc.Brand__c) ||
               (String.isNotBlank(acc.Brand__c) && acc.Brand__c == 'Ezidebit');
          supportPhoneNo = acc.Support_phone_number__c;
          brandType = acc.Brand__c;

          if (acc.Entity_types__c.contains('Government')) {
               nextPageName = 'KYC_Execution';
          } else if (acc.Entity_types__c == 'Individual/Sole Trader') {
               nextPageName = 'KYC_VerifyIndividual';
          } else {
               nextPageName = 'KYC_CompanyOfficers';
          }
     }

     public PageReference init() {
          return null;
     }

     private Opportunity getOpp(String oppId) {
          Opportunity opp = [
               SELECT Accountid, Software__c
               FROM Opportunity
               WHERE Id = :oppid
          ];
          return opp;
     }

     private String getLogo(String oppId) {
         Opportunity opp = [SELECT AccountId FROM Opportunity WHERE Id = :oppId];
         if (String.isNotBlank(opp?.AccountId)) {
             Account acc = [SELECT Partner_Logo_URL__c FROM Account WHERE Id = :opp.AccountId];
             return acc?.Partner_Logo_URL__c;
         }
         return '';
    }
}