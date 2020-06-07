#!/bin/sh
# Disable source following.
#   shellcheck disable=SC1090,SC1091
# Disable optional arguments.
#   shellcheck disable=SC2120
# Disable which non-standard.
#   shellcheck disable=SC2230


TEST_SCRIPT="$0"
TEST_DIR="$(dirname -- "$TEST_SCRIPT")"
. "$TEST_DIR/test_helpers"


get_python_path() {
    cmd_prefix="${1:-}"

    $cmd_prefix which python
}

oneTimeSetUp() {
    th_oneTimeSetUp
    HOST_PYTHON_PATH="$(get_python_path)"
}


test_pipenv_run() {
    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(get_python_path)"

    # Change directory in env 1 and check python path with `pipenv run`.
    cd -- "$TEST_ENVS_TMPDIR/1" || fail "cd to env 1"
    assertEquals "python path equals to host in env 1 without pipenv run"\
        "$HOST_PYTHON_PATH" "$(get_python_path)"

    env_1_python_path="$(get_python_path 'pipenv run')"
    assertNotEquals "python path not equals to host in env 1 with pipenv run"\
        "$HOST_PYTHON_PATH" "$env_1_python_path"

    # Change directory in env 2 and check python path with `pipenv run`.
    cd -- "$TEST_ENVS_TMPDIR/2" || fail "cd to env 2"
    assertEquals "python path equals to host in env 2 without pipenv run"\
        "$HOST_PYTHON_PATH" "$(get_python_path)"

    env_2_python_path="$(get_python_path 'pipenv run')"
    assertNotEquals "python path not equals to host in env 2 with pipenv run"\
        "$HOST_PYTHON_PATH" "$env_2_python_path"
    assertNotEquals "python path not equals to env 1 in env 2 with pipenv run"\
        "$env_1_python_path" "$env_2_python_path"
}


test_pipenv_activate() {
    # Check test environment is ok.
    assertEquals "check host env" "$HOST_PYTHON_PATH" "$(get_python_path)"

    # Cannot activate non virtual environment with pipenv_activate
    err_msg="$(pipenv_activate "$TEST_ENVS_TMPDIR" 2>&1)"\
        && fail "pipenv_activate without valid virtualenv should fail"
    if [ -z "$KSH_VERSION" ]; then
        assertContains "pipenv_activate without valid virtualenv error message"\
            "$TEST_ENVS_TMPDIR is not a valid virtual environment" "$err_msg"
    fi
    assertEquals "python path to host after pipenv_activate without valid virtualenv"\
        "$HOST_PYTHON_PATH" "$(get_python_path)"

    # Change directory in env 1 and check python path with `pipenv_activate`.
    cd -- "$TEST_ENVS_TMPDIR/1" || fail "cd to env 1"
    assertEquals "python path equals to host in env 1 without pipenv_activate"\
        "$HOST_PYTHON_PATH" "$(get_python_path)"

    pipenv_activate || fail "pipenv_activate in env 1"
    env_1_python_path="$(get_python_path)"
    assertNotEquals "python path not equals to host in env 1 with pipenv_activate"\
        "$HOST_PYTHON_PATH" "$env_1_python_path"

    # Change directory in env 2
    cd -- "$TEST_ENVS_TMPDIR/2" || fail "cd to env 2"

    # Since we have not yet deactivate the pipenv environment of env 1, we
    # should still get the python path of env 1.
    assertEquals "python path equals to env 1 in env 2 without python_activate"\
        "$env_1_python_path" "$(get_python_path)"

    # Cannot activate env 2 while env 1 is still active.
    err_msg="$(pipenv_activate 2>&1)"\
        && fail "pipenv_activate in env 2 with env 1 still active should fail"
    if [ -z "$KSH_VERSION" ]; then
        assertContains "pipenv_activate in env 2 with env 1 still active error message"\
            "another virtual environment is already active" "$err_msg"
    fi
    assertEquals "python path to env 1 after invalid pipenv_activate in env 2"\
        "$env_1_python_path" "$(get_python_path)"

    # Deactivate the pipenv environment of env 1, we get the host python path.
    pipenv_deactivate || fail "deactivate env 1"
    assertEquals "python path equals to host after pipenv_deactivate of env 1"\
        "$HOST_PYTHON_PATH" "$(get_python_path)"

    # Use `pipenv_activate` in env 2.
    pipenv_activate || fail "pipenv_activate in env 2"

    # Check python path in env 2 with `pipenv_activate`.
    env_2_python_path="$(get_python_path)"
    assertNotEquals "python path not equals to host in env 2 with pipenv_activate"\
        "$HOST_PYTHON_PATH" "$env_2_python_path"
    assertNotEquals "python path not equals to env 1 in env 2 with pipenv_activate"\
        "$env_1_python_path" "$env_2_python_path"

    # `pipenv run` should be a no operations when the pipenv environment is
    # already loaded with `pipenv_activate`.
    assertEquals "pipenv run no op in env 2 with pipenv_activate"\
        "$env_2_python_path" "$(get_python_path 'pipenv run')"

    # Using `pipenv_activate` twice in th same environment has no effects and
    # should not fail.
    pipenv_activate || fail "pipenv_activate twice should not fail"
    assertEquals "pipenv_activate twice no op "\
        "$env_2_python_path" "$(get_python_path)"

    # Deactivate env 2
    pipenv_deactivate || fail "pipenv_deactivate env 2"

    # Using `pipenv_deactivate` twice has no effect and should not fail.
    pipenv_deactivate || fail "pipenv_deactivate no op"

    # Check python path is the host one after pipenv_deactivate.
    assertEquals "python path to host after pipenv_deactivate"\
        "$HOST_PYTHON_PATH" "$(get_python_path)"
}


. "$TEST_DIR/shunit2/shunit2"
