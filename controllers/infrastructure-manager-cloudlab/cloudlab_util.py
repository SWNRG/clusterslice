#!/usr/bin/env python

from geni.aggregate import cloudlab as cl
from geni.aggregate import protogeni as pg
from geni.aggregate.apis import DeleteSliverError
from geni.aggregate.frameworks import ClearinghouseError
from geni.minigcf.config import HTTP
from geni.util import loadContext
from geni.rspec import pg as rspec

import datetime
import json
import os
import time

HTTP.TIMEOUT = 600

agg = {
    'apt': cl.Apt,
    'cl-clemson': cl.Clemson,
    'cl-utah': cl.Utah,
    'cl-wisconsin': cl.Wisconsin,
    #'ig-utahddc': cl.UtahDDC,
    #'pg-kentucky': pg.Kentucky_PG,
    'pg-utah': pg.UTAH_PG,
}


def check_var(argument, varname):
    if not argument and not os.environ[varname]:
        raise Exception("Expecting '{}' environment variable".format(varname))

    return os.environ[varname]


def get_slice(cloudlab_user, cloudlab_password,
              cloudlab_project, cloudlab_cert_path,
              cloudlab_key_path, experiment_name, expiration=120,
              create_if_not_exists=False, renew_slice=False):

    #cloudlab_user = check_var(cloudlab_user, 'CLOUDLAB_USER')
    #cloudlab_password = check_var(cloudlab_password, 'CLOUDLAB_PASSWORD')
    #cloudlab_project = check_var(cloudlab_project, 'CLOUDLAB_PROJECT')
    #cloudlab_cert_path = check_var(cloudlab_cert_path, 'CLOUDLAB_CERT_PATH')
    #cloudlab_key_path = check_var(cloudlab_key_path, 'CLOUDLAB_PUBKEY_PATH')

    with open('/tmp/context.json', 'w') as f:
        data = {
            "framework": "emulab-ch2",
            "cert-path": cloudlab_cert_path,
            "key-path": cloudlab_cert_path,
            "user-name": cloudlab_user,
            "user-urn": "urn:publicid:IDN+emulab.net+user+"+cloudlab_user,
            "user-pubkeypath": cloudlab_key_path,
            "project": cloudlab_project
        }
        json.dump(data, f)

    print("Loading GENI context")
    c = loadContext("/tmp/context.json") #, key_passphrase=cloudlab_password)

    slice_id = (
        "urn:publicid:IDN+emulab.net:{}+slice+{}"
    ).format(cloudlab_project, experiment_name)

    exp = datetime.datetime.now() + datetime.timedelta(minutes=expiration)

    print("Available slices: {}".format(c.cf.listSlices(c).keys()))
    if slice_id in c.cf.listSlices(c):
        print("Using existing slice {}".format(slice_id))
        if renew_slice:
            print("Renewing slice for {} more minutes".format(expiration))
            c.cf.renewSlice(c, experiment_name, exp=exp)
    else:
        if create_if_not_exists:
            print("Creating slice {} ({} minutes)".format(slice_id,
                                                          expiration))
            c.cf.createSlice(c, experiment_name, exp=exp)
        else:
            print("We couldn't find a slice for {}.".format(experiment_name))
            return None

    return c


def filter_unavailable_hwtypes(ctxt, requests):
    """Removes nodes of particular hwtypes if they're not available.
    """
    available_hwtypes = set()

    for site in requests:
        print("querying site: " + site)
        ad = agg[site].listresources(ctxt, available=True)

        for node in ad.nodes:
            if not node.available:
                continue
            available_hwtypes.update(node.hardware_types.keys())

    filtered_requests = {}
    for site in requests:
        print("Checking requests for site: " + site)
        for r in requests[site].resources:
            print("Checking if node type " + r.hardware_type + " is available")
            if r.hardware_type in available_hwtypes:
                print("  It is available!")
                if site not in filtered_requests:
                    filtered_requests[site] = rspec.Request()
                filtered_requests[site].addResource(r)
            else:
                print("  It is NOT available :-(")

    return filtered_requests


