#!/usr/bin/env python

import geni.cloudlab_util as cl
from geni.rspec import pg as rspec
import os

def check_var(argument, varname):
    if not argument and not os.environ[varname]:
        raise Exception("Expecting '{}' environment variable".format(varname))

    return os.environ[varname]

# input variables
user=''
project=''
cert_path=''
key_path=''
site=''
experiment=''

user = check_var(user, 'CLOUDLAB_USER')
#cloudlab_password = check_var(cloudlab_password, 'CLOUDLAB_PASSWORD')
project = check_var(project, 'CLOUDLAB_PROJECT')
cert_path = check_var(cert_path, 'CLOUDLAB_CERT_PATH')
key_path = check_var(key_path, 'CLOUDLAB_PUBKEY_PATH')
site = check_var(site, 'CLOUDLAB_SITE')
experiment = check_var(key_path, 'CLOUDLAB_EXPERIMENT')

m = cl.release(experiment_name=experiment+'-'+project,
               cloudlab_site=site,
               cloudlab_user=user,
               cloudlab_project=project,
               cloudlab_cert_path=cert_path,
               cloudlab_key_path=key_path)
