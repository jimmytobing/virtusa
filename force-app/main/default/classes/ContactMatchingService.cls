public without sharing class ContactMatchingService {

    private static final String HOLDING_ACCOUNT_NAME =
        'Grant Applicant Holding Account';

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
        applicant.AccountId = resolveApplicantAccountId(applicant);

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

        ensureContactReferenceAccess(applicant);

        return applicant;
    }

    private static void ensureContactReferenceAccess(Contact applicant) {
        if (
            applicant == null ||
            applicant.AccountId == null ||
            UserInfo.getUserType() == 'Standard' ||
            UserInfo.getUserType() == 'Guest'
        ) {
            return;
        }

        Id userId = UserInfo.getUserId();

        List<AccountShare> existingShares = [
            SELECT Id
            FROM AccountShare
            WHERE AccountId = :applicant.AccountId
            AND UserOrGroupId = :userId
            LIMIT 1
        ];

        if (!existingShares.isEmpty()) {
            return;
        }

        insert new AccountShare(
            AccountId = applicant.AccountId,
            UserOrGroupId = userId,
            AccountAccessLevel = 'Read',
            OpportunityAccessLevel = 'None',
            CaseAccessLevel = 'None',
            RowCause = Schema.AccountShare.RowCause.Manual
        );
    }

    private static Contact findByPhone(String phone) {
        if (String.isBlank(phone)) {
            return null;
        }

        List<Contact> contacts = [
            SELECT Id, AccountId
            FROM Contact
            WHERE Phone = :phone
            ORDER BY CreatedDate, Id
            LIMIT 1
        ];

        return contacts.isEmpty()
            ? null
            : contacts[0];
    }

    private static Id resolveApplicantAccountId(Contact applicant) {
        if (applicant != null && applicant.AccountId != null) {
            return applicant.AccountId;
        }

        return getHoldingAccountId();
    }

    private static Id getHoldingAccountId() {
        List<Account> holdingAccounts = [
            SELECT Id
            FROM Account
            WHERE Name = :HOLDING_ACCOUNT_NAME
            ORDER BY CreatedDate, Id
            LIMIT 1
        ];

        if (!holdingAccounts.isEmpty()) {
            return holdingAccounts[0].Id;
        }

        Account holdingAccount = new Account(
            Name = HOLDING_ACCOUNT_NAME,
            OwnerId = getDefaultAccountOwnerId()
        );

        insert holdingAccount;

        return holdingAccount.Id;
    }

    private static Id getDefaultAccountOwnerId() {
        if (UserInfo.getUserType() == 'Standard') {
            return UserInfo.getUserId();
        }

        List<User> users = [
            SELECT Contact.Account.OwnerId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        if (
            !users.isEmpty() &&
            users[0].Contact != null &&
            users[0].Contact.Account != null &&
            users[0].Contact.Account.OwnerId != null
        ) {
            return users[0].Contact.Account.OwnerId;
        }

        List<User> internalUsers = [
            SELECT Id
            FROM User
            WHERE IsActive = TRUE
            AND UserType = 'Standard'
            ORDER BY CreatedDate, Id
            LIMIT 1
        ];

        if (!internalUsers.isEmpty()) {
            return internalUsers[0].Id;
        }

        return UserInfo.getUserId();
    }
}
