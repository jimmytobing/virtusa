# Solution Architecture Design Document (SADD) - Task 2

## 1. Executive Summary

This document defines the Salesforce solution architecture for a government agency that manages citizen enquiries and feedback across website, phone, real-time assistance, mobile app, and email channels.

The recommended solution uses Salesforce Service Cloud as the primary case-management platform, Experience Cloud for citizen-facing digital access, Omni-Channel for work assignment, Salesforce Knowledge for reusable answers, Salesforce Files for supporting photos/documents, Reports and Dashboards for operational oversight, and Microsoft Active Directory / Microsoft Entra ID for internal Single Sign-On.

This SADD only addresses the Task 2 requirement in `SF Technical Assessment (task2).md`. Processes outside citizen enquiry and feedback case management are excluded.

## 2. Requirement Coverage

[Requirement Coverage Map](<../puml task2/10. Requirement Coverage Map.puml>)

| Assessment Requirement                                      | Design Response                                                                                                               |
| ----------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Integrate with external MDM for citizen verification        | Citizen verification service through Named Credentials/API Gateway; verify by phone or email.                                 |
| Flexibility to adapt to changes                             | Case record types, page layouts, queues, Omni-Channel, Flow, Custom Metadata, Knowledge, and configurable dashboards.         |
| Migrate 10 years / 6M records / 100GB files                 | Staged migration with profiling, cleansing, staging, Bulk API, file strategy, reconciliation, and cutover.                    |
| Manage 5,000 new cases and 100MB uploads daily              | Standard Case and Salesforce Files with bulk-safe automation, storage forecasting, archive strategy, and selective reporting. |
| Implement SSO using Microsoft Active Directory              | Salesforce SSO through Microsoft AD / Entra ID using SAML or OpenID Connect.                                                  |
| Branch Admin evaluates agent performance across channels    | Division-level dashboards for volume, SLA, backlog, satisfaction, channel mix, and agent effectiveness.                       |
| Salesforce licensing, editions, features, third-party tools | Covered in Section 4.                                                                                                         |
| System landscape diagram                                    | Covered in Section 5.                                                                                                         |
| Business processes and user stories                         | Covered in Section 6.                                                                                                         |
| Integration considerations                                  | Covered in Section 9.                                                                                                         |
| Data model, sharing, and security design                    | Covered in Sections 7 and 8.                                                                                                  |
| Data migration plan                                         | Covered in Section 11.                                                                                                        |

## 3. Scope, Assumptions, and Constraints

### 3.1 In Scope

| Area                 | Scope                                                                                                          |
| -------------------- | -------------------------------------------------------------------------------------------------------------- |
| Citizen enquiries    | Capture, verify, assign, resolve, follow up, and close enquiry Cases.                                          |
| Citizen feedback     | Capture complaints, suggestions, satisfaction level, analysis, response, reporting, and supervisor evaluation. |
| Channels             | Website, phone, live chat / mobile real-time assistance, and email.                                            |
| Internal roles       | Branch Admin, Supervisor, and Agent.                                                                           |
| Citizen verification | Integration design with external Master Data Management (MDM) using phone or email.                            |
| Assignment           | Routing by expertise, language, workload, availability, priority, channel, and division.                       |
| Reporting            | Branch Admin and Supervisor dashboards for volume, SLA, backlog, satisfaction, channel, and agent performance. |
| Security             | Role hierarchy, permission sets, sharing, queue access, field-level security, SSO, and integration users.      |
| Migration            | Plan for 10 years of historical data, approximately 6 million records, and 100GB of files.                     |
| Daily growth         | Design for 5,000 new Cases and 100MB file uploads per day.                                                     |

### 3.2 Out of Scope

| Area                          | Reason                                                                                |
| ----------------------------- | ------------------------------------------------------------------------------------- |
| Task 1 assessment processes   | Not part of the citizen enquiry and feedback requirement.                             |
| Payment gateway               | Not required for enquiry and feedback case management.                                |
| Non-citizen CRM domains       | This design focuses on citizen service requests only.                                 |
| Detailed vendor procurement   | Product recommendations are architectural guidance and require commercial validation. |
| Physical network provisioning | Salesforce and identity/network setup are covered at design level only.               |

