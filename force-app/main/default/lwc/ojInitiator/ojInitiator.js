import { LightningElement, wire } from 'lwc';
import { MessageContext, publish } from 'lightning/messageService';;
import { loadStyle } from 'lightning/platformResourceLoader';
import getRecords from '@salesforce/apex/OJInitiatorCtrl.getRecords';
import OJ_CSS from '@salesforce/resourceUrl/ojCSSLibrary';
import ONE_JOURNEY_CHANNEL from '@salesforce/messageChannel/oneJourney__c';
import { getAllSteps, getRequiredFields } from 'c/ojUtil';
import { CurrentPageReference } from 'lightning/navigation';
import LightningAlert from 'lightning/alert';
import GLOBAL_FONT_LIBRARY from '@salesforce/resourceUrl/sfGlobalFontLibrary';

export default class ojInitiator extends LightningElement {
    payload = {
        currentStep: 0,
        currentState: {
            billingAcctSelected: null,
            updateBillingAccount: null,
            settlementAcctSelected: null,
            varificationCompletionState: null
        },
        Account: {

        },
        application: {

        },
        Theme: {

        },
        attachment:{
            settlementDocumentId : '',
            settlementDocumentName : '',
            settlementDocumentSize : '',
            billingDocumentId : '',
            billingDocumentName : '',
            billingDocumentSize : ''
        },
    };

    requiredFields = {
    };

    recordId;
    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        console.log('>>pageRef: ' + JSON.stringify(pageRef));
        if (pageRef) {
            this.recordId = pageRef.state.recordId;
        }
    }

    @wire(MessageContext)
    messageContext;

    fetchData() {
        getRecords({ recordId: this.recordId, fields: this.requiredFields })
            .then(result => {
                this.payload.Account = result.Account;
                this.payload.Application = result.Application;
                this.payload.Theme = result.Theme;
                this.payload.allSteps = getAllSteps();
                this.waitSeconds(1);
            })
            .catch(error => {
                console.error('Error fetching data:', error);
                LightningAlert.open({
                    message: 'Sorry, an error occurred. Please contact support.',
                    theme: 'error',
                    label: 'Error in loading account!',
                });
            });
    }

    connectedCallback() {
        Promise.all([
            loadStyle(this, OJ_CSS),
            loadStyle(this, GLOBAL_FONT_LIBRARY + '/sfGlobalFontLibrary/sfGlobalFontStyles.css')
        ]).then(() => {
            this.requiredFields = getRequiredFields();
            this.fetchData();
        })
        .catch(error => {
            console.error('Error loading styles', error);
        });
    }

    waitSeconds(secs) {
        setTimeout(() => {
            publish(this.messageContext, ONE_JOURNEY_CHANNEL, this.payload);
        }, secs * 1000);
    }
}