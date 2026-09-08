# Apex coverage validation

Validated on 8 September 2026 against `hdbsf` using a **check-only deployment** of repository Apex and Flow metadata. Validation `0Affj00000QJoOjCAL` succeeded with **30/30 tests passing**, zero component errors, and zero test failures. These source changes have not been deployed persistently to the org.

| Production Apex class      | Covered locations | Coverage |
| -------------------------- | ----------------: | -------: |
| GrantApplicationController |             14/15 |   93.33% |
| GrantExceptionService      |             26/26 |     100% |
| Total                      |             40/41 |   97.56% |

The 90% requirement is checked for **each production class/trigger in this repository**, not only the combined percentage. Test classes are excluded. Experience Cloud controllers and managed package classes present only in the org are outside this source scope. Apex coverage is executable-location coverage; it does not prove every branch, Flow path, guest permission, or asynchronous delivery behavior.

## Behavioral checks

- `GrantApplicationControllerTest` (5 tests): persisted Contact values and returned ID; newest matching Contact within the default account; preservation of other Contacts; save failure propagation with no Contact created; option values and name ordering; empty option collection.
- `GrantExceptionServiceTest` (5 tests): null/empty/whitespace codes skip the Flow lookup; unknown codes return the supplied fallback, including null; configured messages override defaults; exact client message keys and values; mixed configured/fallback messages.
- `ContactBulkFlowTest` (9 tests): CSV option formats, scoped matching, replay protection, invalid/missing/ambiguous input, Pending rows, corrected retries, and returned-versus-thrown save faults.
- `GrantRecalculationFlowTest` (11 tests): schedule amounts/dates/sequences, paid-record preservation, applicant isolation, paid totals and remaining months, configured errors, fresh rollups with a proposed option, currency rounding, and zero-amount paid months.

Tests use isolated records and invoke the real Flows. Direct Flow tests do not prove delivery/timing of platform asynchronous paths. The uncovered Apex location is the defensive new-empty-list branch in `getActiveSupportOptions`; the actual no-options Flow returns an empty collection, which is asserted. Production Apex was not changed to manufacture coverage.

The validation exposed regressions that were fixed: missing phone/postal/required-option test data; bulk processing without a Ready-status guard or unique-option check; recalculation skipping a proposed option when the stored amount matched an existing payment. The disbursement-name assertion now checks the source's `Dis ` prefix.

## Repeat the validation

From the repository root:

```sh
sf project deploy start --target-org hdbsf \
  --source-dir force-app/main/default/classes \
  --source-dir force-app/main/default/flows \
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
python3 scripts/validation/check_apex_coverage.py doc/validation/apex-coverage-2026-09-08.json
```
