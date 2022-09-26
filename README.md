# Ansible Kubeflow
A Kubeflow pipeline that run an Ansible playbook on a subset of devices

## Pipeline input

```json
{
  "playbook_repo": "<git repo with a playbook>",
  "playbook_path": "<path to playbook in repo>",
  "playbook_localhost_path": "<optional path to playbook in repo for playbook to run on localhost in prepare step>",
  "ansible_limit": "<ansible limit>",
  "add_device_label": "<optional label to add to device after successful play>"
}
```

> __**Label**__
> One label can be added with format "key=value". It will be added to devices that were successful.
> Adding a label also do discard any errors in the play and pipeline will be successful even if the play fails.

### Ansible limit
A limit is used, following the patterns in Ansible, to select devices to run the patch on.
Se reference doc here:
[https://docs.ansible.com/ansible/latest/user_guide/intro_patterns.html](https://docs.ansible.com/ansible/latest/user_guide/intro_patterns.html)

> **The Teknoir inventory:**
> Namespaces/labels become groups, Ansible do not support namespaces/labels with dashes(-) or dots(.).
> Dashes(-) and dots(.) will be replaced with underscores(_).
> Remember that when using them!

## Patching "technique"
Devices might not be accessible, for different reasons.
There is a technique to make sure the patch only runs once per device.
By matching limit and when finished modifying device labels...TBD
Schedule recurrant job
