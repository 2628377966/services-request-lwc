import { LightningElement, wire } from 'lwc'; 
import { MessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import ONE_JOURNEY_CHANNEL from '@salesforce/messageChannel/oneJourney__c';
import { setCSSProperties, setFont, getAllSignupSteps } from 'c/ojUtil';

import ojAppSignupOptions from 'c/ojAppSignupOptions';
import ojAppPartnerServiceOptions from 'c/ojAppPartnerServiceOptions';
import ojAppSignupVerifyAccount from 'c/ojAppSignupVerifyAccount';
import ojAppSignupShowKYCCSA from 'c/ojAppSignupShowKYCCSA';
import ojAppRequestService from 'c/ojAppRequestService';
import ojAppRemoveEftposMultipleMerchants from 'c/ojAppRemoveEftposMultipleMerchants';
import ojAppAddEftposDevices from 'c/ojAppAddEftposDevices';
import ojAppRemoveEftposDevices from 'c/ojAppRemoveEftposDevices';
import ojThankYou from 'c/ojThankYou';

import proceedToNormalCSA from '@salesforce/apex/BillerMatchController.proceedToNormalCSA';
import proceedToProdAdd from '@salesforce/apex/BillerMatchController.proceedToProdAdd';

import createCaseToRemoveMultipleMerchant from '@salesforce/apex/OnboardingCaseCtrl.createCaseToRemoveMultipleMerchant';
import createAddEftposDevicesCase from '@salesforce/apex/OnboardingCaseCtrl.createAddEftposCase';
import createRemoveEftposDevicesCase from '@salesforce/apex/OnboardingCaseCtrl.createRemoveEftposDevicesCase';

export default class OjSignupMain extends LightningElement {
    showForm = false;
    payload;
    subscription;
    showProgressBar = false;
    allSteps;
    currentState;
    buttonLabelMapByStep = new Map([
        [0, { 'Previous_Button_Label': null, 'Next_Button_Label': null }],
        [1, { 'Previous_Button_Label': null, 'Next_Button_Label': null }],
        [2, { 'Previous_Button_Label': 'Previous', 'Next_Button_Label': 'Next' }],
        [3, { 'Previous_Button_Label': 'Previous', 'Next_Button_Label': 'Next' }],
        [4, { 'Previous_Button_Label': 'Previous', 'Next_Button_Label': 'Confirm' }],
        [5, { 'Previous_Button_Label': 'Previous', 'Next_Button_Label': 'Confirm' }],
        [6, { 'Previous_Button_Label': 'Previous', 'Next_Button_Label': 'Confirm' }],
        [7, { 'Previous_Button_Label': null, 'Next_Button_Label': null }]
    ]);
    disableNextButton = true;
    spinnerLoading = false;
    targetPageUrl;
    brand;

    components = [
        { isComplete: true, showNextButton: false , showNewRequestButton: false }, //showSignupOptions 0
        { isComplete: false, showNextButton: false , showNewRequestButton: false }, //showKycCSAApplication ojAppSignupShowKYCCSA 1
        { isComplete: false, showNextButton: true , showNewRequestButton: false }, //showVerifyClientDetails ojAppSignupVerifyAccount 2
        { isComplete: false, showNextButton: true , showNewRequestButton: false }, // ojAppRequestService 3
        { isComplete: false, showNextButton: true , showNewRequestButton: false }, // ojAppRemoveEftposMultipleMerchants 4
        { isComplete: false, showNextButton: true , showNewRequestButton: false }, // ojAppAddEftposDevices 5
        { isComplete: false, showNextButton: true , showNewRequestButton: false }, // ojAppRemoveEftposDevices 6
        { isComplete: true, showNextButton: false , showNewRequestButton: true }  // ojThankYou 7
    ];

    get showProgressBarVertical() {
        return this.showProgressBar;
    }

    get previousButtonLabel() {
        return this.buttonLabelMapByStep.get(this.payload.currentStep)?.Previous_Button_Label;
    }

    get nextButtonLabel() {
        return this.buttonLabelMapByStep.get(this.payload.currentStep)?.Next_Button_Label;
    }

    get showPreviousButton() {
        return this.buttonLabelMapByStep.get(this.payload.currentStep)?.Previous_Button_Label ? true : false;
    }

    get showNextButton() {
        return this.components[this.payload.currentStep].showNextButton;
    }

    get showNewRequestButton(){
        return this.components[this.payload.currentStep].showNewRequestButton || false;
    }


    componentConstructor;
    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.subscribeToOneJourneyChannel();
    }

    renderedCallback() {
        this.setNextButtonState();
    }

    subscribeToOneJourneyChannel() {
        this.subscription = subscribe(this.messageContext, ONE_JOURNEY_CHANNEL, (payload) => this.handlePayload(payload));
    }

    async handlePayload(payload) {
        console.log('Signup Main handlePayload Received payload:', JSON.stringify(payload));
        this.payload = payload;
        if (payload.Account) {
            this.brand = payload.Account.Brand__c;
        } else {
            this.brand = payload.Lead.Brand__c;
        }

        this.allSteps = getAllSignupSteps();
        setCSSProperties(this.template.host, 'button1', this.payload.Theme.Button1__c);
        setCSSProperties(this.template.host, 'button2', this.payload.Theme.Button2__c);
        setFont(this.template.host, this.payload.Theme.Font__c);
        await this.showHideComponents();
        this.showHideProgressBar();
        this.showForm = true;
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    showHideProgressBar() {
        this.showProgressBar = false;
    }

    async handleNewPayload(event) {
        const isNewServiceRequestTemp = this.payload?.currentState?.isNewServiceRequest === true;

        if(isNewServiceRequestTemp){
            this.payload = {
                            ...this.payload,
                            currentState: {
                                ...this.payload.currentState,
                                ...event.detail.currentState
                            }
            };
        }else{
            this.payload = { ...event.detail };
        }


        this.updateFormCompletionStatus();
        if (this.payload.currentStep == 0) {
            //CSA URL generation only for lead client flow
            if (!this.payload.isPartnerServiceFlow) {
                this.targetPageUrl = await this.generateCSAUrl();

                // ProdAdd TBA, do nothing For now
                if (this.targetPageUrl == 'Proceed to ProdAdd (TBA)') {
                    this.spinnerLoading = false;
                    return;
                }

                this.payload.CSA = { ...this.payload.CSA, csaUrl: this.targetPageUrl };
            }
            this.handleNextButton();
        }
        this.setNextButtonState();
    }

    async handlePreviousButton() {
        console.log('#>> Previous Button CurrentStep: ', this.payload.currentStep);
        this.spinnerLoading = true;
        let step;
        if (this.payload.currentStep == 2) {
            step = 0; //showSignupOptions
        } else if (this.payload.currentStep == 5 || this.payload.currentStep == 6) {
            step = 3; //showRequestService
        } else {
            step = this.payload.currentStep - 1;
        }

        this.payload = { ...this.payload, ...{ 'currentStep': step } };
        await this.showHideComponents();
        this.setNextButtonState();
        this.spinnerLoading = false;
    }

    async handleNextButton() {
        this.spinnerLoading = true;

        if (this.isFormFullyValid()) {
            let step = this.getNextStep(this.payload.currentStep);
            this.payload = { ...this.payload, ...{ 'currentStep': step } };
            this.showHideComponents();
        } else {
            console.log('form is invalid');
        }
        this.spinnerLoading = false;
    }

    async generateCSAUrl() {
        let pageUrl;
        try {
            if (this.payload.currentState.ExistingClientNextStep == 'NormalCSA') {
                pageUrl = await proceedToNormalCSA({ leadId: this.payload.Lead.Id });
            } else if (this.payload.currentState.ExistingClientNextStep == 'ProdAdd') {
                pageUrl = await proceedToProdAdd({ leadId: this.payload.Lead.Id });
            }
        } catch (error) {
            this.spinnerLoading = false;
            console.error('error while generating csa url');
        }
        return pageUrl;
    }

    getNextStep(currentStep) {
        if (currentStep == 0 && this.payload.currentState.newClientIsSelected) {
            return 1;
        } else if (currentStep == 0 && this.payload.currentState.eftposMultiMerchantIsSelected && this.payload.isPartnerServiceFlow) {
            return 2;
        } else if (currentStep == 0 && this.payload.currentState.existingClientIsSelected && !this.payload.isPartnerServiceFlow) {
            return 2;
        } else if (currentStep == 2 && this.payload.currentState.existingClientIsSelected && this.isFormFullyValid(this.payload.currentStep)) {
            return 3;
        } else if (currentStep == 3 && this.payload.currentState.addUserIsSelected) {
            window.location.href = this.payload.currentState.siteURL + '/kyc_eftposbiller?oppId='
            + this.payload.currentState.oppId + '&csa=' 
            + this.payload.currentState.csaId  + '&origin=signup' +'&conid='+this.payload.currentState.requesterContactId;
        } else if (currentStep == 3 && this.payload.currentState.removeUserIsSelected) {
            return 4;
        } else if (currentStep == 3 && this.payload?.currentState?.addDeviceIsSelected) {
            return 5;
        } else if (currentStep == 3 && this.payload?.currentState?.removeDeviceIsSelected) {
            return 6;
        } else if (currentStep == 4) {
            console.log(JSON.stringify(this.payload.currentState.toBeRemovedMerchants));
            createCaseToRemoveMultipleMerchant({
                clientId: this.payload?.currentState?.ClientId,
                businessNumber: this.payload?.currentState?.BusinessRegistrationNumber,
                requesterEmailAddress: this.payload?.currentState?.requesterEmailAddress,
                merchants: JSON.stringify(this.payload.currentState.toBeRemovedMerchants)
            })
            //window.location.href = 'https://www.ezidebit.com/en-au/online-csa-enquiry';
            this.payload = { ...this.payload, isNotAddMerchant: true };
            return 7;
        } else if (currentStep == 5) {
            createAddEftposDevicesCase({
                clientId: this.payload?.currentState?.ClientId,
                businessNumber: this.payload?.currentState?.BusinessRegistrationNumber,
                requesterEmailAddress: this.payload?.currentState?.requesterEmailAddress,
                selectedEftposDevices: this.payload?.currentState?.selectedValue.value
            })
            //window.location.href = 'https://www.ezidebit.com/en-au/online-csa-enquiry';
            this.payload = { ...this.payload, isNotAddMerchant: true };
            return 7;
        } else if (currentStep == 6) {

            createRemoveEftposDevicesCase({
                clientId: this.payload?.currentState?.ClientId,
                businessNumber: this.payload?.currentState?.BusinessRegistrationNumber,
                requesterEmailAddress: this.payload?.currentState?.requesterEmailAddress,
                selectedEftposDevices: JSON.stringify(this.payload.currentState.devices)
            })
            //window.location.href = 'https://www.ezidebit.com/en-au/online-csa-enquiry';    
            this.payload = { ...this.payload, isNotAddMerchant: true };        
            return 7;
        } else if (currentStep == 7) {

            return  2;
        }
    }

    isFormFullyValid() {
        return this.components[this.payload.currentStep].isComplete;
    }

    async updateFormCompletionStatus() {
        if (this.payload.currentStep == 2) {
            this.components[2].isComplete = this.payload?.currentState?.enableNextButton ? true : false;
        } else if (this.payload.currentStep == 3) {
            this.components[3].isComplete = !!this.payload?.currentState?.enableStep3NextButton;
            this.components[3].showNextButton = !!this.payload?.currentState?.showStep3NextButton;
        } else if (this.payload.currentStep == 4) {
            this.components[4].isComplete = !!this.payload?.currentState?.enableStep4NextButton;
        } else if (this.payload.currentStep == 5) {
            this.components[5].isComplete = !!this.payload?.currentState?.enableStep5NextButton;
            this.components[5].showNextButton = !!this.payload?.currentState?.showStep5NextButton;
        } else if (this.payload.currentStep == 6) {
            this.components[6].isComplete = !!this.payload?.currentState?.enableStep6NextButton;
            this.components[6].showNextButton = !!this.payload?.currentState?.showStep6NextButton;
        }else if (this.payload.currentStep == 7) {
            this.components[7].isComplete = true;
            this.components[7].showNextButton = false;
            this.components[7].newReqButton = true;
        }
    }

    setNextButtonState() {
        let button2 = this.template.querySelector('[data-name="button2"]');
        if (button2) {
            if (this.components[this.payload.currentStep].isComplete) {
                this.disableNextButton = false;
                button2.classList.remove('button2Disabled');
                button2.classList.add('button2');
            } else {
                this.disableNextButton = true;
                button2.classList.add('button2Disabled');
                button2.classList.remove('button2');
            }
        }
    }

    async showHideComponents() {
        const components = {
            0: ojAppSignupOptions,
            1: ojAppSignupShowKYCCSA,
            2: ojAppSignupVerifyAccount,
            3: ojAppRequestService,
            4: ojAppRemoveEftposMultipleMerchants,
            5: ojAppAddEftposDevices,
            6: ojAppRemoveEftposDevices,
            7: ojThankYou
        };
        
        // For step 0, check if this is partner service flow
        if (this.payload.currentStep === 0 && this.payload.isPartnerServiceFlow) {
            this.componentConstructor = ojAppPartnerServiceOptions;
        } else {
            this.componentConstructor = components[this.payload.currentStep];
        }
    }

    async handleNewRequestButton(){
        this.spinnerLoading = true;
        let step = this.getNextStep(this.payload.currentStep);

        if (this.payload.currentStep === 7 && step === 2) {
            await this.resetPayloadState();
        }

        this.payload = { ...this.payload, currentStep: step };
        await this.showHideComponents();
        this.components[2].isComplete = true;
        this.setNextButtonState();
        this.handleNextButton();
        this.spinnerLoading = false;

    }

    resetPayloadState() {
        this.payload.currentState = {
            ...this.payload.currentState,
            userIsSelected:false,
            addUserIsSelected: false,
            removeUserIsSelected: false,
            deviceIsSelected: false,
            addDeviceIsSelected: false,
            removeDeviceIsSelected: false,
            selectedValue: null,
            showStep3NextButton: true,
            enableStep3NextButton: false,
            toBeRemovedMerchants: [],
            devices: [],
            isNewServiceRequest: true,
            enableNextButton: true
        };

        for (let i = 3; i <= 6; i++) {
            this.components[i].isComplete = false;
        }

    }

}