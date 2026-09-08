@IsTest
private class ContactBulkFlowTest {
  @TestSetup
  static void setup() {
    insert new Account(Name = 'hdbsf');
    insert new List<Support_Option__c>{
      new Support_Option__c(
        Name = 'Option 1',
        Amount__c = 500,
        Duration__c = 3
      ),
      new Support_Option__c(
        Name = 'Option 2',
        Amount__c = 300,
        Duration__c = 6
      ),
      new Support_Option__c(
        Name = 'Option 3',
        Amount__c = 200,
        Duration__c = 12
      )
    };
  }

  private static ContactBulk__c staging(String phone, String option) {
    return new ContactBulk__c(
      FirstName__c = 'CSV',
      LastName__c = 'Applicant',
      Phone__c = phone,
      MailingPostalCode__c = '012345',
      MonthlyIncome__c = 1500,
      SupportOptionRaw__c = option,
      ImportBatch__c = 'test',
      Status__c = 'Ready'
    );
  }

  private static ContactBulk__c process(ContactBulk__c row) {
    // The processor is invoked directly to test real Flow behavior deterministically.
    // This does not assert delivery/timing of the platform asynchronous path.
    Flow.Interview interview = Flow.Interview.createInterview(
      'Auto_processContactBulk',
      new Map<String, Object>{ 'varT_ContactBulkId' => row.Id }
    );
    interview.start();
    return [
      SELECT Status__c, Contact__c, ErrorMessage__c, ProcessedAt__c
      FROM ContactBulk__c
      WHERE Id = :row.Id
    ];
  }

  @IsTest
  static void acceptsEveryCsvStyleAndOption() {
    List<String> labels = new List<String>();
    List<Integer> amounts = new List<Integer>{ 500, 300, 200 };
    List<Integer> months = new List<Integer>{ 3, 6, 12 };
    for (Integer i = 0; i < 3; i++) {
      String description =
        'SGD ' +
        amounts[i] +
        ' per month for ' +
        months[i] +
        ' months';
      labels.add('Option ' + (i + 1));
      labels.add('Option ' + (i + 1) + ': ' + description + '\t');
      labels.add(description + '\t');
      labels.add('  SGD ' + amounts[i] + ' for ' + months[i] + ' months\t');
    }
    List<ContactBulk__c> rows = new List<ContactBulk__c>();
    List<String> givenNames = new List<String>{
      'Andrew',
      'Bella',
      'Charlie',
      'Daisy',
      'Evelyn',
      'Felix',
      'Gabriella',
      'Hunter',
      'Ivy',
      'Jade',
      'Kevin',
      'Luna'
    };
    List<String> familyNames = new List<String>{
      'Lee',
      'Yew',
      'Loong',
      'Chung',
      'Tan',
      'Khan',
      'Chopra',
      'Megat',
      'Doe',
      'Smith',
      'Nguyen',
      'Patel'
    };
    for (Integer i = 0; i < labels.size(); i++) {
      ContactBulk__c row = staging('65 9000 ' + (1000 + i), labels[i]);
      row.FirstName__c = givenNames[i];
      row.LastName__c = familyNames[i];
      rows.add(row);
    }
    insert rows;
    Test.startTest();
    Set<Id> contactIds = new Set<Id>();
    for (Integer i = 0; i < rows.size(); i++) {
      ContactBulk__c result = process(rows[i]);
      Assert.areEqual(
        'Success',
        result.Status__c,
        'Flow error: ' + result.ErrorMessage__c
      );
      Assert.isNotNull(result.Contact__c);
      Assert.isNotNull(result.ProcessedAt__c);
      Assert.isTrue(String.isBlank(result.ErrorMessage__c));
      contactIds.add(result.Contact__c);
    }
    Test.stopTest();
    Assert.areEqual(12, contactIds.size());
    for (Contact c : [
      SELECT
        Phone,
        MailingPostalCode,
        Monthly_Income__c,
        Support_Option__r.Amount__c,
        Support_Option__r.Duration__c
      FROM Contact
      WHERE Id IN :contactIds
    ]) {
      Integer index = Integer.valueOf(c.Phone.right(4)) - 1000;
      Integer groupIndex = index / 4;
      Assert.areEqual(amounts[groupIndex], c.Support_Option__r.Amount__c);
      Assert.areEqual(months[groupIndex], c.Support_Option__r.Duration__c);
      Assert.areEqual('012345', c.MailingPostalCode);
      Assert.areEqual(1500, c.Monthly_Income__c);
    }
  }

