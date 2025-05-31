# Mutual TLS (mTLS) Demo in Java

This project is a simple demonstration of **Mutual TLS (mTLS)** authentication using Java and OpenSSL-generated certificates in **PKCS12** format.

It includes:
- A Bash script (`setup-mtls.sh`) to generate certificates.
- A Java HTTPS server (`MutualTLSServer.java`) that requires clients to present valid certificates.
- A Java HTTPS client (`MutualTLSClient.java`) that authenticates itself and trusts only a known server.

## 📘 What is Mutual TLS?

**Mutual TLS** is an extension of standard TLS (*Transport Layer Security*) where **both** the server and the client authenticate each other using certificates.

- In normal TLS (e.g., HTTPS), the client verifies the server's identity via its certificate.
- In **mutual** TLS, the server also requires the client to present a trusted certificate, creating a **two-way trust**.

This is commonly used in:
- Secure microservice communication
- APIs requiring strong client identity
- Enterprise VPNs

## 🔧 How to Use This Project

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/mutual-tls-java-demo.git
cd mutual-tls-java-demo
```

### 2. Generate Certificates

Make sure you have OpenSSL installed, then run:

```bash
./setup-mtls.sh
```

This will generate:
- A Certificate Authority (CA)
- A server certificate signed by the CA
- A client certificate signed by the CA
- PKCS12 keystores: `server.p12`, `client.p12`

### 3. Compile the Java Classes

Ensure you’re using Java 11 or later (for TLS 1.3 compatibility).

```bash
javac MutualTLSServer.java
javac MutualTLSClient.java
```

### 4. Run the Server

```bash
java MutualTLSServer
```

You should see:

```bash
HTTPS server with mTLS started on port 8443
```

### 5. Run the Client

Open a second terminal and run:

```bash
java MutualTLSClient
```

Expected output:

```bash
Server response: Hello, authenticated client!
```

## 🔒 Requirements
- Java 11+
- OpenSSL (for generating certificates)
- Bash shell

## ✅ Security Notes

- This setup is for local development and educational purposes.
- In production, certificates should have stronger protection, revocation support, and expiry handling.
- Passwords like `changeit` should never be used in real deployments.