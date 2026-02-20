import { api, LightningElement,track } from 'lwc';
import { setCSSProperties } from 'c/ojUtil';
import getCSAUrl from '@salesforce/apex/BillerMatchController.proceedToNormalCSA';
import ToastContainer from 'lightning/toastContainer';
import Toast from 'lightning/toast';

export default class OjAppSignupOptions extends LightningElement {
    @api payload ;
    showForm = false;
    newPayload = {};
    businessName = '';
    customTileClass = 'tile pointer slds-col slds-size_12-of-12';
    brand = 'Ezidebit';
    fromISVPortal;
    @track isLoading = false;
    @track displayError = false;
    @track customSvgColour = 'black';
    @track targetPageUrl;

    connectedCallback() {
        this.checkScreenSize();
        window.addEventListener('resize', this.checkScreenSize.bind(this));  
        setCSSProperties(this.template.host, 'tile', this.payload.Theme.Tile__c);
        this.customSvgColour = this.payload.Theme.Svg_Fill__c;
        this.brand = this.payload.Lead?.Brand__c || this.payload?.Account.Brand__c;
        console.log('>> this.payload.Account:' + JSON.stringify(this.payload.Account));
        this.fromISVPortal = this.payload.Account ? true : false;
        this.newPayload = { ...this.payload };
        this.showForm = true;

        const toastContainer = ToastContainer.instance();
        toastContainer.maxToasts = 5;
        toastContainer.toastPosition = 'top-center';
    }

    renderedCallback() {
        this.highlightSelectedTiles();
    }

    highlightSelectedTiles() {
        if (this.payload?.currentState?.existinClientSelected) {
            this.template.querySelector('[data-name="existingClientDiv"]').classList.add('selected');
        }
        if (this.payload?.currentState?.newClientIsSelected) {
            this.template.querySelector('[data-name="newClientDiv"]').classList.add('selected');
        }
    }

    selectExistingClient(event) {
        event.target.classList.toggle('selected');
        this.template.querySelector('[data-name="newClientDiv"]').classList.remove('selected');
        this.dispatchEvent(new CustomEvent('newpayload', { detail: this.getPayload() }));
    }

    async selectNewClient(event) {
        event.target.classList.toggle('selected');
        this.template.querySelector('[data-name="existingClientDiv"]').classList.remove('selected');
        if (this.fromISVPortal) {
            // go to New Client Referral Process
            // this.isLoading = true;
            // this.targetPageUrl = 'https://ezidebit--ezifull.sandbox.my.site.com/onboarding/partner-merchant-new-referral-page?recordId=0018s00000ewCDHAA2';
            // this.isLoading = false;
            console.log('>> from isv portal');
            Toast.show({
                label: 'Oops.',
                message: 'This page is for existing merchants with Global Payments. Please go to your business management software to understand how you can apply for a new merchant account with us. Or call '+ this.payload.Account.Support_Phone_Number__c +'.',
                mode: 'sticky',
                variant: 'success'
            }, this);

        } else {
            await this.generateCSAUrl();
        }
    }

    async generateCSAUrl(){
        this.isLoading = true;
        try {
            const result = await getCSAUrl({ leadId: this.payload.Lead.Id });
            this.targetPageUrl = result;
            window.location.assign(result);
        } catch (error) {
            this.displayError = true;
        } finally {
            this.isLoading = false;   
        }
    }

    getPayload() {
        let newClientIsSelected = this.template.querySelector('[data-name="newClientDiv"]').classList.contains('selected');
        let existingClientIsSelected = this.template.querySelector('[data-name="existingClientDiv"]').classList.contains('selected');
        this.newPayload.currentState = {
            ...this.newPayload.currentState,
            newClientIsSelected: newClientIsSelected,
            existingClientIsSelected: existingClientIsSelected
        };
        if(newClientIsSelected){
            this.newPayload.CSA = {
                ...this.newPayload.CSA,
                csaUrl: this.targetPageUrl
            };
        }
        return this.newPayload;
    }

    checkScreenSize() {
        this.isDesktop = window.matchMedia('(min-width: 769px)').matches;
        console.log(`Device type: ${this.isDesktop ? 'Desktop' : 'Mobile'}`);
        if (this.isDesktop) {
            this.customTileClass += ' custom-tile-desktop';
        }else{
            this.customTileClass += ' custom-tile-mobile';
        }
    }

}