### 3.3 Assumptions

| ID   | Assumption                                                                                             |
| ---- | ------------------------------------------------------------------------------------------------------ |
| A-01 | Internal agency users authenticate through Microsoft AD / Microsoft Entra ID.                          |
| A-02 | The external MDM exposes secure APIs for citizen lookup by phone and email.                            |
| A-03 | Enquiry and feedback are implemented as Salesforce Case record types.                                  |
| A-04 | The agency has divisions or branches that can be mapped to roles, queues, public groups, and reports.  |
| A-05 | Historical source records contain enough identifiers to support migration reconciliation.              |
| A-06 | File storage strategy will be validated against Salesforce storage limits before production migration. |

### 3.4 Constraints

| ID   | Constraint                                                                                    |
| ---- | --------------------------------------------------------------------------------------------- |
| C-01 | Salesforce governor limits apply to Apex, Flow, and integration transactions.                 |
| C-02 | MDM response time determines whether verification can be fully synchronous.                   |
| C-03 | Salesforce data/file storage capacity must be sized for historical and daily growth.          |
| C-04 | Security design must protect citizen personally identifiable information.                     |
| C-05 | Migration must preserve auditability, ownership, file links, and record-count reconciliation. |

## 4. Salesforce Product and Capability Selection

| Requirement Area       | Recommended Capability                                                  | Rationale                                                                                                   |
| ---------------------- | ----------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Internal case handling | Service Cloud Enterprise or higher                                      | Provides Case, Service Console, queues, automation, reporting, and service process foundation.              |
| Public-sector hosting  | Salesforce Government Cloud or equivalent regulated option, if mandated | Supports public-sector compliance and data residency requirements when required by policy.                  |
| Citizen web access     | Experience Cloud                                                        | Supports case submission, status visibility, file upload, and authenticated/public citizen access patterns. |
| Website intake         | Experience Cloud LWC, Web-to-Case, or API-backed form                   | Supports structured submission, validation, attachments, and channel tracking.                              |
| Phone intake           | Open CTI or Service Cloud Voice-compatible integration                  | Enables screen-pop, call logging, and phone-origin Case creation.                                           |
| Real-time assistance   | Messaging, Chat, or Digital Engagement                                  | Supports real-time citizen assistance from web or mobile and routes work to agents.                         |
| Email intake           | Email-to-Case                                                           | Converts emails into Cases and maintains email thread history.                                              |
| Work assignment        | Omni-Channel                                                            | Routes by queue, skill, language, capacity, workload, and availability.                                     |
| Reusable answers       | Salesforce Knowledge                                                    | Provides approved solutions for recurring enquiries and supports draft-to-approval lifecycle.               |
| SLA management         | Entitlements and Milestones                                             | Tracks first response, follow-up, escalation, and resolution commitments.                                   |
| Reporting              | Reports and Dashboards; CRM Analytics if needed                         | Meets Branch Admin and Supervisor monitoring needs.                                                         |
| Identity               | Salesforce SSO with Microsoft AD / Entra ID through SAML or OIDC        | Reuses the existing identity provider and centralizes access management.                                    |
| Integration            | Named Credentials, External Credentials, Apex, API Gateway or MuleSoft  | Secures MDM and channel integrations without hardcoded credentials.                                         |
| Migration              | Bulk API 2.0, ETL tooling, Data Loader, staging database                | Supports controlled high-volume migration and reconciliation.                                               |
| Backup/archive         | Salesforce Backup or approved AppExchange backup/archive product        | Reduces risk for long retention, files, and operational recovery.                                           |

## 5. Target Solution Architecture

[High-Level Solution Architecture](<../puml task1/1.3 High-Level Solution Architecture.puml>)

[Layered Architecture](<../puml task1/1.5 Layered Architecture.puml>)

[Multi-Channel Case Intake Architecture](<../puml task2/3. Multi-Channel Case Intake Architecture.puml>)

### 5.1 Architecture Overview

Citizens interact with the agency through supported contact channels. Salesforce normalizes those interactions into Case records with consistent channel, record type, priority, service division, citizen identity, SLA, and ownership attributes.

