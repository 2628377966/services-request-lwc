public without sharing class OJbdVerifyYourAccountsCtrl {
    @AuraEnabled
    public static String saveFile(String fileName, String accountType, String base64Data, String recordId) {

        String fileExtension = fileName.substringAfterLast('.');
        String cleanFileName = fileName.substringBeforeLast('.').replaceAll('\\s+', '_'); 
        String timeStamp = Datetime.now().format('yyyyMMdd_HHmmss');
        String newFileName = accountType + '_Bank_Statement_' + cleanFileName + '_' + timeStamp + '.' + fileExtension;
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = newFileName;
        contentVersion.PathOnClient = newFileName;
        contentVersion.VersionData = EncodingUtil.base64Decode(base64Data);
        insert contentVersion;

        // Associate the file with the record
        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
        contentLink.LinkedEntityId = recordId;
        contentLink.ShareType = 'V';
        contentLink.Visibility = 'AllUsers';
        insert contentLink;

        return contentLink.Id;
    }

    @AuraEnabled
    public static String deleteAttachment(String documentLinkId,String attachedRecId){
        try {
            ContentDocumentLink contentLink = [
                SELECT Id, ContentDocumentId, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE Id = :documentLinkId AND LinkedEntityId = :attachedRecId 
                LIMIT 1
            ];
            
            delete contentLink;
            // Check if the ContentDocument has other associated links
            Integer remainingLinks = [
                SELECT COUNT() 
                FROM ContentDocumentLink 
                WHERE ContentDocumentId = :contentLink.ContentDocumentId
            ];
    
            if (remainingLinks == 0) {
                ContentDocument contentDocument = [
                    SELECT Id 
                    FROM ContentDocument 
                    WHERE Id = :contentLink.ContentDocumentId
                ];
                delete contentDocument;
            }
    
            return 'Attachment deleted successfully';

        } catch (Exception e) {
            System.debug('Error deleting attachment: ' + e.getMessage());
            return 'Error deleting attachment: ' + e.getMessage();
        }
    }

}