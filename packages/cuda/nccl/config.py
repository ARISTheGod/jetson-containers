from jetson_containers import L4T_VERSION, IS_SBSA, LSB_RELEASE, CUDA_ARCH
from packaging.version import Version

# This script assumes the 'package' dictionary is pre-defined by the build system.
# Do NOT initialize it with 'package = {}'.

package['build_args'] = { # type: ignore
    'NCCL_VERSION': '2.27.7',
    'IS_SBSA': IS_SBSA,
    'CUDA_ARCH': CUDA_ARCH,
    'DISTRO': f"ubuntu{LSB_RELEASE.replace('.', '')}",
}

# The '# type: ignore' comments suppress harmless linter warnings.
if Version(LSB_RELEASE) >= Version('22.04'): # type: ignore
    package['requires'] = '>=cu124'
