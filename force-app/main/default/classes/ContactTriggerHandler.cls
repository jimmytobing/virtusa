public with sharing class ContactTriggerHandler {

    private static Boolean mergingDuplicatePhones = false;

    public void beforeInsert(List<Contact> records) {
        validateGrantFields(records);
    }

    public void beforeUpdate(List<Contact> records) {
        validateGrantFields(records);
    }

    public void afterInsert(List<Contact> records) {
        mergeDuplicatePhoneContacts(records);
    }

    public void afterUpdate(
        List<Contact> records,
        Map<Id, Contact> oldMap
    ) {
    }

    private static void validateGrantFields(List<Contact> records) {
        for (Contact record : records) {
            if (String.isBlank(record.Support_Option__c)) {
                continue;
            }

            if (record.Monthly_Income__c == null) {
                record.addError(
                    'Monthly Income is required when Support Option is provided.'
                );
            }

        }
    }

    private static Set<Id> mergeDuplicatePhoneContacts(List<Contact> records) {
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
}
