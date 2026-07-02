@IsTest
private class GrantApplicationServiceTest {
  @IsTest
  static void validateApplicantRequestAcceptsValidRequest() {
    GrantDTO request = createGrantRequest('65 6812 3470');

    Test.startTest();
    GrantApplicationService.validateApplicantRequest(request);
    Test.stopTest();

    System.assertEquals(
      '65 6812 3470',
      request.phone,
      'Valid requests should pass without modifying the DTO.'
    );
  }

  @IsTest
  static void validateApplicantRequestRejectsMissingAndInvalidFields() {
    assertValidationMessage(
      requestWithFieldValue('firstName', null),
      'Applicant First Name is required.'
    );
    assertValidationMessage(
      requestWithFieldValue('lastName', ' '),
      'Applicant Last Name is required.'
    );
    assertValidationMessage(
      requestWithFieldValue('phone', '68123456'),
      'Phone must use Singapore format 65 6812 3456.'
    );
    assertValidationMessage(
      requestWithFieldValue('email', 'not-an-email'),
      'Email must be a valid email address.'
    );
    assertValidationMessage(
      requestWithFieldValue('mailingPostalCode', 'ABC123'),
      'Mailing Postal Code must be a 6 digit number.'
    );
    assertValidationMessage(
      requestWithFieldValue('monthlyIncome', Decimal.valueOf(-1)),
      'Monthly Income must be a valid SGD amount.'
    );
    assertValidationMessage(
      requestWithFieldValue('supportOption', ''),
      'Support Option is required.'
    );
  }

  @IsTest
  static void submitApplicationRejectsNullRequest() {
    assertGrantException(
      new SubmitNullApplicationAssertion(),
      'Request cannot be null.'
    );
  }

  @IsTest
  static void controllerWrapsSubmitApplicationErrorsForAura() {
    Boolean exceptionThrown = false;

    Test.startTest();
    try {
      GrantApplicationController.submitApplication(null);
    } catch (AuraHandledException exceptionRecord) {
      exceptionThrown = true;
      System.assertNotEquals(null, exceptionRecord.getMessage());
    }
    Test.stopTest();

    System.assert(
      exceptionThrown,
      'Controller should translate service errors into AuraHandledException.'
    );
  }

  @IsTest
  static void controllerReturnsActiveGrantTypesAndSupportOptions() {
    Test.startTest();
    List<String> grantTypes = GrantApplicationController.getActiveGrantTypes();
    List<GrantSupportOptionDTO> supportOptions = GrantApplicationController.getActiveSupportOptions();
    Test.stopTest();

    System.assert(
      grantTypes.contains('Education Grant'),
      'Active grant types should include deployed active metadata.'
    );
    System.assertEquals(3, supportOptions.size());
    System.assertEquals('Option_One', supportOptions[0].value);
    System.assertEquals('Option One', supportOptions[0].label);
    System.assertEquals(500, supportOptions[0].monthlyAmount);
    System.assertEquals(3, supportOptions[0].durationMonths);
    System.assertEquals(1500, supportOptions[0].totalAmount);
  }

  @IsTest
  static void supportOptionServiceReturnsActiveOptionAndRejectsInvalidNames() {
    Test.startTest();
    Grant_Support_Option__mdt option = GrantSupportOptionService.getActiveOption(
      'Option_Two'
    );
    Test.stopTest();

    System.assertEquals('Option Two', option.MasterLabel);
    System.assertEquals(300, option.Monthly_Amount__c);
    System.assertEquals(6, option.Duration_Months__c);

    assertGrantException(
      new GetNullSupportOptionAssertion(),
      'Support Option is required.'
    );
    assertGrantException(
      new GetMissingSupportOptionAssertion(),
      'Support Option is not available.'
    );
  }

  @IsTest
  static void configurationServiceReturnsActiveConfigurations() {
    Test.startTest();
    Grant_Configuration__mdt educationConfig = GrantConfigurationService.getConfiguration(
      'Education Grant'
    );
    List<String> activeGrantTypes = GrantConfigurationService.getActiveGrantTypes();
    Test.stopTest();

    System.assertEquals('Education Grant', educationConfig.Grant_Type__c);
    System.assert(educationConfig.Maximum_Amount__c > 0);
    System.assert(activeGrantTypes.contains('Education Grant'));
  }

  @IsTest
  static void configurationServiceRejectsUnknownGrantType() {
    assertGrantException(
      new GetMissingConfigurationAssertion(),
      'Grant Configuration not found.'
    );
  }

