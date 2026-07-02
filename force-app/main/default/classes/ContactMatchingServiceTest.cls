@IsTest
private class ContactMatchingServiceTest {

    @IsTest
    static void upsertApplicantByPhoneCreatesNewContact() {
        GrantDTO request = createGrantRequest('65 6812 3458');

        Test.startTest();
        Contact applicant = ContactMatchingService.upsertApplicantByPhone(
            request
        );
        Test.stopTest();

        Contact savedApplicant = [
            SELECT
                Id,
                AccountId,
                FirstName,
                LastName,
                Phone,
                MailingPostalCode,
                Monthly_Income__c,
                Annual_Income__c,
                Support_Option__c
            FROM Contact
            WHERE Id = :applicant.Id
        ];

        System.assertNotEquals(null, savedApplicant.AccountId);
        System.assertEquals('Grant', savedApplicant.FirstName);
        System.assertEquals('Applicant', savedApplicant.LastName);
        System.assertEquals('65 6812 3458', savedApplicant.Phone);
        System.assertEquals('123456', savedApplicant.MailingPostalCode);
        System.assertEquals(1000, savedApplicant.Monthly_Income__c);
        System.assertEquals(12000, savedApplicant.Annual_Income__c);
        System.assertEquals('Option One', savedApplicant.Support_Option__c);

        GrantDTO secondRequest = createGrantRequest('65 6812 3460');
        Contact secondApplicant = ContactMatchingService.upsertApplicantByPhone(
            secondRequest
        );

        Contact savedSecondApplicant = [
            SELECT AccountId
            FROM Contact
            WHERE Id = :secondApplicant.Id
        ];

        System.assertEquals(
            savedApplicant.AccountId,
            savedSecondApplicant.AccountId,
            'New applicants should reuse the existing holding account.'
        );
    }

    @IsTest
    static void upsertApplicantByPhoneUpdatesExistingContact() {
        Account accountRecord = new Account(Name = 'Existing Applicant Account');
        insert accountRecord;

        Contact existingApplicant = new Contact(
            AccountId = accountRecord.Id,
            FirstName = 'Existing',
            LastName = 'Applicant',
            Phone = '65 6812 3459',
            MailingPostalCode = '111111',
            Monthly_Income__c = 400,
            Support_Option__c = 'Option One'
        );
        insert existingApplicant;

        GrantDTO request = createGrantRequest('65 6812 3459');
        request.firstName = 'Updated';
        request.mailingPostalCode = '222222';
        request.monthlyIncome = 750;
        request.supportOption = 'Option Two';

        Test.startTest();
        Contact applicant = ContactMatchingService.upsertApplicantByPhone(
            request
        );
        Test.stopTest();

        List<Contact> savedApplicants = [
            SELECT
                Id,
                AccountId,
                FirstName,
                Phone,
                MailingPostalCode,
                Monthly_Income__c,
                Annual_Income__c,
                Support_Option__c
            FROM Contact
            WHERE Phone = '65 6812 3459'
        ];

        System.assertEquals(existingApplicant.Id, applicant.Id);
        System.assertEquals(1, savedApplicants.size());
        System.assertEquals(accountRecord.Id, savedApplicants[0].AccountId);
        System.assertEquals('Updated', savedApplicants[0].FirstName);
        System.assertEquals('222222', savedApplicants[0].MailingPostalCode);
        System.assertEquals(750, savedApplicants[0].Monthly_Income__c);
        System.assertEquals(9000, savedApplicants[0].Annual_Income__c);
        System.assertEquals('Option Two', savedApplicants[0].Support_Option__c);
    }

