# Apex coverage validation

**Deployment completed:** The Apex classes/tests, seven Flows, and ContactBulk Phone field were deployed permanently to `hdbsf` on 8 September 2026. Deployment `0Affj00000QKFrzCAH` succeeded with `checkOnly=false`, **14/14 components**, **30/30 tests**, zero errors, and Apex coverage of **93.33% / 100%**. Evidence: [deployment result](apex-deployment-2026-09-08.json). The check-only results below are the earlier validation history.

Validated on 8 September 2026 against `hdbsf` using a **check-only deployment** of repository Apex, Flow metadata, and the updated ContactBulk Phone field (Text). Validation `0Affj00000QKCR4CAP` succeeded with **30/30 tests passing**, zero component errors, and zero test failures. This check-only run did not persist changes to the org. It validates the current source after the Auto_processContactBulk edit.

| Production Apex class      | Covered locations | Coverage |
| -------------------------- | ----------------: | -------: |
| GrantApplicationController |             14/15 |   93.33% |
| GrantExceptionService      |             26/26 |     100% |
| Total                      |             40/41 |   97.56% |

The 90% requirement is checked for **each production class/trigger in this repository**, not only the combined percentage. Test classes are excluded. Experience Cloud controllers and managed package classes present only in the org are outside this source scope. Apex coverage is executable-location coverage; it does not prove every branch, Flow path, guest permission, or asynchronous delivery behavior.

## Behavioral checks

- `GrantApplicationControllerTest` (5 tests): persisted Contact values and returned ID; newest matching Contact within the default account; preservation of other Contacts; save failure propagation with no Contact created; option values and name ordering; empty option collection.
- `GrantExceptionServiceTest` (5 tests): null/empty/whitespace codes skip the Flow lookup; unknown codes return the supplied fallback, including null; configured messages override defaults; exact client message keys and values; mixed configured/fallback messages.
- `ContactBulkFlowTest` (9 tests): CSV option formats, scoped matching and replay updates, invalid inputs, missing-option save faults, selection of one matching duplicate option, direct processing of Pending rows, corrected retries, and returned-versus-thrown save faults.
- `GrantRecalculationFlowTest` (11 tests): schedule amounts/dates/sequences, paid-record preservation, applicant isolation, paid totals and remaining months, configured errors, fresh rollups with a proposed option, currency rounding, and zero-amount paid months.

Tests use isolated records and invoke the real Flows. Direct Flow tests do not prove delivery/timing of platform asynchronous paths. The uncovered Apex location is the defensive new-empty-list branch in `getActiveSupportOptions`; the actual no-options Flow returns an empty collection, which is asserted. Production Apex was not changed to manufacture coverage.

The latest Flow edit removes the Ready-status and unique-option guards. The initial recheck still measured 93.33%/100% Apex coverage, but four existing tests failed because they expected the previous behavior. Only test expectations and their behavioral assertions were updated; the user's Flow and Phone metadata edits were preserved:

- Pending rows now process when the Flow is invoked directly.
- Replaying a successful staging row applies changed values to the same Contact without creating a duplicate or modifying other Contacts.
- Duplicate matching options yield one of the matching IDs. With no lookup sort order, the test does not assume which duplicate wins.
- A missing option returns the Contact save fault for required `Support_Option__c`, leaves the row Failed, and creates no Contact.

`Auto_processContactBulk` Flow element coverage is **13/14 (92.86%)**, measured separately from Apex coverage. `Missing_Result` is the only uncovered element. This is not a claim that all Flow decision outcomes or asynchronous trigger delivery were tested. The previous validation snapshot remains in `apex-coverage-2026-09-08.json`; the current evidence is `apex-coverage-flow-recheck-2026-09-08.json`, including SHA-256 hashes of the validated source files.

## Repeat the validation

From the repository root:

```sh
sf project deploy start --target-org hdbsf \
  --source-dir force-app/main/default/classes \
  --source-dir force-app/main/default/flows \
  --source-dir force-app/main/default/objects/ContactBulk__c/fields/Phone__c.field-meta.xml \
  --dry-run --test-level RunSpecifiedTests \
  --tests GrantApplicationControllerTest \
  --tests GrantExceptionServiceTest \
  --tests ContactBulkFlowTest \
  --tests GrantRecalculationFlowTest \
  --wait 30 --json > /tmp/virtusa-apex-coverage.json
python3 scripts/validation/check_apex_coverage.py /tmp/virtusa-apex-coverage.json
```

If the CLI returns an in-progress job, obtain its completed JSON with `sf project deploy report --target-org hdbsf --job-id JOB_ID --wait 30 --json` before running the gate. Add newly introduced test classes to the specified test list. The gate discovers production Apex source automatically and fails for missing coverage, coverage below 90%, unsuccessful validation, zero tests, or failed tests.

The checked-in JSON contains the validation status, test outcomes, and Salesforce coverage evidence from this run. Check it with:

```sh
python3 scripts/validation/check_apex_coverage.py doc/validation/apex-coverage-flow-recheck-2026-09-08.json
```
