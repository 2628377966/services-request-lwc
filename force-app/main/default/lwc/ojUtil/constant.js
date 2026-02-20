const getSteps = () => {
    return [
        { screenName: 'Update bank details', componentName: 'ojbdUpdateBankDetails' },
        { screenName: 'Settlement account', componentName: 'ojbdSettlementAccount' },
        { screenName: 'Update billing account', componentName: 'ojbdUpdateBillingAccount' },
        { screenName: 'Billing account', componentName: 'ojbdBillingAccount' },
        { screenName: 'Verify your accounts', componentName: 'ojbdVerifyYourAccounts' },
        { screenName: 'Submit your change', componentName: 'ojbdSubmitYourChange' },
        { screenName: 'Submitted!', componentName: 'ojbdSubmitted' }
    ];
};

const getSignupSteps = () => {
    return [
        { screenName: 'signup options', componentName: 'ojAppSingupOptions' },
        { screenName: 'validate existing account', componentName: 'ojAppSingupVerifyAccount'},
        { screenName: 'redirect to kyc csa', componentName: 'ojAppSingupShowKYCCSA' }
    ];
};


const getFields = () => {
    return {
        accountFields: [
            'Id',
            'Brand__c',
            'Name',
            'Phone',
            'Registered_Name__c',
            'Support_Phone_Number__c',
            'Partner_Logo_URL__c',
            'Partner_Type__c',
            'Website',
            'Software__c'
        ],
        themeFields: [
            'Id',
            'Button1__c',
            'Button2__c',
            'Description__c',
            'Divider__c',
            'Font__c',
            'Footer__c',
            'Heading_1__c',
            'Header__c',
            'Input__c',
            'Link__c',
            'Name',
            'Phone_Icon__c',
            'Primary_Colour__c',
            'Primary_Color__c',
            'Progress_Bar__c',
            'Tile__c',
            'Tooltip__c',
            'Horizontal_Line__c',
            'Company_Name__c',
            'Privacy_Policy_Link__c',
            'Terms_Of_Use_Link__c',
            'File_Attachment_Card__c',
            'Svg_Fill__c'
        ]
    };
};

const getSignupFields = () => {
    return {
        leadFields: [
            'Id',
            'Brand__c',
            'Name',
            'Phone',
            'Support_Phone_Number__c',
            'Partner_Logo_URL__c'
        ],
        themeFields: [
            'Id',
            'Button1__c',
            'Button2__c',
            'Description__c',
            'Divider__c',
            'Font__c',
            'Footer__c',
            'Heading_1__c',
            'Header__c',
            'Input__c',
            'Link__c',
            'Name',
            'Phone_Icon__c',
            'Primary_Color__c',
            'Primary_Colour__c',
            'Progress_Bar__c',
            'Tile__c',
            'Tooltip__c',
            'Horizontal_Line__c',
            'Company_Name__c',
            'Privacy_Policy_Link__c',
            'Terms_Of_Use_Link__c',
            'Svg_Fill__c'
        ]
    };
};

export { getSteps, getFields, getSignupSteps, getSignupFields };