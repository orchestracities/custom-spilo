# custom-spilo
A custom docker image based on spilo (https://github.com/zalando/spilo)
including CartoDB extensions.

Current configuration is for carto v4.29.0.

To build extension for a new version of carto, you need to update
version used in the Dockerfile of the following services:

- https://github.com/CartoDB/cartodb-postgresql version 0.28.1
- https://github.com/CartoDB/crankshaft version  master
- https://github.com/CartoDB/data-services version 0.0.2
- https://github.com/CartoDB/dataservices-api version 0.35.1-server
- https://github.com/CartoDB/observatory-extension version 1.9.0

Be aware that tracking matching versions between carto components is not
so obvious.
