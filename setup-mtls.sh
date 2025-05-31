#!/bin/bash

set -e

PASSWORD=changeit
DAYS=365

# Arquivo de extensão para SAN
echo "[req]"                         > san.cnf
echo "distinguished_name = req_distinguished_name" >> san.cnf
echo "req_extensions = req_ext"     >> san.cnf
echo "[req_distinguished_name]"     >> san.cnf
echo "[req_ext]"                    >> san.cnf
echo "subjectAltName = DNS:localhost" >> san.cnf

# 1. Gera a chave privada da CA e certificado autoassinado
echo ""
echo "# 1. Gera a chave privada da CA e certificado autoassinado..."
openssl genpkey -algorithm RSA -out ca-key.pem -pkeyopt rsa_keygen_bits:2048
openssl req -x509 -new -key ca-key.pem -days $DAYS -out ca-cert.pem \
  -subj "//CN=MyCA"

# 2. Gera o certificado do servidor
echo ""
echo "# 2. Gera o certificado do servidor..."
openssl genpkey -algorithm RSA -out server-key.pem -pkeyopt rsa_keygen_bits:2048
openssl req -new -key server-key.pem -out server.csr -subj "//CN=localhost" -config san.cnf
openssl x509 -req -in server.csr -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial \
  -out server-cert.pem -days $DAYS -sha256 -extfile san.cnf -extensions req_ext

# 3. Gera o certificado do cliente (com SAN diferente)
echo ""
echo "# 3. Gera o certificado do cliente..."
echo "subjectAltName = DNS:client" >> san.cnf
openssl genpkey -algorithm RSA -out client-key.pem -pkeyopt rsa_keygen_bits:2048
openssl req -new -key client-key.pem -out client.csr -subj "//CN=client" -config san.cnf
openssl x509 -req -in client.csr -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial \
  -out client-cert.pem -days $DAYS -sha256 -extfile san.cnf -extensions req_ext

# 4. Cria PKCS12 (PFX) para o servidor
echo ""
echo "# 4. Cria PKCS12 (PFX) para o servidor..."
openssl pkcs12 -export -out server.p12 \
  -inkey server-key.pem -in server-cert.pem -certfile ca-cert.pem \
  -name server -password pass:$PASSWORD

# 5. Cria PKCS12 (PFX) para o cliente
echo ""
echo "# 5. Cria PKCS12 (PFX) para o cliente..."
openssl pkcs12 -export -out client.p12 \
  -inkey client-key.pem -in client-cert.pem -certfile ca-cert.pem \
  -name client -password pass:$PASSWORD
 
# 6. Cria TrustStore com a CA
echo ""
echo "# 6. Cria truststore.p12 com a CA..."
keytool -importcert -alias ca -file ca-cert.pem -keystore truststore.p12 \
  -storetype PKCS12 -storepass $PASSWORD -noprompt

# Limpeza
rm -f san.cnf

echo ""
echo "✅ Arquivos PKCS12 gerados com sucesso: server.p12 e client.p12"