    @IsTest
    static void upsertApplicantByPhoneRejectsNullRequest() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            ContactMatchingService.upsertApplicantByPhone(null);
        } catch (GrantException exceptionRecord) {
            exceptionThrown = true;
            System.assertEquals(
                'Request cannot be null.',
                exceptionRecord.getMessage()
            );
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Null requests should be rejected.');
    }

    @IsTest
    static void contactRepositoryFindsApplicantsByIdAndPhone() {
        Account accountRecord = new Account(Name = 'Repository Account');
        insert accountRecord;

        Contact applicant = new Contact(
            AccountId = accountRecord.Id,
            FirstName = 'Repository',
            LastName = 'Applicant',
            Phone = '65 6812 3462',
            MailingPostalCode = '123456',
            Monthly_Income__c = 900,
            Support_Option__c = 'Option One'
        );
        insert applicant;

        Test.startTest();
        Contact applicantById = ContactRepository.getById(applicant.Id);
        Contact applicantByPhone = ContactRepository.getByPhone(
            '65 6812 3462'
        );
        Contact missingById = ContactRepository.getById(null);
        Contact missingByPhone = ContactRepository.getByPhone(null);
        Test.stopTest();

        System.assertEquals(applicant.Id, applicantById.Id);
        System.assertEquals(accountRecord.Id, applicantById.AccountId);
        System.assertEquals('Repository Applicant', applicantById.Name);
        System.assertEquals(applicant.Id, applicantByPhone.Id);
        System.assertEquals(accountRecord.Id, applicantByPhone.AccountId);
        System.assertEquals(null, missingById);
        System.assertEquals(null, missingByPhone);
    }

    @IsTest
    static void mergeDuplicatePhoneContactsIgnoresRecordsWithoutPhone() {
        Contact applicant = new Contact(LastName = 'Applicant');

        Test.startTest();
        Set<Id> handledContactIds =
            ContactMatchingService.mergeDuplicatePhoneContacts(
                new List<Contact>{ applicant }
            );
        Test.stopTest();

        System.assertEquals(
            0,
            handledContactIds.size(),
            'Contacts without phone numbers should not be merged.'
        );
    }

    @IsTest
    static void insertingDuplicatePhoneMergesIntoOldestContact() {
        Contact existingApplicant = new Contact(
            FirstName = 'Existing',
            LastName = 'Applicant',
            Phone = '65 6812 3456',
            MailingPostalCode = '123456',
            Monthly_Income__c = 500,
            Support_Option__c = 'Option One'
        );
        insert existingApplicant;

        Contact duplicateApplicant = new Contact(
            FirstName = 'Updated',
            LastName = 'Applicant',
            Phone = '65 6812 3456',
            MailingPostalCode = '654321',
            Monthly_Income__c = 1000,
            Support_Option__c = 'Option Two'
        );

        Test.startTest();
        insert duplicateApplicant;
        Test.stopTest();

        List<Contact> applicants = [
            SELECT
                Id,
                FirstName,
                LastName,
                Phone,
                MailingPostalCode,
                Monthly_Income__c,
                Annual_Income__c,
                Support_Option__c
            FROM Contact
            WHERE Phone = '65 6812 3456'
        ];

        System.assertEquals(
            1,
            applicants.size(),
            'Duplicate phone inserts should keep a single Contact record.'
        );
        System.assertEquals(existingApplicant.Id, applicants[0].Id);
        System.assertEquals('Updated', applicants[0].FirstName);
        System.assertEquals('654321', applicants[0].MailingPostalCode);
        System.assertEquals(1000, applicants[0].Monthly_Income__c);
        System.assertEquals(12000, applicants[0].Annual_Income__c);
        System.assertEquals('Option Two', applicants[0].Support_Option__c);
    }

    @IsTest
    static void insertingDuplicatePhoneHandlesBlankGrantFields() {
        Contact existingApplicant = new Contact(
            LastName = 'Existing',
            Phone = '65 6812 3461'
        );
        insert existingApplicant;

        Contact duplicateApplicant = new Contact(
            LastName = 'Updated',
            Phone = '65 6812 3461'
        );

        Test.startTest();
        insert duplicateApplicant;
        Test.stopTest();

        Contact applicant = [
            SELECT Id, LastName, Annual_Income__c
            FROM Contact
            WHERE Phone = '65 6812 3461'
            LIMIT 1
        ];

        System.assertEquals(existingApplicant.Id, applicant.Id);
        System.assertEquals('Updated', applicant.LastName);
        System.assertEquals(null, applicant.Annual_Income__c);
    }

    @IsTest
    static void supportOptionRequiresMonthlyIncome() {
        Contact applicant = new Contact(
            LastName = 'Applicant',
            Phone = '65 6812 3457',
            Support_Option__c = 'Option One'
        );

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            insert applicant;
        } catch (DmlException exceptionRecord) {
            exceptionThrown = true;
            System.assert(
                exceptionRecord.getMessage().contains(
                    'Monthly Income is required'
                ),
                'Validation error should explain the missing monthly income.'
            );
        }
        Test.stopTest();

        System.assert(
            exceptionThrown,
            'Contact insert should fail when support option has no monthly income.'
        );
    }

    private static GrantDTO createGrantRequest(String phone) {
        GrantDTO request = new GrantDTO();
        request.firstName = 'Grant';
        request.lastName = 'Applicant';
        request.phone = phone;
        request.mailingPostalCode = '123456';
        request.monthlyIncome = 1000;
        request.supportOption = 'Option One';

        return request;
    }
}
