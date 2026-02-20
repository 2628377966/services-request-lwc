import { LightningElement, api } from 'lwc';

export default class ApplicationFooter extends LightningElement {
    @api brandType ;
    //@api currentScreen = '';
    @api showPreviousButton;
    @api showAddAnotherBiller ;
    @api nextButtonLabel;
    @api addBillerLinkLabel;
    @api isNextButtonDisabled;

    @api brandClass;
    previousButtonLabel = 'Previous';
    btnBrandNext = '';
    btnBrandPrev = '';
    linkStyle='';

    connectedCallback() {
        this.setBranding();
    }

    handleNext(event) {
        event.preventDefault()
        // Request validation from the parent component
        const validateFormEvent = new CustomEvent('validateform', {
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(validateFormEvent);
    }

    handleAddBillerLink(){
        const addAnotherBillerEvent = new CustomEvent('addanotherbiller', {
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(addAnotherBillerEvent);
    }

    handlePrevious(event) {
        event.preventDefault()
        const handlePreviousEvent = new CustomEvent('handleprevious', {
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(handlePreviousEvent);
    }

    setBranding() {        
        // Check if brandType is already set from the flow
        if (this.brandType && this.brandType.trim() !== '') { 
            this.brandType = this.brandType.toLowerCase() ;
            this.brandClass = this.brandType == 'ezidebit' ? 'ezidebit-brand' : 'eway-brand';
            if (this.brandType === 'ezidebit') {
                this.btnBrandNext += 'ezidebit-screen-nav-button-text ezidebit-screen-nav-button-next';
                this.btnBrandPrev += 'ezidebit-screen-nav-button-text ezidebit-screen-nav-button-prev ';
                this.linkStyle += 'ezidebit-nav-link';
            } else if (this.brandType === 'eway') {
                if (this.nextButtonLabel.toLowerCase().includes('next')) { 
                }
                this.btnBrandNext += 'eway-screen-nav-button-text eway-screen-nav-button-next';
                this.btnBrandPrev += 'eway-screen-nav-button-text eway-screen-nav-button-prev';
                this.linkStyle += 'eway-nav-link';
            }
        } else {
            //Set Defult
            this.btnBrandNext += 'ezidebit-screen-nav-button-text ezidebit-screen-nav-button-next';
            this.btnBrandPrev += 'ezidebit-screen-nav-button-text ezidebit-screen-nav-button-prev ';
            this.linkStyle += 'ezidebit-nav-link';
        }
    }
}