public with sharing class GrantApplicationService {

    private static final Pattern SINGAPORE_PHONE_PATTERN =
        Pattern.compile('^65 [0-9]{4} [0-9]{4}$');

    private static final Pattern POSTAL_CODE_PATTERN =
        Pattern.compile('^[0-9]{6}$');

    public static Id submitApplication(GrantDTO request) {

        if (request == null) {
            throw new GrantException('Request cannot be null.');
        }

        validateApplicantRequest(request);

        Grant_Support_Option__mdt supportOption =
            GrantSupportOptionService.getActiveOption(
                request.supportOption
            );

        Contact applicant = upsertApplicant(request);

        if (request.monthlyIncome >= 2000) {
            throw new GrantException(
                'Eligibility check failed. Monthly Income must be less than SGD 2000.'
            );
        }

        Grant_Application__c application = new Grant_Application__c();

        application.Applicant__c = applicant.Id;
        application.Grant_Type__c = supportOption.MasterLabel;
        application.Requested_Amount__c =
            supportOption.Monthly_Amount__c
            * supportOption.Duration_Months__c;
        application.Approved_Amount__c = application.Requested_Amount__c;
        application.Eligibility_Score__c = 100;
        application.Reason__c = request.reason;
        application.Status__c = GrantConstants.STATUS_PENDING;
        application.Application_Date__c = Date.today();
        application.Submitted_Date__c = Datetime.now();

        Id applicationId = GrantApplicationRepository.save(application);

        GrantDisbursementService.recalculateDisbursements(
            applicant.Id,
            supportOption
        );

        return applicationId;
    }

    private static Contact upsertApplicant(GrantDTO request) {
        Contact applicant = ContactRepository.getByPhone(request.phone);
        Boolean isNewApplicant = applicant == null;

        if (isNewApplicant) {
            applicant = new Contact();
        }

        applicant.FirstName = request.firstName;
        applicant.LastName = request.lastName;
        applicant.Phone = request.phone;
        applicant.MailingPostalCode = request.mailingPostalCode;
        applicant.Monthly_Income__c = request.monthlyIncome;
        applicant.Annual_Income__c = request.monthlyIncome * 12;
        applicant.Support_Option__c = request.supportOption;

        GrantDisbursementService.bypassContactTrigger = true;

        try {
            if (isNewApplicant) {
                insert applicant;
            } else {
                update applicant;
            }
        } finally {
            GrantDisbursementService.bypassContactTrigger = false;
        }

        return applicant;
    }

    public static void validateApplicantRequest(GrantDTO request) {
        if (String.isBlank(request.firstName)) {
            throw new GrantException('Applicant First Name is required.');
        }

        if (String.isBlank(request.lastName)) {
            throw new GrantException('Applicant Last Name is required.');
        }

        if (
            String.isBlank(request.phone) ||
            !SINGAPORE_PHONE_PATTERN.matcher(request.phone).matches()
        ) {
            throw new GrantException(
                'Phone must use Singapore format 65 6812 3456.'
            );
        }

        if (
            String.isBlank(request.mailingPostalCode) ||
            !POSTAL_CODE_PATTERN.matcher(
                request.mailingPostalCode
            ).matches()
        ) {
            throw new GrantException(
                'Mailing Postal Code must be a 6 digit number.'
            );
        }

        if (request.monthlyIncome == null || request.monthlyIncome < 0) {
            throw new GrantException(
                'Monthly Income must be a valid SGD amount.'
            );
        }

        if (String.isBlank(request.supportOption)) {
            throw new GrantException('Support Option is required.');
        }
    }

}
