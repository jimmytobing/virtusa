@IsTest
private class GrantDisbursementServiceTest {
  @IsTest
  static void recalculateFromFlowUsesApplicationGrantType() {
    User adminUser = createSystemAdminUser('validswitch');

    System.runAs(adminUser) {
      recalculateFromFlowUsesApplicationGrantTypeAsAdmin();
    }
  }

  private static void recalculateFromFlowUsesApplicationGrantTypeAsAdmin() {
    Contact applicant = createApplicant('Option_Two');
    Grant_Application__c application = createApplication(
      applicant.Id,
      'Option One',
      1500
    );

    insert new List<Grant_Disbursement__c>{
      createDisbursement(
        application.Id,
        500,
        Date.today().addMonths(-2),
        true,
        1
      ),
      createDisbursement(
        application.Id,
        500,
        Date.today().addMonths(-1),
        true,
        2
      ),
      createDisbursement(
        application.Id,
        500,
        Date.today().addDays(-1),
        false,
        3
      ),
      createDisbursement(
        application.Id,
        500,
        Date.today().addMonths(1),
        false,
        4
      ),
      createDisbursement(
        application.Id,
        500,
        Date.today().addMonths(2),
        true,
        5
      )
    };

    Test.startTest();
    GrantDisbursementService.recalculateDisbursementsFromFlow(
      new List<GrantDisbursementService.FlowRequest>{
        createFlowRequest(application.Id)
      }
    );
    Test.stopTest();

    Grant_Application__c updatedApplication = [
      SELECT Grant_Type__c, Requested_Amount__c
      FROM Grant_Application__c
      WHERE Id = :application.Id
    ];

    System.assertEquals(
      'Option One',
      updatedApplication.Grant_Type__c,
      'Application grant type should drive recalculation instead of the applicant support option.'
    );
    System.assertEquals(
      1500,
      updatedApplication.Requested_Amount__c,
      'Requested amount should stay aligned to the application grant type total.'
    );

    List<Grant_Disbursement__c> futureDisbursements = [
      SELECT
        Amount_to_be_disbursed__c,
        Grant_is_disbursed__c,
        Support_Option__c,
        Sequence_Number__c
      FROM Grant_Disbursement__c
      WHERE
        Grant_Applicantion__c = :application.Id
        AND Disbursed_Date__c > :Date.today()
        AND Grant_is_disbursed__c = FALSE
      ORDER BY Sequence_Number__c
    ];

    System.assertEquals(
      0,
      futureDisbursements.size(),
      'No future unpaid disbursements should remain when the paid total already equals Option One.'
    );

    for (Grant_Disbursement__c disbursement : futureDisbursements) {
      System.assertEquals(100, disbursement.Amount_to_be_disbursed__c);
      System.assertEquals(false, disbursement.Grant_is_disbursed__c);
      System.assertEquals('Option Two', disbursement.Support_Option__c);
    }

    Integer unpaidRecords = [
      SELECT COUNT()
      FROM Grant_Disbursement__c
      WHERE
        Grant_Applicantion__c = :application.Id
        AND Grant_is_disbursed__c = FALSE
    ];
    Integer paidFutureRecords = [
      SELECT COUNT()
      FROM Grant_Disbursement__c
      WHERE
        Grant_Applicantion__c = :application.Id
        AND Grant_is_disbursed__c = TRUE
        AND Disbursed_Date__c > :Date.today()
    ];

    System.assertEquals(
      0,
      unpaidRecords,
      'Unpaid disbursements should be removed when the application grant type has no remaining amount.'
    );
    System.assertEquals(
      1,
      paidFutureRecords,
      'Future disbursements marked as paid should be kept as already disbursed.'
    );
  }

  @IsTest
  static void recalculateFromFlowRejectsLowerOptionThanReceivedAmount() {
    User adminUser = createSystemAdminUser('invalidswitch');

    System.runAs(adminUser) {
      recalculateFromFlowRejectsLowerOptionThanReceivedAmountAsAdmin();
    }
  }

