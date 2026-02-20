import { LightningElement, api } from 'lwc';
// import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import ONE_JOURNEY_CHANNEL from '@salesforce/messageChannel/oneJourney__c';
export default class OjProgressBarVertical extends LightningElement {
    _payload;
    @api brandType = 'ezidebit';
    @api currentPageName = 'ojbdUpdateBankDetails';
    @api progressValue = 0;
    isSubmittedPage = false;
    subscription;
    progressClass = '';
    tempCircleColor = '';
    tempSvgTextColor = '';
    tempProgressItemTextColor = '';
    stageSvgFillColor1 = '';
    stageSvgFillColor2 = '';
    stageSvgFillColor3 = '';
    stageSvgFillColor4 = '';
    stageSvgTextColor1 = '';
    stageSvgTextColor2 = '';
    stageSvgTextColor3 = '';
    stageSvgTextColor4 = '';
    progressItemTextColor1 = '';
    progressItemTextColor2 = '';
    progressItemTextColor3 = '';
    progressItemTextColor4 = '';
    isDesktop = false;
    stageSvgCompleted1 = false;
    stageSvgCompleted2 = false;
    stageSvgCompleted3 = false;
    stageSvgCompleted4 = false;
    progressBarColor = '';
    progressStageFont = '';
    completedStageSvgColor = '';
    componentConstructor;
    numberOfStepsInBankDetails = 3;
    billingAccountSelected = false;
    settlementAccountSelected = false;

    // @wire(MessageContext)
    // messageContext;

    @api
    get payload() {
        return this._payload;
    }

    set payload(value) {
        this._payload = value;
        this.handlePayload(this._payload);
    }

    connectedCallback() {
        this.checkScreenSize();
        window.addEventListener('resize', this.checkScreenSize.bind(this));    
        this.setCssProperties(this._payload.Theme.Progress_Bar__c);
        this.fetchCurrentProgressStage();
        this.handlePayload(this._payload)
        //this.subscribeToOneJourneyChannel();
    }

    setCssProperties(styleString){
        const declarations = styleString.split(';').filter(declaration => declaration.trim() !== '');
        declarations.forEach(declaration => {
            const [property, value] = declaration.split(':').map(item => item.trim());
            this.template.host.style.setProperty(`--${property}`, value);

            if (property === 'progress-stage-svg-font-color') {
                this.completedStageSvgColor = value;
            }
        });
    }


    handlePayload(payload) {
        var currentStep;
        var componentName;
        currentStep = payload.currentStep;
        if (currentStep >= 0 && currentStep <= payload.allSteps.length) {
           componentName = payload.allSteps[currentStep].componentName; 
        }
        this.currentState = payload.currentState;
        this.billingAccountSelected = this.currentState.billingAcctSelected;
        this.settlementAccountSelected = this.currentState.settlementAcctSelected;

        this.currentPageName = componentName;
        this.setCssProperties(payload.Theme.Progress_Bar__c);
        this.fetchCurrentProgressStage();
            
    }

    checkScreenSize() {
        this.isDesktop= window.matchMedia('(min-width: 768px)').matches;
        if (this.isDesktop) {
            this.progressClass += ' slds-progress_vertical';
        }
    }

    get verticalProgressBarStyle() {
        return `height: ${this.progressValue}%`;
    }

