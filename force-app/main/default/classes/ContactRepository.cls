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
                Name,
                Birthdate,
                Annual_Income__c,
                Employment_Status__c,
                Citizenship_Status__c,
                National_ID__c
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];

        return contacts.isEmpty() ? null : contacts[0];
    }
}