Agents use Service Console to verify citizens, work Cases, review files, search Knowledge, respond to citizens, and complete follow-up actions. Supervisors manage queue health, escalations, SLA risk, and handling quality. Branch Admins monitor division-level demand and performance without directly resolving Cases.

MDM integration verifies citizens by phone or email. Microsoft AD / Entra ID authenticates internal users and maps access through profiles, permission sets, roles, groups, queues, and sharing rules.

## 6. Business Process Architecture

[Citizen Case Management Lifecycle](<../puml task1/8.1 Citizen Case Management Lifecycle.puml>)

[Business Flow](<../puml task1/1.8 Business Flow.puml>)

[Case Routing Decision Model](<../puml task2/4. Case Routing Decision Model.puml>)

[Knowledge Management Lifecycle](<../puml task2/5. Knowledge Management Lifecycle.puml>)

### 6.1 Enquiry Case Process

| Step               | Salesforce Design                                                                                                        |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| Initiation         | Citizen creates an enquiry through website, phone, chat/mobile, or email.                                                |
| Verification       | Agent or automated integration verifies phone/email against MDM and links the Case to Contact.                           |
| Case Recording     | Case captures subject, description, origin, service category, division, priority, language, and supporting files/photos. |
| Assignment         | Omni-Channel assigns work using expertise, language, workload, availability, priority, channel, and division.            |
| Resolution         | Agent searches Knowledge. Existing approved articles are used when available; new solutions are documented when needed.  |
| Supervisor Support | Complex, policy-sensitive, aged, or SLA-risk Cases are escalated to Supervisor.                                          |
| Follow-Up          | Follow-up tasks and milestones remain active until the citizen confirms resolution.                                      |
| Closure            | Case is closed with resolution summary, closure confirmation, and audit trail.                                           |

### 6.2 Feedback Case Process

| Step       | Salesforce Design                                                                                        |
| ---------- | -------------------------------------------------------------------------------------------------------- |
| Receipt    | Feedback, complaint, or suggestion is received through a supported channel.                              |
| Recording  | Case record type `Feedback` captures service area, satisfaction level, category, severity, and evidence. |
| Analysis   | Agent assesses root cause, impact, improvement area, and response requirement.                           |
| Response   | Agent responds when required and records communication history.                                          |
| Reporting  | Feedback is grouped by service, branch, channel, severity, trend, and satisfaction level.                |
| Evaluation | Supervisor reviews handling quality, SLA performance, agent outcome, and citizen satisfaction.           |

### 6.3 User Stories

| Persona      | User Story                                                                                                                              |
| ------------ | --------------------------------------------------------------------------------------------------------------------------------------- |
| Citizen      | As a citizen, I want to submit enquiries or feedback through my preferred channel so that I can receive help without visiting a branch. |
| Citizen      | As a citizen, I want to upload supporting photos or documents so that the agency can understand my request.                             |
| Agent        | As an agent, I want citizen verification by phone or email so that I handle the correct citizen record.                                 |
| Agent        | As an agent, I want cases routed by expertise, language, workload, and availability so that work is distributed fairly.                 |
| Agent        | As an agent, I want to use approved Knowledge articles so that responses are consistent.                                                |
| Agent        | As an agent, I want to document a new solution when no existing answer exists so that similar enquiries can be resolved faster.         |
| Supervisor   | As a supervisor, I want to monitor queue backlog, escalations, and SLA risk so that I can intervene quickly.                            |
| Supervisor   | As a supervisor, I want to evaluate feedback handling and agent outcomes so that service quality improves.                              |
| Branch Admin | As a Branch Admin, I want dashboards by division, channel, case type, and agent so that I can monitor operational performance.          |

## 7. Application Architecture

[Application Layer Overview](<../puml task1/3.2 Application Layer Overview.puml>)

[Application Flow](<../puml task1/3.4 Application Flow.puml>)

[Service Layer Design](<../puml task1/1.7 Service Layer Design.puml>)

[Service Interaction Diagram](<../puml task1/3.7 Service Interaction Diagram.puml>)

[Error Handling Strategy](<../puml task1/3.8 Error Handling Strategy.puml>)

[Configurable Business Rules](<../puml task1/2.9 Configurable Business Rules.puml>)