  @IsTest
  static void recalculateFromFlowIgnoresEmptyRequests() {
    Test.startTest();
    GrantDisbursementService.recalculateDisbursementsFromFlow(null);
    GrantDisbursementService.recalculateDisbursementsFromFlow(
      new List<GrantDisbursementService.FlowRequest>()
    );
    GrantDisbursementService.recalculateDisbursementsFromFlow(
      new List<GrantDisbursementService.FlowRequest>{
        null,
        new GrantDisbursementService.FlowRequest()
      }
    );
    Test.stopTest();

    System.assertEquals(
      0,
      [SELECT COUNT() FROM Grant_Disbursement__c],
      'Empty flow requests should not create disbursements.'
    );
  }

  @IsTest
  static void recalculateFromFlowNormalizesApplicationGrantTypeDeveloperName() {
    User adminUser = createSystemAdminUser('normalizes');

    System.runAs(adminUser) {
      recalculateFromFlowNormalizesApplicationGrantTypeDeveloperNameAsAdmin();
    }
  }

  private static void recalculateFromFlowNormalizesApplicationGrantTypeDeveloperNameAsAdmin() {
    Contact applicant = new Contact(
      LastName = 'Applicant',
      Phone = '65 6812 3472'
    );
    insert applicant;

    Grant_Application__c application = createApplication(
      applicant.Id,
      'Option_One',
      0
    );

    Test.startTest();
    GrantDisbursementService.recalculateDisbursementsFromFlow(
      new List<GrantDisbursementService.FlowRequest>{
        createFlowRequest(application.Id)
      }
    );
    Test.stopTest();

    Grant_Application__c updatedApplication = [
      SELECT Grant_Type__c, Requested_Amount__c
      FROM Grant_Application__c
      WHERE Id = :application.Id
    ];

    System.assertEquals('Option One', updatedApplication.Grant_Type__c);
    System.assertEquals(1500, updatedApplication.Requested_Amount__c);
    System.assertEquals(
      3,
      [
        SELECT COUNT()
        FROM Grant_Disbursement__c
        WHERE Grant_Applicantion__c = :application.Id
      ]
    );
  }

  @IsTest
  static void recalculateFromFlowRejectsRemainingAmountWithoutMonths() {
    User adminUser = createSystemAdminUser('nomonths');

    System.runAs(adminUser) {
      recalculateFromFlowRejectsRemainingAmountWithoutMonthsAsAdmin();
    }
  }

  @IsTest
  static void clearsContactGrantApplicationWhenAllDisbursementsArePaid() {
    Contact applicant = createApplicant('Option_One');
    Grant_Application__c application = createApplication(
      applicant.Id,
      'Option One',
      1500
    );

    update new Contact(
      Id = applicant.Id,
      Grant_Application__c = application.Id
    );

    Grant_Disbursement__c unpaidDisbursement = createDisbursement(
      application.Id,
      500,
      Date.today(),
      false,
      1
    );
    insert new List<Grant_Disbursement__c>{
      unpaidDisbursement,
      createDisbursement(application.Id, 500, Date.today(), true, 2)
    };

    Contact applicantBeforeCompletion = [
      SELECT Grant_Application__c
      FROM Contact
      WHERE Id = :applicant.Id
    ];

    System.assertEquals(
      application.Id,
      applicantBeforeCompletion.Grant_Application__c,
      'Contact should keep the active application while any disbursement is unpaid.'
    );

    unpaidDisbursement.Grant_is_disbursed__c = true;

    Test.startTest();
    update unpaidDisbursement;
    Test.stopTest();

    Contact applicantAfterCompletion = [
      SELECT Grant_Application__c
      FROM Contact
      WHERE Id = :applicant.Id
    ];

    System.assertEquals(
      null,
      applicantAfterCompletion.Grant_Application__c,
      'Contact active application should be cleared once all disbursements are paid.'
    );
  }

  private static void recalculateFromFlowRejectsRemainingAmountWithoutMonthsAsAdmin() {
    Contact applicant = createApplicant('Option_One');
    Grant_Application__c application = createApplication(
      applicant.Id,
      'Option One',
      1500
    );

    insert new List<Grant_Disbursement__c>{
      createDisbursement(
        application.Id,
        100,
        Date.today().addMonths(-3),
        true,
        1
      ),
      createDisbursement(
        application.Id,
        100,
        Date.today().addMonths(-2),
        true,
        2
      ),
      createDisbursement(
        application.Id,
        100,
        Date.today().addMonths(-1),
        true,
        3
      )
    };

    Boolean exceptionThrown = false;

    Test.startTest();
    try {
      GrantDisbursementService.recalculateDisbursementsFromFlow(
        new List<GrantDisbursementService.FlowRequest>{
          createFlowRequest(application.Id)
        }
      );
    } catch (GrantException exceptionRecord) {
      exceptionThrown = true;
      System.assert(
        exceptionRecord.getMessage().contains('no remaining months'),
        'Invalid recalculation should explain the remaining month problem.'
      );
    }
    Test.stopTest();

    System.assert(
      exceptionThrown,
      'Recalculation should fail when amount remains but all months are consumed.'
    );
  }

