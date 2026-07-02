public without sharing class GrantApplicationService {
  private static final Pattern SINGAPORE_PHONE_PATTERN = Pattern.compile(
    '^65 [0-9]{4} [0-9]{4}$'
  );

  private static final Pattern POSTAL_CODE_PATTERN = Pattern.compile(
    '^[0-9]{6}$'
  );

  private static final Pattern EMAIL_PATTERN = Pattern.compile(
    '(?i)^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$'
  );
  @TestVisible
  private static Boolean guestUserOverride;

  public static Id submitApplication(GrantDTO request) {
    if (request == null) {
      throw new GrantException('Request cannot be null.');
    }

    validateApplicantRequest(request);

    Grant_Support_Option__mdt supportOption = GrantSupportOptionService.getActiveOption(
      request.supportOption
    );

    Contact applicant = upsertApplicant(request);
    System.debug('===== Contact ' + applicant.Id);
    System.debug(JSON.serializePretty(applicant));
    System.debug('===== Active Grant ' + applicant.Grant_Application__c);
    Id activeApplicationId = getActiveApplicationId(applicant);

    if (isGuestUser() && activeApplicationId != null) {
      System.enqueueJob(
        new GrantApplicationGuestUpdateJob(
          activeApplicationId,
          applicant.Id,
          supportOption.MasterLabel,
          supportOption.Monthly_Amount__c * supportOption.Duration_Months__c,
          request.reason
        )
      );

      return activeApplicationId;
    }

    // Jika applicant sudah punya Grant Application, gunakan record tersebut.
    // Jika belum, buat baru.
    Grant_Application__c application;

    if (activeApplicationId != null) {
      application = new Grant_Application__c(Id = activeApplicationId);
    } else {
      application = new Grant_Application__c();
    }
    //Grant_Application__c application = new Grant_Application__c();

    if (!isGuestUser()) {
      application.Applicant__c = applicant.Id;
    }

    application.Grant_Type__c = supportOption.MasterLabel;
    application.Requested_Amount__c =
      supportOption.Monthly_Amount__c * supportOption.Duration_Months__c;
    application.Reason__c = request.reason;
    application.Status__c = GrantConstants.STATUS_PENDING;
    application.Application_Date__c = Date.today();
    application.Submitted_Date__c = Datetime.now();

    Id applicationId = GrantApplicationRepository.save(application);

    if (isGuestUser()) {
      System.enqueueJob(
        new GrantApplicationApplicantLinkJob(applicationId, applicant.Id)
      );
    } else if (activeApplicationId != applicationId) {
      update new Contact(
        Id = applicant.Id,
        Grant_Application__c = applicationId
      );
    }

    return applicationId;
  }

  private static Contact upsertApplicant(GrantDTO request) {
    return ContactMatchingService.upsertApplicantByPhone(request);
  }

  private static Id getActiveApplicationId(Contact applicant) {
    if (applicant == null || applicant.Id == null) {
      return null;
    }

    if (applicant.Grant_Application__c != null) {
      return applicant.Grant_Application__c;
    }

    List<Grant_Application__c> applicantApplications = [
      SELECT Id
      FROM Grant_Application__c
      WHERE Applicant__c = :applicant.Id
      ORDER BY Submitted_Date__c DESC NULLS LAST, CreatedDate DESC
      LIMIT 10
    ];

    if (applicantApplications.isEmpty()) {
      return null;
    }

    Set<Id> applicationIds = new Set<Id>();

    for (Grant_Application__c application : applicantApplications) {
      applicationIds.add(application.Id);
    }

    Set<Id> applicationsWithDisbursements = new Set<Id>();
    Set<Id> incompleteApplicationIds = new Set<Id>();

    for (Grant_Disbursement__c disbursement : [
      SELECT Grant_Applicantion__c, Grant_is_disbursed__c
      FROM Grant_Disbursement__c
      WHERE Grant_Applicantion__c IN :applicationIds
    ]) {
      applicationsWithDisbursements.add(disbursement.Grant_Applicantion__c);

      if (disbursement.Grant_is_disbursed__c != true) {
        incompleteApplicationIds.add(disbursement.Grant_Applicantion__c);
      }
    }

    for (Grant_Application__c application : applicantApplications) {
      Boolean hasDisbursements = applicationsWithDisbursements.contains(
        application.Id
      );

      if (
        !hasDisbursements || incompleteApplicationIds.contains(application.Id)
      ) {
        return application.Id;
      }
    }

    return null;
  }

  private static Boolean isGuestUser() {
    if (guestUserOverride != null) {
      return guestUserOverride;
    }

    return UserInfo.getUserType() == 'Guest';
  }

  public static void validateApplicantRequest(GrantDTO request) {
    if (String.isBlank(request.firstName)) {
      throw new GrantException('Applicant First Name is required.');
    }

    if (String.isBlank(request.lastName)) {
      throw new GrantException('Applicant Last Name is required.');
    }

    if (
      String.isBlank(request.phone) ||
      !SINGAPORE_PHONE_PATTERN.matcher(request.phone).matches()
    ) {
      throw new GrantException('Phone must use Singapore format 65 6812 3456.');
    }

    if (
      String.isBlank(request.email) ||
      !EMAIL_PATTERN.matcher(request.email).matches()
    ) {
      throw new GrantException('Email must be a valid email address.');
    }

    if (
      String.isBlank(request.mailingPostalCode) ||
      !POSTAL_CODE_PATTERN.matcher(request.mailingPostalCode).matches()
    ) {
      throw new GrantException('Mailing Postal Code must be a 6 digit number.');
    }

    if (request.monthlyIncome == null || request.monthlyIncome < 0) {
      throw new GrantException('Monthly Income must be a valid SGD amount.');
    }

    if (String.isBlank(request.supportOption)) {
      throw new GrantException('Support Option is required.');
    }
  }
}
