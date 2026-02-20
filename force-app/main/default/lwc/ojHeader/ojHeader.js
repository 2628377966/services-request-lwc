import { LightningElement, wire } from 'lwc';
import { MessageContext, subscribe } from 'lightning/messageService';
import ONE_JOURNEY_CHANNEL from '@salesforce/messageChannel/oneJourney__c';
import { getResourceURLWithBrand, setCSSProperties, setFont } from 'c/ojUtil'

export default class ojbdMain extends LightningElement {
    subscription;
    payload;
    phoneURL;
    logoURL;
    partnerLogoURL;
    supportPhoneNumber;

    componentConstructor;
    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.subscribeToOneJourneyChannel();
    }

    subscribeToOneJourneyChannel() {
        this.subscription = subscribe(this.messageContext, ONE_JOURNEY_CHANNEL, (payload) => this.handlePayload(payload));
    }

    handlePayload(payload) {
        this.payload = payload;
        this.phoneURL = getResourceURLWithBrand(payload.Account?.Brand__c || payload.Lead?.Brand__c, 'Phone');
        this.logoURL = getResourceURLWithBrand(payload.Account?.Brand__c || payload.Lead?.Brand__c, 'Logo');
        this.supportPhoneNumber = payload.Account?.Support_Phone_Number__c || payload.Lead?.Support_Phone_Number__c;
        this.partnerLogoURL = payload.Account?.Partner_Logo_URL__c || payload?.Lead?.Partner_Logo_URL__c;
        setCSSProperties(this.template.host, 'header', payload.Theme.Header__c);
        setCSSProperties(this.template.host, 'divider', payload.Theme.Divider__c);
        setFont(this.template.host, this.payload.Theme.Font__c);
    }

    async callSupport() {
        window.open('tel:' + this.payload.Account.Support_Phone_Number__c, "_self");
    }
}