  @IsTest
  static void updatesNewestContactWithinDefaultAccountAndSkipsReplay() {
    Id accountId = [SELECT Id FROM Account WHERE Name = 'hdbsf' LIMIT 1].Id;
    Id optionId = [
      SELECT Id
      FROM Support_Option__c
      WHERE Amount__c = 500
      LIMIT 1
    ]
    .Id;
    Account otherAccount = new Account(Name = 'Other');
    insert otherAccount;
    List<Contact> contacts = new List<Contact>{
      new Contact(
        LastName = 'Old',
        Phone = '65 9000 0000',
        AccountId = accountId,
        Monthly_Income__c = 500,
        Support_Option__c = optionId
      ),
      new Contact(
        LastName = 'New',
        Phone = '65 9000 0000',
        AccountId = accountId,
        Monthly_Income__c = 500,
        Support_Option__c = optionId
      ),
      new Contact(
        LastName = 'Other',
        Phone = '65 9000 0000',
        AccountId = otherAccount.Id,
        Monthly_Income__c = 500,
        Support_Option__c = optionId
      )
    };
    insert contacts;
    Test.setCreatedDate(contacts[0].Id, System.now().addDays(-3));
    Test.setCreatedDate(contacts[1].Id, System.now().addDays(-2));
    ContactBulk__c row = staging('65 9000 0000', 'Option 2');
    insert row;
    Test.startTest();
    ContactBulk__c result = process(row);
    Assert.areEqual(
      'Success',
      result.Status__c,
      'Flow error: ' + result.ErrorMessage__c
    );
    Assert.areEqual(contacts[1].Id, result.Contact__c);
    Integer beforeDml = Limits.getDmlStatements();
    process(row);
    Assert.areEqual(
      beforeDml,
      Limits.getDmlStatements(),
      'Successful rows must not be processed again.'
    );
    Test.stopTest();
    Map<Id, Contact> saved = new Map<Id, Contact>(
      [SELECT LastName, Monthly_Income__c FROM Contact]
    );
    Assert.areEqual(3, saved.size());
    Assert.areEqual('Old', saved.get(contacts[0].Id).LastName);
    Assert.areEqual('Other', saved.get(contacts[2].Id).LastName);
    Assert.areEqual('Applicant', saved.get(contacts[1].Id).LastName);
    Assert.areEqual(1500, saved.get(contacts[1].Id).Monthly_Income__c);
  }

  @IsTest
  static void rejectsInvalidInputsWithoutCreatingContacts() {
    List<ContactBulk__c> rows = new List<ContactBulk__c>{
      staging('65 9000 0001', 'Option 9'),
      staging(null, 'Option 1'),
      staging('65 9000 0002', 'Option 1'),
      staging('65 9000 0003', 'Option 1'),
      staging('65 9000 0004', 'Option 1'),
      staging('65 9000 0005', 'Option 1: SGD 200 for 3 months')
    };
    rows[2].LastName__c = null;
    rows[3].MonthlyIncome__c = null;
    rows[4].MonthlyIncome__c = -1;
    insert rows;
    Test.startTest();
    for (ContactBulk__c row : rows) {
      ContactBulk__c result = process(row);
      Assert.areEqual('Failed', result.Status__c);
      Assert.isNotNull(result.ErrorMessage__c);
      Assert.isNull(result.Contact__c);
    }
    Test.stopTest();
    Assert.areEqual(0, [SELECT COUNT() FROM Contact]);
  }

