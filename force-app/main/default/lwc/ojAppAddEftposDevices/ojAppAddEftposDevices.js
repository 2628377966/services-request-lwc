import { api, LightningElement, track } from 'lwc'; 
import { setCSSProperties } from 'c/ojUtil';

export default class OjAppAddEftposDevices extends LightningElement {
    @api payload;
    newPayload;
    showForm = true;
    @track selectedValue = '0';

    connectedCallback() {
        setCSSProperties(this.template.host, 'divider', this.payload.Theme.Divider__c);
        setCSSProperties(this.template.host, 'primary', this.payload.Theme.Primary_Color__c);
        this.primaryColour = this.payload.Theme.Primary_Colour__c.match(/#([0-9A-Fa-f]{6})/)[0];
    
        this.newPayload = JSON.parse(JSON.stringify(this.payload));
        this.newPayload.currentState = {
            ...this.newPayload.currentState,
            showStep5NextButton: true
        };

        if (this.newPayload.currentState?.selectedValue?.value !== undefined) {
            this.selectedValue = String(this.newPayload.currentState.selectedValue.value);
        }
   
        this.newPayload.currentState.enableStep5NextButton = this.selectedValue !== '0';
    
        this.dispatchPayload();
    }

    get deviceOptions() {
        
        return [
            { label: 'e.g.1', value: '0' }, // default option
            ...Array.from({ length: 20 }, (_, i) => ({
                label: `${i + 1}`,
                value: `${i + 1}`
            }))
        ];
    }

    dispatchPayload() {
        this.dispatchEvent(new CustomEvent('newpayload', { detail: this.newPayload }));
    }

    handleSelect(event) {
        this.selectedValue = event.target.value;
        this.newPayload.currentState.enableStep5NextButton = this.selectedValue !== '0';

        this.newPayload.currentState.selectedValue = {
            value: this.selectedValue
        };

        this.dispatchPayload();
    }

    get processedDeviceOptions() {
        return this.deviceOptions.map(option => ({
            ...option,
            selected: option.value === this.selectedValue
        }));
    }
}