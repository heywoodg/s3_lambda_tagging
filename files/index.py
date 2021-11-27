import json
import urllib.parse
import boto3
import datetime

print('Loading function')

s3 = boto3.client('s3')
now = datetime.datetime.now()
tagValue = now.date()
tagName = "MyTag"


def lambda_handler(event, context):
    print("Recevied event: " + json.dumps(event, indent=2))
    
    #Get the object from the event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    
    if not key.endswith("/"):
        try:
            response = s3.put_object_tagging(
                Bucket = bucket,
                Key = key,
                Tagging={
                    'TagSet': [
                        {
                            'Key': tagName,
                            'Value': str(tagValue)
                        },
                    ]
                }
            )
        except Exception as e:
            print(e)
            print('Error applying tag {} to {}.'.format(tagName, key))
            raise e