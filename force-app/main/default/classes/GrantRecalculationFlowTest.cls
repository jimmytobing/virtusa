@IsTest
private class GrantRecalculationFlowTest {
  private static Support_Option__c option(Decimal amount, Integer months) {
    Support_Option__c result = new Support_Option__c(
      Name = 'Option ' + amount + ' x ' + months,
      Amount__c = amount,
      Duration__c = months
    );
    insert result;
    return result;
  }

  private static Contact applicant(Support_Option__c support) {
    Contact result = new Contact(
      LastName = 'Flow Test',
      Monthly_Income__c = 1000,
      Support_Option__c = support.Id
    );
    insert result;
    return result;
  }

  private static Grant_Disbursement__c payment(
    Id applicantId,
    Decimal amount,
    Boolean paid
  ) {
    Grant_Disbursement__c result = new Grant_Disbursement__c(
      Grant_Applicant__c = applicantId,
      Amount_to_be_disbursed__c = amount,
      Grant_is_disbursed__c = paid,
      Disbursed_Date__c = Date.today().toStartOfMonth(),
      Sequence_Number__c = 1,
      Name = 'Original option'
    );
    insert result;
    return result;
  }

  private static String invokeFlow(Contact applicant) {
    Flow.Interview interview = Flow.Interview.createInterview(
      'Auto_recalculateForApplications',
      new Map<String, Object>{ 'varR_Contact' => applicant }
    );
    interview.start();
    return (String) interview.getVariableValue('varT_Error');
  }

  private static void runFlow(Contact applicant) {
    Assert.isTrue(
      String.isBlank(invokeFlow(applicant)),
      'Successful Flow must return a blank varT_Error.'
    );
  }

  private static void expectError(Contact applicant, String message) {
    Integer beforeDml = Limits.getDmlStatements();
    String error = invokeFlow(applicant);
    Assert.isTrue(
      String.isNotBlank(error),
      'Expected varT_Error without an exception.'
    );
    Assert.isTrue(error.contains(message), error);
    Assert.areEqual(
      beforeDml,
      Limits.getDmlStatements(),
      'Business errors must not perform DML.'
    );
  }

  @IsTest
  static void emptyInputReturnsErrorWithoutChanges() {
    Test.startTest();
    expectError(null, 'Contact must have an Id and Support Option');
    expectError(new Contact(), 'Contact must have an Id and Support Option');
    Test.stopTest();
  }

  @IsTest
  static void replacesOnlyUnpaidForInputContact() {
    Support_Option__c support = option(300, 4);
    Contact a = applicant(support);
    Contact outside = applicant(support);
    Grant_Disbursement__c paid = payment(a.Id, 400, true);
    Grant_Disbursement__c paidSecond = payment(a.Id, 200, true);
    Grant_Disbursement__c unpaid = payment(a.Id, 99, false);
    Grant_Disbursement__c untouched = payment(outside.Id, 88, false);
    Test.startTest();
    runFlow(a);
    Test.stopTest();
    Map<Id, Grant_Disbursement__c> rows = new Map<Id, Grant_Disbursement__c>(
      [
        SELECT
          Id,
          Grant_Applicant__c,
          Amount_to_be_disbursed__c,
          Grant_is_disbursed__c,
          Disbursed_Date__c,
          Sequence_Number__c,
          Name
        FROM Grant_Disbursement__c
      ]
    );
    Assert.areEqual(5, rows.size());
    Assert.isFalse(rows.containsKey(unpaid.Id));
    Assert.areEqual(400, rows.get(paid.Id).Amount_to_be_disbursed__c);
    Assert.areEqual(200, rows.get(paidSecond.Id).Amount_to_be_disbursed__c);
    Assert.areEqual('Original option', rows.get(paid.Id).Name);
    Assert.areEqual(
      paid.Disbursed_Date__c,
      rows.get(paid.Id).Disbursed_Date__c
    );
    Assert.areEqual(88, rows.get(untouched.Id).Amount_to_be_disbursed__c);
    Integer generated = 0;
    for (Grant_Disbursement__c row : rows.values()) {
      if (
        row.Id == paid.Id ||
        row.Id == paidSecond.Id ||
        row.Id == untouched.Id
      )
        continue;
      generated++;
      Assert.areEqual(a.Id, row.Grant_Applicant__c);
      Assert.isFalse(row.Grant_is_disbursed__c);
      Assert.areEqual(300, row.Amount_to_be_disbursed__c);
      Assert.areEqual(support.Name, row.Name);
      Assert.areEqual(
        Date.today()
          .toStartOfMonth()
          .addMonths(row.Sequence_Number__c.intValue() - 2),
        row.Disbursed_Date__c
      );
    }
    Assert.areEqual(2, generated);
  }

  @IsTest
  static void fullyPaidDeletesUnpaidWithoutReplacement() {
    Contact a = applicant(option(200, 2));
    Grant_Disbursement__c paid = payment(a.Id, 400, true);
    payment(a.Id, 20, false);
    Test.startTest();
    runFlow(a);
    Test.stopTest();
    List<Grant_Disbursement__c> remaining = [
      SELECT Id
      FROM Grant_Disbursement__c
    ];
    Assert.areEqual(1, remaining.size());
    Assert.areEqual(paid.Id, remaining[0].Id);
  }

  @IsTest
  static void lowerTotalReturnsErrorBeforeChanges() {
    Contact valid = applicant(option(100, 2));
    Contact invalid = applicant(option(100, 1));
    payment(valid.Id, 90, false);
    payment(invalid.Id, 150, true);
    payment(invalid.Id, 90, false);
    Set<Id> beforeIds = new Map<Id, Grant_Disbursement__c>(
        [SELECT Id FROM Grant_Disbursement__c]
      )
      .keySet();
    Test.startTest();
    expectError(invalid, 'greater than the new option total');
    Test.stopTest();
    Assert.areEqual(
      beforeIds,
      new Map<Id, Grant_Disbursement__c>([SELECT Id FROM Grant_Disbursement__c])
        .keySet()
    );
  }