  @IsTest
  static void applicationRepositorySavesAndReturnsApplications() {
    Grant_Application__c application = new Grant_Application__c(
      Grant_Type__c = 'Option One',
      Requested_Amount__c = 1500,
      Approved_Amount__c = 1200,
      Status__c = GrantConstants.STATUS_PENDING,
      Eligibility_Score__c = 85,
      Application_Date__c = Date.today(),
      Submitted_Date__c = Datetime.now()
    );

    Test.startTest();
    Id applicationId = GrantApplicationRepository.save(application);
    Grant_Application__c savedApplication = GrantApplicationRepository.getById(
      applicationId
    );
    Grant_Application__c missingApplication = GrantApplicationRepository.getById(
      null
    );
    Test.stopTest();

    System.assertEquals(applicationId, savedApplication.Id);
    System.assertEquals('Option One', savedApplication.Grant_Type__c);
    System.assertEquals(1500, savedApplication.Requested_Amount__c);
    System.assertEquals(1200, savedApplication.Approved_Amount__c);
    System.assertEquals(85, savedApplication.Eligibility_Score__c);
    System.assertEquals(null, missingApplication);
  }

  @IsTest
  static void applicationRepositoryUpdatesExistingApplication() {
    Grant_Application__c application = new Grant_Application__c(
      Grant_Type__c = 'Option One',
      Requested_Amount__c = 1500,
      Status__c = GrantConstants.STATUS_PENDING,
      Application_Date__c = Date.today(),
      Submitted_Date__c = Datetime.now()
    );
    insert application;

    application.Requested_Amount__c = 1800;

    Test.startTest();
    Id applicationId = GrantApplicationRepository.save(application);
    Test.stopTest();

    Grant_Application__c savedApplication = [
      SELECT Requested_Amount__c
      FROM Grant_Application__c
      WHERE Id = :application.Id
    ];

    System.assertEquals(application.Id, applicationId);
    System.assertEquals(1800, savedApplication.Requested_Amount__c);
  }

  @IsTest
  static void contactRepositoryReturnsApplicantFields() {
    Contact applicant = new Contact(
      FirstName = 'Repository',
      LastName = 'Applicant',
      Phone = '65 6812 3477',
      Email = 'repository.applicant@example.com',
      MailingPostalCode = '123456',
      Monthly_Income__c = 1000,
      Annual_Income__c = 12000,
      Support_Option__c = 'Option_One'
    );
    insert applicant;

    Grant_Application__c application = new Grant_Application__c(
      Applicant__c = applicant.Id,
      Grant_Type__c = 'Option One',
      Requested_Amount__c = 1500,
      Status__c = GrantConstants.STATUS_PENDING,
      Application_Date__c = Date.today(),
      Submitted_Date__c = Datetime.now()
    );
    insert application;

    update new Contact(
      Id = applicant.Id,
      Grant_Application__c = application.Id
    );

    Test.startTest();
    Contact contactById = ContactRepository.getById(applicant.Id);
    Contact contactByPhone = ContactRepository.getByPhone('65 6812 3477');
    Contact missingById = ContactRepository.getById(null);
    Contact missingByPhone = ContactRepository.getByPhone(' ');
    Test.stopTest();

    System.assertEquals(applicant.Id, contactById.Id);
    System.assertEquals('Repository Applicant', contactById.Name);
    System.assertEquals(application.Id, contactById.Grant_Application__c);
    System.assertEquals(applicant.Id, contactByPhone.Id);
    System.assertEquals(application.Id, contactByPhone.Grant_Application__c);
    System.assertEquals(null, missingById);
    System.assertEquals(null, missingByPhone);
  }

