import { LightningElement, api, track } from 'lwc';
import LightningAlert from 'lightning/alert';
import addEftposUser from '@salesforce/apex/EftposUserController.addEftposUser';
import deleteEftposUser from '@salesforce/apex/EftposUserController.deleteEftposUser';
import getEftposUsers from '@salesforce/apex/EftposUserController.getEftposUsers';
import editEftposUser from '@salesforce/apex/EftposUserController.editEftposUser';
import getOwnerContactEmail from '@salesforce/apex/EftposUserController.getOwnerContactEmail';
import createLeadForEftposUser from '@salesforce/apex/EftposUserController.createLeadForEftposUser';
import getMultiMidMetadata from '@salesforce/apex/EftposUserController.getMultiMidMetadata';
import updatePrefillDetails from '@salesforce/apex/EftposUserController.updatePrefillDetails';
import getOjThankYouPageURL from '@salesforce/apex/EftposUserController.getOjThankYouPageURL';
import { refreshApex } from '@salesforce/apex';

export default class ApplicationEftposBiller extends LightningElement {
    @api brandType;
    @api partnerLogoUrl;
    @api supportPhoneNumber;
    @api oppId;
    @api csaId;
    @api acctId;
    @api origin;
    @api nextPageName;
    @api conid;
    addBillerLinkLabel = '';

    showAddBiller = false;
    showSummary = false;
    showAddAnotherBiller = false;
    showAddAnotherUser = true;
    showPrefillCheckbox = true;
    showEditForm = false;
    editIconBrandClass = '';
    btnBrandClass = '';
    btnCancelBrandClass = 'slds-m-right_medium ';
    linkStyle = '';
    deleteIconBrandClass = 'delete-icon slds-m-left_large ';
    tooltipClass = '';
    showcounter = 0;
    multiMidTerminology
    addBillerTitle;
    addBillerTitleInfo;
    addBillerTitleInfoAdditional;
    addBillerTitleDisclaimer;
    capturePrefillTitle; 
    capturePrefillNote;
    title;
    titleInfo;


    @api FirstName;
    @api LastName;
    @api Phone;
    @api Email;
    @api TradingName;
    @api payload;
    @track userPayload = [];
    @track userToRemove;
    @track removeUserPayload;
    @track loadedOnce = false;
    @track pageName;
    @track prefillOption = 'Yes'; 
    @track error = false;
    @track message = '';
    @track toggleClass = 'custom-toggle';
       
    prefillChecked = false;  
    ownerEmail = null;
    editingUserId = null;
    editingUser = {};

    async connectedCallback() {
        this.brandClass = this.brandType == 'Ezidebit' ? 'ezidebit-brand' : 'eway-brand';
        this.editIconBrandClass = this.brandType == 'Ezidebit' ? 'ezidebit-icon' : 'eway-icon';
        this.deleteIconBrandClass += this.brandType == 'Ezidebit' ? 'ezidebit-icon' : 'eway-icon';
        this.linkStyle += this.brandType == 'Ezidebit' ?  'ezidebit-nav-link' : 'eway-nav-link';
        this.btnBrandClass = this.brandType == 'Ezidebit' ? 'btn-primary-ezi' : 'btn-primary-eway';
        this.tooltipClass = this.brandType == 'Ezidebit' ? 'tooltip-icon' : 'tooltip-icon eway-tooltip';
        this.toggleClass += this.brandType == 'Ezidebit' ? 'custom-toggle' : 'custom-toggle eway-toggle';
        this.btnCancelBrandClass += this.btnBrandClass;
        this.message = '';
        this.origin = 'signup';
        this.mapPayloadToProps();
        await this.getMetadata();
        await this.getEftposUsers();
        await this.getOwnerContactEmail();
    }

    mapPayloadToProps() {
        if (this.payload) {
            console.log('>> > mapPayloadToProps payload' + JSON.stringify(this.payload));
            this.oppId = this.payload?.currentState?.oppId || this.oppId;
            this.csaId = this.payload?.currentState?.csaId || this.csaId;
            this.conid = this.payload?.currentState?.requesterContactId || this.conid;
            this.acctId = this.payload?.Account?.Id || this.acctId;
            this.brandType = this.payload?.Account?.Brand__c || this.payload?.Lead?.Brand__c || this.brandType;
            
        }
    }

