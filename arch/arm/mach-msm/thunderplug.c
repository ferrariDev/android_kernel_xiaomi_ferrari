/* Copyright (c) 2015, Varun Chitre <varun.chitre15@gmail.com>
 *
 * This software is licensed under the terms of the GNU General Public
 * License version 2, as published by the Free Software Foundation, and
 * may be copied, distributed, and modified under those terms.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * A simple hotplugging driver optimized for Octa Core CPUs
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/device.h>
#include <linux/cpu.h>
#include <linux/powersuspend.h>
#include <linux/cpufreq.h>

static int suspend_cpu_num = 2;

#define THUNDERPLUG "thunderplug"

#define DRIVER_VERSION  1
#define DRIVER_SUBVER 1

static ssize_t thunderplug_suspend_cpus_show(struct kobject *kobj, struct kobj_attribute *attr, char *buf)
{
    return sprintf(buf, "%d", suspend_cpu_num);
}

static ssize_t thunderplug_suspend_cpus_store(struct kobject *kobj, struct kobj_attribute *attr, const char *buf, size_t count)
{
	int val;
	sscanf(buf, "%d", &val);
	if(val < 1 || val > 7)
		pr_info("%s: suspend cpus off-limits\n", THUNDERPLUG);
	else
		suspend_cpu_num = val;

	return count;
}

static inline void offline_cpus()
{
	unsigned int cpu;
	for(cpu = 7; cpu > (suspend_cpu_num - 1); cpu--) {
		if (cpu_online(cpu))
			cpu_down(cpu);
	}
	pr_info("%s: %d cpus were offlined\n", THUNDERPLUG, suspend_cpu_num);
}

static inline void cpus_online_all(void)
{
	unsigned int cpu;

	for (cpu = 1; cpu < 8; cpu++) {
		if (cpu_is_offline(cpu))
			cpu_up(cpu);
	}

	pr_info("%s: all cpus were onlined\n", THUNDERPLUG);
}

static void thunderplug_suspend(struct power_suspend *h)
{
	offline_cpus();

	pr_info("%s: suspend\n", THUNDERPLUG);
}

static void __ref thunderplug_resume(struct power_suspend *h)
{
	cpus_online_all();

	pr_info("%s: resume\n", THUNDERPLUG);
}

static ssize_t thunderplug_ver_show(struct kobject *kobj, struct kobj_attribute *attr, char *buf)
{
       return sprintf(buf, "ThunderPlug %u.%u", DRIVER_VERSION, DRIVER_SUBVER);
}

static struct kobj_attribute thunderplug_ver_attribute =
       __ATTR(version,
               0444,
               thunderplug_ver_show, NULL);

static struct kobj_attribute thunderplug_suspend_cpus_attribute =
       __ATTR(suspend_cpus,
               0666,
               thunderplug_suspend_cpus_show, thunderplug_suspend_cpus_store);

static struct attribute *thunderplug_attrs[] =
    {
        &thunderplug_ver_attribute.attr,
        &thunderplug_suspend_cpus_attribute.attr,
        NULL,
    };

static struct attribute_group thunderplug_attr_group =
    {
        .attrs = thunderplug_attrs,
    };

static struct power_suspend thunderplug_power_suspend_handler = 
	{
		.suspend = thunderplug_suspend,
		.resume = thunderplug_resume,
	};

static struct kobject *thunderplug_kobj;

static int __init thunderplug_init(void)
{
        int ret = 0;
        int sysfs_result;
        printk(KERN_DEBUG "[%s]\n",__func__);

        thunderplug_kobj = kobject_create_and_add("thunderplug", kernel_kobj);

        if (!thunderplug_kobj) {
                pr_err("%s Interface create failed!\n",
                        __FUNCTION__);
                return -ENOMEM;
        }

        sysfs_result = sysfs_create_group(thunderplug_kobj, &thunderplug_attr_group);

        if (sysfs_result) {
                pr_info("%s sysfs create failed!\n", __FUNCTION__);
                kobject_put(thunderplug_kobj);
        }

        register_power_suspend(&thunderplug_power_suspend_handler);

        pr_info("%s: init\n", THUNDERPLUG);

        return ret;
}

static void __exit thunderplug_exit(void)
{
        unregister_power_suspend(&thunderplug_power_suspend_handler);
}


MODULE_LICENSE("GPL and additional rights");
MODULE_AUTHOR("Varun Chitre <varun.chitre15@gmail.com>");
MODULE_DESCRIPTION("Hotplug driver for OctaCore CPU");
late_initcall(thunderplug_init);
module_exit(thunderplug_exit);
