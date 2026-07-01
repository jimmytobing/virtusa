import { LightningElement, track, wire } from 'lwc';

import submitApplication
    from '@salesforce/apex/GrantApplicationController.submitApplication';

import getActiveGrantTypes
    from '@salesforce/apex/GrantApplicationController.getActiveGrantTypes';

import { ShowToastEvent }
    from 'lightning/platformShowToastEvent';

export default class GrantApplicationForm extends LightningElement {

    applicantId;

    grantType;

    requestedAmount;

    reason;

    @track
    loading = false;

    grantTypeOptions = [];

    @wire(getActiveGrantTypes)
    wiredGrantTypes({ data, error }) {

        if (data) {
            this.grantTypeOptions = data.map((grantType) => ({
                label: grantType,
                value: grantType
            }));
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title : 'Error',
                    message : this.getErrorMessage(error),
                    variant : 'error'
                })
            );
        }
    }

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
                        this.getErrorMessage(error),

                    variant : 'error'

                })

            );

        }

        finally{

            this.loading = false;

        }

    }

    getErrorMessage(error) {

        if (error && error.body && error.body.message) {
            return error.body.message;
        }

        if (error && Array.isArray(error.body)) {
            return error.body.map((item) => item.message).join(', ');
        }

        return 'Unexpected error.';
    }

}
