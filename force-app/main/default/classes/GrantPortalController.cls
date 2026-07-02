public without sharing class GrantPortalController {
  public String firstName { get; set; }
  public String lastName { get; set; }
  public String phone { get; set; }
  public String email { get; set; }
  public String mailingPostalCode { get; set; }
  public Decimal monthlyIncome { get; set; }
  public String supportOption { get; set; }
  public String reason { get; set; }

  public List<SelectOption> getSupportOptions() {
    List<SelectOption> options = new List<SelectOption>{
      new SelectOption('', '-- Select Support Option --')
    };

    for (
      GrantSupportOptionDTO option : GrantSupportOptionService.getActiveOptions()
    ) {
      options.add(
        new SelectOption(
          option.value,
          option.label +
            ' - SGD ' +
            option.monthlyAmount +
            ' per month for ' +
            option.durationMonths +
            ' months'
        )
      );
    }

    return options;
  }

  public PageReference submit() {
    GrantDTO request = new GrantDTO();
    request.firstName = firstName;
    request.lastName = lastName;
    request.phone = phone;
    request.email = email;
    request.mailingPostalCode = mailingPostalCode;
    request.monthlyIncome = monthlyIncome;
    request.supportOption = supportOption;
    request.reason = reason;

    try {
      Id applicationId = GrantApplicationService.submitApplication(request);
      ApexPages.addMessage(
        new ApexPages.Message(
          ApexPages.Severity.CONFIRM,
          'Application submitted. Reference: ' + applicationId
        )
      );
      clearForm();
    } catch (Exception exceptionRecord) {
      ApexPages.addMessage(
        new ApexPages.Message(
          ApexPages.Severity.ERROR,
          exceptionRecord.getMessage()
        )
      );
    }

    return null;
  }

  private void clearForm() {
    firstName = null;
    lastName = null;
    phone = null;
    email = null;
    mailingPostalCode = null;
    monthlyIncome = null;
    supportOption = null;
    reason = null;
  }
}
