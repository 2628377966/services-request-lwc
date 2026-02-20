import { api, LightningElement} from 'lwc';
import { setCSSProperties } from 'c/ojUtil';

export default class OjAppRemoveEftposDevices extends LightningElement {
     @api payload;
        newPayload;
        showForm = false;
        primaryColour;
        devices = [];
        toBeUpdatedDevice = new Map();
    
        connectedCallback() {
            setCSSProperties(this.template.host, 'divider', this.payload.Theme.Divider__c);
            setCSSProperties(this.template.host, 'primary', this.payload.Theme.Primary_Color__c);
            this.primaryColour = this.payload.Theme.Primary_Colour__c.match(/#([0-9A-Fa-f]{6})/)[0];
    
            this.newPayload = JSON.parse(JSON.stringify(this.payload));
            if(this.newPayload.currentState?.devices?.length > 0){
                this.devices = this.newPayload.currentState.devices;
            }

            this.newPayload.currentState = {
                ...this.newPayload.currentState,
                showStep6NextButton: true
            };
    
            if (this.devices.length == 0) {
                this.devices = [{
                    "id": 0,
                    "serialNo": "",
                    "reasonToRemoveOpt": "",
                    "reasonToRemoveDesc": "",
                    "expanded": true,
                    "expandRemoveDescription": false,
                    "showCancel": false,
                    "addNewDevice": false,
                    "showSummary": false,
                    "isValid": false,
                    "disableSaveButton": true,
                    "showRemoveDescription": false
                }];
            }
            
            this.showForm = true;
        }
    
        handleSaveButton(event) {
            for (let i = 0; i < this.devices.length; i++) {
                if (this.devices[i].id == Number(event.target.name)) {
                    this.devices[i] = this.toBeUpdatedDevice.get(Number(event.target.name));
                    this.devices[i].isValid = true;
                    this.toBeUpdatedDevice.delete(Number(event.target.name));
                }
            }
    
            this.checkToAddNewDevice();
            this.enableDisableCancelButtons();
    
            this.newPayload.currentState = {
                ...this.newPayload.currentState,
                devices: this.devices
            };
    
            this.refreshPage();
            this.dispatchPayload();
        }
    
        checkToAddNewDevice() {
            if (this.devices[this.devices.length - 1]['isValid'] == true && this.devices[this.devices.length - 1]['addNewDevice'] == false) {
                this.devices.push({
                    "id": this.devices[this.devices.length - 1].id + 1,
                    "serialNo": "",
                    "reasonToRemoveOpt": "",
                    "reasonToRemoveDesc": "",
                    "expanded": false,
                    "expandRemoveDescription": false,
                    "showCancel": true,
                    "addNewDevice": true,
                    "showSummary": false,
                    "isValid": false,
                    "disableSaveButton": true,
                    "showRemoveDescription": false
                });
            }
        }
    
        enableDisableCancelButtons() {
            const validItemsCount = this.devices.filter(item => item.isValid).length;
            this.devices.forEach(item => {
                if (validItemsCount > 1) {
                    item.showCancel = true;
                } else if (validItemsCount === 1 && item.isValid) {
                    item.showCancel = false;
                }
            });
        }

    
        handleSerialNumberChange(event) {
            this.template.querySelector(`[data-id="${event.target.dataset.id}"]`).checkValidity();
            this.validateFields(event.target.dataset.id);
            this.saveToBeUpdatedDevices(Number(event.target.dataset.id), event.detail.value, 'serialNo');
        }
    
        handleReasonToRemoveDescription(event) {
            this.template.querySelector(`[data-id="${event.target.dataset.id}"]`).checkValidity();
            this.validateFields(event.target.dataset.id);
            this.saveToBeUpdatedDevices(Number(event.target.dataset.id), event.detail.value, 'reasonToRemoveDesc');
          }
    
        saveToBeUpdatedDevices(id, value, fieldName) {
            if (this.toBeUpdatedDevice.get(id)) {
                this.toBeUpdatedDevice.get(id)[fieldName] = value;
            } else {
                this.toBeUpdatedDevice.set(id, {
                    "id": id,
                    "expanded": false,
                    "expandRemoveDescription": false,
                    "showCancel": false,
                    "showSummary": true,
                    "addNewDevice": false,
                    "isValid": true
                });
                this.toBeUpdatedDevice.get(id)[fieldName] = value;
            }
        }

        validateFields(id) {
            console.log('>ValidateFields Id:', id);
            let isFormValid = [
                ...this.template.querySelectorAll(`lightning-input[data-id="${id}"]`),
                ...this.template.querySelectorAll(`lightning-combobox[data-id="${id}"]`)
            ].reduce((validSoFar, inputCmp) => {
                const value = inputCmp.value?.trim();
                let isInputValid = true;
                
                if (inputCmp.tagName === 'LIGHTNING-INPUT') {
                    isInputValid = value !== '' && inputCmp.checkValidity();
                } else {
                    isInputValid = inputCmp.checkValidity();
                }
                return validSoFar && isInputValid;
            }, true);

            this.changeSaveButtonStatus(isFormValid, id);
        }

        getDeviceIndexById(id) {
            return this.devices.findIndex(device => device.id === Number(id));
        }
    
        changeSaveButtonStatus(isFormValid, id) {
            const index = this.getDeviceIndexById(id);
            if (index !== -1) {
                this.devices[index].disableSaveButton = !isFormValid;
            }
            this.refreshPage();
        }
    

        deleteDevice(event) {
            for (let i = 0; i < this.devices.length; i++) {
                if (this.devices[i].id == Number(event.currentTarget.dataset.id)) {
                    this.devices.splice(i, 1);
                    this.toBeUpdatedDevice.delete(Number(event.currentTarget.dataset.id));
                }
            }
            this.enableDisableCancelButtons();
            
            Promise.resolve().then(() => {
                this.dispatchPayload();
            });
            
            this.refreshPage();
            //this.dispatchPayload();
        }
    
        editDevice(event) {
            for (let i = 0; i < this.devices.length; i++) {                        
                const index = this.getDeviceIndexById(event.currentTarget.dataset.id);
                if (this.devices[i].id == event.currentTarget.dataset.id) {
                // if (this.devices[i].id == index) {
                    this.devices[i].expanded = true;
                    this.devices[i].showSummary = false;
                    this.devices[i].showRemoveDescription = this.devices[i].reasonToRemoveOpt === 'Other' ? true : false;
                    this.toBeUpdatedDevice.set(Number(event.currentTarget.dataset.id), {
                        "id": Number(event.currentTarget.dataset.id),
                        "serialNo": this.devices[i].serialNo,
                        "reasonToRemoveOpt": this.devices[i].reasonToRemoveOpt,
                        "reasonToRemoveDesc": this.devices[i].reasonToRemoveDesc,
                        "expanded": false,
                        "expandRemoveDescription": this.devices[i].reasonToRemoveOpt === 'Other' ? true : false,
                        "showCancel": false,
                        "showSummary": true,
                        "addNewDevice": false,
                        "isValid": true
                    });
                }
            }
    
            this.refreshPage();
            this.dispatchPayload();
        }
    
        enterAnotherDevice(event) {
            for (let i = 0; i < this.devices.length; i++) {
                if (this.devices[i].id == event.currentTarget.dataset.id) {
                    this.devices[i].expanded = true;
                    this.devices[i].addNewDevice = false;
                    this.toBeUpdatedDevice.set(Number(event.currentTarget.dataset.id), {
                        "id": Number(event.currentTarget.dataset.id),
                        "serialNo": this.devices[i].serialNo,
                        "reasonToRemoveOpt": this.devices[i].reasonToRemoveOpt,
                        "reasonToRemoveDesc": this.devices[i].reasonToRemoveDesc,
                        "expanded": false,
                        "expandRemoveDescription": this.devices[i].reasonToRemoveOpt === 'Other' ? true : false,
                        "showCancel": true,
                        "showSummary": true,
                        "addNewDevice": false,
                        "isValid": false
                    });
                }
            }
            
            this.refreshPage();
            this.dispatchPayload();
        }
    
        handleCancelButton(event) {
            
            const id = Number(event.currentTarget.dataset.id);
            const device = this.devices.find(device => device.id === id);
            //let device = this.devices[Number(event.currentTarget.dataset.id)];

            if (!device) {
                console.error(`Device with id ${id} not found.`);
                return;
            }

            device.expanded = false;
            if (device.isValid) { device.showSummary = true; }
            else {
                device.addNewDevice = true;
            }
            this.toBeUpdatedDevice.delete(Number(event.currentTarget.dataset.id));
            this.refreshPage();
            this.dispatchPayload();
        }
    
        refreshPage() {
            this.showForm = false;
            this.showForm = true;
        }
    
        dispatchPayload(){        
            this.newPayload.currentState = {
                ...this.newPayload.currentState,
                enableStep6NextButton: !this.devices.some(item => item.expanded)
            };
            this.dispatchEvent(new CustomEvent('newpayload', { detail: this.newPayload }));
        }

        reasonToRemoveOptions = [        
            { label: '---Please Select---', value: '' },
            { label: 'Faulty', value: 'Faulty' },
            { label: 'Swollen Battery', value: 'Swollen Battery' },
            { label: 'Other', value: 'Other' }
        ];
        
        handleReasonToRemoveOptions(event) {
            const value  = event.target.value;
            const id = event.target.dataset.id;

            if (!value || value === '') {
                event.target.setCustomValidity('Please enter a valid reason.');
            } else {
                event.target.setCustomValidity('');
            }

            event.target.reportValidity();
            this.saveToBeUpdatedDevices(Number(id), value, 'reasonToRemoveOpt');

        
            const index = this.getDeviceIndexById(id);
            //Show and hide desableDescription field
            if (value === 'Other') {
                this.enableDisableDescriptionField(index, true);
            } else {
                this.enableDisableDescriptionField(index, false);
                this.saveToBeUpdatedDevices(Number(id), '', 'reasonToRemoveDesc');
            }
            this.refreshPage();

            Promise.resolve().then(() => {
                this.validateFields(id);
            });
        }
        
        enableDisableDescriptionField(index,showField) {
            this.devices[index].showRemoveDescription = showField;
            this.refreshPage();
        }
    
}