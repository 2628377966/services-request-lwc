import { LightningElement, wire } from 'lwc';
import { MessageContext, subscribe } from 'lightning/messageService';
import ONE_JOURNEY_CHANNEL from '@salesforce/messageChannel/oneJourney__c';
import { setFont } from 'c/ojUtil';
import { getAllSteps } from 'c/ojUtil';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class OjFooter extends LightningElement {
    subscription;

    @wire(MessageContext)
    messageContext;
    companyName;
    privacyPolicyLink;
    termsOfUseLink;
    chevronDoubleDown = true;

    connectedCallback() {
        this.subscribeToOneJourneyChannel();
    }

    subscribeToOneJourneyChannel() {
        this.subscription = subscribe(this.messageContext, ONE_JOURNEY_CHANNEL, (payload) => this.handlePayload(payload));
    }

    handlePayload(payload) {
        this.payload = { ...payload };
        this.companyName = payload.Theme.Company_Name__c;
        this.privacyPolicyLink = payload.Theme.Privacy_Policy_Link__c;
        this.termsOfUseLink = payload.Theme.Terms_Of_Use_Link__c;
        this.setCSSProperties(payload.Theme.Footer__c);
        setFont(this.template.host, payload.Theme.Font__c);

        if (FORM_FACTOR === 'Small' || FORM_FACTOR === 'Medium') {
            if (payload.currentStep == 0 || getAllSteps().length - 1 == payload.currentStep) {
                //this is the first / last component
                this.chevronDoubleDown = true;
            } else {
                this.chevronDoubleDown = false;
            }
            this.template.host.style.setProperty(`--font-size`, '0.79rem');
        } else {
            this.template.host.style.setProperty(`--font-size`, '0.875rem');
        }

    }

    get yearOfCopyright() { 
        let date = new Date();
        return date.getFullYear();
    }

    handleCollapse() {
        let collapseSection = this.template.querySelector(".collapsible");
        collapseSection.classList.toggle("active");

        if (this.chevronDoubleDown) {
            this.chevronDoubleDown = false;
        } else {
            this.chevronDoubleDown = true;
            window.scrollTo(0, document.body.scrollHeight);
        }        
    }

    setCSSProperties(styleString) {
        const declarations = styleString.split(';').filter(declaration => declaration.trim() !== '');
        declarations.forEach(declaration => {
            const [property, value] = declaration.split(':').map(item => item.trim());
            this.template.host.style.setProperty(`--${property}`, value);
        });
    }
}