public with sharing class GrantApplicationService {

    public static Id submitApplication(GrantDTO request) {

        if (request == null) {
            throw new GrantException('Request cannot be null.');
        }

        EligibilityResult eligibility =
            GrantEligibilityService.evaluate(
                request.applicantId,
                request.grantType,
                request.requestedAmount
            );

        if (!eligibility.eligible) {
            throw new GrantException(eligibility.message);
        }

        Grant_Application__c application = new Grant_Application__c();

        application.Applicant__c = request.applicantId;
        application.Grant_Type__c = request.grantType;
        application.Requested_Amount__c = request.requestedAmount;
        application.Approved_Amount__c = eligibility.approvedAmount;
        application.Eligibility_Score__c = eligibility.score;
        application.Reason__c = request.reason;
        application.Status__c = GrantConstants.STATUS_PENDING;
        application.Application_Date__c = Date.today();
        application.Submitted_Date__c = Datetime.now();

        return GrantApplicationRepository.save(application);
    }

}