#!/bin/sh
#
# Read cert.pem and ca.pem, and create signercert.pfx.
#


cat ../../configs/freeradius/certs/cert.pem ca.pem \
 | openssl pkcs12 -export \
     -inkey ../../configs/freeradius/certs/privkey.pem -password "pass:" -out signercert.pfx
chmod 640 signercert.pfx

