"""Exercise installed CMake identity/import contracts without compiling native code."""
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
CORE_REVISION = "a" * 40
PROSE_REVISION = "b" * 40


@unittest.skipUnless(shutil.which("cmake"), "CMake is required for configuration tests")
class PackageConfigTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.sdk = self.root / "sdk"
        self.core = self.sdk / "lib/cmake/OpenMS"
        self.prose = self.sdk / "lib/cmake/OpenMSProSE"
        self.core.mkdir(parents=True)
        self.prose.mkdir(parents=True)
        self.write_core(CORE_REVISION)
        (self.prose / "OpenMSProSETargets.cmake").write_text(
            "add_library(OpenMS::ProSE INTERFACE IMPORTED)\n"
            "set_property(TARGET OpenMS::ProSE PROPERTY INTERFACE_LINK_LIBRARIES OpenMS::Core)\n"
        )
        producer = self.root / "producer"
        producer.mkdir()
        (producer / "CMakeLists.txt").write_text(f"""
cmake_minimum_required(VERSION 3.24)
project(ConfigFixture VERSION 1.0.0 LANGUAGES NONE)
include(CMakePackageConfigHelpers)
set(OpenMS_VERSION 4.0.0)
set(OpenMS_SOURCE_REVISION {CORE_REVISION})
set(OpenMS_SOURCE_DIRTY OFF)
set(OpenMSProSE_SOURCE_REVISION {PROSE_REVISION})
set(OpenMSProSE_SOURCE_DIRTY ON)
configure_package_config_file("{ROOT / 'cmake/OpenMSProSEConfig.cmake.in'}"
  "{self.prose / 'OpenMSProSEConfig.cmake'}" INSTALL_DESTINATION lib/cmake/OpenMSProSE)
""")
        self.configure(producer, self.root / "producer-build", expect_success=True)

    def write_core(self, revision):
        (self.core / "OpenMSConfig.cmake").write_text(f"""
set(OpenMS_VERSION 4.0.0)
set(OpenMS_SOURCE_REVISION "{revision}")
set(OpenMS_SOURCE_DIRTY OFF)
if(NOT TARGET OpenMS::Core)
  add_library(OpenMS::Core INTERFACE IMPORTED)
endif()
""")
        (self.core / "OpenMSConfigVersion.cmake").write_text("""
set(PACKAGE_VERSION 4.0.0)
if(PACKAGE_FIND_VERSION STREQUAL PACKAGE_VERSION)
  set(PACKAGE_VERSION_EXACT TRUE)
  set(PACKAGE_VERSION_COMPATIBLE TRUE)
endif()
""")

    def configure(self, source, build, expect_success):
        result = subprocess.run(
            ["cmake", "-S", str(source), "-B", str(build),
             f"-DCMAKE_PREFIX_PATH={self.sdk}", "-DCMAKE_FIND_USE_PACKAGE_REGISTRY=OFF",
             "-DCMAKE_FIND_USE_SYSTEM_PACKAGE_REGISTRY=OFF"],
            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False,
        )
        if expect_success:
            self.assertEqual(result.returncode, 0, result.stdout)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout)
        return result.stdout

    def consumer(self, commands, expect_success=True):
        source = self.root / "consumer"
        source.mkdir()
        (source / "CMakeLists.txt").write_text(
            "cmake_minimum_required(VERSION 3.24)\nproject(Consumer LANGUAGES NONE)\n" + commands
        )
        return self.configure(source, self.root / "consumer-build", expect_success)

    def test_repeated_import_without_cli_preserves_backend_and_core_identity(self):
        # Duplicate target definition would fail if the installed import were not guarded.
        self.consumer(f"""
find_package(OpenMSProSE CONFIG REQUIRED)
find_package(OpenMSProSE CONFIG REQUIRED)
if(NOT TARGET OpenMS::ProSE OR TARGET OpenMS::CLI)
  message(FATAL_ERROR "Backend import must require only Core")
endif()
if(NOT OpenMSProSE_SOURCE_REVISION STREQUAL "{PROSE_REVISION}" OR
   NOT OpenMSProSE_CORE_SOURCE_REVISION STREQUAL "{CORE_REVISION}" OR
   NOT OpenMSProSE_SOURCE_DIRTY OR OpenMSProSE_CORE_SOURCE_DIRTY)
  message(FATAL_ERROR "Installed source identity was not preserved")
endif()
""")

    def test_wrong_core_commit_is_rejected(self):
        self.write_core("c" * 40)
        output = self.consumer("find_package(OpenMSProSE CONFIG REQUIRED)\n", False)
        self.assertIn("OpenMSProSE requires OpenMS core commit", output)

    def test_missing_core_identity_is_rejected(self):
        self.write_core("")
        output = self.consumer("find_package(OpenMSProSE CONFIG REQUIRED)\n", False)
        self.assertIn("OpenMSProSE requires OpenMS core commit", output)

    def test_unknown_required_component_is_rejected(self):
        output = self.consumer("find_package(OpenMSProSE CONFIG REQUIRED COMPONENTS Missing)\n", False)
        self.assertIn("OpenMSProSE_FOUND to FALSE", output)

    def test_lock_declares_independent_core_and_cli_dependencies(self):
        lock = json.loads((ROOT / "dependencies.lock.json").read_text())["dependencies"]
        for name in ("OpenMS", "OpenMSCLI"):
            self.assertRegex(lock[name]["source_revision"], r"^[0-9a-f]{40}$")

    def configure_backend(self, testing=False, extra=()):
        # A real package configure against a minimal installed SDK fixture. CMake
        # may probe its compiler, but no backend/tool target is compiled here.
        source = self.root / "package"
        shutil.copytree(ROOT, source, ignore=shutil.ignore_patterns(".git", "build*", "__pycache__"))
        lock = {"dependencies": {"OpenMS": {"version": "4.0.0", "source_revision": CORE_REVISION}}}
        (source / "dependencies.lock.json").write_text(json.dumps(lock))
        if testing:
            support = self.root / "test_support.cpp"
            support.write_text("// Configuration-only fixture\n")
            with (self.core / "OpenMSConfig.cmake").open("a") as stream:
                stream.write(f"""
add_library(OpenMS::TestFramework INTERFACE IMPORTED)
set(OpenMS_TEST_SUPPORT_SOURCE "{support}")
set(OpenMS_WITH_OPENTIMS OFF)
""")
        return subprocess.run(
            ["cmake", "-S", str(source), "-B", str(self.root / "backend-build"),
             f"-DCMAKE_PREFIX_PATH={self.sdk}", "-DOPENMS_PROSE_BUILD_TOOL=OFF",
             f"-DBUILD_TESTING={'ON' if testing else 'OFF'}",
             f"-DOPENMS4_SOURCE_REVISION={PROSE_REVISION}", "-DOPENMS4_SOURCE_DIRTY=ON",
             *extra], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False,
        )

    def test_backend_configuration_does_not_find_cli(self):
        result = self.configure_backend()
        self.assertEqual(result.returncode, 0, result.stdout)
        config = (self.root / "backend-build/OpenMSProSEConfig.cmake").read_text()
        self.assertIn(f'set(OpenMSProSE_CORE_SOURCE_REVISION "{CORE_REVISION}")', config)

    def test_requested_bruker_test_rejects_sdk_without_reader(self):
        result = self.configure_backend(testing=True, extra=("-DOPENTIMS_DDA_TEST_DATA=/missing.d",))
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("ProSE Bruker integration requires an OpenMS SDK with Opentims enabled", result.stdout)


if __name__ == "__main__":
    unittest.main()
