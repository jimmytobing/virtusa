public without sharing class GrantDisbursementService {
  @InvocableMethod(
    label='Recalculate Grant Disbursements'
    description='Creates or recalculates Grant Disbursement records for Grant Applications.'
  )
  public static void recalculateDisbursementsFromFlow(
    List<FlowRequest> requests
  ) {
    if (requests == null || requests.isEmpty()) {
      return;
    }

    Set<Id> applicationIds = new Set<Id>();

    for (FlowRequest request : requests) {
      if (request != null && request.grantApplicationId != null) {
        applicationIds.add(request.grantApplicationId);
      }
    }

    recalculateForApplicationIds(applicationIds);
  }

  public static void recalculateForApplicationIds(Set<Id> applicationIds) {
    if (applicationIds == null || applicationIds.isEmpty()) {
      return;
    }

    Map<String, Grant_Support_Option__mdt> optionsByDeveloperName = getActiveOptionsByDeveloperName();
    Map<Id, Grant_Support_Option__mdt> optionsByApplicationId = new Map<Id, Grant_Support_Option__mdt>();
    List<Grant_Application__c> applicationsToUpdate = new List<Grant_Application__c>();

    Decimal incomeThreshold = getActiveIncomeThreshold();
    Set<Id> ineligibleApplicationIds = new Set<Id>();

    for (Grant_Application__c application : [
      SELECT
        Id,
        Grant_Type__c,
        Requested_Amount__c,
        Applicant__r.Monthly_Income__c
      FROM Grant_Application__c
      WHERE Id IN :applicationIds
    ]) {
      String optionName = application.Grant_Type__c;

      if (String.isBlank(optionName)) {
        continue;
      }

      Grant_Support_Option__mdt option = optionsByDeveloperName.get(optionName);

      if (option != null) {
        Decimal optionTotal =
          option.Monthly_Amount__c * option.Duration_Months__c;

        if (
          application.Grant_Type__c != option.MasterLabel ||
          application.Requested_Amount__c != optionTotal
        ) {
          applicationsToUpdate.add(
            new Grant_Application__c(
              Id = application.Id,
              Grant_Type__c = option.MasterLabel,
              Requested_Amount__c = optionTotal
            )
          );
        }

        if (!isApplicantIncomeEligible(application, incomeThreshold)) {
          ineligibleApplicationIds.add(application.Id);
          continue;
        }

        optionsByApplicationId.put(application.Id, option);
      }
    }

    clearUndisbursedRecords(ineligibleApplicationIds);
    recalculateForApplications(optionsByApplicationId);

    if (!applicationsToUpdate.isEmpty()) {
      update applicationsToUpdate;
    }
  }

  private static Boolean isApplicantIncomeEligible(
    Grant_Application__c application,
    Decimal incomeThreshold
  ) {
    if (incomeThreshold == null) {
      return true;
    }

    Decimal monthlyIncome = application.Applicant__r == null
      ? null
      : application.Applicant__r.Monthly_Income__c;

    return monthlyIncome == null || monthlyIncome <= incomeThreshold;
  }

  private static Decimal getActiveIncomeThreshold() {
    Grant_Configuration__mdt selectedConfiguration;

    for (
      Grant_Configuration__mdt configuration : GrantConfigurationRepository.getActiveConfigurations()
    ) {
      if (configuration.Income_Threshold__c == null) {
        continue;
      }

      if (
        selectedConfiguration == null ||
        configuration.Priority__c < selectedConfiguration.Priority__c
      ) {
        selectedConfiguration = configuration;
      }
    }

    return selectedConfiguration == null
      ? null
      : selectedConfiguration.Income_Threshold__c;
  }

  private static void clearUndisbursedRecords(Set<Id> applicationIds) {
    if (applicationIds == null || applicationIds.isEmpty()) {
      return;
    }

    List<Grant_Disbursement__c> disbursementsToDelete = [
      SELECT Id
      FROM Grant_Disbursement__c
      WHERE
        Grant_Applicantion__c IN :applicationIds
        AND Grant_is_disbursed__c = FALSE
    ];

    if (!disbursementsToDelete.isEmpty()) {
      delete disbursementsToDelete;
    }
  }

  public static void clearCompletedApplicationReferences(
    Set<Id> applicationIds
  ) {
    if (applicationIds == null || applicationIds.isEmpty()) {
      return;
    }

    Set<Id> referencedApplicationIds = new Set<Id>();

    for (Contact applicant : [
      SELECT Grant_Application__c
      FROM Contact
      WHERE Grant_Application__c IN :applicationIds
    ]) {
      referencedApplicationIds.add(applicant.Grant_Application__c);
    }

    if (referencedApplicationIds.isEmpty()) {
      return;
    }

    Set<Id> applicationsWithDisbursements = new Set<Id>();
    Set<Id> incompleteApplicationIds = new Set<Id>();

    for (Grant_Disbursement__c disbursement : [
      SELECT Grant_Applicantion__c, Grant_is_disbursed__c
      FROM Grant_Disbursement__c
      WHERE Grant_Applicantion__c IN :referencedApplicationIds
    ]) {
      applicationsWithDisbursements.add(disbursement.Grant_Applicantion__c);

      if (disbursement.Grant_is_disbursed__c != true) {
        incompleteApplicationIds.add(disbursement.Grant_Applicantion__c);
      }
    }

    List<Contact> applicantsToClear = new List<Contact>();

    for (Contact applicant : [
      SELECT Id, Grant_Application__c
      FROM Contact
      WHERE Grant_Application__c IN :referencedApplicationIds
    ]) {
      if (
        applicationsWithDisbursements.contains(
          applicant.Grant_Application__c
        ) && !incompleteApplicationIds.contains(applicant.Grant_Application__c)
      ) {
        applicantsToClear.add(
          new Contact(Id = applicant.Id, Grant_Application__c = null)
        );
      }
    }

    if (!applicantsToClear.isEmpty()) {
      update applicantsToClear;
    }
  }

  private static void recalculateForApplications(
    Map<Id, Grant_Support_Option__mdt> optionsByApplicationId
  ) {
    if (optionsByApplicationId == null || optionsByApplicationId.isEmpty()) {
      return;
    }

    Map<Id, List<Grant_Disbursement__c>> disbursementsByApplicationId = new Map<Id, List<Grant_Disbursement__c>>();

    for (Grant_Disbursement__c disbursement : [
      SELECT
        Id,
        Grant_Applicantion__c,
        Amount_to_be_disbursed__c,
        Grant_is_disbursed__c,
        Disbursed_Date__c
      FROM Grant_Disbursement__c
      WHERE Grant_Applicantion__c IN :optionsByApplicationId.keySet()
      ORDER BY Disbursed_Date__c
    ]) {
      if (
        !disbursementsByApplicationId.containsKey(
          disbursement.Grant_Applicantion__c
        )
      ) {
        disbursementsByApplicationId.put(
          disbursement.Grant_Applicantion__c,
          new List<Grant_Disbursement__c>()
        );
      }

      disbursementsByApplicationId.get(disbursement.Grant_Applicantion__c)
        .add(disbursement);
    }

    List<Grant_Disbursement__c> disbursementsToDelete = new List<Grant_Disbursement__c>();
    List<Grant_Disbursement__c> disbursementsToInsert = new List<Grant_Disbursement__c>();
    for (Id applicationId : optionsByApplicationId.keySet()) {
      Grant_Support_Option__mdt option = optionsByApplicationId.get(
        applicationId
      );
      List<Grant_Disbursement__c> existingDisbursements = disbursementsByApplicationId.containsKey(
          applicationId
        )
        ? disbursementsByApplicationId.get(applicationId)
        : new List<Grant_Disbursement__c>();

      Decimal totalReceived = 0;
      Integer receivedMonths = 0;

      for (Grant_Disbursement__c disbursement : existingDisbursements) {
        Boolean hasBeenDisbursed = disbursement.Grant_is_disbursed__c == true;

        if (hasBeenDisbursed) {
          totalReceived += disbursement.Amount_to_be_disbursed__c;
          receivedMonths++;
        } else {
          disbursementsToDelete.add(disbursement);
        }
      }

      Decimal newTotalAmount =
        option.Monthly_Amount__c * option.Duration_Months__c;

      if (totalReceived > newTotalAmount) {
        throw new GrantException(
          GrantExceptionService.getMessage(
            GrantExceptionService.DISBURSEMENT_OPTION_TOTAL_TOO_LOW,
            'Support Option cannot be changed because the total disbursed amount is greater than the new option total.'
          )
        );
      }

      Integer durationMonths = option.Duration_Months__c.intValue();
      Integer remainingMonths = durationMonths - receivedMonths;
      Decimal remainingAmount = newTotalAmount - totalReceived;

      if (remainingAmount > 0 && remainingMonths <= 0) {
        throw new GrantException(
          GrantExceptionService.getMessage(
            GrantExceptionService.DISBURSEMENT_OPTION_NO_MONTHS,
            'Support Option cannot be changed because there are no remaining months available.'
          )
        );
      }

      if (remainingAmount <= 0) {
        continue;
      }

      Decimal monthlyAmount = remainingAmount / remainingMonths;
      Date today = Date.today();
      Date disbursementDate = firstDayOfNextMonth(today);

      for (
        Integer monthNumber = 1; monthNumber <= remainingMonths; monthNumber++
      ) {
        disbursementsToInsert.add(
          new Grant_Disbursement__c(
            Grant_Applicantion__c = applicationId,
            Amount_to_be_disbursed__c = monthlyAmount,
            Grant_is_disbursed__c = false,
            Disbursed_Date__c = disbursementDate.addMonths(monthNumber - 1),
            Support_Option__c = option.MasterLabel,
            Sequence_Number__c = receivedMonths + monthNumber
          )
        );
      }
    }

    if (!disbursementsToDelete.isEmpty()) {
      delete disbursementsToDelete;
    }

    if (!disbursementsToInsert.isEmpty()) {
      insert disbursementsToInsert;
    }
  }

  private static Map<String, Grant_Support_Option__mdt> getActiveOptionsByDeveloperName() {
    Map<String, Grant_Support_Option__mdt> optionsByDeveloperName = new Map<String, Grant_Support_Option__mdt>();

    for (Grant_Support_Option__mdt option : [
      SELECT
        DeveloperName,
        MasterLabel,
        Monthly_Amount__c,
        Duration_Months__c,
        Active__c
      FROM Grant_Support_Option__mdt
      WHERE Active__c = TRUE
    ]) {
      optionsByDeveloperName.put(option.DeveloperName, option);
      optionsByDeveloperName.put(option.MasterLabel, option);
    }

    return optionsByDeveloperName;
  }

  private static Date firstDayOfNextMonth(Date sourceDate) {
    return Date.newInstance(sourceDate.year(), sourceDate.month(), 1)
      .addMonths(1);
  }

  public class FlowRequest {
    @InvocableVariable(
      label='Grant Application Id'
      description='The Grant Application record to create or recalculate disbursements for.'
      required=true
    )
    public Id grantApplicationId;
  }
}