### 7.1 Declarative-First Approach

| Requirement                | Technology                                           | Rationale                                                        |
| -------------------------- | ---------------------------------------------------- | ---------------------------------------------------------------- |
| Case creation and updates  | Flow, Case assignment, Email-to-Case, Web/API intake | Standard Salesforce service capabilities.                        |
| Routing                    | Omni-Channel, queues, skills, capacity               | Native routing by availability and workload.                     |
| SLA                        | Entitlements and Milestones                          | Standard response and resolution tracking.                       |
| Notifications              | Flow and email templates                             | Administrator maintainable.                                      |
| Knowledge lifecycle        | Salesforce Knowledge approval process                | Standard article governance.                                     |
| MDM verification           | Apex / middleware integration                        | Requires external callout, mapping, timeout, and retry handling. |
| Migration                  | Bulk API / ETL                                       | High-volume load and reconciliation.                             |
| Operational error tracking | Custom object and dashboards                         | Required for support visibility.                                 |

### 7.2 Service Responsibilities

| Service                        | Responsibility                                                                  |
| ------------------------------ | ------------------------------------------------------------------------------- |
| CaseIntakeService              | Normalize website, phone, chat/mobile, and email submissions into Case records. |
| CitizenVerificationService     | Verify phone/email against MDM and update Contact/Case verification fields.     |
| CaseRoutingService             | Prepare routing attributes used by Omni-Channel and queues.                     |
| CaseLifecycleService           | Enforce lifecycle transitions, closure validations, and follow-up requirements. |
| FeedbackAnalysisService        | Classify feedback, satisfaction, severity, and improvement area.                |
| KnowledgeSuggestionService     | Suggest existing articles and create draft article candidates when needed.      |
| IntegrationErrorService        | Capture MDM/channel/file failures and retry status.                             |
| MigrationReconciliationService | Track migration batches, counts, file links, and exception summaries.           |

## 8. Data Architecture

[Entity Relationship Diagram](<../puml task1/2.2 Entity Relationship Diagram.puml>)

[Object Relationships](<../puml task1/2.5 Object Relationships.puml>)

[Case Lifecycle](<../puml task1/2.6 Application Lifecycle.puml>)

[Feedback Review Lifecycle](<../puml task1/2.7 Feedback Case Lifecycle.puml>)

### 8.1 Core Data Model

| Object                               | Purpose                                                                                   |
| ------------------------------------ | ----------------------------------------------------------------------------------------- |
| Account                              | Optional household, organization, or agency account grouping where required.              |
| Contact                              | Citizen master profile linked to verified phone/email and MDM reference.                  |
| Case                                 | Primary enquiry and feedback transaction record.                                          |
| Case Record Type                     | Separates Enquiry and Feedback lifecycle, page layout, fields, and validation.            |
| Service_Division__c                  | Branch/division scope for reporting, queues, ownership, and sharing.                      |
| User                                 | Branch Admin, Supervisor, Agent, integration user, and migration user.                    |
| Group / Queue                        | Work queues for triage, division assignment, and escalation.                              |
| Knowledge__kav                       | Approved solutions and draft knowledge candidates.                                        |
| ContentVersion / ContentDocumentLink | Supporting photos and documents attached to Cases.                                        |
| CaseMilestone                        | SLA tracking for response, follow-up, and resolution.                                     |
| Integration_Error__c                 | Operational tracking for failed MDM, channel, or file-processing transactions.            |
| Migration_Batch__c                   | Migration batch tracking and reconciliation summary.                                      |
| Case_Routing_Rule__mdt               | Configurable routing attributes such as channel, skill, language, priority, and division. |

### 8.2 Recommended Case Fields

