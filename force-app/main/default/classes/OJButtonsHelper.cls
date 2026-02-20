public without sharing class OJButtonsHelper {
    @AuraEnabled(cacheable=true)
    public static List<OJ_Button_Label__mdt> getFormButtonLabels(String brand) {
        List<String> fields = new List<String>{'DeveloperName','Button1_Label__c','Button2_Label__c'};
        String buttonsQuery = 'SELECT ' + String.join(fields, ', ') + ' FROM OJ_Button_Label__mdt WHERE Brand__c = :brand ORDER BY DeveloperName';
        List<OJ_Button_Label__mdt> formButtons = Database.query(buttonsQuery);
        if(formButtons.isEmpty()){
            throw new CustomException('No labels found for the brand: ' + brand);
        }

        return formButtons;
    }
}