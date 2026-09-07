module opencl

fn test_error_preserves_operation_and_status() {
	err := OpenCLError{
		operation: 'create buffer'
		status: invalid_value
	}
	assert err.code() == -30
	assert err.msg() == 'create buffer: invalid_value (-30)'
}

fn test_check_accepts_success() {
	check(success, 'successful operation') or { assert false, err.msg() }
}

fn test_unknown_error_name_is_stable() {
	assert error_code_name(ErrorCode(-9999)) == 'opencl_error'
}
