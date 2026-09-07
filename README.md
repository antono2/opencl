# opencl

Generated OpenCL bindings for the [V programming language](https://vlang.io/).

[Available as `antono2.opencl` on VPM](https://vpm.vlang.io/packages/antono2.opencl).

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

## Convenience API

The generated functions remain available as the complete low-level API. An opt-in,
hand-written layer adds typed errors and safe discovery helpers without hiding native
OpenCL handles:

```v
for platform in cl.platforms()! {
	println(cl.platform_info_string(platform, cl.platform_name)!)
	for device in cl.devices(platform, cl.device_type_all)! {
		println('  ${cl.device_info_string(device, cl.device_name)!}')
	}
}
```

Contexts and queues use explicit, idempotent cleanup:

```v
mut context := cl.new_context(device)!
defer { context.close() or {} }
mut queue := context.command_queue(device, cl.CommandQueueProperties(0))!
defer { queue.close() or {} }

mut buffer := cl.new_buffer[f32](&context, cl.mem_read_write, 1024)!
defer { buffer.close() or {} }
buffer.write(&queue, 0, []f32{len: 1024, init: f32(index)})!
```

Source compilation preserves compiler diagnostics through `ProgramBuildError`. Owned
kernels support typed scalar and buffer arguments plus one-dimensional dispatch:

```v
mut program := cl.build_source_program(&context, device, source, '')!
defer { program.close() or {} }
mut kernel := program.kernel('transform')!
defer { kernel.close() or {} }
kernel.set_buffer_arg(0, buffer.handle)!
kernel.enqueue_1d(&queue, usize(buffer.count), 0)!
```

See [`API_DESIGN.md`](API_DESIGN.md) for the conventions shared with the companion
Vulkan convenience layer.

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
Optional extension commands are resolved through the ICD at runtime instead of
being required linker symbols, so applications that do not use them can still
build against older OpenCL loaders.

CI exercises a complete buffer/program/kernel compute path, OpenCL 1.1 user
events, an OpenCL 1.2 marker-with-wait-list dependency, and OpenCL 2.0
property-list queue creation and SVM allocation on PoCL.
OpenCL 2.1 coverage additionally checks synchronized device and host timer
queries; IL programs, kernel cloning, subgroup queries, and SVM migration are
present in the generated API.
OpenCL 2.2 adds program specialization constants and program-release callbacks.
OpenCL 3.0 adds numeric version helpers, `NameVersion`, context destructor
callbacks, and property-based buffer and image creation.