| Field                          | Purpose                                                                                         |
| ------------------------------ | ----------------------------------------------------------------------------------------------- |
| RecordTypeId                   | Enquiry or Feedback.                                                                            |
| Origin                         | Website, Phone, Chat, Mobile App, or Email.                                                     |
| Status                         | New, Verification Pending, Assigned, In Progress, Pending Citizen, Escalated, Resolved, Closed. |
| Priority                       | Standard Salesforce priority plus agency-specific severity mapping if required.                 |
| Service_Division__c            | Branch or division scope.                                                                       |
| Service_Category__c            | Agency service/product area.                                                                    |
| Language__c                    | Preferred language for routing.                                                                 |
| Citizen_Verification_Status__c | Verified, Not Found, Manual Review, Failed.                                                     |
| MDM_Verification_Id__c         | External verification reference.                                                                |
| Satisfaction_Level__c          | Feedback satisfaction indicator.                                                                |
| Improvement_Area__c            | Feedback classification for trend reporting.                                                    |
| Resolution_Summary__c          | Required before closure.                                                                        |
| Citizen_Confirmed_Closure__c   | Confirms citizen acceptance for enquiry closure.                                                |
| Follow_Up_Date__c              | Drives follow-up tasks and overdue reporting.                                                   |

## 9. Integration Architecture

[Citizen Verification Integration Pattern](<../puml task2/8. Citizen Verification Integration Pattern.puml>)

[Citizen Verification Flow](<../puml task1/3.9 Contact Matching Flow.puml>)

[Retry Strategy](<../puml task1/7.4 Retry Strategy.puml>)

### 9.1 MDM Verification

MDM verification is required during intake and case handling. Salesforce sends phone or email to the external MDM through a secured integration layer and receives citizen match status, citizen identifier, and profile attributes required for case servicing.

| Design Area       | Decision                                                                                            |
| ----------------- | --------------------------------------------------------------------------------------------------- |
| Integration style | Synchronous lookup when MDM response time is acceptable; asynchronous fallback when unavailable.    |
| Security          | Named Credentials and External Credentials, or approved middleware credential vault.                |
| Transport         | REST API through API Gateway, MuleSoft, or existing enterprise middleware.                          |
| Error handling    | Failed verification is logged to `Integration_Error__c`; Case moves to Manual Review when required. |
| Retry             | Retry only transient failures and cap retry attempts to avoid loops.                                |
| Data protection   | Store only required MDM response data in Salesforce.                                                |

### 9.2 Channel Integrations

| Channel     | Design                                                                                             |
| ----------- | -------------------------------------------------------------------------------------------------- |
| Website     | Experience Cloud/LWC or API-backed case intake with validation, file controls, and bot protection. |
| Phone       | CTI or Service Cloud Voice-compatible adapter for screen-pop, call log, and Case creation.         |
| Chat/Mobile | Messaging, Chat, or Digital Engagement routed through Omni-Channel.                                |
| Email       | Email-to-Case with routing addresses, thread identifiers, auto-response, and spam controls.        |
| Files       | Salesforce Files with file type/size validation and malware scanning where required by policy.     |

## 10. Security, Access, and Identity

[Role-Based Access and Visibility Model](<../puml task2/1. Role-Based Access and Visibility Model.puml>)

[SSO Authentication Flow with Microsoft Active Directory](<../puml task2/2. SSO Authentication Flow with Microsoft Active Directory.puml>)

### 10.1 Access Model

| Role             | Access Design                                                                                                    |
| ---------------- | ---------------------------------------------------------------------------------------------------------------- |
| Branch Admin     | Read-only visibility to Cases, dashboards, and reports for assigned division. No case resolution responsibility. |
| Supervisor       | Read/write access to team Cases, escalation queues, feedback evaluation, and performance dashboards.             |
| Agent            | Read/write access to owned Cases, assigned queue Cases, required Contact details, Knowledge, and linked Files.   |
| Citizen          | Access only to own submitted Cases through Experience Cloud when authenticated access is enabled.                |
| Integration User | API-only least privilege access for MDM, channel, and migration integrations.                                    |
| Migration User   | Temporary least privilege access for historical data load and reconciliation.                                    |

### 10.2 Security Controls

| Control              | Design                                                                                   |
| -------------------- | ---------------------------------------------------------------------------------------- |
| OWD                  | Set Case to Private unless the final branch model supports safe broader visibility.      |
| Role hierarchy       | Align to branch/division and service management structure.                               |
| Queues               | Separate triage, division, skill, and escalation ownership.                              |
| Sharing rules        | Criteria-based sharing for division-level Branch Admin and Supervisor visibility.        |
| Restriction rules    | Use where needed to prevent cross-division access.                                       |
| Permission sets      | Agent, Supervisor, Branch Admin, Integration User, Migration User.                       |
| Field-Level Security | Protect sensitive citizen information and internal evaluation fields.                    |
| Platform Encryption  | Recommended for sensitive personally identifiable information if compliance requires it. |
| Event Monitoring     | Recommended when audit and security monitoring requirements are high.                    |
| SSO                  | Microsoft AD / Entra ID through SAML or OpenID Connect.                                  |

