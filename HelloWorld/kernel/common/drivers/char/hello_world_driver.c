#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/kobject.h>
#include <linux/sysfs.h>
#include <linux/string.h>
#include <linux/slab.h>

static struct kobject *hello_kobj;

/*
 * hello_print - sysfs 'store' callback for 'hello' attribute
 * @kobj: kobject pointer
 * @attr: attribute pointer
 * @buf: user input buffer
 * @count: number of bytes written
 *
 * Copies input to a temporary buffer, logs the received string.
 */
static ssize_t hello_print(struct kobject *kobj,
                           struct kobj_attribute *attr, const char *buf, size_t count)
{
    char tmp[128];

    pr_info("hello_world: hello_print called with count=%zu\n", count);

    if (count >= sizeof(tmp)) {
        pr_err("hello_world: input too large (%zu bytes), max is %zu\n", count, sizeof(tmp) - 1);
        return -EINVAL;
    }

    strncpy(tmp, buf, count);
    tmp[count] = '\0';

    pr_info("hello_world received: %s\n", tmp);

    return count;
}

/* Define a sysfs attribute named 'hello' with write-only permissions */
/* Only root (owner) can write to this sysfs file (mode 0200)
 * Permissions: -w------- (write-only for owner, as shown by 'ls -l')
 */
static struct kobj_attribute hello_attribute =
    __ATTR(hello, 0200, NULL, hello_print);

/*
 * hello_sysfs_init - Module initialization
 *
 * Creates a kobject and sysfs file for 'hello_world'.
 */
static int __init hello_sysfs_init(void)
{
    int retval;

    pr_info("hello_world_sysfs: Initializing sysfs interface\n");

    hello_kobj = kobject_create_and_add("hello_world", kernel_kobj);
    if (!hello_kobj) {
        pr_err("hello_world_sysfs: Failed to create kobject\n");
        return -ENOMEM;
    }

    retval = sysfs_create_file(hello_kobj, &hello_attribute.attr);
    if (retval) {
        pr_err("hello_world_sysfs: Failed to create sysfs file (retval=%d)\n", retval);
        kobject_put(hello_kobj);
    } else {
        pr_info("hello_world_sysfs: sysfs file created successfully\n");
    }

    pr_info("hello_world_sysfs: device_initcall loaded\n");
    return retval;
}

device_initcall(hello_sysfs_init);
