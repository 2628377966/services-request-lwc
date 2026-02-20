import { api, LightningElement, track } from 'lwc';
import searchExistingBiller from '@salesforce/apex/BillerMatchController.searchExistingBiller';

export default class OjAppSignupVerifyAccount extends LightningElement {
    @api payload ;
    showForm = false;
    @track newPayload = {};
    brand;
    @track message = 'Unable to process the application, please contact support for further assistance.';
    @track proceedTo = '';
    @track error = false;
    @track isValid = false;
    isMultiMidEnabled = false;
    hasEFTPOS = false;
    goToNextScreen = false;
    csaId;
    oppId;
    siteURL;
    requesterContactId;

    isLoading = false;
    success = false;
    clientId;
    businessNumber;
    requesterEmailAddress;
    leadId;
    supportPhoneNumber = '';
    tempIsNewServiceRequest = false;

    connectedCallback() {
        this.checkScreenSize();
        window.addEventListener('resize', this.checkScreenSize.bind(this));  
        this.newPayload = { ...this.payload };
        this.brand = this.payload.Lead?.Brand__c || this.payload?.Account.Brand__c;
        this.leadId = this.payload.Lead?.Id;
        this.clientId = this.payload.currentState.ClientId;
        this.businessNumber = this.payload.currentState.BusinessRegistrationNumber;
        this.requesterEmailAddress = this.payload.currentState.requesterEmailAddress;
        this.supportPhoneNumber = this.payload.Lead?.Support_Phone_Number__c || this.payload.Account?.Support_Phone_Number__c;
        this.showForm = true;
        this.tempIsNewServiceRequest = !!this.payload?.currentState?.isNewServiceRequest;
        if (this.clientId != null && this.businessNumber != null && this.requesterEmailAddress != null && this.tempIsNewServiceRequest === true) {
            this.isValid = true;
            this.startSearchMatch();
        }

    }

    handleInputChange(event) {
        this.error = false;
        const field = event.target.name;
        if (field === 'clientId')
            this.clientId = event.detail.value;
        if (field === 'businessNumber')
            this.businessNumber = event.detail.value;
        if (field === 'requesterEmailAddress')
            this.requesterEmailAddress = event.detail.value;
        this.isValid = this.validateFields();
    }

    validateFields() {
        return [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
    }

    dispatchPayload() {
        this.newPayload.currentState = {
            ...this.newPayload.currentState,
            ClientId : this.clientId,
            BusinessRegistrationNumber : this.businessNumber,
            requesterEmailAddress : this.requesterEmailAddress,
            ExistingClientNextStep : this.proceedTo,
            isMultiMidEnabled : this.isMultiMidEnabled,
            hasEFTPOS : this.hasEFTPOS,
            Message : this.message,
            enableNextButton : this.goToNextScreen,
            csaId: this.csaId,
            oppId: this.oppId,
            siteURL: this.siteURL,
            requesterContactId: this.requesterContactId
        }

        this.dispatchEvent(new CustomEvent('newpayload', { detail: this.newPayload }));
    }
    
    async startSearchMatch(){
        this.goToNextScreen = false;
        if(this.isValid) {
            await this.searchMatch();
        }
        this.dispatchPayload();
    }

    async searchMatch() {
        try {
            this.isLoading = true;
    
            const result = await searchExistingBiller({
                clientId: this.clientId,
                businessNumber: this.businessNumber,
                requesterEmailAddress: this.requesterEmailAddress,
                leadId: this.leadId,
                supportPhoneNumber: this.supportPhoneNumber
            });
            
            this.proceedTo = result.proceedTo;
            this.message = result.message;
            this.isMultiMidEnabled = result.isMultiMidEnabled;
            this.hasEFTPOS = result.hasEFTPOS;
            this.csaId = result.csaId;
            this.oppId = result.oppId;
            this.siteURL = result.siteURL;
            this.requesterContactId = result.requesterContactId;
            if(this.payload?.Account?.Partner_Type__c == 'ISV' && this.proceedTo == 'ProdAdd'){
                this.success = false;
                this.goToNextScreen = true;
            } else {
                this.success = !!this.proceedTo;
            }
            this.error = !this.proceedTo;
        } catch (error) {
            this.error = true;
            this.success = false;
            this.message = error.body?.message || 'An error occurred';
        } finally {
            this.isLoading = false;
        }

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