    async getMetadata() {
        try {
            this.multiMidTerminology = await getMultiMidMetadata();
            console.log('>> > multiMidTerminology' + this.multiMidTerminology.AB_Add_Title__c);
            this.addBillerTitle = this.multiMidTerminology.AB_Add_Title__c;
            this.addBillerTitleInfo = this.multiMidTerminology.AB_Add_Info__c;
            this.addBillerTitleInfoAdditional = this.multiMidTerminology.AB_Add_Info_Additional__c;
            this.addBillerTitleDisclaimer = this.multiMidTerminology.AB_Add_Disclaimer__c;
            this.title = this.multiMidTerminology.AB_Title__c;
            this.titleInfo = this.multiMidTerminology.AB_Info__c;
            this.addBillerLinkLabel = this.multiMidTerminology.AB_Add_Biller_Label__c;
            this.capturePrefillTitle = this.multiMidTerminology.AB_Capture_Prefill_CSA_Title__c;
            this.capturePrefillNote = this.multiMidTerminology.AB_Capture_Prefill_CSA_Note__c;
        } catch (error) {
            console.log('error in getMultiMidMetadata' + error);
        }

    }

    async getOwnerContactEmail() {
        try {
            const email = await getOwnerContactEmail({ accountId: this.acctId });
            if (email) {
                this.ownerEmail = email.toLowerCase();
            }
        } catch (error) {
            console.log('Error fetching owner contact email');
        } 
    }

    handlePrefillChange(event) {
        this.prefillChecked = event.target.checked;
        this.dispatchPayload();
    }

    handlePrefillToggle(event) {
        const selected = event.target.dataset.value; // 'Yes' or 'No'
        this.prefillOption = selected;
        this.prefillChecked = selected === 'Yes';
        this.dispatchPayload();
    }

    handleInputChange(event) {
        const field = event.target.name;
        switch (field) {
            case 'TradingName':
                this.TradingName = event.detail.value;
                break;
            case 'FirstName':
                this.FirstName = event.detail.value;
                break;
            case 'LastName':
                this.LastName = event.detail.value;
                break;
            case 'Email':
                this.Email = event.detail.value;
                event.target.setCustomValidity('');
                break;
            case 'Phone':
                this.Phone = event.detail.value;
                break;
            default:
                break;
        }
    }


    get yesClass() {
        return this.prefillOption === 'Yes' ? 'yes custom-toggle-on' : 'yes';
    }

    get noClass() {
        return this.prefillOption === 'No' ? 'no custom-toggle-on' : 'no';
    }

    handlePhoneBlur(event) {
        this.validatePhone(event.target, event.target.value);
    }

