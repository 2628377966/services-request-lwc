import { api, LightningElement } from 'lwc'; 
import { setCSSProperties } from 'c/ojUtil';

export default class OjAppRemoveEftposMultipleMerchants extends LightningElement {
    @api payload;
    newPayload;
    showForm = false;
    toBeRemovedMerchants = [];
    saveButtonStyle = "color: #C2C1C2; border: 1.5px solid #C2C1C2;";
    isSaveButtonDisabled = true;
    toBeUpdatedMerchants = new Map();
    primaryColour;
    firstTimeLoad = false;

    connectedCallback() {
        setCSSProperties(this.template.host, 'divider', this.payload.Theme.Divider__c);
        setCSSProperties(this.template.host, 'primary', this.payload.Theme.Primary_Color__c);
        this.primaryColour = this.payload.Theme.Primary_Colour__c.match(/#([0-9A-Fa-f]{6})/)[0];

        this.newPayload = JSON.parse(JSON.stringify(this.payload));
        if(this.newPayload.currentState?.toBeRemovedMerchants?.length > 0){
            this.toBeRemovedMerchants = this.newPayload.currentState.toBeRemovedMerchants;
        }

        if (this.toBeRemovedMerchants.length == 0) {
            this.toBeRemovedMerchants = [{
                "id": 0,
                "tradingName": "",
                "email": "",
                "clientId": "",
                "expanded": true,
                "showCancel": false,
                "addNewMerchant": false,
                "showSummary": false,
                "isValid": false,
                "disableSaveButton": true
            }];
        }
        
        this.showForm = true;
    }

    handleSaveButton(event) {
        for (let i = 0; i < this.toBeRemovedMerchants.length; i++) {
            if (this.toBeRemovedMerchants[i].id == Number(event.target.name)) {
                this.toBeRemovedMerchants[i] = this.toBeUpdatedMerchants.get(Number(event.target.name));
                this.toBeRemovedMerchants[i].isValid = true;
                this.toBeUpdatedMerchants.delete(Number(event.target.name));
            }
        }

        this.checkToAddNewMerchant();
        this.enableDisableCancelButtons();

        this.newPayload.currentState = {
            ...this.newPayload.currentState,
            toBeRemovedMerchants: this.toBeRemovedMerchants
        };

        this.refreshPage();
        this.dispatchPayload();
    }

    checkToAddNewMerchant() {
        if (this.toBeRemovedMerchants[this.toBeRemovedMerchants.length - 1]['isValid'] == true && this.toBeRemovedMerchants[this.toBeRemovedMerchants.length - 1]['addNewMerchant'] == false) {
            this.toBeRemovedMerchants.push({
                "id": this.toBeRemovedMerchants[this.toBeRemovedMerchants.length - 1].id + 1,
                "tradingName": "",
                "email": "",
                "clientId": "",
                "expanded": false,
                "showCancel": true,
                "addNewMerchant": true,
                "showSummary": false,
                "isValid": false,
                "disableSaveButton": true
            });
        }
    }

    enableDisableCancelButtons() {
        const validItemsCount = this.toBeRemovedMerchants.filter(item => item.isValid).length;
        this.toBeRemovedMerchants.forEach(item => {
            if (validItemsCount > 1) {
                item.showCancel = true;
            } else if (validItemsCount === 1 && item.isValid) {
                item.showCancel = false;
            }
        });
    }

    handleTradingNameChange(event) {
        this.template.querySelector(`[data-id="${event.target.dataset.id}"]`).checkValidity();
        this.validateFields(event.target.dataset.id);
        this.saveToBeUpdatedMerchants(Number(event.target.dataset.id), event.detail.value, 'tradingName');
    }

    handleEmailChange(event) {
        var value = event.target.value;
        if (value != '' && value.length > 0) {
            const regex = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
            var isEmailValid = regex.test(value);
            if (!isEmailValid) {
                event.target.setCustomValidity('Please enter a valid email');
            } else {
                event.target.setCustomValidity('');
            }
            event.target.reportValidity();
        }
        this.validateFields(event.target.dataset.id);
        this.saveToBeUpdatedMerchants(Number(event.target.dataset.id), event.detail.value, 'email');
    }

    handlePaymentsIdChange(event) {
        this.template.querySelector(`[data-id="${event.target.dataset.id}"]`).checkValidity();
        this.validateFields(event.target.dataset.id);
        this.saveToBeUpdatedMerchants(Number(event.target.dataset.id), event.detail.value, 'clientId');
    }

    saveToBeUpdatedMerchants(id, value, fieldName) {
        if (this.toBeUpdatedMerchants.get(id)) {
            this.toBeUpdatedMerchants.get(id)[fieldName] = value;
        } else {
            this.toBeUpdatedMerchants.set(id, {
                "id": id,
                "expanded": false,
                "showCancel": false,
                "showSummary": true,
                "addNewMerchant": false,
                "isValid": true
            });
            this.toBeUpdatedMerchants.get(id)[fieldName] = value;
        }
    }

    validateFields(id) {
        let isFormValid = [
            ...this.template.querySelectorAll(`lightning-input[data-id="${id}"]`),
        ].reduce((validSoFar, inputCmp) => {
            return validSoFar && inputCmp.checkValidity();
        }, true);
        this.changeSaveButtonStatus(isFormValid, id);
    }

    changeSaveButtonStatus(isFormValid, id) {
        for (let i = 0; i < this.toBeRemovedMerchants.length; i++) {
            if (this.toBeRemovedMerchants[i].id == Number(id)) {
                this.toBeRemovedMerchants[i].disableSaveButton = !isFormValid;
            }
        }
        this.refreshPage();
    }

    deleteMerchant(event) {
        for (let i = 0; i < this.toBeRemovedMerchants.length; i++) {
            if (this.toBeRemovedMerchants[i].id == Number(event.currentTarget.dataset.id)) {
                this.toBeRemovedMerchants.splice(i, 1);
                this.toBeUpdatedMerchants.delete(Number(event.currentTarget.dataset.id));
            }
        }
        this.enableDisableCancelButtons();
        this.refreshPage();
        this.dispatchPayload();
    }

    editMerchant(event) {
        for (let i = 0; i < this.toBeRemovedMerchants.length; i++) {
            if (this.toBeRemovedMerchants[i].id == event.currentTarget.dataset.id) {
                this.toBeRemovedMerchants[i].expanded = true;
                this.toBeRemovedMerchants[i].showSummary = false;
                this.toBeUpdatedMerchants.set(Number(event.currentTarget.dataset.id), {
                    "id": Number(event.currentTarget.dataset.id),
                    "tradingName": this.toBeRemovedMerchants[i].tradingName,
                    "email": this.toBeRemovedMerchants[i].email,
                    "clientId": this.toBeRemovedMerchants[i].clientId,
                    "expanded": false,
                    "showCancel": false,
                    "showSummary": true,
                    "addNewMerchant": false,
                    "isValid": true
                });
            }
        }

        this.refreshPage();
        this.dispatchPayload();
    }

    enterAnotherMerchant(event) {
        for (let i = 0; i < this.toBeRemovedMerchants.length; i++) {
            if (this.toBeRemovedMerchants[i].id == event.currentTarget.dataset.id) {
                this.toBeRemovedMerchants[i].expanded = true;
                this.toBeRemovedMerchants[i].addNewMerchant = false;
                this.toBeUpdatedMerchants.set(Number(event.currentTarget.dataset.id), {
                    "id": Number(event.currentTarget.dataset.id),
                    "tradingName": this.toBeRemovedMerchants[i].tradingName,
                    "email": this.toBeRemovedMerchants[i].email,
                    "clientId": this.toBeRemovedMerchants[i].clientId,
                    "expanded": false,
                    "showCancel": true,
                    "showSummary": true,
                    "addNewMerchant": false,
                    "isValid": false
                });
            }
        }
        
        this.refreshPage();
        this.dispatchPayload();
    }

    handleCancelButton(event) {
        let merchant = this.toBeRemovedMerchants[Number(event.currentTarget.dataset.id)];
        merchant.expanded = false;
        if (merchant.isValid) { merchant.showSummary = true; }
        else {
            merchant.addNewMerchant = true;
        }
        this.toBeUpdatedMerchants.delete(Number(event.currentTarget.dataset.id));
        this.refreshPage();
        this.dispatchPayload();
    }

    refreshPage() {
        this.showForm = false;
        this.showForm = true;
    }

    dispatchPayload(){
        const hasExpanded = this.toBeRemovedMerchants.some(item => item.expanded);
        const hasValid = this.toBeRemovedMerchants.some(item => item.isValid);
        this.newPayload.currentState = {
            ...this.newPayload.currentState,
            enableStep4NextButton: !hasExpanded && hasValid
        };
        this.dispatchEvent(new CustomEvent('newpayload', { detail: this.newPayload }));
    }
}