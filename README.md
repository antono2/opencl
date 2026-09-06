# opencl

Generated OpenCL bindings for the [V programming language](https://vlang.io/).

The bindings are generated from Khronos' canonical OpenCL XML registry by
[`antono2/v_opencl_bindings`](https://github.com/antono2/v_opencl_bindings).

Applications must have an OpenCL ICD loader and OpenCL development headers.
On Debian or Ubuntu, a CPU implementation suitable for development and testing
can be installed with:

```sh
sudo apt install ocl-icd-opencl-dev pocl-opencl-icd
```

```v
import opencl as cl

fn main() {
	mut count := u32(0)
	result := cl.get_platform_ids(0, unsafe { nil }, &count)
	if result != cl.success {
		panic('clGetPlatformIDs failed: ${result}')
	}
	println('OpenCL platforms: ${count}')
}
```

The current module also supports the basic compute lifecycle: context and
queue creation, buffers, source-program compilation, kernels, ND-range
dispatch, buffer reads, synchronization, build-log queries, and resource
release.
