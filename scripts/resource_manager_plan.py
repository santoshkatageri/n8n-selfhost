#!/usr/bin/env python3
"""Create plans for Git-sourced OCI stacks; never apply or expose plan contents."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import zipfile


def oci_json(*args):
    result = subprocess.run(['oci', *args], capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError('OCI operation failed; inspect its job privately in Resource Manager.')
    return json.loads(result.stdout)


def main():
    required = ('OCI_USER_OCID', 'OCI_TENANCY_OCID', 'OCI_FINGERPRINT', 'OCI_PRIVATE_KEY',
                'OCI_COMPARTMENT_STACK_OCID', 'OCI_CONTROLLER_STACK_OCID', 'GITHUB_REPOSITORY', 'GITHUB_SHA')
    if any(not os.environ.get(key) for key in required):
        raise RuntimeError('Required protected OCI workflow settings are missing.')
    with tempfile.TemporaryDirectory(prefix='oci-plan-') as temp:
        root = Path(temp)
        root.chmod(0o700)
        key = root / 'key.pem'
        key.write_text(os.environ['OCI_PRIVATE_KEY'])
        key.chmod(0o600)
        config = root / 'config'
        config.write_text('[DEFAULT]\n' + '\n'.join([
            'user=' + os.environ['OCI_USER_OCID'],
            'tenancy=' + os.environ['OCI_TENANCY_OCID'],
            'fingerprint=' + os.environ['OCI_FINGERPRINT'],
            'key_file=' + str(key), 'region=us-ashburn-1']) + '\n')
        config.chmod(0o600)
        os.environ['OCI_CLI_CONFIG_FILE'] = str(config)
        for name, setting in [('compartment', 'OCI_COMPARTMENT_STACK_OCID'),
                              ('controller', 'OCI_CONTROLLER_STACK_OCID')]:
            stack_id = os.environ[setting]
            source = oci_json('resource-manager', 'stack', 'get', '--stack-id', stack_id)['data']['config-source']
            expected_url = 'https://github.com/' + os.environ['GITHUB_REPOSITORY']
            if (source.get('config-source-type') != 'GIT_CONFIG_SOURCE'
                    or source.get('repository-url', '').removesuffix('.git') != expected_url
                    or source.get('branch-name') != 'main'
                    or source.get('working-directory') != 'terraform/' + name):
                raise RuntimeError('Stack source does not match this repository, main and its working directory.')
            job = oci_json('resource-manager', 'job', 'create-plan-job', '--stack-id', stack_id,
                           '--display-name', 'github-plan-' + name + '-' + os.environ['GITHUB_SHA'][:12],
                           '--wait-for-state', 'SUCCEEDED', '--wait-for-state', 'FAILED',
                           '--max-wait-seconds', '900')['data']
            if job['lifecycle-state'] != 'SUCCEEDED':
                raise RuntimeError('The plan failed; inspect its logs privately in Resource Manager.')
            archive = root / (name + '.zip')
            result = subprocess.run(['oci', 'resource-manager', 'job', 'get-job-tf-config',
                                     '--job-id', job['id'], '--file', str(archive)], capture_output=True)
            if result.returncode:
                raise RuntimeError('Unable to verify the source snapshot used for the plan.')
            with zipfile.ZipFile(archive) as files:
                entries = {p for p in files.namelist() if not p.endswith('/')}
                local = Path('terraform') / name
                for path in local.iterdir():
                    if path.name.endswith('.tf') or path.name == '.terraform.lock.hcl':
                        match = [p for p in entries if p == path.name or p == str(path)]
                        if len(match) != 1 or files.read(match[0]) != path.read_bytes():
                            raise RuntimeError('Plan source differs from this checkout. Review a fresh plan.')
            print(f'{name}: plan succeeded and Terraform source matches this checkout. No apply was run.')
            summary = os.environ.get('GITHUB_STEP_SUMMARY')
            if summary:
                with open(summary, 'a') as output:
                    output.write(f'- {name}: verified plan succeeded. Review its private Resource Manager job before manual apply.\n')


if __name__ == '__main__':
    main()
