# POC_AOSP: Hello World Example for AOSP 14 on Raspberry Pi 4

## Overview

This project is a complete "Hello World" demonstration for Android Open Source Project (AOSP) 14, targeting the Raspberry Pi 4 (rbpi4) platform. It showcases the integration of a custom kernel driver, a Hardware Abstraction Layer (HAL) service, an AIDL interface, and a privileged Android application. The folder structure strictly follows the AOSP 14 tree for rbpi4, making it easy to merge with your existing AOSP source tree.

**To run this example:**  
Replace the corresponding files in your AOSP tree for rbpi4 with those from this project, preserving the directory structure.

## Author Information

**Created by:** Arkadiusz Kubiak  
**Purpose:** Hello World example for AOSP 14 on Raspberry Pi 4  
**Architecture Focus:** AIDL HAL Services, JNI Integration, and SELinux Policies

For more information about AOSP development and HAL services, feel free to contact the author.

---

## Component Overview

### 1. Kernel Driver

- **Path:** `kernel/common/drivers/char/hello_world_driver.c`
- **Description:** Implements a simple character driver that creates a sysfs entry `/sys/kernel/hello_world/hello`. Messages sent from user space are logged in the kernel log.

### 2. HAL Service

- **Path:** `vendor/brcm/interfaces/helloworld/default/`
- **Description:** Implements the AIDL HAL service (`vendor.brcm.helloworld-service`). The service receives messages from clients and writes them to the kernel driver via sysfs.

### 3. AIDL Interface

- **Path:** `vendor/brcm/interfaces/helloworld/aidl/vendor/brcm/helloworld/IHelloWorld.aidl`
- **Description:** Defines the AIDL interface for communication between the Android app and the HAL service.

#### AIDL Versioning and API Freezing

AIDL versioning is managed using the `aidl_api` folder, which contains frozen snapshots of your AIDL interface to ensure backward compatibility and stability.

- **Path:** `vendor/brcm/interfaces/helloworld/aidl/aidl_api/vendor.brcm.helloworld/current/`
- **Description:** Contains the current frozen version of the AIDL interface. These files are immutable and should not be edited manually.

**How to generate and freeze the AIDL API:**
1. Create or modify the AIDL file (e.g., `IHelloWorld.aidl`) as needed.
2. Run the following command in your AOSP build environment to generate or update the API:
   ```sh
   m vendor.brcm.helloworld-update-api
   ```
   This will create or update the API files in the `aidl_api` directory.
3. After generating the API, freeze it to prevent further changes:
   ```sh
   m vendor.brcm.helloworld-freeze-api
   ```
4. Commit the changes in the `aidl_api` folder to your repository to ensure the API version is tracked.

**Note:**  
Frozen AIDL APIs guarantee that clients depending on your interface will not break due to incompatible changes. Always generate and freeze the API before releasing or integrating with other modules.

### 4. Android Application

- **Path:** `vendor/brcm/apps/HelloWorld/`
- **Description:** Privileged Android app with a simple UI to send messages to the HAL service. Uses JNI to communicate with the HAL.

### 5. SELinux Policy

- **Path:** `device/brcm/rpi4/sepolicy/`
- **Description:** SELinux type enforcement and file contexts for the HAL service.

### 6. Device Makefile

- **Path:** `device/brcm/rpi4/device.mk`
- **Description:** Adds the HAL service and HelloWorld app to the build.

---

## How to Integrate and Run

**Integration Steps Across Two Projects: AOSP Android 14 and AOSP Kernel**

1. **Copy or Create Files:** For each component, if the required file or directory does not exist in your AOSP Android 14 or AOSP Kernel source tree, create it. If it exists, modify it as needed according to the structure described above.
2. **Kernel Driver:** Add or update `hello_world_driver.c` in the AOSP Kernel repository and update the corresponding `Makefile` to include the new driver in the kernel build process.
3. **Build Kernel:** Compile the kernel with the new or updated driver and generate a bootable kernel image.
4. **Build AOSP:** Configure and build the Android 14 system (`lunch`, `make`, etc.), ensuring that the HAL service, application, and SELinux policies are present and included in the build configuration.
5. **Flash Images:** Flash both the system image and the kernel image onto the Raspberry Pi device.
6. **Test:** Launch the `HelloWorld` application on the device, send a message, and verify the kernel log to confirm correct communication between the app, HAL service, and kernel driver.

*Note: This workflow requires coordination between the AOSP Android 14 and AOSP Kernel projects. Changes to the kernel driver must be made in the kernel repository, while user space components (HAL, app, SELinux policies) are managed in the AOSP Android 14 repository. Always ensure missing files are created and existing files are updated as needed.*

---

## License

This project is licensed under the MIT License.  
You are free to use, modify, and distribute this software for any purpose, including commercial and private use.

See the [LICENSE](LICENSE) file for the full text of the MIT License.