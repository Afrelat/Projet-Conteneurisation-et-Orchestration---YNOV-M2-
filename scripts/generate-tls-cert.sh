#!/bin/bash

# Generate self-signed TLS certificate for M2Cloud
set -e

DOMAIN="m2cloud.local"
CERT_DIR="./certs"

mkdir -p $CERT_DIR

echo "🔐 Generating self-signed TLS certificate for $DOMAIN"

# Generate private key and certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout $CERT_DIR/tls.key \
  -out $CERT_DIR/tls.crt \
  -subj "/CN=$DOMAIN/O=M2Cloud" \
  -addext "subjectAltName=DNS:$DOMAIN,DNS:api.$DOMAIN,DNS:kibana.$DOMAIN"

echo "✅ Certificate generated!"
echo ""
echo "📁 Files created:"
echo "   - $CERT_DIR/tls.crt"
echo "   - $CERT_DIR/tls.key"
echo ""
echo "📋 To create Kubernetes secret:"
echo "   kubectl create secret tls tls-secret --cert=$CERT_DIR/tls.crt --key=$CERT_DIR/tls.key -n m2cloud"
