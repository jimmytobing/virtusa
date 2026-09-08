@IsTest
private class GrantApplicationControllerTest {
  @TestSetup
  static void setup() {
    insert new Account(Name = 'hdbsf');
  }

  private static Contact request() {
    return new Contact(
      FirstName = 'Test',
      LastName = 'Applicant',
      Phone = '65 9000 1234',
      MailingPostalCode = '012345',
      Email = 'applicant@example.com',
      Monthly_Income__c = 1500
    );
  }

  @IsTest
  static void submitsContactAndReturnsPersistedId() {
    Support_Option__c option = new Support_Option__c(
      Name = 'Option 1',
      Amount__c = 500,
      Duration__c = 3
    );
    insert option;
    Contact input = request();
    input.Support_Option__c = option.Id;
    Test.startTest();
    Id result = GrantApplicationController.submitApplication(input);
    Test.stopTest();
    Assert.isNotNull(result, 'Controller must return the saved Contact ID.');
    Contact saved = [
      SELECT
        FirstName,
        LastName,
        Phone,
        Email,
        MailingPostalCode,
        Monthly_Income__c,
        Support_Option__c,
        Account.Name
      FROM Contact
      WHERE Id = :result
    ];
    Assert.areEqual('Test', saved.FirstName);
    Assert.areEqual('Applicant', saved.LastName);
    Assert.areEqual(input.Phone, saved.Phone);
    Assert.areEqual(input.Email, saved.Email);
    Assert.areEqual('012345', saved.MailingPostalCode);
    Assert.areEqual(1500, saved.Monthly_Income__c);
    Assert.areEqual(option.Id, saved.Support_Option__c);
    Assert.areEqual('hdbsf', saved.Account.Name);
    Assert.areEqual(1, [SELECT COUNT() FROM Contact]);
  }

  @IsTest
  static void updatesNewestMatchingContactOnly() {
    Support_Option__c option = new Support_Option__c(
      Name = 'Option 1',
      Amount__c = 500,
      Duration__c = 3
    );
    insert option;
    Id accountId = [SELECT Id FROM Account WHERE Name = 'hdbsf' LIMIT 1].Id;
    Account other = new Account(Name = 'Other');
    insert other;
    List<Contact> existing = new List<Contact>();
    for (Integer i = 0; i < 3; i++) {
      Contact c = request();
      c.Support_Option__c = option.Id;
      c.LastName = 'Original';
      c.AccountId = i == 2 ? other.Id : accountId;
      existing.add(c);
    }
    insert existing;
    Test.setCreatedDate(existing[0].Id, System.now().addDays(-3));
    Test.setCreatedDate(existing[1].Id, System.now().addDays(-2));
    Contact input = request();
    input.Monthly_Income__c = 1200;
    input.Support_Option__c = option.Id;
    Test.startTest();
    Id result = GrantApplicationController.submitApplication(input);
    Test.stopTest();
    Assert.areEqual(existing[1].Id, result);
    Map<Id, Contact> saved = new Map<Id, Contact>(
      [SELECT LastName, Monthly_Income__c, AccountId FROM Contact]
    );
    Assert.areEqual(
      3,
      saved.size(),
      'Matching submission must not create a duplicate.'
    );
    Assert.areEqual('Applicant', saved.get(result).LastName);
    Assert.areEqual(1200, saved.get(result).Monthly_Income__c);
    Assert.areEqual(accountId, saved.get(result).AccountId);
    for (Integer i : new List<Integer>{ 0, 2 }) {
      Assert.areEqual('Original', saved.get(existing[i].Id).LastName);
      Assert.areEqual(1500, saved.get(existing[i].Id).Monthly_Income__c);
    }
  }

  @IsTest
  static void propagatesSaveFailureWithoutCreatingContact() {
    Support_Option__c option = new Support_Option__c(
      Name = 'Option 1',
      Amount__c = 500,
      Duration__c = 3
    );
    insert option;
    Contact input = request();
    input.Support_Option__c = option.Id;
    input.LastName = null;
    Boolean failed = false;
    Test.startTest();
    try {
      GrantApplicationController.submitApplication(input);
    } catch (Exception expected) {
      failed = true;
      Assert.isTrue(String.isNotBlank(expected.getMessage()));
    }
    Test.stopTest();
    Assert.isTrue(failed, 'Failed Flow saves must propagate an exception.');
    Assert.areEqual(0, [SELECT COUNT() FROM Contact]);
  }

  @IsTest
  static void returnsOptionsInNameOrderWithValues() {
    List<Support_Option__c> options = new List<Support_Option__c>{
      new Support_Option__c(
        Name = 'Option 2',
        Amount__c = 300,
        Duration__c = 6
      ),
      new Support_Option__c(Name = 'Option 1', Amount__c = 500, Duration__c = 3)
    };
    insert options;
    Test.startTest();
    List<Support_Option__c> result = GrantApplicationController.getActiveSupportOptions();
    Test.stopTest();
    Assert.areEqual(2, result.size());
    Assert.areEqual(options[1].Id, result[0].Id);
    Assert.areEqual('Option 1', result[0].Name);
    Assert.areEqual(500, result[0].Amount__c);
    Assert.areEqual(3, result[0].Duration__c);
    Assert.areEqual(options[0].Id, result[1].Id);
    Assert.areEqual(300, result[1].Amount__c);
    Assert.areEqual(6, result[1].Duration__c);
  }

  @IsTest
  static void returnsEmptyListWhenNoOptionsExist() {
    Test.startTest();
    List<Support_Option__c> result = GrantApplicationController.getActiveSupportOptions();
    Test.stopTest();
    Assert.isNotNull(result);
    Assert.areEqual(0, result.size());
  }
}
