public without sharing class ContactRepository {
  private static final String ACCOUNT_ID_FIELD = 'AccountId';

  /**
   * Retrieves a Contact by Id.
   */
  public static Contact getById(Id contactId) {
    if (contactId == null) {
      return null;
    }

    String contactIdString = String.escapeSingleQuotes(
      String.valueOf(contactId)
    );

    List<Contact> contacts = Database.query(
      'SELECT ' +
        String.join(getByIdFields(), ', ') +
        ' FROM Contact' +
        ' WHERE Id = \'' +
        contactIdString +
        '\'' +
        ' LIMIT 1'
    );

    return contacts.isEmpty() ? null : contacts[0];
  }

  public static Contact getByPhone(String phone) {
    if (String.isBlank(phone)) {
      return null;
    }

    String escapedPhone = String.escapeSingleQuotes(phone);

    List<Contact> contacts = Database.query(
      'SELECT ' +
        String.join(getByPhoneFields(), ', ') +
        ' FROM Contact' +
        ' WHERE Phone = \'' +
        escapedPhone +
        '\'' +
        ' ORDER BY CreatedDate, Id' +
        ' LIMIT 1'
    );

    return contacts.isEmpty() ? null : contacts[0];
  }

  private static List<String> getByIdFields() {
    List<String> fields = new List<String>{
      'Id',
      'FirstName',
      'LastName',
      'Name',
      'Phone',
      'Email',
      'MailingPostalCode',
      'Birthdate',
      'Annual_Income__c',
      'Monthly_Income__c',
      'Support_Option__c',
      'Grant_Application__c',
      'Employment_Status__c',
      'Citizenship_Status__c',
      'National_ID__c'
    };

    addAccountIdFieldForSupportedUsers(fields);

    return fields;
  }

  private static List<String> getByPhoneFields() {
    List<String> fields = new List<String>{
      'Id',
      'FirstName',
      'LastName',
      'Phone',
      'Email',
      'MailingPostalCode',
      'Annual_Income__c',
      'Monthly_Income__c',
      'Support_Option__c',
      'Grant_Application__c'
    };

    addAccountIdFieldForSupportedUsers(fields);

    return fields;
  }

  private static void addAccountIdFieldForSupportedUsers(List<String> fields) {
    if (
      UserInfo.getUserType() == 'Guest' ||
      !Schema.SObjectType.Contact.fields.getMap().containsKey(ACCOUNT_ID_FIELD)
    ) {
      return;
    }

    fields.add(ACCOUNT_ID_FIELD);
  }
}