## 11. Data Migration and Large Volume Strategy

[Large Data Volume and File Storage Strategy](<../puml task2/6. Large Data Volume and File Storage Strategy.puml>)

[Historical Case Data Migration Plan](<../puml task1/8.2 Historical Case Data Migration Plan.puml>)

The migration scope includes 10 years of historical records, approximately 6 million records, and 100GB of files.

| Phase      | Activity                                                                                                                                                   |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Discovery  | Identify source systems, record counts, file stores, retention rules, ownership, and branch mappings.                                                      |
| Profiling  | Analyze duplicates, missing phone/email, invalid identifiers, orphan files, and channel gaps.                                                              |
| Mapping    | Map citizens to Contact, service requests to Case, files to Salesforce Files or external archive links, users to owners, and branches to Service Division. |
| Cleansing  | Standardize phone/email, deduplicate citizens, normalize categories, and define exception handling.                                                        |
| Pilot Load | Load representative data, validate transformations, reconcile counts, verify ownership and file links.                                                     |
| Full Load  | Use Bulk API 2.0 or ETL tooling with controlled batches and `Migration_Batch__c` tracking.                                                                 |
| File Load  | Load into Salesforce Files when storage/compliance allows; otherwise use approved external archive links.                                                  |
| Delta Load | Freeze or limit legacy writes, migrate final changes, and reconcile before go-live.                                                                        |
| Validation | Reconcile counts, file links, sharing, audit fields, reports, and sample citizen histories.                                                                |
| Cutover    | Switch channels to Salesforce, monitor exceptions, and retain rollback checkpoints until accepted.                                                         |

### 11.1 Large Volume Design

| Concern                | Design                                                                         |
| ---------------------- | ------------------------------------------------------------------------------ |
| 6M historical records  | Use external IDs, selective indexes, ownership mapping, and Bulk API batching. |
| 100GB historical files | Forecast storage and consider external archive links for older files.          |
| 5,000 daily Cases      | Keep automation bulk-safe and avoid excessive synchronous callouts.            |
| 100MB daily uploads    | Monitor file storage growth and retention/archive policies.                    |
| Reporting performance  | Use selective filters by date, division, record type, and status.              |

## 12. Reporting, SLA, and Performance Evaluation

[Operational Monitoring and SLA Management](<../puml task2/7. Operational Monitoring and SLA Management.puml>)

[Case Analytics Model](<../puml task2/9. Case Analytics Model.puml>)

[Agent Performance Evaluation Model](<../puml task2/11. Agent Performance Evaluation Model.puml>)

### 12.1 Branch Admin Dashboard

| KPI                                             | Purpose                                                   |
| ----------------------------------------------- | --------------------------------------------------------- |
| New Cases by channel, division, and record type | Monitor demand across contact channels.                   |
| Open backlog by age and priority                | Identify operational pressure.                            |
| SLA breach count and rate                       | Evaluate service performance.                             |
| Average first response time                     | Measure responsiveness.                                   |
| Average resolution time                         | Measure closure efficiency.                               |
| Agent case volume and closure rate              | Evaluate agent effectiveness.                             |
| Reopened case rate                              | Identify quality or premature closure issues.             |
| Feedback satisfaction trend                     | Track citizen satisfaction and service improvement areas. |

### 12.2 Supervisor Dashboard

| KPI                             | Purpose                                          |
| ------------------------------- | ------------------------------------------------ |
| Queue backlog and aging         | Manage daily workload.                           |
| Escalated cases                 | Focus supervisor intervention.                   |
| SLA at risk                     | Prevent breaches.                                |
| Agent workload and availability | Balance assignments.                             |
| Knowledge article usage         | Improve response consistency.                    |
| Feedback handling outcome       | Evaluate agent quality and citizen satisfaction. |

