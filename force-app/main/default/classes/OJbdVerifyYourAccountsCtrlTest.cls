@isTest
public with sharing class OJbdVerifyYourAccountsCtrlTest {

    @isTest
    static void testSaveFile() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        String fileName = 'TestDocument.pdf';
        String accountType = 'Checking';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Sample file content'));
        String recordId = testAccount.Id;

        Test.startTest();
        String contentLinkId = OJbdVerifyYourAccountsCtrl.saveFile(fileName, accountType, base64Data, recordId);
        Test.stopTest();

        System.assertNotEquals(null, contentLinkId, 'ContentDocumentLink ID should not be null');

        ContentDocumentLink contentLink = [
            SELECT Id, ContentDocumentId, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE Id = :contentLinkId
        ];
        System.assertEquals(recordId, contentLink.LinkedEntityId, 'LinkedEntityId should match the test Account Id');
    }

    @isTest
    static void testDeleteAttachment() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        String fileName = 'TestDocument.pdf';
        String accountType = 'Checking';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Sample file content'));
        String recordId = testAccount.Id;

        String contentLinkId = OJbdVerifyYourAccountsCtrl.saveFile(fileName, accountType, base64Data, recordId);


        ContentDocumentLink contentLink = [
            SELECT Id, ContentDocumentId, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE Id = :contentLinkId
        ];
        System.assertNotEquals(null, contentLink, 'ContentDocumentLink should exist');

        Test.startTest();
        String deleteMessage = OJbdVerifyYourAccountsCtrl.deleteAttachment(contentLinkId, recordId);
        Test.stopTest();


        System.assertEquals('Attachment deleted successfully', deleteMessage, 'The deleteAttachment method should return a success message');

        Integer linkCount = [
            SELECT COUNT() 
            FROM ContentDocumentLink 
            WHERE Id = :contentLinkId
        ];
        System.assertEquals(0, linkCount, 'ContentDocumentLink should be deleted');
    }
}