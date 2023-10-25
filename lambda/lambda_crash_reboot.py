import json
import boto3

def lambda_handler(event, context):
    client = boto3.client('ecs')
    response = client.update_service(
        cluster='phoenix-cluster',
        service='phoenix-service',
        desiredCount=1
    )
    return {
        'statusCode': 200,
        'body': json.dumps('Successfully restarted service.')
    }