  private static void recalculateFromFlowRejectsLowerOptionThanReceivedAmountAsAdmin() {
    Contact applicant = createApplicant('Option_Three');
    Grant_Application__c application = createApplication(
      applicant.Id,
      'Option One',
      1500
    );
    List<Grant_Disbursement__c> receivedDisbursements = new List<Grant_Disbursement__c>();

    for (Integer monthNumber = 1; monthNumber <= 10; monthNumber++) {
      receivedDisbursements.add(
        createDisbursement(
          application.Id,
          200,
          Date.today().addMonths(-monthNumber),
          true,
          monthNumber
        )
      );
    }

    insert receivedDisbursements;

    Boolean exceptionThrown = false;

    Test.startTest();
    try {
      GrantDisbursementService.recalculateDisbursementsFromFlow(
        new List<GrantDisbursementService.FlowRequest>{
          createFlowRequest(application.Id)
        }
      );
    } catch (GrantException exceptionRecord) {
      exceptionThrown = true;
      System.assert(
        exceptionRecord.getMessage().contains('total disbursed amount'),
        'Invalid support option changes should return a meaningful error.'
      );
    }
    Test.stopTest();

    System.assert(
      exceptionThrown,
      'Recalculation should fail when the applicant already received more than the new option total.'
    );
  }

  private static Contact createApplicant(String supportOption) {
    Contact applicant = new Contact(
      LastName = 'Applicant',
      Phone = '65 6812 3456',
      MailingPostalCode = '123456',
      Monthly_Income__c = 1000,
      Support_Option__c = supportOption
    );
    insert applicant;

    return applicant;
  }

  private static Grant_Application__c createApplication(
    Id applicantId,
    String grantType,
    Decimal requestedAmount
  ) {
    Grant_Application__c application = new Grant_Application__c(
      Applicant__c = applicantId,
      Grant_Type__c = grantType,
      Requested_Amount__c = requestedAmount,
      Application_Date__c = Datetime.now(),
      Submitted_Date__c = Datetime.now()
    );
    insert application;

    return application;
  }

  private static Grant_Disbursement__c createDisbursement(
    Id applicationId,
    Decimal amount,
    Date disbursedDate,
    Boolean grantIsDisbursed,
    Integer sequenceNumber
  ) {
    return new Grant_Disbursement__c(
      Grant_Applicantion__c = applicationId,
      Amount_to_be_disbursed__c = amount,
      Grant_is_disbursed__c = grantIsDisbursed,
      Disbursed_Date__c = disbursedDate,
      Support_Option__c = 'Existing Option',
      Sequence_Number__c = sequenceNumber
    );
  }

  private static GrantDisbursementService.FlowRequest createFlowRequest(
    Id applicationId
  ) {
    GrantDisbursementService.FlowRequest request = new GrantDisbursementService.FlowRequest();
    request.grantApplicationId = applicationId;

    return request;
  }

  private static User createSystemAdminUser(String suffix) {
    Profile adminProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'System Administrator'
      LIMIT 1
    ];
    String uniqueSuffix = suffix + String.valueOf(DateTime.now().getTime());

    User adminUser = new User(
      Alias = uniqueSuffix.left(8),
      Email = uniqueSuffix + '@example.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Admin',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = adminProfile.Id,
      TimeZoneSidKey = 'Asia/Jakarta',
      UserName = uniqueSuffix + '@example.com'
    );
    insert adminUser;

    PermissionSet grantPermissionSet = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'Grant_Disbursement_Access'
      LIMIT 1
    ];

    insert new PermissionSetAssignment(
      AssigneeId = adminUser.Id,
      PermissionSetId = grantPermissionSet.Id
    );

    return adminUser;
  }
}
