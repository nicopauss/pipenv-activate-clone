#!/bin/sh
# Disable source following.
#   shellcheck disable=SC1090,SC1091
# Disable optional arguments.
#   shellcheck disable=SC2120


TEST_SCRIPT="$0"
TEST_DIR="$(dirname -- "$TEST_SCRIPT")"
. "$TEST_DIR/test_helpers"


ENV_1_SIX_VERSION="1.15.0"
ENV_2_SIX_VERSION="None"

get_six_version() {
    cmd_prefix="${1:-}"

    $cmd_prefix python3 <<EOF
try:
    import six
except ImportError:
    print("None")
else:
    print(six.__version__)
EOF
}


test_pipenv_run() {
    # Change directory to env A and check six version.
    cd -- "$TEST_ENVS_TMPDIR/A" || fail "cd to env A"
    assertEquals "six version in env A" "$ENV_1_SIX_VERSION" \
        "$(get_six_version 'pipenv run')"

    # Change directory to env B and check six version.
    cd -- "$TEST_ENVS_TMPDIR/B" || fail "cd to env B"
    assertEquals "six version in env B" "$ENV_2_SIX_VERSION" \
        "$(get_six_version 'pipenv run')"
}


test_pipenv_activate() {
    # Change directory to env A and check six version.
    cd -- "$TEST_ENVS_TMPDIR/A" || fail "cd to env A"
    pipenv_activate || fail "pipenv_activate in env A"
    assertEquals "six version in env A" "$ENV_1_SIX_VERSION" \
        "$(get_six_version)"
    pipenv_deactivate || fail "deactivate env A"

    # Change directory to env B and check six version.
    cd -- "$TEST_ENVS_TMPDIR/B" || fail "cd to env B"
    pipenv_activate || fail "pipenv_activate in env B"
    assertEquals "six version in env B" "$ENV_2_SIX_VERSION" \
        "$(get_six_version)"
    pipenv_deactivate || fail "deactivate env B"
}


th_test_pipenv_auto_activate() {
    enable_cmd="$1"
    disable_cmd="$2"
    cd_cmd="$3"

    $enable_cmd || fail "enable auto activate"

    # Change directory to env A and check six version.
    $cd_cmd -- "$TEST_ENVS_TMPDIR/A" || fail "cd to env A"
    assertEquals "six version in env A" "$ENV_1_SIX_VERSION" \
        "$(get_six_version)"

    # Change directory to env B and check six version.
    $cd_cmd -- "$TEST_ENVS_TMPDIR/B" || fail "cd to env B"
    assertEquals "six version in env B" "$ENV_2_SIX_VERSION" \
        "$(get_six_version)"

    # Go back to envs tmpdir
    $cd_cmd -- "$TEST_ENVS_TMPDIR" || fail "cd to envs tmpdir"

    $disable_cmd || fail "disable auto activate"
}


suite() {
    suite_addTest 'test_pipenv_run'
    suite_addTest 'test_pipenv_activate'
    th_pipenv_auto_activate_suite
}


. "$TEST_DIR/shunit2/shunit2"
