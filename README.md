# device-patch-base
A Kubeflow pipeline that run an Ansible playbook to patch devices

## Pipeline input

```json
{
  "playbook_repo": "<git repo with a playbook>",
  "playbook_path": "<path to playbook in repo>",
  "ansible_limit": "<ansible limit>"
}
```

### Ansible limit
A limit is used, following the patterns in Ansible, to select devices to run the patch on.
Se reference doc here:
[https://docs.ansible.com/ansible/latest/user_guide/intro_patterns.html](https://docs.ansible.com/ansible/latest/user_guide/intro_patterns.html)

> **The Teknoir inventory:**
> Namespaces/labels become groups, Ansible do not support namespaces/labels with dashes(-).
> Dashes(-) will be replaced with underscores(_).
> Remember that when using them!

## Patching "technique"
Devices might not be accessible, for different reasons.
There is a technique to make sure the patch only runs once per device.
By matching limit and when finished modifying device labels...TBD
Schedule recurrant job
