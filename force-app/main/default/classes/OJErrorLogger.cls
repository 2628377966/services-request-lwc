public class OJErrorLogger {
    public static void sendMail(String mailSubject, String mailBody) {
        try {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            List<string> toAddress = new List<string>();
            List<ApexEmailNotification> toAddressList = [SELECT User.Email FROM ApexEmailNotification WHERE Email = '' AND USER.IsActive = true];
            List<ApexEmailNotification> toAddressAdditionalList = [SELECT Email FROM ApexEmailNotification WHERE Email != ''];
            if (toAddressList.size() == 0 && toAddressAdditionalList.size() == 0) {
                toAddress.add(Label.Ezidebit_Error_Email_Address);
            } else {
                for(Integer i = 0; i < toAddressList.size(); i++){
                    toAddress.add(toAddressList[i].User.Email);
                }
                for(Integer i = 0; i < toAddressAdditionalList.size(); i++){
                    toAddress.add(toAddressAdditionalList[i].Email);
                }
            }
            
            message.setToAddresses(toAddress);
            message.subject = mailSubject;
            message.plaintextbody = mailBody;
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        } catch (Exception e) {
            System.debug('Error sending email: ' + e.getMessage());
        }
    }

    public static String processEmailBody(String emailBody, String RelatedEntityType, String recordId) {
        Pattern pattern = Pattern.compile('\\{\\{\\{([a-zA-Z_][a-zA-Z0-9_]*(?:\\.[a-zA-Z_][a-zA-Z0-9_]*)*)\\}\\}\\}');
        Matcher matcher = pattern.matcher(emailBody);
        Set<String> fieldNames = new Set<String>();
        while (matcher.find()) {
            String fieldName = matcher.group(1);
            fieldNames.add(fieldName);
        }
        if (fieldNames.size() > 0) {
            String soqlQuery = 'SELECT ' + String.join(new List<String>(fieldNames), ', ') + ' FROM ' + RelatedEntityType + ' WHERE Id = :recordId';
            SObject record = Database.query(soqlQuery);
            matcher.reset();
            while (matcher.find()) {
                String fieldName = matcher.group(1);
                String[] fieldPath = fieldName.split('\\.');
                SObject relatedRecord = record;
                String fieldValue = '';
                for (Integer i = 1; i < fieldPath.size(); i++) {
                    if (i == fieldPath.size() - 1) {
                        fieldValue = (String) relatedRecord.get(fieldPath[i]);
                    } else {
                        relatedRecord = (SObject) relatedRecord.getSobject(fieldPath[i]);
                    }
                }
                emailBody = emailBody.replace(matcher.group(0), fieldValue);
            }
        }
        return emailBody;
    }
}
