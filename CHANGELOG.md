# Changelog

## Unreleased

- Reject external-buffer element counts whose byte size would overflow before calling OpenCL.

## 0.3.0

- Preserve typed OpenCL pointer declarations at the C ABI while accepting opaque-handle arrays through pointer-safe `voidptr` wrapper parameters.
- Pass real null event and global-offset pointers from blocking transfers and synchronous kernel dispatch.
- Add a strict C pointer-ABI regression test independent of the installed OpenCL implementation.
- Reject typed-buffer byte-size overflow before calling OpenCL.
- Record the immutable Khronos registry and header revisions used by the generator.
- Publish releases only from matching version tags after the full test matrix succeeds.

## 0.2.2

- Add owned opaque-FD external-memory and external-semaphore interoperability helpers.
- Resolve extension entry points for the selected OpenCL platform and preserve Windows calling conventions.
- Migrate the Vulkan particles example to typed imports and explicit event dependency chains.
- Validate live zero-copy memory and semaphore interoperability on an NVIDIA GeForce GTX 1060.

## 0.2.1

- Add parsed runtime capability and device/driver UUID helpers.

## 0.2.0

- Add typed errors and platform/device discovery helpers.
- Add owned contexts, queues, typed buffers, programs, kernels, and events.
- Add checked blocking and asynchronous buffer transfers.
- Add source builds with compiler logs and typed kernel arguments.
- Add event wait lists, markers, barriers, profiling, and 1D/2D/3D dispatch.
- Add external-memory and external-semaphore interoperability extensions.
- Add `cl_khr_device_uuid` device identity constants.
- Add portable and Vulkan/OpenCL interoperability examples.

## 0.1.3

- Complete the generated OpenCL 1.0 through 3.0 core binding surface.