def do_request(ctxt, exp_name, requests, timeout,
               ignore_failed_slivers, skip_unavailable_hwtypes=True):

    manifests = {}

    if skip_unavailable_hwtypes:
        print("Will query for available hardware types and filter requests.")
        requests = filter_unavailable_hwtypes(ctxt, requests)

    failed = set()

    for site, request in requests.iteritems():

        print("Creating sliver on " + site)

        try:
            manifests[site] = agg[site].createsliver(ctxt, exp_name, request)
        except ClearinghouseError:
            # sometimes slice creating takes a bit, so we wait for 30 secs
            time.sleep(30)
            manifests[site] = agg[site].createsliver(ctxt, exp_name, request)
        except Exception as e:
            print("Failed trying to create sliver on {}.".format(site))
            print(e)
            return
            if ignore_failed_slivers:
                print("Will ignore and keep going")
                failed.add(site)
                try:
                    agg[site].deletesliver(ctxt, exp_name)
                except DeleteSliverError as delerror:
                    print('Got DeleteSilverError... skipping site.')
                    print(delerror)

    print("Waiting for resources to come up online")
    sites = set(requests.keys()) - failed
    ready = set()
    timeout = time.time() + 60 * timeout
    while True:
        time.sleep(60)
        for site in sites - ready:
            try:
                status = agg[site].sliverstatus(ctxt, exp_name)
            except Exception:
                break

            if status['pg_status'] == 'ready':
                ready.add(site)

        if sites == ready:
            # all good!
            break

        if time.time() > timeout:
            if ignore_failed_slivers:
                break

            for site in sites - ready:
                do_release(ctxt, exp_name, site)
                del manifests[site]
            raise Exception("Not all nodes came up after 15 minutes")

    return manifests


def do_release(ctxt, exp_name, site):
    try:
        print('Deleting sliver on ' + site + ".")
        agg[site].deletesliver(ctxt, exp_name)
    except ClearinghouseError as e:
        print('Got ClearinghouseError: "{}". Retrying.'.format(e))
        time.sleep(10)
        try:
            agg[site].deletesliver(ctxt, exp_name)
        except DeleteSliverError as err:
            print('Got DeleteSilverError: "{}".'.format(err))
            return
    except DeleteSliverError as e:
        print('Got DeleteSilverError: "{}".'.format(e))
        return

    print('Finished releasing resources on requested site')


def request(experiment_name=None,  
            requests=None, timeout=15, expiration=120,
            cloudlab_user=None, cloudlab_password=None,
            cloudlab_project=None, cloudlab_cert_path=None,
            cloudlab_key_path=None, ignore_failed_slivers=False):

    if not experiment_name or not requests:
        raise Exception("Expecting 'experiment_name' and 'requests' args")

    ctxt = get_slice(cloudlab_user, cloudlab_password, cloudlab_project,
                     cloudlab_cert_path, cloudlab_key_path,
                     experiment_name, expiration,
                     create_if_not_exists=True, renew_slice=False)

    return do_request(ctxt, experiment_name, requests,
                      timeout, ignore_failed_slivers)


def print_slivers(experiment_name, cloudlab_site=None, cloudlab_user=None,
                  cloudlab_password=None, cloudlab_project=None,
                  cloudlab_cert_path=None, cloudlab_key_path=None):
    print('Checking if slice for experiment exists')
    ctxt = get_slice(cloudlab_user, cloudlab_password, cloudlab_project,
                     cloudlab_cert_path, cloudlab_key_path,
                     experiment_name)
    if ctxt is None:
        return

    try:
        status = agg[cloudlab_site].sliverstatus(ctxt, experiment_name)
        print(json.dumps(status, indent=2))
    except Exception as e:
        print("#####################")
        print("{}: {}\n. Skipping.".format(cloudlab_site, e))
        print("#####################")
        #print(json.dumps(status, indent=2))


def release(experiment_name=None, cloudlab_site=None, cloudlab_user=None,
            cloudlab_password=None, cloudlab_project=None,
            cloudlab_cert_path=None, cloudlab_key_path=None):

    ctxt = get_slice(cloudlab_user, cloudlab_password, cloudlab_project,
                     cloudlab_cert_path, cloudlab_key_path,
                     experiment_name)
    if ctxt is not None:
        do_release(ctxt, experiment_name, cloudlab_site)
    else:
        print('No slice for experiment, all done.')


def renew(experiment_name=None, cloudlab_user=None, expiration=120,
          cloudlab_password=None, cloudlab_project=None,
          cloudlab_cert_path=None, cloudlab_key_path=None):
    ctxt = get_slice(cloudlab_user, cloudlab_password, cloudlab_project,
                     cloudlab_cert_path, cloudlab_key_path,
                     experiment_name, expiration,
                     create_if_not_exists=False, renew_slice=True)

    if ctxt is None:
        return

    exp = datetime.datetime.now() + datetime.timedelta(minutes=expiration)

    for site in agg.keys():
        try:
            agg[site].renewsliver(ctxt, experiment_name, exp)
            status = agg[site].sliverstatus(ctxt, experiment_name)
        except Exception as e:
            print("#####################")
            print("{}: {}\n. Skipping.".format(site, e))
            print("#####################")
        print(json.dumps(status, indent=2))
