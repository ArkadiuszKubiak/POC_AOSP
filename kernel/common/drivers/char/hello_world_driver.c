#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/kobject.h>
#include <linux/sysfs.h>
#include <linux/string.h>
#include <linux/slab.h>

static struct kobject *hello_kobj;

static ssize_t hello_print(struct kobject *kobj,
                           struct kobj_attribute *attr, const char *buf, size_t count)
{
    char tmp[128];

    if (count >= sizeof(tmp))
        return -EINVAL;

    strncpy(tmp, buf, count);
    tmp[count] = '\0';

    pr_info("hello_world received: %s\n", tmp);

    return count;
}

static struct kobj_attribute hello_attribute =
    __ATTR(hello, 0200, NULL, hello_print);

static int __init hello_sysfs_init(void)
{
    int retval;

    hello_kobj = kobject_create_and_add("hello_world", kernel_kobj);
    if (!hello_kobj)
        return -ENOMEM;

    retval = sysfs_create_file(hello_kobj, &hello_attribute.attr);
    if (retval)
        kobject_put(hello_kobj);

    pr_info("hello_world_sysfs: device_initcall loaded\n");
    return retval;
}

device_initcall(hello_sysfs_init);
