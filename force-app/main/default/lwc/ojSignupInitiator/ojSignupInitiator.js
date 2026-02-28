import { LightningElement, wire,api } from 'lwc';
import { MessageContext, publish } from 'lightning/messageService';;
import { loadStyle } from 'lightning/platformResourceLoader';
import getRecords from '@salesforce/apex/OJInitiatorCtrl.getRecords';
import getNewRequestUserData from '@salesforce/apex/OJInitiatorCtrl.getNewRequestUserData';
import OJ_CSS from '@salesforce/resourceUrl/ojCSSLibrary';
import ONE_JOURNEY_CHANNEL from '@salesforce/messageChannel/oneJourney__c';
import { getAllSignupSteps, getAllSignupFields, getRequiredFields } from 'c/ojUtil';
import { CurrentPageReference } from 'lightning/navigation';
import LightningAlert from 'lightning/alert';
import GLOBAL_FONT_LIBRARY from '@salesforce/resourceUrl/sfGlobalFontLibrary';

export default class OjSignupInitiator extends LightningElement {

     //Component properties
     @api testLeadId;
     @api sandboxEnvironment = false;

    payload = {
        currentStep: 0,
        currentState: {
            newClientIsSelected: null,
            existingClientIsSelected: null
        },
        Theme: {

        },
        Lead: {

        },
        Account: {

        },
        CSA : {

        }
    };

    requiredFields = {
    };

    objName = 'Lead';

    recordId = '';
    opptId = '';
    contId = '';
    recOrigin = '';
    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef) {
            if (pageRef.state.pId) {
                this.recordId = pageRef.state.pId;
                this.requiredFields = getRequiredFields();
                console.log('recordId for account:', this.recordId);
                console.log('Required fields for account:', JSON.stringify(this.requiredFields));
            } else {
                this.recordId = pageRef.state.Id;
                this.requiredFields = getAllSignupFields();
            }
        
            // Check if oppid and conid are present in the URL (returning from add merchant page)
            if (pageRef.state.pId && pageRef.state.oppid && pageRef.state.conid) {
                this.opptId = pageRef.state.oppid;
                this.contId = pageRef.state.conid;
                this.recOrigin = pageRef.state.origin;

                // Run the payload update
                this.setNewRequestData().then(() => {
                            console.log('Payload update complete');
                        })
                        .catch(error => {
                            console.error('Error updating payload:', error);
                        });
            }

        }
    }

    @wire(MessageContext)
    messageContext;

    fetchData() {
        if(this.recordId === undefined && this.sandboxEnvironment ){
            this.recordId = this.testLeadId;
        }
        getRecords({ recordId: this.recordId, fields: this.requiredFields })
            .then(result => {
                this.payload.Lead = result.Lead;
                this.payload.Account = result.Account;
                this.payload.Theme = result.Theme;
                this.payload.allSteps = getAllSignupSteps();
                
                // Add flag to indicate partner service flow (pId parameter)
                this.payload.isPartnerServiceFlow = this.payload.Account ? true : false;
                console.log('Fetched data:', JSON.stringify(this.payload));
                this.waitSeconds(2);
            })
            .catch(error => {
                console.error('Error fetching data:', error);
                LightningAlert.open({
                    message: 'Sorry we are unable to direct you to the correct page, please contact our support team.',
                    theme: 'error',
                    label: 'Error!',
                });
            });
    }

    connectedCallback() {
        Promise.all([
            loadStyle(this, OJ_CSS),
            loadStyle(this, GLOBAL_FONT_LIBRARY + '/sfGlobalFontLibrary/sfGlobalFontStyles.css')
        ]).then(() => {
            this.fetchData();
        })
        .catch(error => {
            console.error('Error loading styles', error);
        });
    }

    waitSeconds(secs) {
        const self = this;
        setTimeout(() => {
            try {
                console.log(`Publishing message after waiting for ${secs} seconds...`);
                publish(self.messageContext, ONE_JOURNEY_CHANNEL, self.payload);
                console.log(`Published message: ${JSON.stringify(self.payload)}`);
            } catch (error) {
                console.error('Error publishing message:', error.message);
                console.error('Error stack:', error.stack);
            }
        }, secs * 1000);
    }

    setNewRequestData(){
       return getNewRequestUserData({ oppid: this.opptId, conid: this.contId })  // <-- return here
        .then(result => {
            this.payload.currentState = {
                ...this.payload.currentState,
                newClientIsSelected: null,
                existingClientIsSelected: true,
                ClientId: result.clientId,
                BusinessRegistrationNumber: result.businessNumber,
                requesterEmailAddress: result.requesterEmailAddress,
                showStep3NextButton: true,
                enableStep3NextButton: false,
                hasEFTPOS : true,
                isMultiMidEnabled : true
            };
            const tempIsNotAddMerchant = this.payload.isNotAddMerchant ? true : false;
            if(tempIsNotAddMerchant || ( this.recOrigin == 'appbiller')&& (!tempIsNotAddMerchant)){
                this.payload.currentStep = 3;
            } else {
                this.payload.currentStep = 7;
            }
        })
        .catch(error => {
            console.error('Error fetching data:', error);
            LightningAlert.open({
                message: 'Sorry we are unable to direct you to the correct page, please contact our support team.',
                theme: 'error',
                label: 'Error!',
            });
        });
    }
}