import boto3
import os
import sys
import time

from datetime import datetime, timedelta


def get_client(service):
    options = {
        'aws_access_key_id': os.environ['AWS_ACCESS_KEY_ID'],
        'aws_secret_access_key': os.environ['AWS_SECRET_ACCESS_KEY'],
        'region_name': os.environ['AWS_DEFAULT_REGION']
    }
    if 'AWS_SESSION_TOKEN' in os.environ:
        options['aws_session_token'] = os.environ['AWS_SESSION_TOKEN']
    return boto3.client(service, **options)


def get_lambda_metrics(metric):
    lambda_name = os.environ['LAMBDA']
    metrics = cw.get_metric_statistics(
        Namespace='AWS/Lambda',
        MetricName=metric,
        Dimensions=[{'Name': 'FunctionName', 'Value': lambda_name}],
        Period=60,
        Statistics=['Sum'],
        StartTime=datetime.today() - timedelta(hours=1),
        EndTime=datetime.today(),
    )

    return sum([x['Sum'] for x in metrics['Datapoints']])


def check_instance(instance, launch_config):
    return all([
        launch_config == instance.get('LaunchConfigurationName'),
        instance['HealthStatus'] == 'Healthy',
        instance['LifecycleState'] == 'InService'
    ])


autoscaling = get_client('autoscaling')
cw = get_client('cloudwatch')

print("Checking Autoscaling Group instances...\n")
asg_name = os.environ['ASG']
endtime = datetime.today() + timedelta(minutes=5)
while datetime.today() < endtime:
    response = autoscaling.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_name])
    asg = response['AutoScalingGroups'][0]

    instance_count = len([x for x in asg['Instances'] if check_instance(x, asg['LaunchConfigurationName'])])
    if instance_count == asg['DesiredCapacity']:
        print("{} instances updated and healthy.  Proceeding to invocation checks...\n".format(instance_count))
        break
    print("{} of {} instances updated and healthy.  Timeout in {}".format(instance_count, asg['DesiredCapacity'],
                                                                          endtime - datetime.today()))
    time.sleep(15)
else:
    sys.exit("Error: Timed out waiting for ASG instances to update")

lambda_errors = get_lambda_metrics('Errors')
lambda_invocations = get_lambda_metrics('Invocations')
print("{} out of {} invocations generated errors\n".format(lambda_errors, lambda_invocations))
if lambda_errors > 0:
    sys.exit("Error: Lambda function encountered errors.")
else:
    print("All test passed.  Exiting successfully...")
