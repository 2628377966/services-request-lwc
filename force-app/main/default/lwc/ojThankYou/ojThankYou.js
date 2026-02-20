import { api, LightningElement } from 'lwc';
import resources from '@salesforce/resourceUrl/ApplicationResources';
import { setCSSProperties } from 'c/ojUtil';
 
export default class OjThankYou extends LightningElement {
    
    @api payload;
    brandType;

    connectedCallback() {        
        this.variabelAssignement();
        this.newPayload = JSON.parse(JSON.stringify(this.payload));
        this.dispatchPayload();
    }

    variabelAssignement() {
        const accountBrand = this.payload.Account?.Brand__c?.trim();
        const leadBrand = this.payload.Lead?.Brand__c?.trim();
        this.brandType = accountBrand ? accountBrand : leadBrand ? leadBrand : 'Ezidebit';
        
        setCSSProperties(this.template.host, 'primary', this.payload.Theme.Primary_Color__c);
        setCSSProperties(this.template.host, 'font', this.payload.Theme.Font__c);
    }

    dispatchPayload() {
        this.dispatchEvent(new CustomEvent('newpayload', { detail: this.newPayload }));
    }

    get tickURL() { 
        return resources + `/${this.brandType}ThankYouTick.svg#tick`;
    }

    get image01(){
        return resources + `/${this.brandType}ThankYou01.png`;
    }

    get image02(){
        return resources + `/${this.brandType}ThankYou02.png`;
    }

    get image03(){
        return resources + `/${this.brandType}ThankYou03.png`;
    }

    handleNewRequest() {
        // go to the Request service page
    }
}