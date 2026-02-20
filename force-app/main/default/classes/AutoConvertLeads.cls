public inherited sharing class AutoConvertLeads {

    @InvocableMethod
    public static void ConvertLeads(List<Id> leadIds) {
        if (leadIds.size() == 0) return;

        for(Id eachLeadId: leadIds){
            try{
                LeadStatus leads = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
                    
                Database.LeadConvert leadConvert = new Database.LeadConvert();
                leadConvert.setLeadId(eachLeadId);
                leadConvert.setConvertedStatus(leads.MasterLabel);
            
                Database.LeadConvertResult leadConverts = Database.convertLead(leadConvert);
                if( leadConverts.isSuccess() ) {
                    // based on the Auto Email offer on Onboard Parnter mapping either the offer will be sent and auto emailed to partner 
                    // or will not be sent to onboard at all check sendPartnerOfferToOnboard for further checks
                    List<Lead> ld = [SELECT id, Onboard_Package_Id__c, Form_Code__c FROM LEAD where Id = :eachLeadId ];
                    if( !String.isBlank(ld[0].Onboard_Package_Id__c) && !String.isBlank(ld[0].Form_Code__c))
                        sendPartnerRefferalOfferToOnboard.sendPartnerOfferToOnboard(eachLeadId , leadConverts.getOpportunityId(), leadConverts.getAccountId());
                }
            }catch(Exception ex){
                System.debug('Error in lead conversion: ' + ex.getMessage());
            }
        }
    }

    @Future
    public static void ConvertLead(Id leadId) {
        try {
            LeadStatus leads = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];

            Database.LeadConvert leadConvert = new Database.LeadConvert();
            leadConvert.setLeadId(leadId);
            leadConvert.setConvertedStatus(leads.MasterLabel);

            Database.LeadConvertResult leadConverts = Database.convertLead(leadConvert);
        } catch (Exception ex) {
            OnBoardUtils.writeGPLog('An error occured while converting the lead' , 'Line Number: ' + ex.getLineNumber() + ', ' + ex.getStackTraceString() + ', ' + ex.getMessage() , 'ERROR', 'Lead Conversion', null, null);
        }
    }

    public static Database.LeadConvertResult ConvertLeadsWithoutOpp(Id leadId) {
        try {
                if (String.isBlank(leadId)) return null;
        
                LeadStatus leadStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        
                Database.LeadConvert leadConvert = new Database.LeadConvert();

                leadConvert.setLeadId(leadId);
                leadConvert.setConvertedStatus(leadStatus.MasterLabel);
                leadConvert.setDoNotCreateOpportunity(true);
        
                return Database.convertLead(leadConvert);
        } catch (Exception ex){
            //Checking the error
            OnBoardUtils.writeGPLog('An error occured while converting the lead' , 'Line Number: ' + ex.getLineNumber() + ', ' + ex.getStackTraceString() + ', ' + ex.getMessage() , 'ERROR', 'Lead Conversion without Opp', null, null);
            return null;
            //throw ex;
        }
    }
}