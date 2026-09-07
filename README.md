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

Install the module from VPM:

```sh
v install antono2.opencl
```

```v
import antono2.opencl as cl

fn main() {
	mut count := u32(0)
	result := cl.get_platform_ids(0, unsafe { nil }, &count)
	if result != cl.success {
		panic('clGetPlatformIDs failed: ${result}')
	}
	println('OpenCL platforms: ${count}')
}
```

## Advanced example

[`examples/vulkan_particles`](examples/vulkan_particles) is an interactive particle-galaxy
example that combines OpenCL compute with Vulkan presentation. On UUID-matched devices it imports
one exported Vulkan allocation into OpenCL and synchronizes access with reusable opaque-FD
semaphores. It also includes a portable host-staged fallback, swapchain recreation, velocity
trails, interactive controls, and display-independent interoperability smoke tests.

The example is a separate nested V module, so its `vulkan` and `glfw` dependencies are not
dependencies of applications that only import `opencl`.

The module exposes all 114 cumulative OpenCL 1.0 through 3.0 commands and 14
portable Khronos extension entry points with V-style snake-case wrappers,
including platform and device discovery, contexts, queues, memory and images,
programs, kernels, events, profiling, synchronization, and object lifecycle.
The bindings generator reads command prototypes, types, pointer depth, and all
OpenCL 1.0 through 3.0 core constants from Khronos' XML registry. Constants are
exposed using their corresponding OpenCL typedefs.
Core command callbacks use named V function types, allowing callback signatures
to be checked at compile time while optional callbacks still accept `unsafe { nil }`.
The initial extension set covers `cl_khr_il_program`,
`cl_khr_create_command_queue`, `cl_khr_subgroups`, and
`cl_khr_suggested_local_work_size`.
Zero-copy synchronization support covers `cl_khr_semaphore`,
`cl_khr_external_semaphore`, and `cl_khr_external_memory`, including opaque-FD,
DMA-BUF, and sync-file handle variants.
`cl_khr_device_uuid` provides UUID, LUID, and node-mask device queries for
matching an OpenCL device with another compute or graphics API.

CI exercises a complete buffer/program/kernel compute path, OpenCL 1.1 user
events, an OpenCL 1.2 marker-with-wait-list dependency, and OpenCL 2.0
property-list queue creation and SVM allocation on PoCL.
OpenCL 2.1 coverage additionally checks synchronized device and host timer
queries; IL programs, kernel cloning, subgroup queries, and SVM migration are
present in the generated API.
OpenCL 2.2 adds program specialization constants and program-release callbacks.
OpenCL 3.0 adds numeric version helpers, `NameVersion`, context destructor
callbacks, and property-based buffer and image creation.
