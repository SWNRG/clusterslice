#!/usr/bin/env python

import geni.cloudlab_util as cl
from geni.rspec import pg as rspec
import os
import sys

requests = {}

def check_var(argument, varname):
    if not argument and not os.environ[varname]:
        raise Exception("Expecting '{}' environment variable".format(varname))

    return os.environ[varname]

def create_request(_site, hw_type, num_nodes, img):
    for i in range(0, num_nodes):
        node = rspec.RawPC('node' + str(i))
        node.disk_image = img
        node.hardware_type = hw_type
        if _site not in requests:
            requests[_site] = rspec.Request()
        requests[_site].addResource(node)

def parse_arguments(args):
    arg_sets = []
    num_args = len(args)

    i = 1 
    while i < num_args:
        site = args[i]
        nodes_type = args[i + 1]
        nodes_number = args[i + 2]
        masters_number = args[i + 3]
        image = args[i + 4]
        arg_sets.append((site, nodes_type, int(nodes_number), int(masters_number), image))
        i += 5

    return arg_sets

def extract_hostname(domain_name):
    # Split the domain_name using the '.' separator
    parts = domain_name.split('.')
    
    # Extract the hostname (the first part)
    hostname = parts[0]
    
    return hostname



# main code

if len(sys.argv) < 6 or len(sys.argv) % 5 != 1:
    print ("no or wrong parameters have been passed, using env variables.")
    image=''
    site=''
    nodes_number=''
    nodes_type=''
    masters_number=''
    image = check_var(image, 'CLOUDLAB_IMAGE')
    site = check_var(site, 'CLOUDLAB_SITE')
    nodes_number = check_var(nodes_number, 'CLOUDLAB_NODES_NUMBER')
    masters_number = check_var(masters_number, 'MASTERS_NUMBER')
    nodes_type = check_var(nodes_type, 'CLOUDLAB_NODES_TYPE')
    # append arguments to arg_sets
    arg_sets = []
    arg_sets.append((site, nodes_type, int(nodes_number), int(masters_number), image))
else:
    # parse the arguments in sets of four
    arg_sets = parse_arguments(sys.argv)

# input variables for generic configuration
user=''
project=''
cert_path=''
key_path=''
experiment=''
domain=''

user = check_var(user, 'CLOUDLAB_USER')
#cloudlab_password = check_var(cloudlab_password, 'CLOUDLAB_PASSWORD')
project = check_var(project, 'CLOUDLAB_PROJECT')
cert_path = check_var(cert_path, 'CLOUDLAB_CERT_PATH')
key_path = check_var(key_path, 'CLOUDLAB_PUBKEY_PATH')
experiment = check_var(key_path, 'CLOUDLAB_EXPERIMENT')
domain = check_var(key_path, 'DOMAIN')

nodes_type_dict = {}

for site, nodes_type, nodes_number, masters_number, image in arg_sets:
    # Define the image
    img = "urn:publicid:IDN+emulab.net+image+emulab-ops//" + image # UBUNTU22-64-STD

    # Create request object out of input variables
    #create_request(site, nodes_type, nodes_number, img)
    print ("creating request for site:" + site + " nodes_type:" + nodes_type + " nodes_number:" + str(nodes_number) + " image:" + img)
    create_request(site, nodes_type, int(nodes_number), img)
    # keep nodes_type in a dictonary with key the site
    nodes_type_dict[site]=nodes_type

# Example that boots four node in emulab
# create_request('pg-utah', 'pc3000', 4, 'UBUNTU22-64-STD')

# Example that boots a node in Virtual Wall 2
#create_request('pg-wall2', 'pc', 1, 'UBUNTU22-64-STD')

# defining image
#img = "urn:publicid:IDN+emulab.net+image+emulab-ops//" + image # UBUNTU22-64-STD

# creates request object out of input variables
#create_request(site, nodes_type, int(nodes_number), img)

# executing request
m = cl.request(experiment_name=experiment+'-'+project,
               requests=requests,
               expiration=2880,
               timeout=15,
               cloudlab_user=user,
               cloudlab_project=project,
               cloudlab_cert_path=cert_path,
               cloudlab_key_path=key_path)

if m is None:
    print ("Failed to create slice. Trying one more time after releasing slice.")
    # releasing all slices
    for site,request in requests.iteritems():
        m = cl.release(experiment_name=experiment+'-'+project,
                       cloudlab_site=site,
                       cloudlab_user=user,
                       cloudlab_project=project,
                       cloudlab_cert_path=cert_path,
                       cloudlab_key_path=key_path)

    m = cl.request(experiment_name=experiment+'-'+project,
               requests=requests,
               expiration=240,
               timeout=15,
               cloudlab_user=user,
               cloudlab_project=project,
               cloudlab_cert_path=cert_path,
               cloudlab_key_path=key_path)

    if m is None:
        exit (1)

# show IPs of allocated machines
print ("The IPs of the allocated machines follow:")
hostIPs={}
privateHostIPs={}

for keys,values in m.items():
    hostIPs[keys]=[]
    privateHostIPs[keys]=[]
    for node in values.nodes:
        # Keep all host IPs
        hostIPs[keys].append(node.hostipv4)
        for i in node.interfaces:
            privateHostIPs[keys].append(i.address_info[0])

print (hostIPs)

print("Writing output files.")
# creating ansible file
with open('machines', 'w') as f:
    f.write('[cloudlab]'+os.linesep)
    for site, manifest in m.iteritems():
        for n in manifest.nodes:
#            print ("node:"+str(dir(n)))
#            print ("logins:"+str(dir(n.logins)))
            for services in n.logins:
               # print ("services:"+str(dir(services)))
            #    for login in services:
            #        print ("login:"+str(dir(login)))
            #        if not (login.get('hostname') is None):
            #            f.write (login.get('hostname'))
              #  f.write(n.hostfqdn)
                f.write(extract_hostname(services.hostname))
                f.write(' ansible_ssh_host=' + n.hostipv4)
                f.write(' ansible_ssh_port=22')
                f.write(' ansible_ssh_user=' + user)
                f.write(' host_key_checking=False' +os.linesep)

        with open('output-{}.xml'.format(site), 'w') as mf:
            mf.write(manifest.text)

# creating computeresources yaml file
counter=1
with open('cloudlab-cr.yaml', 'w') as f:
    for site, manifest in m.iteritems():
        for n in manifest.nodes:
            for services in n.logins:
                hostname=extract_hostname(services.hostname)
            f.write("---" + os.linesep)
            f.write("apiVersion: \"swn.uom.gr/v1\"" + os.linesep)
            f.write("kind: ComputeResource" + os.linesep)
            f.write ("metadata:" + os.linesep)
            f.write ("  name: " + hostname + "-" + site + os.linesep)
            f.write ("  namespace: swn" + os.linesep)
            f.write ("spec:" + os.linesep)
            f.write ("  ip: \"" + n.hostipv4 + "\"" + os.linesep)
            if counter > masters_number:
                f.write ("  resourcetype: \"workernode\"" + os.linesep)
            else:
                f.write ("  resourcetype: \"masternode\"" + os.linesep)
            f.write ("  nodetype: \"" + nodes_type_dict[site] + "\"" + os.linesep)
            f.write ("  mac: \"\"" + os.linesep)
            f.write ("  domain: \"" + domain + "\"" + os.linesep)
            f.write ("  operator: \"resource-manager\"" + os.linesep)
            f.write ("  status: os_ready" + os.linesep)
            counter=counter+1