    fetchCurrentProgressStage() {
        const defaultFillColor = 'default-progress-svg-circle';
        const defaultSvgTextColor = 'default-progress-stage-svg-text-color progress-stage-svg-text';
        const defaultProgressItemTextColor = 'slds-progress__item_content slds-grid slds-grid_align-spread progress-stage-text-style';
        const tempCircleColor = 'progress-svg-circle';
        const tempSvgTextColor = 'progress-stage-svg-text-color  progress-stage-svg-text';
        const tempProgressItemTextColor = 'progress-item-text-color progress-stage-text-style';
        
        let numberOfStages = 3; // Number of Stages in Progressbar (0-3)
        let stageOrder = 0; // Current Stage number
        let numberOfStepsInTheStage = 2;
    
        this.stageSvgFillColor1 = this.stageSvgFillColor2 = this.stageSvgFillColor3 = this.stageSvgFillColor4 = defaultFillColor;        
        this.stageSvgTextColor1 = this.stageSvgTextColor2 = this.stageSvgTextColor3 = this.stageSvgTextColor4 = defaultSvgTextColor;        
        this.progressItemTextColor1 = this.progressItemTextColor2 = this.progressItemTextColor3 = this.progressItemTextColor4 = defaultProgressItemTextColor;
        this.stageSvgCompleted1 = this.stageSvgCompleted2 = this.stageSvgCompleted3 = this.stageSvgCompleted4 = false;

        
        if(this.settlementAccountSelected == true && this.billingAccountSelected == true){
            this.numberOfStepsInBankDetails = 3;
        }else if(this.settlementAccountSelected == false && this.billingAccountSelected == true){
            this.numberOfStepsInBankDetails = 1;
        }else if(this.settlementAccountSelected == true && this.billingAccountSelected == false){            
            this.numberOfStepsInBankDetails = 1;
        }

        switch (this.currentPageName) {
            case 'ojbdUpdateBankDetails':
                stageOrder = 0;
                numberOfStepsInTheStage = 1;
                this.stageSvgFillColor1 = tempCircleColor;
                this.stageSvgTextColor1 = tempSvgTextColor;
                this.progressItemTextColor1 = tempProgressItemTextColor + ' current-progress-item-text-style';              
                this.progressValue = this.calculateProgress(numberOfStages, stageOrder, numberOfStepsInTheStage, 0);
                break;

            case 'ojbdSettlementAccount':
            case 'ojbdUpdateBillingAccount':
            case 'ojbdBillingAccount':
                stageOrder = 1;
                numberOfStepsInTheStage = this.numberOfStepsInBankDetails;
                this.stageSvgFillColor1 = this.stageSvgFillColor2 = tempCircleColor;
                this.stageSvgTextColor1 = this.stageSvgTextColor2 = tempSvgTextColor;
                this.progressItemTextColor1 = this.progressItemTextColor2 = tempProgressItemTextColor;
                this.progressItemTextColor2 += ' current-progress-item-text-style';
                this.stageSvgCompleted1 = true;
   
                if(this.numberOfStepsInBankDetails === 3){
                    this.progressValue = this.calculateProgress(numberOfStages, stageOrder, numberOfStepsInTheStage,this.currentPageName === 'ojbdSettlementAccount' ? 0 : this.currentPageName === 'ojbdUpdateBillingAccount' ? 1 : 2);
                }else if(this.numberOfStepsInBankDetails === 2){
                    this.progressValue = this.calculateProgress(numberOfStages, stageOrder, numberOfStepsInTheStage,this.currentPageName === 'ojbdUpdateBillingAccount' ? 0 : 1);
                }else if(this.numberOfStepsInBankDetails === 1){
                    this.progressValue = this.calculateProgress(numberOfStages, stageOrder, numberOfStepsInTheStage, 0);
                }             
                break;

            case 'ojbdVerifyYourAccounts': 
            case 'ojbdVerifyYourAccounts2':
                stageOrder = 2;
                numberOfStepsInTheStage = 2;
                this.stageSvgFillColor1 = this.stageSvgFillColor2 = this.stageSvgFillColor3 = tempCircleColor;
                this.stageSvgTextColor1 = this.stageSvgTextColor2 = this.stageSvgTextColor3 = tempSvgTextColor;
                this.progressItemTextColor1 = this.progressItemTextColor2 = this.progressItemTextColor3 = tempProgressItemTextColor;
                this.progressItemTextColor3 += ' current-progress-item-text-style';
                this.stageSvgCompleted1 = this.stageSvgCompleted2 = true;
                this.progressValue = this.calculateProgress(numberOfStages, stageOrder, numberOfStepsInTheStage, 'ojbdSettlementAccount' ? 0 : 1);
                break;

            case 'ojbdSubmitYourChange':
                stageOrder = 3;
                numberOfStepsInTheStage = 1;
                this.stageSvgFillColor1 = this.stageSvgFillColor2 = this.stageSvgFillColor3 = this.stageSvgFillColor4 = tempCircleColor;                
                this.stageSvgTextColor1 = this.stageSvgTextColor2 = this.stageSvgTextColor3 = this.stageSvgTextColor4 = tempSvgTextColor;
                this.progressItemTextColor1 = this.progressItemTextColor2 = this.progressItemTextColor3 = this.progressItemTextColor4 = tempProgressItemTextColor;
                this.progressItemTextColor4 += ' current-progress-item-text-style';
                this.stageSvgCompleted1 = this.stageSvgCompleted2 = this.stageSvgCompleted3 = true;
                this.progressValue = this.calculateProgress(numberOfStages, stageOrder, numberOfStepsInTheStage, 0);
                break;

            case 'ojbdSubmitted':
                this.isSubmitPage = true;
                break;

            default:
                break;
        }
    }

    calculateProgress(numberOfStages, stageOrder, numberOfStepsInTheStage, stepInStage) {
        return (100 / numberOfStages) * stageOrder + (stepInStage / numberOfStepsInTheStage) * (100 / numberOfStages);
    }

}