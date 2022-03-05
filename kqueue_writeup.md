## kqueue writeup

First of all, I apologize for the mistakes about challenge environment, which caused a low-level unexpected solution.

The inspiration for this challenge is that I wrote a simple queue and created a double-free vulnerability by imitating the "kstack"  on SECCON.

Unlike kstack, I added SMAP protection to the kernel, so theoretically you can't do ROP attacks through stack pivot, but the method of leaking kernel addresses can still refer to kstack's writeup.

##### Vulnerability

```c
static int ioctl_deque(void __user *argp) {
  node_t *tmp = queue->head;
  node_t *newHead = tmp->next;
  if (newHead == NULL)
    return -1;
  if(copy_to_user(argp, &newHead->value, sizeof(unsigned long)))
    return -2;
  mutex_lock(&queue->headlock);
  queue->head = newHead;
  kfree(tmp);
  mutex_unlock(&queue->headlock);
  return 0;
}
```

Since the copy_to_user function precedes the lock take operation, it is obvious that we can use the userfaultfd mechanism to create an operation that deletes the same node twice.

##### Exploit

There should be a variety of methods for the leakage of the kernel address. The basic idea is to obtain 0x20 size dirty data which contains kernel pointer at offset 8, then use deque to leak it out. Here I choose shm_file_data structure.

```c
// ipc/shm.c
struct shm_file_data {
	int id;
	struct ipc_namespace *ns;
	struct file *file;
	const struct vm_operations_struct *vm_ops;
};
```

Simply speaking, my expected solution to the problem is to rewrite modprobe_path through double free to execute the shell script to obtain the flag, the only difficulty is that enque cannot start writing from offset 0, that is to say, it cannot directly write the "next" pointer of the freed object, so I can provide two solutions here

1> Use the setxattr() function

```c
// fs/xattr.c
static long
setxattr(struct dentry *d, const char __user *name, const void __user *value,
	 size_t size, int flags)
{
	int error;
	void *kvalue = NULL;
	char kname[XATTR_NAME_MAX + 1];

	if (flags & ~(XATTR_CREATE|XATTR_REPLACE))
		return -EINVAL;

	error = strncpy_from_user(kname, name, sizeof(kname));
	if (error == 0 || error == sizeof(kname))
		error = -ERANGE;
	if (error < 0)
		return error;

	if (size) {
		if (size > XATTR_SIZE_MAX)
			return -E2BIG;
		kvalue = kvmalloc(size, GFP_KERNEL);
		if (!kvalue)
			return -ENOMEM;
		if (copy_from_user(kvalue, value, size)) {
			error = -EFAULT;
			goto out;
		/* ... */
out:
	kvfree(kvalue);

	return error;
}
```

kvmalloc actually uses kmalloc to get object (especially when request size is smaller than page size), we can use this kernel function to write "next" pointer.

2> Using the proc_pid_attr_write() function

When we write data to /proc/self/attr/current, the following function will be triggered:

```c
// fs/proc/base.c
static ssize_t proc_pid_attr_write(struct file * file, const char __user * buf,
				   size_t count, loff_t *ppos)
{
	struct inode * inode = file_inode(file);
	struct task_struct *task;
	void *page;
	int rv;

	rcu_read_lock();
	task = pid_task(proc_pid(inode), PIDTYPE_PID);
	if (!task) {
		rcu_read_unlock();
		return -ESRCH;
	}
	/* A task may only write its own attributes. */
	if (current != task) {
		rcu_read_unlock();
		return -EACCES;
	}
	/* Prevent changes to overridden credentials. */
	if (current_cred() != current_real_cred()) {
		rcu_read_unlock();
		return -EBUSY;
	}
	rcu_read_unlock();

	if (count > PAGE_SIZE)
		count = PAGE_SIZE;

	/* No partial writes. */
	if (*ppos != 0)
		return -EINVAL;

	page = memdup_user(buf, count);
	/* ... */
out_free:
	kfree(page);
out:
	return rv;
}
```

proc_pid_attr_write() calls memdup_user() to copy the user-mode data to the object of the temporary buffer. Let’s take a look at memdup_user():

```c
// mem/util.c
void *memdup_user(const void __user *src, size_t len)
{
	void *p;

	p = kmalloc_track_caller(len, GFP_USER | __GFP_NOWARN);
	if (!p)
		return ERR_PTR(-ENOMEM);

	if (copy_from_user(p, src, len)) {
		kfree(p);
		return ERR_PTR(-EFAULT);
	}

	return p;
}
```

so this difficulty is solved.

I won't put the complete exp here. There should be many excellent writeups on the Internet. Here I only represent some of my thoughts and understandings on this challenge. I hope it can be helpful to you.
