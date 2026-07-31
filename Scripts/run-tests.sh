#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
result_root="${RESULT_ROOT:-$(mktemp -d "${TMPDIR:-/tmp}/iOSRingingRoomTests.XXXXXX")}"
derived_data_path="${DERIVED_DATA_PATH:-${result_root}/DerivedData}"
destination="${DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.2}"
test_target="${TEST_TARGET:-unit}"
minimum_line_coverage="${MIN_LINE_COVERAGE:-0.20}"

mkdir -p "${result_root}"

run_tests() {
    local label="$1"
    local filter="$2"
    local result_bundle="${result_root}/${label}.xcresult"

    echo "Running ${label} tests on ${destination}"
    xcodebuild \
        -project "${project_root}/Ringing Room.xcodeproj" \
        -scheme iOSRingingRoom \
        -destination "${destination}" \
        "${filter}" \
        test \
        -enableCodeCoverage YES \
        CODE_SIGNING_ALLOWED=NO \
        -derivedDataPath "${derived_data_path}" \
        -resultBundlePath "${result_bundle}"

    echo "Result bundle: ${result_bundle}"
    printf '%s\n' "${result_bundle}"
}

case "${test_target}" in
    unit)
        unit_result="$(run_tests unit '-only-testing:iOSRingingRoomTests' | tail -n 1)"
        report_path="${result_root}/coverage.json"
        xcrun xccov view --report --json "${unit_result}" > "${report_path}"

        app_line_coverage="$(jq -er '[.targets[] | select(.name == "Ringing Room.app") | .lineCoverage] | if length == 1 then .[0] else error("Ringing Room.app coverage target not found") end' "${report_path}")"
        echo "Ringing Room.app line coverage: ${app_line_coverage}"
        awk -v actual="${app_line_coverage}" -v minimum="${minimum_line_coverage}" 'BEGIN { exit !(actual + 0 >= minimum + 0) }'
        echo "Coverage gate passed (minimum ${minimum_line_coverage})."
        ;;
    ui)
        run_tests ui '-only-testing:iOSRingingRoomUITests' >/dev/null
        ;;
    all)
        unit_result="$(run_tests unit '-only-testing:iOSRingingRoomTests' | tail -n 1)"
        run_tests ui '-only-testing:iOSRingingRoomUITests' >/dev/null
        report_path="${result_root}/coverage.json"
        xcrun xccov view --report --json "${unit_result}" > "${report_path}"
        app_line_coverage="$(jq -er '[.targets[] | select(.name == "Ringing Room.app") | .lineCoverage] | if length == 1 then .[0] else error("Ringing Room.app coverage target not found") end' "${report_path}")"
        echo "Ringing Room.app line coverage: ${app_line_coverage}"
        awk -v actual="${app_line_coverage}" -v minimum="${minimum_line_coverage}" 'BEGIN { exit !(actual + 0 >= minimum + 0) }'
        ;;
    *)
        echo "Unsupported TEST_TARGET: ${test_target}. Use unit, ui, or all." >&2
        exit 2
        ;;
esac
