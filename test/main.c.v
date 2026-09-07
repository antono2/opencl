module main

import antono2.opencl as cl

fn main() {
	mut platform_count := u32(0)
	result := cl.get_platform_ids(0, unsafe { nil }, &platform_count)
	assert result == cl.success
	assert platform_count > 0
	println('OpenCL package smoke test passed with ${platform_count} platform(s)')
}
