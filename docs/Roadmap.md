## Feature Roadmap

- Handle additional fields in custom CommunicationEvents (see coaty-unity)
- Error rethrowing rather than nil
- Implementation of communication manager, including Advertise-, Deadvertise-, 
Discover/Resolve-, Query/Retrieve- & Channel Events-
- Caching of subscriptions and publications -> Check whether the MQTT client 
already implements caching functionality
- Broker Discovery (can be found in coaty-js: node.ts) based on Bonjour, 
ask Maxim for more details about his setup
- As a demo: Rewrite coaty-js hello-world for swift