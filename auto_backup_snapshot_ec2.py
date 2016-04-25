import requests
from boto.ec2 import connect_to_region
import datetime  


def get_instance_metadata():
    #############################################
    #
    #  Get instance informations 
    #
    #############################################

    _id = requests.get('http://169.254.169.254/latest/meta-data/instance-id').text
    _available_zone = requests.get('http://169.254.169.254/latest/meta-data/placement/availability-zone').text
    response = {
        "id" : _id,
        "available_zone" : _available_zone[:-1]
        }
    return response

def create_snapshot_daily(instance_info):
    ############################################
    #
    #  Create snapshot
    #
    ############################################
    
    # connect to aws 
    conn = connect_to_region(instance_info['available_zone'])
    
    # get list of volume for instance
    volumes = conn.get_all_volumes(filters={'attachment.instance-id': instance_info['id']})

    for _volume in volumes:
        description = 'daily snapshot for instance {0} ceated at {1}'.format(
            instance_info['id'],
            datetime.datetime.today().strftime('%d-%m-%Y %H:%M:%S'))
        try:
            _snapshot = _volume.create_snapshot(description)
        except:
            raise Exception("unable to create snapshot")
    return True

def cleanup_snapshots(instance_info):

    _now = datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S.000Z')
    _now = datetime.datetime.strptime(
                                            _now,
                                            '%Y-%m-%dT%H:%M:%S.000Z'
                                         )
    # connect to aws 
    conn = connect_to_region(instance_info['available_zone'])
    
    # get list of volume for instance
    volumes = conn.get_all_volumes(filters={'attachment.instance-id': instance_info['id']})
    for _volume in volumes:
        _all_snapshot = _volume.snapshots()
        for _snapshot in _all_snapshot:
            start_time = datetime.datetime.strptime(
                                            _snapshot.start_time,
                                            '%Y-%m-%dT%H:%M:%S.000Z'
                                         )
            duration = (_now - start_time).days
            if duration > 7 :
                _snapshot.delete()

    return True

if __name__ == '__main__':
    _instance_info = get_instance_metadata()
    create_snapshot_daily(_instance_info)
    cleanup_snapshots(_instance_info)
