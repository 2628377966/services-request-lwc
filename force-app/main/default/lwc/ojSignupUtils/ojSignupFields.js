const getSignupSteps = () => {
    return [
        { screenName: 'signup options', componentName: 'ojAppSingupOptions' },
        { screenName: 'validate existing account', componentName: 'ojAppSingupVerifyAccount'},
        { screenName: 'redirect to kyc csa', componentName: 'ojAppSingupShowKYCCSA' }
    ];
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

export { getSignupSteps, getSignupFields };