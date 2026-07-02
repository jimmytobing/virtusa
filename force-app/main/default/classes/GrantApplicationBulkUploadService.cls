public without sharing class GrantApplicationBulkUploadService {
  private static final Pattern SINGAPORE_PHONE_PATTERN = Pattern.compile(
    '^65 [0-9]{4} [0-9]{4}$'
  );
  private static final Pattern POSTAL_CODE_PATTERN = Pattern.compile(
    '^[0-9]{6}$'
  );
  private static Boolean processingApplicationUpdates = false;

  public static void validateBeforeInsert(List<Grant_Application__c> records) {
    if (records == null || records.isEmpty()) {
      return;
    }

    Map<String, Grant_Support_Option__mdt> optionsByUploadValue = getActiveOptionsByUploadValue();

    for (Grant_Application__c application : records) {
      if (!hasUploadApplicantFields(application)) {
        continue;
      }

      validateUploadApplication(application, optionsByUploadValue);
    }
  }

  public static void processAfterInsert(List<Grant_Application__c> records) {
    if (records == null || records.isEmpty()) {
      return;
    }

    List<Grant_Application__c> uploadApplications = new List<Grant_Application__c>();

    for (Grant_Application__c application : records) {
      if (hasUploadApplicantFields(application)) {
        uploadApplications.add(application);
      }
    }

    processUploadedApplications(uploadApplications);
  }

  public static void processAfterUpdate(
    List<Grant_Application__c> records,
    Map<Id, Grant_Application__c> oldMap
  ) {
    if (processingApplicationUpdates || records == null || records.isEmpty()) {
      return;
    }

    Set<Id> applicationIdsToRecalculate = new Set<Id>();

    for (Grant_Application__c application : records) {
      Grant_Application__c oldApplication = oldMap == null
        ? null
        : oldMap.get(application.Id);

      if (
        oldApplication == null ||
        application.Grant_Type__c != oldApplication.Grant_Type__c
      ) {
        applicationIdsToRecalculate.add(application.Id);
      }
    }

    GrantDisbursementService.recalculateForApplicationIds(
      applicationIdsToRecalculate
    );
  }

  private static void processUploadedApplications(
    List<Grant_Application__c> applications
  ) {
    if (applications.isEmpty()) {
      return;
    }

    Map<String, Grant_Support_Option__mdt> optionsByUploadValue = getActiveOptionsByUploadValue();
    Set<String> phones = new Set<String>();

    for (Grant_Application__c application : applications) {
      phones.add(application.Applicant_Phone__c);
    }

    Map<String, Contact> existingContactsByPhone = new Map<String, Contact>();

    for (Contact applicant : [
      SELECT
        Id,
        FirstName,
        LastName,
        Phone,
        Email,
        MailingPostalCode,
        Monthly_Income__c,
        Annual_Income__c,
        Support_Option__c,
        Grant_Application__c
      FROM Contact
      WHERE Phone IN :phones
      ORDER BY CreatedDate, Id
    ]) {
      if (!existingContactsByPhone.containsKey(applicant.Phone)) {
        existingContactsByPhone.put(applicant.Phone, applicant);
      }
    }

    Map<String, Contact> contactsToInsertByPhone = new Map<String, Contact>();
    Map<Id, Contact> contactsToUpdateById = new Map<Id, Contact>();

    for (Grant_Application__c application : applications) {
      Grant_Support_Option__mdt option = optionsByUploadValue.get(
        normalizeUploadValue(application.Support_Option__c)
      );
      String optionDeveloperName = option == null ? null : option.DeveloperName;
      Contact applicant = existingContactsByPhone.get(
        application.Applicant_Phone__c
      );

      if (applicant == null) {
        applicant = contactsToInsertByPhone.get(application.Applicant_Phone__c);
      }

      if (applicant == null) {
        applicant = new Contact(Phone = application.Applicant_Phone__c);
        contactsToInsertByPhone.put(application.Applicant_Phone__c, applicant);
      }

      copyApplicantFields(application, applicant, optionDeveloperName);

      if (applicant.Id == null) {
        continue;
      }

      contactsToUpdateById.put(applicant.Id, applicant);
    }

    if (!contactsToInsertByPhone.isEmpty()) {
      insert contactsToInsertByPhone.values();
    }

    if (!contactsToUpdateById.isEmpty()) {
      update contactsToUpdateById.values();
    }

    for (Contact applicant : contactsToInsertByPhone.values()) {
      existingContactsByPhone.put(applicant.Phone, applicant);
    }

    List<Grant_Application__c> applicationsToUpdate = new List<Grant_Application__c>();
    Set<Id> applicationIdsToRecalculate = new Set<Id>();

    for (Grant_Application__c application : applications) {
      Grant_Support_Option__mdt option = optionsByUploadValue.get(
        normalizeUploadValue(application.Support_Option__c)
      );
      Contact applicant = existingContactsByPhone.get(
        application.Applicant_Phone__c
      );

      if (applicant == null || option == null) {
        continue;
      }

      applicationsToUpdate.add(
        new Grant_Application__c(
          Id = application.Id,
          Applicant__c = applicant.Id,
          Grant_Type__c = option.MasterLabel,
          Requested_Amount__c = option.Monthly_Amount__c *
            option.Duration_Months__c,
          Status__c = String.isBlank(application.Status__c)
            ? GrantConstants.STATUS_PENDING
            : application.Status__c,
          Application_Date__c = application.Application_Date__c == null
            ? Date.today()
            : application.Application_Date__c,
          Submitted_Date__c = application.Submitted_Date__c == null
            ? Datetime.now()
            : application.Submitted_Date__c
        )
      );
      applicationIdsToRecalculate.add(application.Id);
    }

    if (!applicationsToUpdate.isEmpty()) {
      processingApplicationUpdates = true;

      try {
        update applicationsToUpdate;
      } finally {
        processingApplicationUpdates = false;
      }
    }

    updateApplicantActiveApplications(applicationsToUpdate);
    GrantDisbursementService.recalculateForApplicationIds(
      applicationIdsToRecalculate
    );
  }

  private static void updateApplicantActiveApplications(
    List<Grant_Application__c> applications
  ) {
    Map<Id, Contact> contactsToUpdateById = new Map<Id, Contact>();

    for (Grant_Application__c application : applications) {
      if (application.Applicant__c == null) {
        continue;
      }

      contactsToUpdateById.put(
        application.Applicant__c,
        new Contact(
          Id = application.Applicant__c,
          Grant_Application__c = application.Id
        )
      );
    }

    if (!contactsToUpdateById.isEmpty()) {
      update contactsToUpdateById.values();
    }
  }

  private static void copyApplicantFields(
    Grant_Application__c application,
    Contact applicant,
    String optionDeveloperName
  ) {
    applicant.FirstName = application.Applicant_First_Name__c;
    applicant.LastName = application.Applicant_Last_Name__c;
    applicant.Phone = application.Applicant_Phone__c;
    applicant.MailingPostalCode = application.Mailing_Postal_Code__c;
    applicant.Monthly_Income__c = application.Monthly_Income__c;
    applicant.Annual_Income__c = application.Monthly_Income__c == null
      ? null
      : application.Monthly_Income__c * 12;
    applicant.Support_Option__c = optionDeveloperName;
  }

  private static void validateUploadApplication(
    Grant_Application__c application,
    Map<String, Grant_Support_Option__mdt> optionsByUploadValue
  ) {
    if (String.isBlank(application.Applicant_First_Name__c)) {
      application.addError(
        GrantExceptionService.getMessage(
          GrantExceptionService.APPLICANT_FIRST_NAME_REQUIRED,
          'Applicant First Name is required.'
        )
      );
    }

    if (String.isBlank(application.Applicant_Last_Name__c)) {
      application.addError(
        GrantExceptionService.getMessage(
          GrantExceptionService.APPLICANT_LAST_NAME_REQUIRED,
          'Applicant Last Name is required.'
        )
      );
    }

    if (
      String.isBlank(application.Applicant_Phone__c) ||
      !SINGAPORE_PHONE_PATTERN.matcher(application.Applicant_Phone__c).matches()
    ) {
      application.addError(
        GrantExceptionService.getMessage(
          GrantExceptionService.PHONE_INVALID,
          'Phone must use Singapore format 65 6812 3456.'
        )
      );
    }

    if (
      String.isBlank(application.Mailing_Postal_Code__c) ||
      !POSTAL_CODE_PATTERN.matcher(application.Mailing_Postal_Code__c).matches()
    ) {
      application.addError(
        GrantExceptionService.getMessage(
          GrantExceptionService.POSTAL_CODE_INVALID,
          'Mailing Postal Code must be a 6 digit number.'
        )
      );
    }

    if (
      application.Monthly_Income__c == null ||
      application.Monthly_Income__c < 0
    ) {
      application.addError(
        GrantExceptionService.getMessage(
          GrantExceptionService.MONTHLY_INCOME_INVALID,
          'Monthly Income must be a valid SGD amount.'
        )
      );
    }

    if (
      String.isBlank(application.Support_Option__c) ||
      !optionsByUploadValue.containsKey(
        normalizeUploadValue(application.Support_Option__c)
      )
    ) {
      application.addError(
        GrantExceptionService.getMessage(
          GrantExceptionService.SUPPORT_OPTION_UNAVAILABLE,
          'Support Option is not available.'
        )
      );
    }
  }

  private static Boolean hasUploadApplicantFields(
    Grant_Application__c application
  ) {
    return application != null &&
      (!String.isBlank(application.Applicant_First_Name__c) ||
      !String.isBlank(application.Applicant_Last_Name__c) ||
      !String.isBlank(application.Applicant_Phone__c) ||
      !String.isBlank(application.Mailing_Postal_Code__c) ||
      application.Monthly_Income__c != null ||
      !String.isBlank(application.Support_Option__c));
  }

  private static Map<String, Grant_Support_Option__mdt> getActiveOptionsByUploadValue() {
    Map<String, Grant_Support_Option__mdt> optionsByUploadValue = new Map<String, Grant_Support_Option__mdt>();

    for (Grant_Support_Option__mdt option : [
      SELECT
        DeveloperName,
        MasterLabel,
        Monthly_Amount__c,
        Duration_Months__c,
        Sort_Order__c
      FROM Grant_Support_Option__mdt
      WHERE Active__c = TRUE
    ]) {
      addOptionKey(optionsByUploadValue, option.DeveloperName, option);
      addOptionKey(optionsByUploadValue, option.MasterLabel, option);

      if (option.Sort_Order__c != null) {
        String sortOrder = String.valueOf(option.Sort_Order__c.intValue());
        addOptionKey(optionsByUploadValue, sortOrder, option);
        addOptionKey(optionsByUploadValue, 'Option ' + sortOrder, option);
        addOptionKey(optionsByUploadValue, 'Option_' + sortOrder, option);
      }
    }

    return optionsByUploadValue;
  }

  private static void addOptionKey(
    Map<String, Grant_Support_Option__mdt> optionsByUploadValue,
    String key,
    Grant_Support_Option__mdt option
  ) {
    if (!String.isBlank(key)) {
      optionsByUploadValue.put(normalizeUploadValue(key), option);
    }
  }

  private static String normalizeUploadValue(String value) {
    return String.isBlank(value)
      ? null
      : value.toLowerCase().replaceAll('[^a-z0-9]', '');
  }
}