    validatePhone(target, value) {
        if (value && value.length > 0) {
            const cleanedValue = value.replace(/[^+()0-9]/g, '');
            const regex = /^(\+{0,1}61){0,1}(((\({0,1})0{0,1}\){0,1}[2|3|7|8]{1}\){0,1}(\d{8}))|(1(300|800|900|902)(\d{6}))|(13(\d{4})|((\({0,1})0{0,1}\){0,1}4{1}\d{8})))$/;
            const isPhoneValid = regex.test(cleanedValue);
            if (!isPhoneValid) {
                target.setCustomValidity('Please enter a valid phone number');
            } else {
                target.setCustomValidity('');
            }
        } else {
            target.setCustomValidity('');
        }
        target.reportValidity();
    }

    handleEmailBlur(event) {
        this.validateEmail(event.target, event.target.value);
    }

    validateEmail(target, value) {
        if (value && value.length > 0) {
            const regex = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
            const isEmailValid = regex.test(value);
            if (!isEmailValid) {
                target.setCustomValidity('Please enter a valid email');
            } else if (this.ownerEmail && value.toLowerCase() === this.ownerEmail) {
                target.setCustomValidity('Please provide an email address that is unique to the EFTPOS User.');
            } else {
                const emailLc = value.toLowerCase();
                const isDuplicate = this.userPayload.some(user => 
                    user.email && user.email.toLowerCase() === emailLc && user.id !== this.editingUser.id
                );
                if (isDuplicate) {
                    target.setCustomValidity('Please provide an email address that is unique to the EFTPOS User.');
                } else {
                    target.setCustomValidity('');
                }
            }
        } else {
            target.setCustomValidity('');
        }
        target.reportValidity();
    }


    async showValidationErrorModal() {
        const result = await LightningModal.open({
            label: 'Validation Error!',
            size: 'large', // Makes it bigger
            description: 'Please correct the errors in the form before proceeding.',
            content: 'Please correct the errors in the form before proceeding.',
        });
    }

    async validateComponent() {
        this.message = '';
        const inputs = this.template.querySelectorAll('lightning-input');
        let allValid = true;
        inputs.forEach(input => {
            const { name, value } = input;
            if (name === 'email' || name === 'Email') {
                this.validateEmail(input, value);
            } else if (name === 'phone' || name === 'Phone') {
                this.validatePhone(input, value);
            }
            // Add other field validations as needed
            input.reportValidity();
            if (!input.checkValidity()) {
                allValid = false;
            }
        });
        return allValid;
    }

    async handleAddMerchantSave(event){
        event.preventDefault();
        let validInputs = await this.validateComponent();
        if (validInputs === true) {
            this.saveEftposUser();
        }
    }

    saveEftposUser() {
        this.message = '';
        const eftposUserPayload = this.buildEftposUserPayload();
        addEftposUser({ eftposUserPayload: JSON.stringify(eftposUserPayload) })
            .then((result) => {
                console.log('>> > saveEftposUser result' + JSON.stringify(result));
                eftposUserPayload.id = result;

                var idExists = this.userPayload.find(obj => {
                    return obj.id == result;
                });

                if (idExists === undefined || idExists == null || idExists == '') {
                    this.userPayload = [...this.userPayload, eftposUserPayload];
                }
                // Stay on the current page (form) after a successful save.
                // Clear the input fields so the user can add another biller.
                this.showAddBiller = false;
                this.showSummary = true;
                this.showAddAnotherUser = true;
                this.userPayload = this.userPayload.map(user => ({ ...user, isEditing: false }));
                this.FirstName = '';
                this.LastName = '';
                this.TradingName = '';
                this.Email = '';
                this.Phone = '';

                this.dispatchPayload();
            })
            .catch((error) => {
                console.log('Error in adding eftpos user: ' + JSON.stringify(error));
                this.error = true;
                this.message = 'Sorry, something went wrong. Please contact support.';
            })
    }

    buildEftposUserPayload() {
        return {
            "id": '',
            "firstName": this.FirstName,
            "lastName": this.LastName,
            "tradingName": this.TradingName,
            "email": this.Email,
            "phone": this.Phone,
            "csaId": this.csaId,
            "oppId": this.oppId,
            "acctId": this.acctId,
            "prefillChecked": this.prefillChecked,
            "isEditing": false
        };
    }

    async handleDeleteUser(event) {
        if (event.target.dataset.id != undefined) {
            this.userIdToRemove = event.target.dataset.id;
        } else if (event.currentTarget.dataset.id != undefined) {
            this.userIdToRemove = event.currentTarget.dataset.id
        }
        this.getEftposUserPayload();
        await this.deleteUser();
        if(this.userPayload.length == 0 || this.userPayload == undefined){
            this.showSummary = false;
            this.showAddBiller = true;
            this.showAddAnotherUser = false;
            this.FirstName = '';
            this.LastName = '';
            this.TradingName = '';
            this.Email = '';
            this.Phone = '';
        }
        this.dispatchPayload();
    }

    getEftposUserPayload() {
        this.removeUserPayload = this.userPayload.find(obj => {
            return obj.id == this.userIdToRemove;
        });
    }

    deleteUser() {
        return deleteEftposUser({ eftposUserPayload: JSON.stringify(this.removeUserPayload) })
            .then((result) => {
                this.showSummary = true;
                this.showAddAnotherUser = true;
                var removeIndex = this.userPayload.map(function (item) { return item.id; }).indexOf(this.userIdToRemove);
                this.userPayload.splice(removeIndex, 1);
                this.removeUserPayload = '';
                this.userIdToRemove = '';
                refreshApex(this.userPayload);
            })
            .catch((error) => {
                LightningAlert.open({
                    message: 'Sorry, something went wrong. Please contact support.',
                    theme: 'error',
                    label: 'Error!',
                });
            })
    }

    handleAddAnotherMerchant(event) {
        this.FirstName = '';
        this.LastName = '';
        this.TradingName = '';
        this.Email = '';
        this.Phone = '';
        this.showAddBiller = true;
        this.showSummary = false;
        this.addBillerLinkLabel = this.multiMidTerminology.AB_Add_Biller_Label__c;
        this.showAddAnotherUser = false;
        this.dispatchPayload();
    }

    getUrl() {
        const host = window.location.host;
        var pathname = window.location.hostname;
        return this.pageName + '?oppId=' + this.oppId + '&csa=' + this.csaId;
    }

    getEftposUsers() {
        getEftposUsers({ accountId: this.acctId, oppId: this.oppId, csaId: this.csaId })
            .then((result) => {
                this.userPayload = result;
                if (this.userPayload.length > 0) {
                    this.showSummary = true;
                    this.userPayload = this.userPayload.map(user => ({ ...user, isEditing: false }));
                    this.showAddBiller = false;
                    this.showAddAnotherUser = true;
                    this.prefillChecked = this.userPayload[0].prefillChecked || false;
                    this.prefillOption = this.prefillChecked ? 'Yes' : 'No';
                } else {
                    this.showAddBiller = true;
                    this.showAddAnotherUser = false;
                }
                this.dispatchPayload();
            })
            .catch((error) => {
                console.error("An error occurred:", error.message);
                LightningAlert.open({
                    message: 'Sorry, something went wrong. Please contact support.',
                    theme: 'error',
                    label: 'Error!',
                });
            })
    }

    handleEditUser(event) {
        const userId = event.currentTarget.dataset.id;
            this.userPayload = this.userPayload.map(user => ({
            ...user,
            isEditing: user.id === userId
        }));
        const user = this.userPayload.find(u => u.id === userId);
        if (user) {
            //this.editingUserId = userId;
            this.editingUser = { ...user }; // Create a copy for editing
        }
        this.showEditForm = true;
    }

    handleCancelEdit() {
        this.userPayload = this.userPayload.map(user => ({
            ...user,
            isEditing: false
        }));
        this.editingUser = {};
    }

    async handleSaveEdit(event) {
        event.preventDefault();
        let validInputs = await this.validateComponent();
        if (validInputs === true) {
            const index = this.userPayload.findIndex(u => u.id === this.editingUser.id);
            if (index !== -1) {
                this.userPayload[index] = { ...this.editingUser, isEditing: false };
                this.userPayload = [...this.userPayload];
                this.editUserPayload = this.userPayload[index];
                this.editUser();
            }
            this.editingUser = {};
        }
    }

    editUser() {
        editEftposUser({ eftposUserPayload: JSON.stringify(this.editUserPayload) })
            .then((result) => {
                this.showSummary = true;
                this.showAddAnotherUser = true;
                refreshApex(this.userPayload);
                this.dispatchPayload();
            })
            .catch((error) => {
                LightningAlert.open({
                    message: 'Sorry, something went wrong. Please contact support.',
                    theme: 'error',
                    label: 'Error!',
                });
            });
    }

    handleEditInputChange(event) {
        const { name, value } = event.target;
        this.editingUser = { ...this.editingUser, [name]: value };
        if (name === 'email') {
            event.target.setCustomValidity('');
        }
    
    }


    createLeads() {
        createLeadForEftposUser({ accountId: this.acctId })
            .then((result) => {
                console.log('Success');
            })
            .catch((error) => {
                console.error("An error occurred:", error.message);
                LightningAlert.open({
                    message: 'Sorry, something went wrong. Please contact support.',
                    theme: 'error',
                    label: 'Error!',
                });
            })
    }

    dispatchPayload() {
        const isStepComplete = this.userPayload && this.userPayload.length > 0;
        this.dispatchEvent(new CustomEvent('newpayload', {
            detail: {
                ...this.payload,
                currentState: {
                    ...(this.payload?.currentState || {}),
                    enableStep4NextButton: isStepComplete,
                    isNotAddMerchant: isStepComplete,
                    prefillChecked: this.prefillChecked
                }
            }
        }));
    }

}