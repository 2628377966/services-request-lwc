public inherited sharing class AutoConvertLeads {

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
            System.debug('An error occured while converting the lead: Line Number: ' + ex.getLineNumber() + ', ' + ex.getStackTraceString() + ', ' + ex.getMessage());
            return null;
        }
    }
}