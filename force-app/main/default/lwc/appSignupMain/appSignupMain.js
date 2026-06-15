import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { MessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import ONE_JOURNEY_CHANNEL from '@salesforce/messageChannel/oneJourney__c';
import { setCSSProperties, setFont, getAllSignupSteps } from 'c/appUtil';

import appSignupOptions from 'c/appSignupOptions';
import appPartnerServiceOptions from 'c/appPartnerServiceOptions';
import appSignupVerifyAccount from 'c/appSignupVerifyAccount';
import appSignupShowKYCCSA from 'c/appSignupShowKYCCSA';
import appRequestService from 'c/appRequestService';
import applicationEftposBiller from 'c/applicationEftposBiller';
import appRemoveEftposMultipleMerchants from 'c/appRemoveEftposMultipleMerchants';
import appAddEftposDevices from 'c/appAddEftposDevices';
import appRemoveEftposDevices from 'c/appRemoveEftposDevices';
import appThankYou from 'c/appThankYou';

import proceedToNormalCSA from '@salesforce/apex/BillerMatchController.proceedToNormalCSA';
import proceedToProdAdd from '@salesforce/apex/BillerMatchController.proceedToProdAdd';
import updatePrefillDetails from '@salesforce/apex/EftposUserController.updatePrefillDetails';

import createCaseToRemoveMultipleMerchant from '@salesforce/apex/OnboardingCaseCtrl.createCaseToRemoveMultipleMerchant';
import createAddEftposDevicesCase from '@salesforce/apex/OnboardingCaseCtrl.createAddEftposCase';
import createRemoveEftposDevicesCase from '@salesforce/apex/OnboardingCaseCtrl.createRemoveEftposDevicesCase';

export default class AppSignupMain extends LightningElement {
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
        [4, { 'Previous_Button_Label': 'Previous', 'Next_Button_Label': 'Next' }],
        [5, { 'Previous_Button_Label': 'Previous', 'Next_Button_Label': 'Confirm' }],
        [6, { 'Previous_Button_Label': 'Previous', 'Next_Button_Label': 'Confirm' }],
        [7, { 'Previous_Button_Label': 'Previous', 'Next_Button_Label': 'Confirm' }],
        [8, { 'Previous_Button_Label': null, 'Next_Button_Label': null }]
    ]);
    disableNextButton = true;
    spinnerLoading = false;
    targetPageUrl;
    brand;

    components = [
        { isComplete: true, showNextButton: false , showNewRequestButton: false }, //showSignupOptions 0
        { isComplete: false, showNextButton: false , showNewRequestButton: false }, //showKycCSAApplication appSignupShowKYCCSA 1
        { isComplete: false, showNextButton: true , showNewRequestButton: false }, //showVerifyClientDetails appSignupVerifyAccount 2
        { isComplete: false, showNextButton: true , showNewRequestButton: false }, // appRequestService 3
        { isComplete: false, showNextButton: true , showNewRequestButton: false }, // applicationEftposBiller 4
        { isComplete: false, showNextButton: true , showNewRequestButton: false }, // appRemoveEftposMultipleMerchants 5
        { isComplete: false, showNextButton: true , showNewRequestButton: false }, // appAddEftposDevices 6
        { isComplete: false, showNextButton: true , showNewRequestButton: false }, // appRemoveEftposDevices 7
        { isComplete: true, showNextButton: false , showNewRequestButton: true }  // appThankYou 8
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

    @wire(CurrentPageReference)
    pageRef;

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
        // const stepParam = parseInt(this.pageRef?.state?.step, 10);
        // if (!isNaN(stepParam) && stepParam >= 0 && stepParam <= 8) {
        //     this.payload = { ...this.payload, currentStep: stepParam };
        // }
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
        } else if (this.payload.currentStep == 6 || this.payload.currentStep == 7) {
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
            // Update prefill details server-side when leaving step 4 (applicationEftposBiller)
            if (this.payload.currentStep == 4 && this.payload?.currentState?.prefillChecked != null) {
                try {
                    await updatePrefillDetails({
                        oppId: this.payload?.currentState?.oppId,
                        prefill: this.payload.currentState.prefillChecked
                    });
                } catch (err) {
                    console.log('Failed to update prefill details' + JSON.stringify(err));
                }
            }
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
            return 4;
        } else if (currentStep == 3 && this.payload.currentState.removeUserIsSelected) {
            return 5;
        } else if (currentStep == 3 && this.payload?.currentState?.addDeviceIsSelected) {
            return 6;
        } else if (currentStep == 3 && this.payload?.currentState?.removeDeviceIsSelected) {
            return 7;
        } else if (currentStep == 4) {
            this.payload = { ...this.payload, isNotAddMerchant: true };
            return 8;
        } else if (currentStep == 5) {
            console.log(JSON.stringify(this.payload.currentState.toBeRemovedMerchants));
            createCaseToRemoveMultipleMerchant({
                clientId: this.payload?.currentState?.ClientId,
                businessNumber: this.payload?.currentState?.BusinessRegistrationNumber,
                requesterEmailAddress: this.payload?.currentState?.requesterEmailAddress,
                merchants: JSON.stringify(this.payload.currentState.toBeRemovedMerchants)
            })
            //window.location.href = 'https://www.ezidebit.com/en-au/online-csa-enquiry';
            this.payload = { ...this.payload, isNotAddMerchant: true };
            return 8;
        } else if (currentStep == 6) {
            createAddEftposDevicesCase({
                clientId: this.payload?.currentState?.ClientId,
                businessNumber: this.payload?.currentState?.BusinessRegistrationNumber,
                requesterEmailAddress: this.payload?.currentState?.requesterEmailAddress,
                selectedEftposDevices: this.payload?.currentState?.selectedValue.value
            })
            //window.location.href = 'https://www.ezidebit.com/en-au/online-csa-enquiry';
            this.payload = { ...this.payload, isNotAddMerchant: true };
            return 8;
        } else if (currentStep == 7) {

            createRemoveEftposDevicesCase({
                clientId: this.payload?.currentState?.ClientId,
                businessNumber: this.payload?.currentState?.BusinessRegistrationNumber,
                requesterEmailAddress: this.payload?.currentState?.requesterEmailAddress,
                selectedEftposDevices: JSON.stringify(this.payload.currentState.devices)
            })
            //window.location.href = 'https://www.ezidebit.com/en-au/online-csa-enquiry';    
            this.payload = { ...this.payload, isNotAddMerchant: true };        
            return 8;
        } else if (currentStep == 8) {

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
        } else if (this.payload.currentStep == 6) {
            this.components[6].isComplete = !!this.payload?.currentState?.enableStep6NextButton;
            this.components[6].showNextButton = !!this.payload?.currentState?.showStep6NextButton;
        } else if (this.payload.currentStep == 7) {
            this.components[7].isComplete = !!this.payload?.currentState?.enableStep7NextButton;
            this.components[7].showNextButton = !!this.payload?.currentState?.showStep7NextButton;
        } else if (this.payload.currentStep == 8) {
            this.components[8].isComplete = true;
            this.components[8].showNextButton = false;
            this.components[8].newReqButton = true;
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
            0: appSignupOptions,
            1: appSignupShowKYCCSA,
            2: appSignupVerifyAccount,
            3: appRequestService,
            4: applicationEftposBiller,
            5: appRemoveEftposMultipleMerchants,
            6: appAddEftposDevices,
            7: appRemoveEftposDevices,
            8: appThankYou
        };

        // For step 0, check if this is partner service flow
        if (this.payload.currentStep === 0 && this.payload.isPartnerServiceFlow) {
            this.componentConstructor = appPartnerServiceOptions;
        } else {
            this.componentConstructor = components[this.payload.currentStep];
        }
    }

    async handleNewRequestButton(){
        this.spinnerLoading = true;
        let step = this.getNextStep(this.payload.currentStep);

        if (this.payload.currentStep === 8 && step === 2) {
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