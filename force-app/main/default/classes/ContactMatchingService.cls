public without sharing class ContactMatchingService {

    public static Contact upsertApplicantByPhone(GrantDTO request) {
        if (request == null) {
            throw new GrantException('Request cannot be null.');
        }

        Contact applicant = findByPhone(request.phone);
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

    private static Contact findByPhone(String phone) {
        if (String.isBlank(phone)) {
            return null;
        }

        List<Contact> contacts = [
            SELECT Id
            FROM Contact
            WHERE Phone = :phone
            ORDER BY CreatedDate, Id
            LIMIT 1
        ];

        return contacts.isEmpty()
            ? null
            : contacts[0];
    }
}
