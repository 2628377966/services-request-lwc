import { api, LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

export default class OjAppSignupShowKYCCSA extends LightningElement {

    @wire(CurrentPageReference)
    currentPageReference;
    @track pageUrl;
    @track displayError = false;
    @api targetPageUrl;
    @api payload;
    @track showSpinner = false;

    connectedCallback() {
        this.showSpinner = true;
        this.newPayload = {...this.payload};
        this.pageUrl = this.payload.CSA.csaUrl;
        console.log('pageUrl: ' + this.pageUrl);
        if(this.pageUrl !== undefined){
            this.navigateToTargetPage();
        }else{
            this.showSpinner = false;
            this.displayError = true;
        }
    }

    async navigateToTargetPage() {
        let redirectUrl = this.pageUrl;
        window.open(redirectUrl, '_self');
    }

}