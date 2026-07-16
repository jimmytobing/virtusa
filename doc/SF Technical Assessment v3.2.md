# Salesforce Technical Assessment v3.2

# Disclaimer

- This assignment is strictly used for official purposes and should not be reproduced in your personal capacity or shared with others.

- Your submission must be wholly your work and completed without any external help from other individuals. Any form of plagiarism will result in your assignment being forfeited, and your application will no longer be under consideration.

# Pre-requisites

1. Sign up or log in to your Salesforce Trailblazer account

2. Create a **new** Trailhead Playground developer edition account for you to implement your build via code

3. You may use Visual Studio Code IDE with Apex PMD extension for your assignment

**1\. Coding Assessment**

# Background

Agency X offers three support options of financial support for low-income individuals:

- Option 1: SGD 500 per month for 3 months
- Option 2: SGD 300 per month for 6 months
- Option 3: SGD 200 per month for 12 months

Individuals can submit their information and select their support option through Salesforce. They are also allowed to change their selected support option after their initial application.

# Objective

Your task is to develop a Salesforce Lightning Web Components (LWC) to capture the applicant's first name, last name, phone number, postal code, monthly income and the support options, as well as the back-end logic via Apex to handle monthly disbursements.

# Business Requirements

**User Story 1**  
As a Grant Applicant, I want to submit my application for financial support online so that I can be considered for financial support from Agency X.

Acceptance Criteria:

- Grant applicants can submit the online application form using Salesforce Experience Cloud Site

- Utilize LWC for the user interface of the online application form

- The online application form should include **mandatory** fields for providing personal information and specifying their monthly income they are applying for as below:

  - **Applicant First Name**
  - **Applicant Last Name**
  - **Phone** \- should be a valid Singapore phone number with this format: 65\<space\>6812\<space\>3456. Other formats shouldn’t be accepted
  - **Mailing Postal Code \-** should be 6 digit number only (e.g. 123456\)
  - **Monthly Income** \- should be a number representing the amount in SGD
  - **Support Option** \- the three available options as stated on the Background section

- Upon submission, the application should be processed to create new **Contact** in Salesforce if the provided phone number is not already associated with an existing contact

**User Story 2**  
As a Grant Administrator, I want the Grant Disbursed records under the Contact to be created after passing eligibility checks so that I can monitor the allocation of funds to ensure transparency and accountability.

Acceptance Criteria:

- The eligibility check should pass only if the applicant’s **Monthly Income** is less than SGD 2000

- Grant Disbursed records should be created based on the different options of support they chosen\* :

  - **Option One: SGD 500 for 3 months** \- If selected, 3 records should be created filling up each Grant Disbursed record based on the picklist selection with each record representing the disbursement for one month
  - **Option Two: SGD 300 for 6 months** \- If selected, 6 records should be created filling up each Grant Disbursed record based on the picklist selection with each record representing the disbursement for one month
  - **Option Three: SGD 200 for 12 months** \- If selected, 12 records should be created filling up each Grant Disbursed record based on the picklist selection with each record representing the disbursement for one month

- Each “Grant Disbursed” record should include these custom fields :

  - **Grant Applicant** (Contact Lookup) \- the contact record of the grant applicant
  - **Amount to be disbursed** (Currency) \- default to value selected on the support option chosen above
  - **Grant is disbursed?** (Checkbox) \- assume that the every grant will be disbursed on the Disbursed Date
  - **Disbursed Date** (Date) \- where the date to be disbursed is the 1st day of every month where the first month to be disbursed is the month after the submission date (e.g. If submission date \= 29 Feb 2024 and Support Option One is chosen, Disbursed Date to be on 1 Mar 2024, 1 Apr 2024, 1 May 2024\)

\*In future, Grant Administrator want the flexibility to add more options and/or edit existing options

**User Story 3**  
As a Grant Applicant, I want to update my application for financial support on the same application form so that I can get the right financial support from Agency X.

Acceptance Criteria:

- After submitting a request by using the same phone number as the existing contact, the information of the following fields of the existing contact should be updated accordingly.
  - **Applicant First Name**
  - **Applicant Last Name**
  - **Phone**
  - **Mailing Postal Code**
  - **Monthly Income**
  - **Support Option**

- If the applicant want to change the support option in the middle of an existing option, the following rules will be applied :
  - An applicant can change the support option provided the total disbursed amount is less than the total amount of the new option. On changing the support option, recalculate the remaining funds based on the new option. The remaining amount should be evenly distributed over the remaining months of the new option. For example, if an applicant shifts from Option One to Option Two after receiving two months of support, the remaining 800 will be divided over the next four months, providing SGD 200 per month.

  - An applicant cannot change their support option if the total disbursed amount is greater than the total amount of the new option.  
    For example, if someone tries to switch from Option Three to Option One after ten months, they won’t be able to change as the total amount received is SGD 2000, which is greater than the total amount of Option One support (SGD 1500). This invalid option would need to be handled appropriately.

**User Story 4**  
As a Grant Administrator, I want the flexibility to create the application record manually or to bulk upload multiple applications into Salesforce in one go so that I can quickly upload many grant applications into Salesforce.

Acceptance Criteria:

- You have the flexibility to utilize any of Salesforce's data upload tools.