  @IsTest
  static void rejectsAmbiguousOption() {
    insert new Support_Option__c(
      Name = 'Duplicate',
      Amount__c = 500,
      Duration__c = 3
    );
    ContactBulk__c row = staging('65 9000 0001', 'Option 1');
    insert row;
    Test.startTest();
    ContactBulk__c result = process(row);
    Test.stopTest();
    Assert.areEqual('Failed', result.Status__c);
    Assert.isTrue(result.ErrorMessage__c.contains('exactly one'));
    Assert.areEqual(0, [SELECT COUNT() FROM Contact]);
  }

  @IsTest
  static void rejectsMissingOption() {
    delete [SELECT Id FROM Support_Option__c WHERE Amount__c = 500];
    ContactBulk__c row = staging('65 9000 0001', 'Option 1');
    insert row;
    Test.startTest();
    ContactBulk__c result = process(row);
    Test.stopTest();
    Assert.areEqual('Failed', result.Status__c);
    Assert.isTrue(result.ErrorMessage__c.contains('exactly one'));
    Assert.areEqual(0, [SELECT COUNT() FROM Contact]);
  }

  @IsTest
  static void rejectsMissingAccount() {
    delete [SELECT Id FROM Account WHERE Name = 'hdbsf'];
    ContactBulk__c row = staging('65 9000 0001', 'Option 1');
    insert row;
    Test.startTest();
    ContactBulk__c result = process(row);
    Test.stopTest();
    Assert.areEqual('Failed', result.Status__c);
    Assert.isTrue(result.ErrorMessage__c.contains('hdbsf'));
    Assert.areEqual(0, [SELECT COUNT() FROM Contact]);
  }

  @IsTest
  static void pendingRowDoesNothing() {
    ContactBulk__c row = staging('65 9000 0001', 'Option 1');
    row.Status__c = 'Pending';
    insert row;
    Test.startTest();
    ContactBulk__c result = process(row);
    Test.stopTest();
    Assert.areEqual('Pending', result.Status__c);
    Assert.isNull(result.ProcessedAt__c);
    Assert.areEqual(0, [SELECT COUNT() FROM Contact]);
  }

  @IsTest
  static void failedRowCanBeCorrectedAndRetried() {
    ContactBulk__c row = staging('65 9000 0001', 'Wrong');
    insert row;
    Test.startTest();
    Assert.areEqual('Failed', process(row).Status__c);
    row.SupportOptionRaw__c = 'Option 1';
    row.Status__c = 'Ready';
    update row;
    ContactBulk__c result = process(row);
    Test.stopTest();
    Assert.areEqual(
      'Success',
      result.Status__c,
      'Flow error: ' + result.ErrorMessage__c
    );
    Assert.isTrue(String.isBlank(result.ErrorMessage__c));
    Assert.areEqual(1, [SELECT COUNT() FROM Contact]);
  }
  @IsTest
  static void saveFaultCanBeReturnedWithoutChangingLegacyCallers() {
    Id optionId = [
      SELECT Id
      FROM Support_Option__c
      WHERE Amount__c = 500
      LIMIT 1
    ]
    .Id;
    Contact invalid = new Contact(
      Phone = '65 9000 0099',
      Monthly_Income__c = 1000,
      Support_Option__c = optionId
    );
    Test.startTest();
    Flow.Interview captured = Flow.Interview.createInterview(
      'Auto_submitApplication',
      new Map<String, Object>{
        'varR_Contact' => invalid,
        'varB_ReturnErrors' => true
      }
    );
    captured.start();
    Assert.isTrue(
      String.isNotBlank((String) captured.getVariableValue('varT_Error'))
    );
    Boolean threw = false;
    try {
      Flow.Interview legacy = Flow.Interview.createInterview(
        'Auto_submitApplication',
        new Map<String, Object>{ 'varR_Contact' => invalid }
      );
      legacy.start();
    } catch (Exception expected) {
      threw = true;
    }
    Assert.isTrue(
      threw,
      'Legacy callers must still receive an exception for a failed save.'
    );
    Test.stopTest();
    Assert.areEqual(0, [SELECT COUNT() FROM Contact]);
  }
}
