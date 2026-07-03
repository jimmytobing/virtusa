import { LightningElement, track, wire } from "lwc";

import submitApplication from "@salesforce/apex/GrantApplicationController.submitApplication";

import getActiveSupportOptions from "@salesforce/apex/GrantApplicationController.getActiveSupportOptions";
import getClientMessages from "@salesforce/apex/GrantExceptionService.getClientMessages";

import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class GrantApplicationForm extends LightningElement {
  firstName;
  lastName;
  phone;
  email;
  mailingPostalCode;
  monthlyIncome;
  supportOption;

  @track
  loading = false;

  supportOptionOptions = [];
  clientMessages = {};

  @wire(getActiveSupportOptions)
  wiredSupportOptions({ data, error }) {
    if (data) {
      this.supportOptionOptions = data.map((option) => ({
        label: `${option.label} - SGD ${option.monthlyAmount} per month for ${option.durationMonths} months`,
        value: option.value
      }));
    } else if (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: this.getErrorMessage(error),
          variant: "error"
        })
      );
    }
  }

  @wire(getClientMessages)
  wiredClientMessages({ data }) {
    if (data) {
      this.clientMessages = data;
    }
  }

  get phonePatternMessage() {
    return this.getClientMessage(
      "PHONE_INVALID",
      "Phone must use Singapore format 65 6812 3456."
    );
  }

  get postalCodePatternMessage() {
    return this.getClientMessage(
      "POSTAL_CODE_INVALID",
      "Mailing Postal Code must be a 6 digit number."
    );
  }

  handleInputChange(event) {
    const { name, value } = event.target;
    this[name] = name === "monthlyIncome" ? Number(value) : value;
  }

  async submitApplication() {
    if (!this.validateForm()) {
      return;
    }

    this.loading = true;

    try {
      const dto = {
        firstName: this.firstName,
        lastName: this.lastName,
        phone: this.phone,
        email: this.email,
        mailingPostalCode: this.mailingPostalCode,
        monthlyIncome: this.monthlyIncome,
        supportOption: this.supportOption
      };

      const applicationId = await submitApplication({
        request: dto
      });

      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",

          message: "Application requested [ Id: " + applicationId + " ]",

          variant: "success"
        })
      );
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",

          message: this.getErrorMessage(error),

          variant: "error"
        })
      );
    } finally {
      this.loading = false;
    }
  }

  getErrorMessage(error) {
    if (!error) {
      return this.getClientMessage(
        "UNEXPECTED_ERROR_NULL",
        "Unexpected error(null)."
      );
    }

    if (typeof error === "string") {
      return error;
    }

    if (error && error.body && error.body.message) {
      return error.body.message;
    }

    if (error && Array.isArray(error.body)) {
      return error.body.map((item) => item.message).join(", ");
    }

    if (error.body && error.body.pageErrors) {
      return error.body.pageErrors.map((item) => item.message).join(", ");
    }

    if (error.body && error.body.fieldErrors) {
      return Object.values(error.body.fieldErrors)
        .reduce((messages, fieldMessages) => messages.concat(fieldMessages), [])
        .map((item) => item.message)
        .join(", ");
    }

    if (error.body && typeof error.body === "string") {
      return error.body;
    }

    if (error.message) {
      return error.message;
    }

    return this.getClientMessage("UNEXPECTED_ERROR", "Unexpected error.");
  }

  getClientMessage(code, defaultMessage) {
    return this.clientMessages && this.clientMessages[code]
      ? this.clientMessages[code]
      : defaultMessage;
  }

  validateForm() {
    const inputs = [
      ...this.template.querySelectorAll("lightning-input, lightning-combobox")
    ];

    return inputs.reduce((validSoFar, input) => {
      input.reportValidity();
      return validSoFar && input.checkValidity();
    }, true);
  }
}