## 13. Non-Functional Requirements

| Area            | Design Response                                                                                       |
| --------------- | ----------------------------------------------------------------------------------------------------- |
| Scalability     | Standard Case, Omni-Channel, bulk-safe Flow/Apex, selective reports, and archive strategy.            |
| Flexibility     | Record types, page layouts, Flow, Custom Metadata, queues, and Knowledge allow process changes.       |
| Security        | SSO, least privilege, sharing, FLS, encryption where required, and audit monitoring.                  |
| Reliability     | Retry strategy, manual verification fallback, Integration Error tracking, and operational dashboards. |
| Maintainability | Standard Service Cloud capabilities are preferred before custom code.                                 |
| Performance     | Avoid unnecessary synchronous processing; use asynchronous retries for slow external systems.         |
| Availability    | Salesforce platform resilience with controlled handling of MDM/channel outages.                       |
| Compliance      | Minimize stored MDM data, protect PII, and apply retention/archive rules.                             |

## 14. Risks and Mitigation

| Risk                         | Impact                       | Mitigation                                                          |
| ---------------------------- | ---------------------------- | ------------------------------------------------------------------- |
| MDM unavailable              | Citizen verification delayed | Manual review status, retry queue, operational alerting.            |
| Duplicate citizens           | Incorrect history or routing | Match by phone/email/MDM ID and deduplicate during migration.       |
| High historical volume       | Slow migration or reporting  | Staging, pilot loads, batch tuning, indexing, archive strategy.     |
| File storage growth          | Storage cost and limits      | Forecast 100GB history plus 100MB daily, define retention/archive.  |
| Complex routing rules        | Incorrect assignment         | Use Omni-Channel skills/capacity and configurable routing metadata. |
| Cross-division data exposure | Privacy or compliance issue  | Private OWD, sharing rules, restriction rules, FLS, audit logs.     |
| SLA breach                   | Citizen dissatisfaction      | Entitlements, milestones, supervisor alerts, dashboards.            |
| Over-customization           | Higher maintenance           | Use standard Service Cloud capabilities wherever possible.          |

## 15. Architectural Decision Records

### ADR-001 - Use Standard Case for Enquiry and Feedback

Decision: Use Salesforce Case with `Enquiry` and `Feedback` record types.

Rationale: Standard Case works natively with Service Console, Omni-Channel, queues, Email-to-Case, Web-to-Case, Knowledge, entitlements, milestones, reports, dashboards, and CTI/messaging integrations.

### ADR-002 - Use Service Cloud as the Core Platform

Decision: Use Service Cloud as the internal operating model for Agents, Supervisors, and Branch Admins.

Rationale: The requirement is case-centric and relies on channel intake, assignment, service process control, and performance reporting.

### ADR-003 - Use Omni-Channel for Assignment

Decision: Route Cases using Omni-Channel, queues, skills, capacity, availability, language, and priority.

Rationale: Assignment must consider expertise, language, workload, and availability.

### ADR-004 - Verify Citizens Through MDM Integration

Decision: Verify by phone or email against external MDM through Named Credentials or middleware.

Rationale: MDM remains the authoritative citizen source while Salesforce stores the service interaction.

### ADR-005 - Use Microsoft AD / Entra ID for SSO

Decision: Implement Salesforce SSO using SAML or OpenID Connect with Microsoft AD / Entra ID.

Rationale: The assessment requires use of the existing Microsoft Active Directory.

### ADR-006 - Use Salesforce Knowledge for Reusable Solutions

Decision: Agents use approved Knowledge articles and create draft solutions when no answer exists.

Rationale: Enquiry resolution requires consistent answers and a way to document new solutions.

### ADR-007 - Use Salesforce Files for Photos and Supporting Documents

Decision: Store uploaded photos/documents as Salesforce Files or approved archive links.

Rationale: Salesforce Files is the modern attachment model and supports versioning, sharing, preview, and audit.

### ADR-008 - Use Staged Migration for Historical Data

Decision: Migrate historical data through profiling, cleansing, staging, pilot load, full load, file load, delta, validation, and cutover.

Rationale: The volume of 6 million records and 100GB files requires controlled migration and reconciliation.
