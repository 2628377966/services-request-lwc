public class SchemaUtil {
    //Smartapps: dd/MM/yyyy
    public static final String DATE_PARSE_STRING_FORMAT = '^\\d{2}/\\d{2}/\\d{4}$';
    //Smartapps: yyyy-MM-dd
    public static final String DATE_VALUE_STRING_FORMAT = '^\\d{4}-\\d{2}-\\d{2}$';
    //Smartapps: dd/MM/yyyy hh:mm AM/PM
    public static final String DATETIME_PARSE_STRING_FORMAT= '^\\d{1,2}/\\d{1,2}/\\d{4} \\d{1,2}:\\d{1,2} [AP]M$';
    //Smartapps: yyyy-MM-dd HH:mm:ss
    public static final String DATETIME_VALUE_STRING_FORMAT = '^\\d{4}-\\d{2}-\\d{2} (?:[01]\\d|2[0123]):(?:[012345]\\d):(?:[012345]\\d)$';
    //Smartapps: yyyy-MM-dd'T'HH:mm:ss.sss'Z'
    public static final String DATETIME_LIGHTNING_INPUT_FORMAT = '^\\d{4}-\\d{2}-\\d{2}T(?:[01]\\d|2[0123]):(?:[012345]\\d):(?:[012345]\\d).\\d+Z$';

    public static SObject createObject(String typeName) {
        Schema.SObjectType targetType = createObjectType(typeName);
        return createObject(targetType);
    }

    public static SObject createObject(SObjectType sObjectType) {
        if (sObjectType == null) {
            return null;
        }
        return sObjectType.newSObject();
    }

    public static SObjectType createObjectType(String objectName) {
        SObjectType type;
        if (String.isNotBlank(objectName)) {
            type = Schema.getGlobalDescribe().get(objectName.trim().toLowerCase());
        }
        return type;
    }

    public static DescribeSObjectResult createDescribeSObjectResult(SObjectType sObjectType) {
        if (sObjectType == null) {
            return null;
        }
        return sObjectType.getDescribe();
    }

    public static DescribeSObjectResult getDescribeSObjectResult(String typeName) {
        Schema.SObjectType objectType = createObjectType(typeName);
        return createDescribeSObjectResult(objectType);
    }

    public static String getSObjectName(SObjectType objectType) {
        String sObjName = '';
        DescribeSObjectResult sObjectResult = createDescribeSObjectResult(objectType);
        if (sObjectResult != null) {
            sObjName = sObjectResult.getName();
        }
        return sObjName;
    }

    public static String getSObjectLabel(SObjectType objectType) {
        String sObjLabel;
        DescribeSObjectResult sObjectResult = createDescribeSObjectResult(objectType);
        if (sObjectResult != null) {
            sObjLabel = sObjectResult.getLabel();
        }
        return sObjLabel;
    }

    public static SObjectType getSObjectTypeFromId(Id sObjectId) {
        SObjectType sObjectType;
        if (String.isNotBlank(sObjectId)) {
            sObjectType = sObjectId.getSobjectType();
        }
        return sObjectType;
    }

    public static String getSObjectNameFromId(Id sObjectId) {
        SObjectType sObjectType = getSObjectTypeFromId(sObjectId);
        return getSObjectName(sObjectType);
    }

    public static String getSObjectLabelFromId(Id sObjectId) {
        SObjectType sObjectType = getSObjectTypeFromId(sObjectId);
        return getSObjectLabel(sObjectType);
    }

    public static String getRecordNameFromId(Id sObjectId) {
        String recordName;
        String sObjectName = getSObjectNameFromId(sObjectId);
        if (String.isNotBlank(sObjectName)) {
            List<SObject> foundSObjects = Database.query('select Id, Name from ' +  String.escapeSingleQuotes(sObjectName) + ' where Id= \'' + String.escapeSingleQuotes(sObjectId) + '\' limit 1');
            if (foundSObjects != null && !foundSObjects.isEmpty()) {
                recordName = (String)foundSObjects[0].get('Name');
            }
        }
        return recordName;
    }

    public static Map<String, SObjectType> getSObjectTypeMap() {
        Map<String,SObjectType> returnMap = new Map<String, SObjectType>();
        Map<String,SObjectType> describeMap = Schema.getGlobalDescribe();
        for (String key : describeMap.keySet()) {
            SObjectType type = describeMap.get(key);
            DescribeSObjectResult result = type.getDescribe();
            if (result.isQueryable()) {
                returnMap.put(key.capitalize(), type);
            }
        }
        return returnMap;
    }

    //lowercase api name to label, i.e. 'custom_field__c' -> 'Custom Field'
    public static Map<String, String> getFieldLabels(String sObjName){
        Map<String, String> fieldLabels = new Map<String, String>();
        Map<String, Schema.SObjectField> fieldMap = getSObjectFieldMap(createObjectType(sObjName));
        for(String fieldAPIName : fieldMap.keySet()){
            fieldLabels.put(fieldAPIName, fieldMap.get(fieldAPIName).getDescribe().getLabel());
        }
        return fieldLabels;
    }

    public static Map<String, Schema.SObjectField> getSObjectFieldMap(SObjectType objectType) {
        Schema.DescribeSObjectResult r = createDescribeSObjectResult(objectType);
        return (r != null && r.isQueryable()) ? r.fields.getMap() : new Map<String, Schema.SObjectField>();
    }

    public static List<Schema.SObjectField> getSObjectFieldList(SObjectType objectType) {
        Map<String, Schema.SObjectField> fieldMap = SchemaUtil.getSObjectFieldMap(objectType);
        return fieldMap.values();
    }

    public static Boolean isFieldContainedBySObject(SObjectType objectType, String fieldName) {
        Map<String, Schema.SObjectField> fieldMap = SchemaUtil.getSObjectFieldMap(objectType);
        return (String.isNotBlank(fieldName) && fieldMap.containsKey(fieldName.trim().toLowerCase()));
    }

    public static Boolean isFieldEditable(SObjectType objectType, String fieldName) {
        Schema.DescribeFieldResult fieldDescribeResult = getDescribeFieldResult(objectType, fieldName);
        return isFieldEditable(fieldDescribeResult);
    }

    public static Boolean isFieldEditable(Schema.DescribeFieldResult fieldDescribeResult) {
        return (fieldDescribeResult != null && !fieldDescribeResult.isCalculated() && !fieldDescribeResult.isExternalId() && !fieldDescribeResult.isAutoNumber() && !fieldDescribeResult.isEncrypted());
    }

    //Smartapps: true if the field can be edited by the current user, or child records in a master-detail relationship field on a custom object can be reparented to different parent records; false otherwise.
    public static Boolean isFieldUpdateable(SObjectType objectType, String fieldName) {
        Schema.DescribeFieldResult fieldDescribeResult = getDescribeFieldResult(objectType, fieldName);
        return isFieldUpdateable(fieldDescribeResult);
    }
    //Smartapps: true if the field can be edited by the current user, or child records in a master-detail relationship field on a custom object can be reparented to different parent records; false otherwise.
    public static Boolean isFieldUpdateable(Schema.DescribeFieldResult fieldDescribeResult) {
        return (fieldDescribeResult != null && fieldDescribeResult.isUpdateable());
    }

    public static Boolean isFieldContainedBySObject(Map<String, Schema.SObjectField> fieldMap, String fieldName) {
        return (fieldMap != null && String.isNotBlank(fieldName) && fieldMap.containsKey(fieldName.toLowerCase()));
    }

    public static Schema.DescribeFieldResult getDescribeFieldResult(SObjectType objectType, String fieldName) {
        Map<String, Schema.SObjectField> fieldMap = SchemaUtil.getSObjectFieldMap(objectType);
        Schema.SObjectField field = isFieldContainedBySObject(fieldMap, fieldName) ? fieldMap.get(fieldName.toLowerCase()) : null;
        return field != null ? field.getDescribe() : null;
    }

    public static String getFieldDisplayType(SObjectType objectType,String fieldName) {
        String displayType;
        Schema.DescribeFieldResult fieldDescribeResult = getDescribeFieldResult(objectType, fieldName);
        Schema.DisplayType fieldDisplayType = getFieldDisplayType(fieldDescribeResult);
        if (fieldDisplayType != null) {
            displayType = fieldDisplayType.name();
        }
        return displayType;
    }

    public static Schema.DisplayType getFieldDisplayType(Schema.DescribeFieldResult fieldDescribeResult) {
        return fieldDescribeResult != null ? fieldDescribeResult.getType() : null;
    }

    public static List<Schema.PickListEntry> getPickListTypeFieldEntries(SObjectType sObjectType, String fieldName) {
        Schema.DescribeFieldResult fieldDescribeResult = getDescribeFieldResult(sObjectType, fieldName);
        return getPickListTypeFieldEntries(fieldDescribeResult);
    }

    public static List<String> getPickListTypeFieldValues(SObjectType sObjectType, String fieldName) {
        List<String> picklistValues = new List<String>();
        List<Schema.PickListEntry> picklistEntries = getPickListTypeFieldEntries(sObjectType, fieldName);
        for (Schema.PickListEntry entry : picklistEntries) {
            picklistValues.add(entry.getValue());
        }
        return picklistValues;
    }

    public static List<Schema.PickListEntry> getPickListTypeFieldEntries(Schema.DescribeFieldResult fieldDescribeResult) {
        List<Schema.PickListEntry> picklistEntries = new List<Schema.PickListEntry>();
        DisplayType fieldDisplayType = getFieldDisplayType(fieldDescribeResult);
        if (fieldDisplayType == DisplayType.PICKLIST || fieldDisplayType == DisplayType.MULTIPICKLIST) {
            picklistEntries = fieldDescribeResult.getPicklistValues();
        }
        return picklistEntries;
    }

    public static Object convertStringBasedOnFieldDisplayType(SObjectType sObjectType, String fieldName, String fieldValue) {
        Object castedFieldValue = fieldValue;
        try {
            Schema.DescribeFieldResult fieldDescribeResult = getDescribeFieldResult(sObjectType, fieldName);
            Schema.DisplayType fieldType = SchemaUtil.getFieldDisplayType(fieldDescribeResult);
            if (String.isNotBlank(fieldValue)) {
                if (fieldType == Schema.DisplayType.DATETIME){
                    if (checkIfStringMatchPattern(fieldValue, DATETIME_PARSE_STRING_FORMAT)) {
                        castedFieldValue = Datetime.parse(fieldValue);
                    } else if (checkIfStringMatchPattern(fieldValue, DATETIME_VALUE_STRING_FORMAT)) {
                        castedFieldValue = Datetime.valueOf(fieldValue);
                    } else if (checkIfStringMatchPattern(fieldValue, DATETIME_LIGHTNING_INPUT_FORMAT)) {
                        castedFieldValue = Datetime.valueOf(fieldValue.replace('T',' ').replace('Z',''));
                    } else if (checkIfStringMatchPattern(fieldValue, DATE_PARSE_STRING_FORMAT)) {
                        castedFieldValue = Date.parse(fieldValue);
                    } else if (checkIfStringMatchPattern(fieldValue, DATE_VALUE_STRING_FORMAT) || checkIfStringMatchPattern(fieldValue, DATETIME_VALUE_STRING_FORMAT)) {
                        castedFieldValue = Date.valueOf(fieldValue);
                    }
                } else if (fieldType == Schema.DisplayType.DATE){
                    if (checkIfStringMatchPattern(fieldValue, DATE_PARSE_STRING_FORMAT)) {
                        castedFieldValue = Date.parse(fieldValue);
                    } else if (checkIfStringMatchPattern(fieldValue, DATE_VALUE_STRING_FORMAT)) {
                        castedFieldValue = Date.valueOf(fieldValue);
                    }
                } else if (fieldType == Schema.DisplayType.TIME && (fieldValue.endsWithIgnoreCase('AM') || fieldValue.endsWithIgnoreCase('PM'))){
                    Datetime dt = Datetime.now();
                    String dateTimeString = dt.format('dd/MM/yyyy', 'Australia/Melbourne');
                    dt = Datetime.parse(dateTimeString + ' ' + fieldValue);
                    castedFieldValue = Time.newInstance(dt.hour(), dt.minute(), dt.second(), dt.millisecond());
                } else if (fieldType == Schema.DisplayType.DOUBLE || fieldType == Schema.DisplayType.INTEGER || fieldType == Schema.DisplayType.CURRENCY || fieldType == Schema.DisplayType.PERCENT){
                    fieldValue = fieldValue.replaceAll('\\s*,\\s*', '');
                    castedFieldValue = Decimal.valueOf(fieldValue);
                } else if (fieldType == Schema.DisplayType.REFERENCE || fieldType == Schema.DisplayType.ID){
                    castedFieldValue = Id.valueOf(fieldValue);
                } else if (fieldType == Schema.DisplayType.BOOLEAN){
                    castedFieldValue = Boolean.valueOf(fieldValue);
                }
            } else {
                castedFieldValue = null;
            }
        } catch(Exception ex) {
            castedFieldValue = null;
            System.debug('SchemaUtil.convertStringBasedOnFieldDisplayType() failed, ex= ' + ex.getMessage() + ', ' + ex.getStackTraceString());
        }

        return castedFieldValue;
    }

    public static String convertObjectToStringBasedOnFieldDisplayType(SObjectType sObjectType, String fieldName, Object fieldValue) {
        String fieldValueString;
        try {
            Schema.DescribeFieldResult fieldDescribeResult = getDescribeFieldResult(sObjectType, fieldName);
            Schema.DisplayType fieldType = SchemaUtil.getFieldDisplayType(fieldDescribeResult);
            if (fieldType != null && fieldValue != null) {
                fieldValueString = String.valueOf(fieldValue);
                if (fieldType == Schema.DisplayType.DATETIME){
                    Datetime dateTimeObject = (Datetime) fieldValue;
                    fieldValueString = dateTimeObject.format('yyyy-MM-dd HH:mm:ss', 'Australia/Melbourne');
                } else if (fieldType == Schema.DisplayType.DATE){
                    Date dateObject = (Date) fieldValue;
                    Datetime dateTimeObject = Datetime.newInstance(dateObject.year(), dateObject.month(),dateObject.day());
                    fieldValueString = dateTimeObject.format('dd/MM/yyyy', 'Australia/Melbourne');
                } else if (fieldType == Schema.DisplayType.DOUBLE){
                    Double doubleObject = (Decimal) fieldValue;
                    Decimal decimalObject = Decimal.valueOf(doubleObject);
                    decimalObject.setScale(2);
                    fieldValueString = decimalObject.format();
                } else if (fieldType == Schema.DisplayType.INTEGER){
                    Double doubleObject = (Decimal) fieldValue;
                    Decimal decimalObject = Decimal.valueOf(doubleObject);
                    decimalObject.setScale(0);
                    fieldValueString = decimalObject.format();
                } else if (fieldType == Schema.DisplayType.CURRENCY){
                    Double doubleObject = (Decimal) fieldValue;
                    Decimal decimalObject = Decimal.valueOf(doubleObject);
                    decimalObject.setScale(2);
                    fieldValueString = decimalObject.format();
                } else if (fieldType == Schema.DisplayType.PERCENT){
                    Double doubleObject = (Decimal) fieldValue;
                    Decimal decimalObject = Decimal.valueOf(doubleObject);
                    decimalObject.setScale(0);
                    fieldValueString = decimalObject.format();
                }
            }
        } catch (Exception ex) {
            fieldValueString = null;
            System.debug('SchemaUtil.convertObjectToStringBasedOnFieldDisplayType() failed, ex= ' + ex.getMessage() + ', ' + ex.getStackTraceString());
        }
        return fieldValueString;
    }

    public static List<String> getSObjectFieldNames(SObjectType objectType) {
        return new List<String>(getSObjectFieldMap(objectType).keySet());
    }

    public static List<String> getObjectTypeNames() {
        return new List<String>(getSObjectTypeMap().keySet());
    }

    public static String findAllFieldNames(SObjectType sObjectType) {
        List<String> allFieldNames = getSObjectFieldNames(sObjectType);
        return String.join(allFieldNames, ', ');
    }

    public static String buildGeneralDatabaseQuery(String sObjectName) {
        return 'select ' + findAllFieldNames(createObjectType(sObjectName)) + ' from ' + sObjectName + ' ';
    }

    public static String buildGeneralDatabaseQuery(SObjectType sObjectType) {
        String sObjectName = sObjectType.getDescribe().getName();
        return 'select ' + findAllFieldNames(sObjectType) + ' from ' + sObjectName + ' ';
    }

    public static Boolean isFieldExist(SObjectType sObjectType, String fieldName) {
        Boolean isValid = false;
        List<String> allFieldNames = getSObjectFieldNames(sObjectType);
        for (String name : allFieldNames) {
            if (name.equalsIgnoreCase(fieldName)) {
                isValid = true;
                break;
            }
        }
        return isValid;
    }

    public static String buildIdsString(Set<Id> ids) {
        List<String> idList = new List<String>();
        if (ids != null && !ids.isEmpty()) {
            for (Id id : ids) {
                idList.add(' \'' + String.escapeSingleQuotes(id) + '\' ');
            }
            return ' (' + String.join(idList, ', ') + ') ';
        } else {
            return '';
        }
    }

    public static String buildInQueryString(Set<String> candidateSet) {
        List<String> candidateList = new List<String>();
        if (candidateSet != null && !candidateSet.isEmpty()) {
            for (String candidate : candidateSet) {
                candidateList.add(' \'' + String.escapeSingleQuotes(candidate) + '\' ');
            }
            return ' (' + String.join(candidateList, ', ') + ') ';
        } else {
            return '';
        }
    }

    public static SObjectType getReferenceToObjectType(Schema.DescribeFieldResult fieldDescribeResult) {
        SObjectType referenceToObjectType;
        List<SObjectType> referenceToObjectTypes = fieldDescribeResult.getReferenceTo();
        if (referenceToObjectTypes != null && !referenceToObjectTypes.isEmpty()) {
            referenceToObjectType = referenceToObjectTypes[0];
        }
        return referenceToObjectType;
    }

    public static SObject getParentSObjectRecord(String selfRecordId, SObjectType parentSObjectType) {
        SObject parentSObject;
        if (String.isBlank(selfRecordId) || (parentSObjectType == null)) {
            return parentSObject;
        }

        SObjectType selfSObjectType = getSObjectTypeFromId(Id.valueOf(selfRecordId));
        String selfSObjectName = getSObjectName(selfSObjectType);

        Map<String, Schema.SObjectField> fieldMap = getSObjectFieldMap(selfSObjectType);
        for (String fieldName : fieldMap.keySet()) {
            Schema.SObjectField field = fieldMap.get(fieldName);
            Schema.DescribeFieldResult fieldDescribeResult = field.getDescribe();
            if (getFieldDisplayType(fieldDescribeResult) == Schema.DisplayType.REFERENCE) {
                SObjectType referenceToObjectType = getReferenceToObjectType(fieldDescribeResult);
                if (parentSObjectType == referenceToObjectType) {
                    List<SObject> selfRecordList = Database.query('select ' + fieldName + ' from ' + selfSObjectName + ' where Id= \'' + String.escapeSingleQuotes(selfRecordId) + '\' limit 1');
                    if (selfRecordList != null && !selfRecordList.isEmpty()) {
                        String parentSObjectRecordId = (String)selfRecordList[0].get(fieldName);
                        if (String.isNotBlank(parentSObjectRecordId)) {
                            List<SObject> parentSObjectRecords = Database.query(buildGeneralDatabaseQuery(parentSObjectType) + ' where Id= \'' + String.escapeSingleQuotes(parentSObjectRecordId) + '\' limit 1');
                            if (parentSObjectRecords != null && !parentSObjectRecords.isEmpty()) {
                                parentSObject = parentSObjectRecords[0];
                                break;
                            }
                        }

                    }
                }
            }
        }

        return parentSObject;
    }

    public static SObject getSelfSObjectRecord(String selfRecordId, SObjectType targetSObjectType) {
        SObject selfSObject;
        if (targetSObjectType != getSObjectTypeFromId(selfRecordId)) {
            return selfSObject;
        }

        SObjectType selfSObjectType = getSObjectTypeFromId(Id.valueOf(selfRecordId));

        List<SObject> selfSObjectRecords = Database.query(buildGeneralDatabaseQuery(selfSObjectType) + ' where Id = \'' + String.escapeSingleQuotes(selfRecordId) + '\' limit 1');
        if (selfSObjectRecords != null && !selfSObjectRecords.isEmpty()) {
            selfSObject = selfSObjectRecords[0];
        }
        return selfSObject;
    }

    public static List<SObject> getChildSObjectRecords(String selfRecordId, SObjectType childSObjectType, String extraConditions) {
        List<SObject> childSObjectRecords = new List<SObject>();

        if (String.isBlank(selfRecordId) || (childSObjectType == null)) {
            return childSObjectRecords;
        }

        SObjectType selfSObjectType = getSObjectTypeFromId(Id.valueOf(selfRecordId));

        for (Schema.ChildRelationship cr : getAllChildRelationships(selfSObjectType)) {
            String childSObjectLookupFieldName = cr.getField().getDescribe().getName();
            if (childSObjectType == cr.getChildSObject()) {
                String soql = buildGeneralDatabaseQuery(childSObjectType) + ' where ' + childSObjectLookupFieldName + '= \'' + String.escapeSingleQuotes(selfRecordId) + '\'';
                if (String.isNotBlank(extraConditions)) {
                    soql += extraConditions + ' ';
                }
                childSObjectRecords = Database.query(soql);
                break;
            }
        }
        return childSObjectRecords;
    }

    public static List<ChildRelationship> getAllChildRelationships(SObjectType sObjectType) {
        List<ChildRelationship> allChildRelationships = new List<ChildRelationship>();
        DescribeSObjectResult describeSObjectResult = createDescribeSObjectResult(sObjectType);
        if (describeSObjectResult != null) {
            allChildRelationships = describeSObjectResult.getChildRelationships();
        }
        return allChildRelationships;
    }

    /**
     * @param sObjectType
     *
     * @return Map<String, RecordTypeInfo>: Key is record type name; value is RecordTypeInfo.
     */
    public static Map<String, RecordTypeInfo> buildRecordTypeInfoMapWithNameAsKey(SObjectType sObjectType) {
        Map<String, RecordTypeInfo> recordTypeInfoMap = new Map<String,RecordTypeInfo>();
        if (sObjectType != null) {
            Schema.DescribeSObjectResult describe = createDescribeSObjectResult(sObjectType);
            recordTypeInfoMap = describe.getRecordTypeInfosByName();
        }

        return recordTypeInfoMap;
    }

    /**
     * @param sObjectType
     *
     * @return Map<Id, RecordTypeInfo>: Key is record type id; value is RecordTypeInfo.
     */
    public static Map<Id, RecordTypeInfo> buildRecordTypeInfoMapWithIdAsKey(SObjectType sObjectType) {
        Map<Id, RecordTypeInfo> recordTypeInfoMap = new Map<Id,RecordTypeInfo>();
        if (sObjectType != null) {
            Schema.DescribeSObjectResult describe = createDescribeSObjectResult(sObjectType);
            recordTypeInfoMap = describe.getRecordTypeInfosById();
        }

        return recordTypeInfoMap;
    }

    public static RecordTypeInfo retrieveRecordTypeInfoById(SObjectType sObjectType, Id recordTypeId) {
        RecordTypeInfo recordTypeInfo;
        if (sObjectType != null && String.isNotBlank(recordTypeId)) {
            Schema.DescribeSObjectResult describe = createDescribeSObjectResult(sObjectType);
            Map<Id, RecordTypeInfo> recordTypeInfoMap = describe.getRecordTypeInfosById();
            recordTypeInfo = recordTypeInfoMap.get(recordTypeId);
        }

        return recordTypeInfo;
    }

    public static RecordTypeInfo retrieveRecordTypeInfoByName(SObjectType sObjectType, String recordTypeName) {
        RecordTypeInfo recordTypeInfo;
        if (sObjectType != null && String.isNotBlank(recordTypeName)) {
            Schema.DescribeSObjectResult describe = createDescribeSObjectResult(sObjectType);
            Map<String, RecordTypeInfo> recordTypeInfoMap = describe.getRecordTypeInfosByName();
            recordTypeInfo = recordTypeInfoMap.get(recordTypeName);
        }

        return recordTypeInfo;
    }

    /**
     * @param sObjectType
     *
     * @return Map<String, Id> Key is record type name; value is record type id.
     */
    public static Map<String, Id> buildRecordTypeMapWithNameAsKey(SObjectType sObjectType) {
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        Map<String, RecordTypeInfo> recordTypeInfoMap = buildRecordTypeInfoMapWithNameAsKey(sObjectType);
        if (recordTypeInfoMap != null && !recordTypeInfoMap.isEmpty()) {
            for (String recordTypeName : recordTypeInfoMap.keySet()) {
                recordTypeMap.put(recordTypeName, recordTypeInfoMap.get(recordTypeName).getRecordTypeId());
            }
        }
        return recordTypeMap;
    }

    /**
     * @param sObjectType
     *
     * @return Map<String, Id> Key is record type name; value is record type id.
     */
    public static Map<Id, String> buildRecordTypeMapWithIdAsKey(SObjectType sObjectType) {
        Map<Id, String> recordTypeMap = new Map<Id, String>();
        Map<Id, RecordTypeInfo> recordTypeInfoMap = buildRecordTypeInfoMapWithIdAsKey(sObjectType);
        if (recordTypeInfoMap != null && !recordTypeInfoMap.isEmpty()) {
            for (String recordTypeId : recordTypeInfoMap.keySet()) {
                recordTypeMap.put(recordTypeId, recordTypeInfoMap.get(recordTypeId).getName());
            }
        }
        return recordTypeMap;
    }

    public static Id retrieveRecordTypeId(SObjectType sObjectType, String recordTypeName) {
        Id recordTypeId;
        RecordTypeInfo recordTypeInfo = retrieveRecordTypeInfoByName(sObjectType, recordTypeName);
        if (recordTypeInfo != null) {
            recordTypeId = recordTypeInfo.getRecordTypeId();
        }
        return recordTypeId;
    }

    public static String retrieveRecordTypeName(SObjectType sObjectType, Id recordTypeId) {
        String recordTypeName;
        RecordTypeInfo recordTypeInfo = retrieveRecordTypeInfoById(sObjectType, recordTypeId);
        if (recordTypeInfo != null) {
            recordTypeName = recordTypeInfo.getName();
        }
        return recordTypeName;
    }

    public static List<Schema.FieldSetMember> getFieldSetMembers(SObjectType sObjectType, String fieldSetName) {
        List<Schema.FieldSetMember> fieldSetMembers = new List<Schema.FieldSetMember>();
        Schema.DescribeSObjectResult describeSObjectResult =  SchemaUtil.createDescribeSObjectResult(sObjectType);
        if (describeSObjectResult != null) {
            Schema.FieldSet fieldSet = describeSObjectResult.fieldSets.getMap().get(fieldSetName);
            if (fieldSet != null) {
                fieldSetMembers.addAll(fieldSet.getFields());
            }
        }
        return fieldSetMembers;
    }

    public static List<String> getFieldSetMemberPaths(SObjectType sObjectType, String fieldSetName) {
        List<String> fieldSetMemberPaths = new List<String>();
        List<Schema.FieldSetMember> fieldSetMembers = getFieldSetMembers(sObjectType, fieldSetName);
        if (fieldSetMembers != null && !fieldSetMembers.isEmpty()) {
            for (Schema.FieldSetMember fieldSetMember : fieldSetMembers) {
                fieldSetMemberPaths.add(fieldSetMember.getFieldPath());
            }
        }
        return fieldSetMemberPaths;
    }

    public static void clearFields(SObject raw, List<String> fieldNames) {
        if (raw != null) {
            List<String> allFieldNames = getSObjectFieldNames(raw.getSObjectType());
            for (String fieldName : fieldNames) {
                if (String.isNotBlank(fieldName) && allFieldNames.contains(fieldName.toLowerCase())) {
                    raw.put(fieldName, null);
                }
            }
        }
    }

    public static Boolean checkIfStringIsId(String idString) {
        Boolean isId = false;
        try {
            Id.valueOf(idString);
            isId = true;
        } catch (Exception ex) {
            isId = false;
        }
        return isId;
    }

    public static Boolean checkIfStringMatchPattern(String str, String regRex) {
        Pattern MyPattern = Pattern.compile(regRex);
        Matcher MyMatcher = MyPattern.matcher(str);
        return MyMatcher.matches();
    }

    public static String getObjectNameById(Id recordId) {
        System.debug('getObjectNameById:');
        System.debug(recordId);
        String objectName = recordId.getSObjectType().getDescribe().getName();
        System.debug(objectName);
        return objectName;
    }
}