public with sharing class GrantConstants {

    // Grant Application Status
    public static final String STATUS_DRAFT = 'Draft';
    public static final String STATUS_PENDING = 'Pending';
    public static final String STATUS_APPROVED = 'Approved';
    public static final String STATUS_REJECTED = 'Rejected';

    // Integration Status
    public static final String INTEGRATION_PENDING = 'Pending';
    public static final String INTEGRATION_SUCCESS = 'Success';
    public static final String INTEGRATION_FAILED = 'Failed';

    // Grant Types
    public static final String GRANT_EDUCATION = 'Education';
    public static final String GRANT_HEALTHCARE = 'Healthcare';

    // Error Types
    public static final String ERROR_VALIDATION = 'Validation';
    public static final String ERROR_INTEGRATION = 'Integration';
    public static final String ERROR_SYSTEM = 'System';

    // Default Values
    public static final Integer MAX_RETRY = 3;
}