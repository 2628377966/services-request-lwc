import { api, LightningElement } from 'lwc'; 

export default class OjAppRequestService extends LightningElement {
    @api payload;
    newPayload;

    deviceIsSelected = false;
    addDeviceIsSelected = false;
    removeDeviceIsSelected = false;

    userIsSelected = false;
    addUserIsSelected = false;
    removeUserIsSelected = false;

    showForm = false;
        
    showUserTile = false;
    showDeviceTile = false;
    showNoEftposMessage = false;

    primaryColour;

    get selectedUserStyle() {
        if (this.userIsSelected) {
            return `border: 2px solid var(--Ezidebit-Green, ${this.primaryColour}); cursor: default;`;
        }
        return '';
    }

    get selectedDeviceStyle() {
        if (this.deviceIsSelected) {
            return `border: 2px solid var(--Ezidebit-Green, ${this.primaryColour}); cursor: default;`;
        }
        return '';
    }

    get addMMUserButtonStyle() {
        if (this.addUserIsSelected && this.userIsSelected) {
            return `border-radius: 5px; border: 2px solid ${this.primaryColour}; background: var(--Ezidebit-Light, #CDE9C3);`;
        }
        return '';
    }

    get removeMMUserButtonStyle() {
        if (this.removeUserIsSelected && this.userIsSelected) {
            return `border: 2px solid var(--Ezidebit-Green, ${this.primaryColour}); background: var(--Ezidebit-Light, #CDE9C3);`;
        }
        return '';
    }

    get addDeviceUserButtonStyle() {
        if (this.addDeviceIsSelected && this.deviceIsSelected) {
            return `border-radius: 5px; border: 2px solid ${this.primaryColour}; background: var(--Ezidebit-Light, #CDE9C3);`;
        }
        return '';
    }

    get removeDeviceUserButtonStyle() {
        if (this.removeDeviceIsSelected && this.deviceIsSelected) {
            return `border: 2px solid var(--Ezidebit-Green, ${this.primaryColour}); background: var(--Ezidebit-Light, #CDE9C3);`;
        }
        return '';
    }

    get dividerStyle(){
        return `margin: 16px; border-top: 1px solid ${this.primaryColour};`;
    }

    connectedCallback() {
        this.primaryColour = this.payload.Theme.Primary_Colour__c.match(/#([0-9A-Fa-f]{6})/)[0];
        this.newPayload = JSON.parse(JSON.stringify(this.payload));
        this.newPayload.currentState = {
            ...this.newPayload.currentState,
            showStep3NextButton: true
        };

        if(this.newPayload.currentState?.enableStep3NextButton == undefined ){
            this.newPayload.currentState.enableStep3NextButton = false;
        }
    

        const { isMultiMidEnabled, hasEFTPOS } = this.newPayload.currentState || {};

        if (hasEFTPOS) {
            this.showDeviceTile = true;
            if (isMultiMidEnabled) this.showUserTile = true;
        } else {
            this.showNoEftposMessage = true;
            this.newPayload.currentState = {
                ...this.newPayload.currentState,
                showStep3NextButton: false
            };
        }

        this.userIsSelected = !!this.payload?.currentState?.userIsSelected;
        this.deviceIsSelected = !!this.payload?.currentState?.deviceIsSelected;
        this.addDeviceIsSelected = !!this.payload?.currentState?.addDeviceIsSelected;
        this.removeDeviceIsSelected = !!this.payload?.currentState?.removeDeviceIsSelected;
        this.addUserIsSelected = !!this.payload?.currentState?.addUserIsSelected;
        this.removeUserIsSelected = !!this.payload?.currentState?.removeUserIsSelected;

        this.dispatchPayload();
        this.showForm = true;
    }

    selectUser() {
        this.selectTile("user");
    }

    selecDevice() {
        this.selectTile("device");
    }

    selectAddUser(event){
        this.selectButton("addUser", event);
    }

    selectRemoveUser(event){
        this.selectButton("removeUser", event);
    }

    selectAddDevice(event){
        this.selectButton("addDevice", event);
    }

    selectRemoveDevice(event){
        this.selectButton("removeDevice", event);
    }

    selectTile(type) {
        const selectionMap = {
            user: { userIsSelected: true, deviceIsSelected: false, addDeviceIsSelected: false, removeDeviceIsSelected: false },
            device: { deviceIsSelected: true, userIsSelected: false, addUserIsSelected: false, removeUserIsSelected: false }
        };
    
        if (!this[Object.keys(selectionMap[type])[0]]) {
            Object.assign(this, selectionMap[type]);
    
            this.newPayload.currentState = {
                ...this.newPayload.currentState,
                enableStep3NextButton: false,
                ...selectionMap[type]
            };
    
            this.dispatchPayload();
        }
    }
 
    selectButton(type, event) {
        if (event) event.stopPropagation();
    
        const selectionStates = {
            addUser: { addUserIsSelected: true, removeUserIsSelected: false, userIsSelected: true, deviceIsSelected: false },
            removeUser: { removeUserIsSelected: true, addUserIsSelected: false, userIsSelected: true, deviceIsSelected: false },
            addDevice: { addDeviceIsSelected: true, removeDeviceIsSelected: false, userIsSelected: false, deviceIsSelected: true },
            removeDevice: { removeDeviceIsSelected: true, addDeviceIsSelected: false, userIsSelected: false, deviceIsSelected: true }
        };
    
        this[Object.keys(selectionStates[type])[0]] = !this[Object.keys(selectionStates[type])[0]];
        Object.assign(this, selectionStates[type]);
    
        if (this[Object.keys(selectionStates[type])[0]]) {
            this.newPayload.currentState = {
                ...this.newPayload.currentState,
                enableStep3NextButton: true,
                ...selectionStates[type]
            };
            this.dispatchPayload();
        }
    }

    dispatchPayload() {
        this.dispatchEvent(new CustomEvent('newpayload', { detail: this.newPayload }));
    }
}