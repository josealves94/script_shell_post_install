#!/usr/bin/env python
#
# Based on Autoscaling or Manual notifications delete a hostname from
# PuppetDB, Puppet Dashboard and its certificate file
#
# Events:
# autoscaling:EC2_INSTANCE_TERMINATE
# manual:EC2_INSTANCE_TERMINATE
#

import sys
import json
import subprocess
import boto.sqs
import boto.ec2
from boto.sqs.message import RawMessage

region = sys.argv[1]
sqsqueuename = sys.argv[2]

def puppet_cleanup(instanceid):
    print "\ninstance: %s" % instanceid

    cmd = subprocess.Popen('puppet cert list --all | sed -ne \'/%s/s/.*"\([^"]*\)".*/\\1/p\'' % instanceid, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    hostname, cert_err = cmd.communicate()

    if not hostname == "":
        print "Cleaning up certificate for %s" % hostname
        cmd = subprocess.Popen('puppet node clean --unexport %s' % hostname, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        node_clean_output, node_clean_err = cmd.communicate()
        print node_clean_output

        print "Deactivating %s on PuppetDB" % hostname
        cmd = subprocess.Popen('puppet node deactivate %s' % hostname, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        node_deactivate_output, node_deactivate_err = cmd.communicate()
        print node_deactivate_output

        print "Cleaning up dashboard for %s" % hostname
        cmd = subprocess.Popen('rake RAILS_ENV=production -f /usr/share/puppet-dashboard/Rakefile node:del name=%s' % hostname, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        rake_output, rake_err = cmd.communicate()
        print rake_output

        print "Removing certificate whitelist for %s" % hostname
        f = open ("/etc/puppet/autosign.conf", "r+")
        d = f.readlines()
        f.seek(0)
        for i in d:
            if not i.startswith(instanceid + "-" + region):
                f.write(i)
        f.truncate()
        f.close()
    else:
        print "Certificate not found for %s" % instanceid

    return
    
    def main():
    conn = boto.sqs.connect_to_region(region)
    ec2_conn = boto.ec2.connect_to_region(region)

    q = conn.get_queue("coyote_sqs")
    q.set_message_class(RawMessage)
    results = q.get_messages(num_messages=10, wait_time_seconds=20)
    if not len(results) == 0:
        for result in results:
            body = json.loads(result.get_body())
            msg = json.loads(body['Message'])
            event = msg['Event']
            if 'EC2InstanceId' in msg:
                instanceid = msg['EC2InstanceId']
                # Look for (autoscaling,manual):EC2_INSTANCE_TERMINATE events
                if 'EC2_INSTANCE_TERMINATE' in event:
                    puppet_cleanup(instanceid)
                    q.delete_message(result)
                elif 'EC2_INSTANCE_LAUNCH_' in event:
                    print "Removing not used message event %s from queue" % event
                    q.delete_message(result)
                elif 'EC2_INSTANCE_LAUNCH' in event:
                    print "Found a launch event for instance ID %s" % instanceid
                    cert_name = instanceid + "-" + region + ".amazonaws.com"
                    with open ("/etc/puppet/autosign.conf", "a") as autosignconf:
                        autosignconf.write (cert_name + "\n")
                    print "Signing instance certificate " + cert_name
                    cmd = subprocess.Popen('puppet cert sign %s' % cert_name, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
                    sign_cert_out, sign_cert_err = cmd.communicate()
                    print sign_cert_out
                    q.delete_message(result)
                else:
                    print "Removing not used message event %s from queue" % event
                    q.delete_message(result)
            exit()

if __name__ == "__main__":
    main()
