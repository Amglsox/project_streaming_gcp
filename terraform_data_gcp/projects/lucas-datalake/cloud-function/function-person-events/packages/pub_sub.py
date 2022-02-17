from google.cloud import pubsub_v1

import os
import simplejson as json

# Get Env Vars
class PubSub:
    def __init__(self, PROJECT_ID):
        # Init PubSub client
        self.publisher = pubsub_v1.PublisherClient()
        self.queued = True
        self.project_id = PROJECT_ID
    
    def publish_message_datalake(self, topic_name, message):
        # Define topic path
        topic = self.publisher.topic_path(self.project_id, topic_name)

        # Publish message
        message_future = self.publisher.publish(
            topic,
            data=json.dumps(message).encode("UTF-8")
        )
        message_future.add_done_callback(self.callback)

    def callback(self, message_future):
        # When timeout is unspecified, the exception method waits indefinitely.
        if message_future.exception(timeout=30):
            self.queued = False