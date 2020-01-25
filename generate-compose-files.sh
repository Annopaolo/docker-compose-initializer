#!/bin/bash

# Generate keys if necessary
if [ ! -f /compose/cfssl-config/ca.pem ] || [ ! -f /compose/cfssl-config/ca-key.pem ] ; then
	cd /compose/cfssl-config/
	cfssl gencert -initca "csr_root_ca.json" | cfssljson -bare ca
	cd -
fi

# Generate housekeeping keypairs
if [ ! -f /compose/astarte-keys/housekeeping_public.pem ] ; then
    cd /compose/astarte-keys/
    astartectl utils gen-keypair housekeeping
    cd -
fi

# Generate self-signed VerneMQ certificate if necessary
if [ ! -f /compose/vernemq-certs/cert ] ; then
	cd /compose/vernemq-certs/
	# Structure
	mkdir -p ca/certs ca/crl ca/newcerts ca/private
	touch ca/index.txt
	touch ca/index.txt.attr
	echo 1000 > ca/serial

	# The root CA
	openssl genrsa -out ca/private/ca.key.pem 2048
	openssl req -config openssl.cnf -key ca/private/ca.key.pem -new -x509 -days 7300 -sha256 -extensions v3_ca -out ca/certs/ca.cert.pem -subj "/C=IT/O=Astarte Internal/CN=Root CA/"

	openssl req -config openssl.cnf -nodes -newkey rsa:2048 -keyout privkey -out server.csr -subj "/C=IT/O=Astarte Internal/CN=vernemq/"
	openssl ca -batch -config openssl.cnf -extensions server_cert -days 3750 -notext -md sha256 -in server.csr -out server.crt

	# Generate VMQ-friendly certificate with the whole chain
	cat server.crt ca/certs/ca.cert.pem > cert
	cd -
fi
