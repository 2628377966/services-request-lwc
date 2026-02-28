import { api, LightningElement, track } from 'lwc';
import { setCSSProperties, getIconURL } from 'c/ojUtil';
import Toast from 'lightning/toast';
import getPartnerConfig from '@salesforce/apex/OJInitiatorCtrl.getPartnerConfigByAccountId';


export default class OjAppPartnerServiceOptions extends LightningElement {
    @api payload;
    @track isMultiMidEnabled = false;
    @track isLoading = true;
    showForm = false;
    brand = 'Ezidebit';
    isDesktop;
    
    // Icons
    eftposMultiMerchantIcon;
    requestNewProductIcon;

    async connectedCallback() {
        this.checkScreenSize();
        window.addEventListener('resize', this.checkScreenSize.bind(this));
        
        // Set CSS properties from theme
        setCSSProperties(this.template.host, 'tile', this.payload.Theme.Tile__c);
        
        // Get brand
        this.brand = this.payload?.Account?.Brand__c || 'Ezidebit';
        
        // Set icons based on brand
        const iconPrefix = this.brand.toLowerCase();
        this.eftposMultiMerchantIcon = getIconURL(`${iconPrefix}-icon-cards`);
        this.requestNewProductIcon = getIconURL(`${iconPrefix}-icon-fees`);
        
        // Load partner configuration to check Multi-MID status
        await this.loadPartnerConfiguration();
    }

    disconnectedCallback() {
        window.removeEventListener('resize', this.checkScreenSize.bind(this));
    }

    checkScreenSize() {
        this.isDesktop = window.matchMedia('(min-width: 769px)').matches;
    }

    get requestNewProductClass() {
        return this.isDesktop ? 'tile tile-clickable custom-tile-desktop' : 'tile tile-clickable custom-tile-mobile';
    }

    get eftposMultiMerchantClass() {
        let eftposClass = this.isDesktop ? 'tile custom-tile-desktop' : 'tile custom-tile-mobile';
        eftposClass += this.isMultiMidEnabled ? ' tile-clickable' : ' tile-disabled';
        return eftposClass;
    }

    async loadPartnerConfiguration() {
        const accountId = this.payload?.Account?.Id;
        const software = this.payload?.Account?.Software__c;
        
        if (!accountId) {
            console.warn('No Account Id available');
            this.isMultiMidEnabled = false;
            this.isLoading = false;
            this.showForm = true;
            return;
        }
        
        console.log('Loading partner config for account:', accountId, 'software:', software);
        await getPartnerConfig({ accountId: accountId, software: software })
            .then(result => {
                if (result && result.Multi_MID_Enabled__c) {
                    this.isMultiMidEnabled = true;
                } else {
                    this.isMultiMidEnabled = false;
                }
                this.isLoading = false;
                this.showForm = true;
            })
            .catch(error => {
                console.error('Error loading partner configuration:', error);
                console.error('Error message:', error.body?.message || error.message);
                this.isMultiMidEnabled = false;
                this.isLoading = false;
                this.showForm = true;
                
                // Show error toast
                Toast.show({
                    label: 'Error',
                    message: 'Unable to load partner configuration. Please try again.',
                    variant: 'error',
                    mode: 'dismissible',
                    position: 'top-center'
                }, this);
            });
    }

    handleEftposMultiMerchantClick() {
        if (!this.isMultiMidEnabled) {
            Toast.show({
                label: 'Service Unavailable',
                message: 'EFTPOS Multi-Merchant service is not available for your account.',
                variant: 'warning',
                mode: 'dismissible',
                position: 'top-center'
            }, this);
            return;
        }
                
        // Update payload and navigate to ojAppSignupVerifyAccount
        const updatedPayload = {
            ...this.payload,
            currentState: {
                ...this.payload.currentState,
                eftposMultiMerchantIsSelected: true,
                requestNewProductIsSelected: false,
                existingClientIsSelected: true // Indicate existing client flow
            }
        };
                
        // Dispatch event to update payload
        const event = new CustomEvent('newpayload', {
            detail: updatedPayload,
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(event);
        console.log('newpayload event dispatched');
    }

    handleRequestNewProductClick() {
        // Update payload state
        const updatedPayload = {
            ...this.payload,
            currentState: {
                ...this.payload.currentState,
                eftposMultiMerchantIsSelected: false,
                requestNewProductIsSelected: true
            }
        };
        
        // Show message that this feature is pending
        Toast.show({
            label: 'Coming Soon',
            message: 'Request New Payment Product flow is under development.',
            variant: 'info',
            mode: 'dismissible',
            position: 'top-center'
        }, this);
    }
}