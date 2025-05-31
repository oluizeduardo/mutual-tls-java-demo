#!/bin/bash

set -e

OUTPUT_DIR="mtls-output"
PASSWORD=changeit
DAYS=365

mkdir -p "$OUTPUT_DIR"

# Arquivo de extensão para SAN
SAN_CONFIG="$OUTPUT_DIR/san.cnf"
{
  echo "[req]"
  echo "distinguished_name = req_distinguished_name"
  echo "req_extensions = req_ext"
  echo "[req_distinguished_name]"
  echo "[req_ext]"
  echo "subjectAltName = DNS:localhost"
} > "$SAN_CONFIG"

# 1. Generate CA private key and self-signed certificate
echo ""
echo "# 1. Generate CA private key and self-signed certificate..."
openssl genpkey -algorithm RSA -out "$OUTPUT_DIR/ca-key.pem" -pkeyopt rsa_keygen_bits:2048
openssl req -x509 -new -key "$OUTPUT_DIR/ca-key.pem" -days $DAYS -out "$OUTPUT_DIR/ca-cert.pem" \
  -subj "//CN=MyCA"

# 2. Generate the server certificate
echo ""
echo "# 2. Generate the server certificate..."
openssl genpkey -algorithm RSA -out "$OUTPUT_DIR/server-key.pem" -pkeyopt rsa_keygen_bits:2048
openssl req -new -key "$OUTPUT_DIR/server-key.pem" -out "$OUTPUT_DIR/server.csr" -subj "//CN=localhost" -config "$SAN_CONFIG"
openssl x509 -req -in "$OUTPUT_DIR/server.csr" -CA "$OUTPUT_DIR/ca-cert.pem" -CAkey "$OUTPUT_DIR/ca-key.pem" -CAcreateserial \
  -out "$OUTPUT_DIR/server-cert.pem" -days $DAYS -sha256 -extfile "$SAN_CONFIG" -extensions req_ext

# 3. Generate client certificate (with different SAN)
echo ""
echo "# 3. Generate client certificate..."
echo "subjectAltName = DNS:client" >> "$SAN_CONFIG"
openssl genpkey -algorithm RSA -out "$OUTPUT_DIR/client-key.pem" -pkeyopt rsa_keygen_bits:2048
openssl req -new -key "$OUTPUT_DIR/client-key.pem" -out "$OUTPUT_DIR/client.csr" -subj "//CN=client" -config "$SAN_CONFIG"
openssl x509 -req -in "$OUTPUT_DIR/client.csr" -CA "$OUTPUT_DIR/ca-cert.pem" -CAkey "$OUTPUT_DIR/ca-key.pem" -CAcreateserial \
  -out "$OUTPUT_DIR/client-cert.pem" -days $DAYS -sha256 -extfile "$SAN_CONFIG" -extensions req_ext

# 4. Create PKCS12 (PFX) for the server
echo ""
echo "# 4. Create PKCS12 (PFX) for the server..."
openssl pkcs12 -export -out "$OUTPUT_DIR/server.p12" \
  -inkey "$OUTPUT_DIR/server-key.pem" -in "$OUTPUT_DIR/server-cert.pem" -certfile "$OUTPUT_DIR/ca-cert.pem" \
  -name server -password pass:$PASSWORD

# 5. Create PKCS12 (PFX) for the client
echo ""
echo "# 5. Create PKCS12 (PFX) for the client..."
openssl pkcs12 -export -out "$OUTPUT_DIR/client.p12" \
  -inkey "$OUTPUT_DIR/client-key.pem" -in "$OUTPUT_DIR/client-cert.pem" -certfile "$OUTPUT_DIR/ca-cert.pem" \
  -name client -password pass:$PASSWORD
 
# 6. Create TrustStore with CA
echo ""
echo "# 6. Create truststore.p12 with CA..."
keytool -importcert -alias ca -file "$OUTPUT_DIR/ca-cert.pem" -keystore "$OUTPUT_DIR/truststore.p12" \
  -storetype PKCS12 -storepass $PASSWORD -noprompt

# Cleaning
rm -f "$SAN_CONFIG"

echo ""
echo "✅ Successfully generated all certificate files in $OUTPUT_DIR/"
