public with sharing class ContactRepository {

    /**
     * Retrieves a Contact by Id.
     */
    public static Contact getById(Id contactId) {

        if (contactId == null) {
            return null;
        }

        List<Contact> contacts = [
            SELECT
                Id,
                FirstName,
                LastName,
                Name,
                Phone,
                MailingPostalCode,
                Birthdate,
                Annual_Income__c,
                Monthly_Income__c,
                Support_Option__c,
                Employment_Status__c,
                Citizenship_Status__c,
                National_ID__c
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];

        return contacts.isEmpty() ? null : contacts[0];
    }

    public static Contact getByPhone(String phone) {
        if (String.isBlank(phone)) {
            return null;
        }

        List<Contact> contacts = [
            SELECT
                Id,
                FirstName,
                LastName,
                Phone,
                MailingPostalCode,
                Annual_Income__c,
                Monthly_Income__c,
                Support_Option__c
            FROM Contact
            WHERE Phone = :phone
            ORDER BY CreatedDate
            LIMIT 1
        ];

        return contacts.isEmpty() ? null : contacts[0];
    }
}