- Uploading the [sample csv](https://docs.google.com/spreadsheets/d/1zAL85lSt5kj1hEcpt0bW7DHK798Noru6p9RwmLF_Qno/edit#gid=0) should not bypass any validation rules

- When all records are processed, the Contact records and the Grant Disbursed records should be created accordingly without any errors

- If a matching phone number is found, update the existing contact record with the latest information

#

# Evaluation Criteria

Experience Cloud:

- Demonstrates your understanding of Experience Cloud functionalities, such as creating and managing public-facing sites and exposing Salesforce functionality to external users

LWC Development:

- Able to develop the LWC component for the user interface and verify the data integrity

- Demonstrate skills on exception handling (e.g. missing billing country, invalid phone format, etc.). You should prevent online submission and display a user friendly error message. Salesforce administrators should have an easy way to update and manage these error messages.

- Adherence to LWC best practices

Apex Development :

- Demonstrates correctness and completeness of the user story solutions

- Demonstrate skills on exception handling (e.g. missing billing country, invalid phone format, etc.). You should prevent the trigger operation and display a user friendly error message. Salesforce administrators should have an easy way to update and manage these error messages.

- Adherence to Apex coding best practices and security guidelines in Apex development with a focus of code scalability
- Effectiveness of test coverage to validate **all** apex code to at least 90% test coverage

- Ensure all code is production ready

#

#

**2\. Scenario-based assessment**

You are tasked with architecting a Salesforce solution for a government agency that offers services related to citizen enquiries and feedback.

# Roles and Responsibilities

- **Branch Admin** \- Needs to monitor all incoming requests across various citizen contact channels within their division. They are not directly involved in case resolution but require a comprehensive overview for management and oversight purposes.

- **Supervisor** \- Oversees the agents, ensuring that they effectively address both enquiry and feedback cases, regardless of the communication channel.

- **Agent \-** Directly engages with citizens, addressing day-to-day enquiries and processing feedback received through any of the citizen contact channels.

# Case Management

**Enquiry Cases**: Includes handling citizen questions, concerns, or requests for information about the agency's services.

High level enquiry case process :

1. **Initiation** \- Citizens initiate queries via any of the available channels.
2. **Verification** \- Agents verify citizen’s details, primarily using the citizen's phone number or email against an external master data management system.
3. **Case Recording** \- Detailed enquiry information, along with any supporting documents e.g. photos, are recorded in the system.
4. **Case Assignment** \- The system assigns the case to an agent based on conditions such as expertise, language, workload, and availability.
5. **Resolution** \- Agents address the enquiry, potentially involving Supervisors for complex cases. For cases with existing solutions, agents to provide the relevant solution. Otherwise, agents are to develop and document down new solutions.
6. **Follow-Up** \- Regular follow-ups with the citizen are to be conducted until resolved fully.
7. **Closure** \- Once resolved, the case is closed with citizen’s confirmation.

**Feedback Cases**: Involves processing citizen’s feedback, complaints, or suggestions regarding the agency's services.

High level feedback case process :

1. **Receipt** \- Feedback is received through the designated channels.
2. **Recording** \- Feedback details are captured in the system, including the specific

   service or product it relates to.

3. **Analysis** \- Agents analyse the feedback to understand citizen’s satisfaction level and areas for improvement.
4. **Response** \- If necessary, agents respond to citizens.
5. **Reporting** \- Feedback is compiled for internal review, enabling improvements and strategic plannings.
6. **Evaluation** \- Supervisors review feedback handling process and outcomes to assess agent’s performance and citizen’s satisfaction level.

# Channels of Contact

- Citizens can submit cases directly through the agency’s website.
- Citizens can call in to report issues or ask questions.
- Citizens can get real-time assistance via the agency’s website or mobile app.
- Citizens can send inquiries or feedback via email.

# High Level Requirements

- The system should be capable of integrating with an external master data management system for citizen verification.
- Flexibility is required to adapt to changes.
- Data handling includes migration of 10 years’ data amounting to 6 million records and 100GB of files.
- Ability to manage 5,000 new cases and 100MB of file uploads daily.
- Implement Single Sign-On (SSO) using the existing Microsoft Active Directory.
- The system should enable Branch Admins to evaluate the performance of each agent, considering their effectiveness in handling cases across different channels of contact.

Your challenge is to design a solution that meets above business requirements, we will run through the architecture design solution during the interview, please be prepared to present and justify your design.

The solution should comprehensively address the following aspects, among others:

- Salesforce licensing, editions, features and any third-party tools
- System landscape diagram
- Business processes, e.g. user stories
- Integration considerations
- Data model considerations, e.g. Entity-Relationship Diagram (ERD), data sharing and security design
- Data migration plan

| _You may make reasonable assumptions for this section. Remember to state your assumption clearly._ |
| :------------------------------------------------------------------------------------------------: |

**3\. Submission**

# Coding Submission

Upon completion of assignment, kindly provide us the access to your Trailhead Playground Developer Org by creating a Salesforce user account with the follow details :

1. Email \= support@sfcoe.gov.sg
2. Username \= \<YourCompanyName\>.\<YourFirstName\>@govtech.coe.review  
   e.g. UniversalContainers.John@govtech.coe.review
3. Profile \= \`System Administrator\`
4. Do fill in the other mandatory fields e.g LastName, Alias

A verification email will be sent to the email address you specified above for review of your work. You may deactivate the account after completion of review.

# Scenario-based Submission

1. Present your solution in a suitable format e.g. PowerPoint

2. In your Salesforce environment, **upload** your solution design via Salesforce Files and share to the Salesforce user account in the coding submission step.

3. You will need to present your solution. Demonstration of your solution is optional.
