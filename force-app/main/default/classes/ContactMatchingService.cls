public without sharing class ContactMatchingService {

    private static final String HOLDING_ACCOUNT_NAME =
        'Grant Applicant Holding Account';
    private static Boolean mergingDuplicatePhones = false;

    public static Contact upsertApplicantByPhone(GrantDTO request) {
        if (request == null) {
            throw new GrantException('Request cannot be null.');
        }

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

        if (shouldManageContactAccount()) {
            applicant.AccountId = resolveApplicantAccountId(applicant);
        }

        if (isNewApplicant) {
            insert applicant;
        } else {
            update applicant;
        }

        ensureContactReferenceAccess(applicant);

        return applicant;
    }

    public static Set<Id> mergeDuplicatePhoneContacts(List<Contact> records) {
        Set<Id> contactsHandledByMerge = new Set<Id>();

        if (mergingDuplicatePhones) {
            return contactsHandledByMerge;
        }

        Set<String> phones = new Set<String>();
        Set<Id> insertedContactIds = new Set<Id>();

        for (Contact record : records) {
            insertedContactIds.add(record.Id);

            if (!String.isBlank(record.Phone)) {
                phones.add(record.Phone);
            }
        }

        if (phones.isEmpty()) {
            return contactsHandledByMerge;
        }

        Map<String, Contact> keeperByPhone = new Map<String, Contact>();

        for (Contact contactRecord : [
            SELECT
                Id,
                FirstName,
                LastName,
                Phone,
                MailingPostalCode,
                Monthly_Income__c,
                Annual_Income__c,
                Support_Option__c,
                CreatedDate
            FROM Contact
            WHERE Phone IN :phones
            ORDER BY CreatedDate, Id
        ]) {
            if (!keeperByPhone.containsKey(contactRecord.Phone)) {
                keeperByPhone.put(contactRecord.Phone, contactRecord);
            }
        }

        Map<Id, Contact> contactsToUpdateById = new Map<Id, Contact>();
        List<Contact> contactsToDelete = new List<Contact>();

        for (Contact insertedContact : records) {
            if (String.isBlank(insertedContact.Phone)) {
                continue;
            }

            Contact keeper = keeperByPhone.get(insertedContact.Phone);

            if (keeper == null || keeper.Id == insertedContact.Id) {
                continue;
            }

            contactsToUpdateById.put(
                keeper.Id,
                new Contact(
                    Id = keeper.Id,
                    FirstName = insertedContact.FirstName,
                    LastName = insertedContact.LastName,
                    Phone = insertedContact.Phone,
                    MailingPostalCode = insertedContact.MailingPostalCode,
                    Monthly_Income__c = insertedContact.Monthly_Income__c,
                    Annual_Income__c = insertedContact.Monthly_Income__c == null
                        ? null
                        : insertedContact.Monthly_Income__c * 12,
                    Support_Option__c = insertedContact.Support_Option__c
                )
            );

            contactsToDelete.add(new Contact(Id = insertedContact.Id));
            contactsHandledByMerge.add(insertedContact.Id);

            if (insertedContactIds.contains(keeper.Id)) {
                contactsHandledByMerge.add(keeper.Id);
            }
        }

        if (contactsToUpdateById.isEmpty() && contactsToDelete.isEmpty()) {
            return contactsHandledByMerge;
        }

        mergingDuplicatePhones = true;

        try {
            if (!contactsToUpdateById.isEmpty()) {
                update contactsToUpdateById.values();
            }

            if (!contactsToDelete.isEmpty()) {
                delete contactsToDelete;
            }
        } finally {
            mergingDuplicatePhones = false;
        }

        return contactsHandledByMerge;
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

    private static Id resolveApplicantAccountId(Contact applicant) {
        if (applicant != null && applicant.AccountId != null) {
            return applicant.AccountId;
        }

        return getHoldingAccountId();
    }

    private static Boolean shouldManageContactAccount() {
        return UserInfo.getUserType() != 'Guest' &&
            Schema.SObjectType.Contact.fields.getMap().containsKey(
                'AccountId'
            );
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