  @IsTest
  static void noRemainingMonthsUsesConfiguredMessage() {
    Contact a = applicant(option(500, 1));
    payment(a.Id, 100, true);
    insert new Grant_Message__c(
      Name = 'DISBURSEMENT_OPTION_NO_MONTHS',
      Message_Text__c = 'No months configured test'
    );
    Test.startTest();
    expectError(a, 'No months configured test');
    Test.stopTest();
    Assert.areEqual(1, [SELECT COUNT() FROM Grant_Disbursement__c]);
  }

  @IsTest
  static void createsFullScheduleWithoutExistingDisbursements() {
    Contact a = applicant(option(200, 3));
    Test.startTest();
    runFlow(a);
    Test.stopTest();
    List<Grant_Disbursement__c> rows = [
      SELECT Amount_to_be_disbursed__c, Disbursed_Date__c, Sequence_Number__c
      FROM Grant_Disbursement__c
      WHERE Grant_Applicant__c = :a.Id
      ORDER BY Sequence_Number__c
    ];
    Assert.areEqual(3, rows.size());
    for (Integer i = 0; i < rows.size(); i++) {
      Assert.areEqual(200, rows[i].Amount_to_be_disbursed__c);
      Assert.areEqual(i + 1, rows[i].Sequence_Number__c);
      Assert.areEqual(
        Date.today().toStartOfMonth().addMonths(i + 1),
        rows[i].Disbursed_Date__c
      );
    }
  }

  @IsTest
  static void missingOptionIsRejected() {
    Contact a = applicant(option(100, 2));
    a.Support_Option__c = null;
    Test.startTest();
    expectError(a, 'must have an Id and Support Option');
    Test.stopTest();
  }

  @IsTest
  static void currencyRoundsToZeroDecimalPlaces() {
    Contact a = applicant(option(100, 4));
    payment(a.Id, 300, true);
    Test.startTest();
    runFlow(a);
    Test.stopTest();
    List<Grant_Disbursement__c> unpaid = [
      SELECT Amount_to_be_disbursed__c
      FROM Grant_Disbursement__c
      WHERE Grant_is_disbursed__c = FALSE
    ];
    Assert.areEqual(3, unpaid.size());
    for (Grant_Disbursement__c row : unpaid) {
      Assert.areEqual(33, row.Amount_to_be_disbursed__c);
    }
  }

  @IsTest
  static void unavailableOptionReturnsError() {
    Contact a = applicant(option(100, 2));
    Support_Option__c unavailable = option(200, 3);
    Id unavailableId = unavailable.Id;
    delete unavailable;
    a.Support_Option__c = unavailableId;
    Test.startTest();
    expectError(a, 'Support Option is unavailable');
    Test.stopTest();
  }
  @IsTest
  static void readsFreshRollupsAndKeepsProposedOption() {
    Contact a = applicant(option(100, 4));
    Contact staleInput = [
      SELECT Id, Support_Option__c, TotalReceived__c
      FROM Contact
      WHERE Id = :a.Id
    ];
    payment(a.Id, 100, true);
    Grant_Disbursement__c changed = payment(a.Id, 50, false);
    update new Grant_Disbursement__c(
      Id = changed.Id,
      Grant_is_disbursed__c = true
    );
    Grant_Disbursement__c removed = payment(a.Id, 25, true);
    delete removed;
    Contact current = [
      SELECT TotalReceived__c
      FROM Contact
      WHERE Id = :a.Id
    ];
    Assert.areEqual(150, current.TotalReceived__c);
    Assert.areEqual(0, staleInput.TotalReceived__c);
    staleInput.Support_Option__c = option(200, 4).Id;
    Test.startTest();
    runFlow(staleInput);
    Test.stopTest();
    List<Grant_Disbursement__c> rows = [
      SELECT Amount_to_be_disbursed__c, Sequence_Number__c
      FROM Grant_Disbursement__c
      WHERE Grant_Applicant__c = :a.Id AND Grant_is_disbursed__c = FALSE
      ORDER BY Sequence_Number__c
    ];
    Assert.areEqual(2, rows.size());
    Assert.areEqual(325, rows[0].Amount_to_be_disbursed__c);
    Assert.areEqual(325, rows[1].Amount_to_be_disbursed__c);
    Assert.areEqual(3, rows[0].Sequence_Number__c);
    Assert.areEqual(4, rows[1].Sequence_Number__c);
  }

  @IsTest
  static void zeroAmountPaidRecordStillConsumesMonth() {
    Contact a = applicant(option(100, 3));
    payment(a.Id, 0, true);
    Test.startTest();
    runFlow(a);
    Test.stopTest();
    List<Grant_Disbursement__c> rows = [
      SELECT Amount_to_be_disbursed__c, Sequence_Number__c
      FROM Grant_Disbursement__c
      WHERE Grant_Applicant__c = :a.Id AND Grant_is_disbursed__c = FALSE
      ORDER BY Sequence_Number__c
    ];
    Assert.areEqual(2, rows.size());
    Assert.areEqual(150, rows[0].Amount_to_be_disbursed__c);
    Assert.areEqual(150, rows[1].Amount_to_be_disbursed__c);
    Assert.areEqual(2, rows[0].Sequence_Number__c);
    Assert.areEqual(3, rows[1].Sequence_Number__c);
  }
}