  @IsTest
  static void submitApplicationReusesContactGrantApplication() {
    Contact applicant = new Contact(
      LastName = 'Existing Applicant',
      Phone = '65 6812 3475',
      Email = 'existing.applicant@example.com',
      MailingPostalCode = '123456',
      Monthly_Income__c = 1000,
      Support_Option__c = 'Option_One'
    );
    insert applicant;

    Grant_Application__c application = new Grant_Application__c(
      Applicant__c = applicant.Id,
      Grant_Type__c = 'Option One',
      Requested_Amount__c = 1500,
      Status__c = GrantConstants.STATUS_PENDING,
      Application_Date__c = Date.today(),
      Submitted_Date__c = Datetime.now()
    );
    insert application;

    update new Contact(
      Id = applicant.Id,
      Grant_Application__c = application.Id
    );

    GrantDTO request = createGrantRequest('65 6812 3475');
    request.reason = 'Updated reason.';

    Test.startTest();
    Id applicationId = GrantApplicationService.submitApplication(request);
    Test.stopTest();

    System.assertEquals(application.Id, applicationId);
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM Grant_Application__c
        WHERE Applicant__c = :applicant.Id
      ],
      'Existing active application should be updated instead of creating another record.'
    );

    Contact savedApplicant = [
      SELECT Grant_Application__c
      FROM Contact
      WHERE Id = :applicant.Id
    ];

    System.assertEquals(application.Id, savedApplicant.Grant_Application__c);
  }

  @IsTest
  static void submitApplicationReusesApplicantApplicationWhenContactLookupIsNull() {
    Contact applicant = new Contact(
      LastName = 'Guest Linked Applicant',
      Phone = '65 6812 3478',
      Email = 'guest.linked@example.com',
      MailingPostalCode = '123456',
      Monthly_Income__c = 1000,
      Support_Option__c = 'Option_One'
    );
    insert applicant;

    Grant_Application__c application = new Grant_Application__c(
      Applicant__c = applicant.Id,
      Grant_Type__c = 'Option One',
      Requested_Amount__c = 1500,
      Status__c = GrantConstants.STATUS_PENDING,
      Application_Date__c = Date.today(),
      Submitted_Date__c = Datetime.now()
    );
    insert application;

    GrantDTO request = createGrantRequest('65 6812 3478');
    request.reason = 'Guest retry should update active application.';

    Test.startTest();
    Id applicationId = GrantApplicationService.submitApplication(request);
    Test.stopTest();

    System.assertEquals(
      application.Id,
      applicationId,
      'Application linked by Applicant__c should be reused when Contact.Grant_Application__c is null.'
    );
    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM Grant_Application__c
        WHERE Applicant__c = :applicant.Id
      ]
    );
  }

  @IsTest
  static void guestSubmitReusesActiveApplicationWithQueueableUpdate() {
    Contact applicant = new Contact(
      LastName = 'Guest Reuse Applicant',
      Phone = '65 6812 3480',
      Email = 'guest.reuse@example.com',
      MailingPostalCode = '123456',
      Monthly_Income__c = 1000,
      Support_Option__c = 'Option_One'
    );
    insert applicant;

    Grant_Application__c application = new Grant_Application__c(
      Applicant__c = applicant.Id,
      Grant_Type__c = 'Option One',
      Requested_Amount__c = 1500,
      Reason__c = 'Original reason.',
      Status__c = GrantConstants.STATUS_PENDING,
      Application_Date__c = Date.today(),
      Submitted_Date__c = Datetime.now()
    );
    insert application;

    GrantDTO request = createGrantRequest('65 6812 3480');
    request.reason = 'Guest queueable should update active application.';

    GrantApplicationService.guestUserOverride = true;

    try {
      Test.startTest();
      Id applicationId = GrantApplicationService.submitApplication(request);
      Test.stopTest();

      Grant_Application__c savedApplication = [
        SELECT
          Applicant__c,
          Grant_Type__c,
          Requested_Amount__c,
          Reason__c,
          Status__c
        FROM Grant_Application__c
        WHERE Id = :application.Id
      ];

      System.assertEquals(application.Id, applicationId);
      System.assertEquals(applicant.Id, savedApplication.Applicant__c);
      System.assertEquals('Option One', savedApplication.Grant_Type__c);
      System.assertEquals(1500, savedApplication.Requested_Amount__c);
      System.assertEquals(
        'Guest queueable should update active application.',
        savedApplication.Reason__c,
        'Guest reuse should update the existing application through the queueable job.'
      );
      System.assertEquals(
        GrantConstants.STATUS_PENDING,
        savedApplication.Status__c
      );
    } finally {
      GrantApplicationService.guestUserOverride = null;
    }
  }

  @IsTest
  static void submitApplicationDoesNotReuseCompletedApplicantApplication() {
    Contact applicant = new Contact(
      LastName = 'Completed Applicant',
      Phone = '65 6812 3479',
      Email = 'completed.applicant@example.com',
      MailingPostalCode = '123456',
      Monthly_Income__c = 1000,
      Support_Option__c = 'Option_One'
    );
    insert applicant;

    Grant_Application__c completedApplication = new Grant_Application__c(
      Applicant__c = applicant.Id,
      Grant_Type__c = 'Option One',
      Requested_Amount__c = 1500,
      Status__c = GrantConstants.STATUS_PENDING,
      Application_Date__c = Date.today(),
      Submitted_Date__c = Datetime.now().addDays(-1)
    );
    insert completedApplication;

    insert new Grant_Disbursement__c(
      Grant_Applicantion__c = completedApplication.Id,
      Amount_to_be_disbursed__c = 1500,
      Grant_is_disbursed__c = true,
      Disbursed_Date__c = Date.today(),
      Support_Option__c = 'Option One',
      Sequence_Number__c = 1
    );

    GrantDTO request = createGrantRequest('65 6812 3479');

    Test.startTest();
    Id applicationId = GrantApplicationService.submitApplication(request);
    Test.stopTest();

    System.assertNotEquals(
      completedApplication.Id,
      applicationId,
      'Completed applications should not be reused after every disbursement is marked paid.'
    );
    System.assertEquals(
      2,
      [
        SELECT COUNT()
        FROM Grant_Application__c
        WHERE Applicant__c = :applicant.Id
      ]
    );
  }

  @IsTest
  static void triggerAndHandlerMaintainApplicationStage() {
    Grant_Application__c application = new Grant_Application__c(
      Grant_Type__c = 'Option One',
      Requested_Amount__c = 1500,
      Status__c = GrantConstants.STATUS_PENDING,
      Application_Date__c = Date.today(),
      Submitted_Date__c = Datetime.now()
    );

    Test.startTest();
    insert application;
    application.Status__c = GrantConstants.STATUS_APPROVED;
    update application;
    Test.stopTest();

    Grant_Application__c savedApplication = [
      SELECT Current_Stage__c, Status__c
      FROM Grant_Application__c
      WHERE Id = :application.Id
    ];

    System.assertEquals('Submitted', savedApplication.Current_Stage__c);
    System.assertEquals(
      GrantConstants.STATUS_APPROVED,
      savedApplication.Status__c
    );
  }

  @IsTest
  static void utilityMethodsReturnExpectedValues() {
    Test.startTest();
    Boolean blankValue = GrantUtility.isBlank('   ');
    Boolean nullValue = GrantUtility.isNull(null);
    String transactionId = GrantUtility.generateTransactionId();
    GrantIntegrationService integrationService = new GrantIntegrationService();
    GrantRetryService retryService = new GrantRetryService();
    GrantExceptionService exceptionService = new GrantExceptionService();
    Test.stopTest();

    System.assertEquals(true, blankValue);
    System.assertEquals(true, nullValue);
    System.assertNotEquals(null, transactionId);
    System.assertEquals(40, transactionId.length());
    System.assertNotEquals(null, integrationService);
    System.assertNotEquals(null, retryService);
    System.assertNotEquals(null, exceptionService);
    System.assertEquals(3, GrantConstants.MAX_RETRY);
    System.assertEquals('Approved', GrantConstants.STATUS_APPROVED);
    System.assertEquals('Integration', GrantConstants.ERROR_INTEGRATION);
  }

  @IsTest
  static void smallBranchesCoverGuardClausesAndDtoDefaults() {
    Grant_Application__c application = new Grant_Application__c();
    new GrantApplicationTriggerHandler()
      .beforeInsert(new List<Grant_Application__c>{ application });

    GrantSupportOptionDTO option = new GrantSupportOptionDTO(
      new Grant_Support_Option__mdt(
        DeveloperName = 'Test_Option',
        MasterLabel = 'Test Option',
        Monthly_Amount__c = 25
      )
    );

    Test.startTest();
    System.enqueueJob(new GrantApplicationApplicantLinkJob(null, null));
    Test.stopTest();

    System.assertEquals('Submitted', application.Current_Stage__c);
    System.assertEquals(0, option.durationMonths);
    System.assertEquals(0, option.totalAmount);
  }

  @IsTest
  static void applicantLinkJobLinksApplicationAndContact() {
    Contact applicant = new Contact(
      LastName = 'Queued Applicant',
      Phone = '65 6812 3476'
    );
    insert applicant;

    Grant_Application__c application = new Grant_Application__c(
      Grant_Type__c = 'Option One',
      Requested_Amount__c = 1500,
      Status__c = GrantConstants.STATUS_PENDING,
      Application_Date__c = Date.today(),
      Submitted_Date__c = Datetime.now()
    );
    insert application;

    Test.startTest();
    System.enqueueJob(
      new GrantApplicationApplicantLinkJob(application.Id, applicant.Id)
    );
    Test.stopTest();

    Grant_Application__c savedApplication = [
      SELECT Applicant__c
      FROM Grant_Application__c
      WHERE Id = :application.Id
    ];
    Contact savedApplicant = [
      SELECT Grant_Application__c
      FROM Contact
      WHERE Id = :applicant.Id
    ];

    System.assertEquals(applicant.Id, savedApplication.Applicant__c);
    System.assertEquals(application.Id, savedApplicant.Grant_Application__c);
  }

  @IsTest
  static void grantDtoPropertiesCanBeRoundTripped() {
    Account accountRecord = new Account(Name = 'DTO Applicant Account');
    insert accountRecord;

    Contact applicant = new Contact(
      AccountId = accountRecord.Id,
      FirstName = 'DTO',
      LastName = 'Applicant',
      Phone = '65 6812 3473'
    );
    insert applicant;

    Grant_Application__c application = new Grant_Application__c(
      Applicant__c = applicant.Id,
      Grant_Type__c = 'Option One',
      Requested_Amount__c = 1500,
      Status__c = GrantConstants.STATUS_PENDING,
      Application_Date__c = Date.today(),
      Submitted_Date__c = Datetime.now()
    );
    insert application;

    GrantDTO request = createGrantRequest('65 6812 3474');
    request.applicationId = application.Id;
    request.applicantId = applicant.Id;
    request.grantType = 'Option One';
    request.requestedAmount = 1500;
    request.status = GrantConstants.STATUS_PENDING;

    System.assertEquals(application.Id, request.applicationId);
    System.assertEquals(applicant.Id, request.applicantId);
    System.assertEquals('Option One', request.grantType);
    System.assertEquals(1500, request.requestedAmount);
    System.assertEquals(GrantConstants.STATUS_PENDING, request.status);
  }

  private static GrantDTO createGrantRequest(String phone) {
    GrantDTO request = new GrantDTO();
    request.firstName = 'Grant';
    request.lastName = 'Applicant';
    request.phone = phone;
    request.email = 'grant.applicant@example.com';
    request.mailingPostalCode = '123456';
    request.monthlyIncome = 1000;
    request.supportOption = 'Option_One';
    request.reason = 'Need short term support.';

    return request;
  }

  private static GrantDTO requestWithFieldValue(
    String fieldName,
    Object fieldValue
  ) {
    GrantDTO request = createGrantRequest('65 6812 3471');

    if (fieldName == 'firstName') {
      request.firstName = (String) fieldValue;
    } else if (fieldName == 'lastName') {
      request.lastName = (String) fieldValue;
    } else if (fieldName == 'phone') {
      request.phone = (String) fieldValue;
    } else if (fieldName == 'email') {
      request.email = (String) fieldValue;
    } else if (fieldName == 'mailingPostalCode') {
      request.mailingPostalCode = (String) fieldValue;
    } else if (fieldName == 'monthlyIncome') {
      request.monthlyIncome = (Decimal) fieldValue;
    } else if (fieldName == 'supportOption') {
      request.supportOption = (String) fieldValue;
    }

    return request;
  }

  private static void assertValidationMessage(
    GrantDTO request,
    String expectedMessage
  ) {
    assertGrantException(
      new ValidateRequestAssertion(request),
      expectedMessage
    );
  }

  private static void assertGrantException(
    ExceptionAssertion assertion,
    String expectedMessage
  ) {
    Boolean exceptionThrown = false;

    try {
      assertion.execute();
    } catch (GrantException exceptionRecord) {
      exceptionThrown = true;
      System.assertEquals(expectedMessage, exceptionRecord.getMessage());
    }

    System.assert(exceptionThrown, expectedMessage);
  }

  private interface ExceptionAssertion {
    void execute();
  }

  private class ValidateRequestAssertion implements ExceptionAssertion {
    private GrantDTO request;

    ValidateRequestAssertion(GrantDTO request) {
      this.request = request;
    }

    public void execute() {
      GrantApplicationService.validateApplicantRequest(request);
    }
  }

  private class SubmitNullApplicationAssertion implements ExceptionAssertion {
    public void execute() {
      GrantApplicationService.submitApplication(null);
    }
  }

  private class GetNullSupportOptionAssertion implements ExceptionAssertion {
    public void execute() {
      GrantSupportOptionService.getActiveOption(null);
    }
  }

  private class GetMissingSupportOptionAssertion implements ExceptionAssertion {
    public void execute() {
      GrantSupportOptionService.getActiveOption('Missing_Option');
    }
  }

  private class GetMissingConfigurationAssertion implements ExceptionAssertion {
    public void execute() {
      GrantConfigurationService.getConfiguration('Unknown Grant');
    }
  }
}
