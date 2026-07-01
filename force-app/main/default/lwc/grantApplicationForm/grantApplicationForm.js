import { LightningElement, track } from 'lwc';

import submitApplication
    from '@salesforce/apex/GrantApplicationController.submitApplication';

import { ShowToastEvent }
    from 'lightning/platformShowToastEvent';

export default class GrantApplicationForm extends LightningElement {

    applicantId;

    grantType;

    requestedAmount;

    reason;

    @track
    loading = false;

    grantTypeOptions = [

        {
            label: 'Education Grant',
            value: 'Education Grant'
        },

        {
            label: 'Healthcare Grant',
            value: 'Healthcare Grant'
        }

    ];

    handleApplicantChange(event){

        this.applicantId = event.detail.recordId;

    }

    handleGrantTypeChange(event){

        this.grantType = event.detail.value;

    }

    handleAmountChange(event){

        this.requestedAmount = Number(event.detail.value);

    }

    handleReasonChange(event){

        this.reason = event.detail.value;

    }

    async submitApplication(){

        this.loading = true;

        try{

            const dto = {

                applicantId : this.applicantId,

                grantType : this.grantType,

                requestedAmount : this.requestedAmount,

                reason : this.reason

            };

            console.log('DTO =', JSON.stringify(dto));
            console.log('Applicant =', this.applicantId);
            console.log('GrantType =', this.grantType);
            console.log('Amount =', this.requestedAmount);
            console.log('Reason =', this.reason);

            const applicationId =
                await submitApplication({
                    request : dto
                });

            this.dispatchEvent(

                new ShowToastEvent({

                    title : 'Success',

                    message :
                        'Application submitted. Id : '
                        + applicationId,

                    variant : 'success'

                })

            );

        }

        catch(error){

            this.dispatchEvent(

                new ShowToastEvent({

                    title : 'Error',

                    message :
                        error.body.message,

                    variant : 'error'

                })

            );

        }

        finally{

            this.loading = false;

        }

    }

}