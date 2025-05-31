import com.sun.net.httpserver.HttpsServer;
import com.sun.net.httpserver.HttpsConfigurator;
import com.sun.net.httpserver.HttpsParameters;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;

import javax.net.ssl.*;
import java.io.*;
import java.net.InetSocketAddress;
import java.security.KeyStore;

public class MutualTLSServer {
    public static void main(String[] args) throws Exception {
        char[] password = "changeit".toCharArray();

        // Load the keystore (certificate + server private key)
        KeyStore keyStore = KeyStore.getInstance("PKCS12");
        keyStore.load(new FileInputStream("mtls-output/server.p12"), password);

        KeyManagerFactory kmf = KeyManagerFactory.getInstance("SunX509");
        kmf.init(keyStore, password);

        // Load the truststore (trusted CA to validate the client)
        KeyStore trustStore = KeyStore.getInstance("PKCS12");
        trustStore.load(new FileInputStream("mtls-output/truststore.p12"), password);

        TrustManagerFactory tmf = TrustManagerFactory.getInstance("SunX509");
        tmf.init(trustStore);

        // Configure SSLContext with mutual authentication
        SSLContext sslContext = SSLContext.getInstance("TLS");
        sslContext.init(kmf.getKeyManagers(), tmf.getTrustManagers(), null);

        // Start HTTPS server
        HttpsServer server = HttpsServer.create(new InetSocketAddress(8443), 0);
        server.setHttpsConfigurator(new HttpsConfigurator(sslContext) {
            public void configure(HttpsParameters params) {
                try {
                    SSLParameters sslParams = sslContext.getDefaultSSLParameters();
                    sslParams.setNeedClientAuth(true); // Requires client authentication
                    params.setSSLParameters(sslParams);
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
            }
        });

        // Define the endpoint
        server.createContext("/hello", (HttpExchange exchange) -> {
            System.out.println("Request received!");
            String response = "Hello, authenticated client!";
            exchange.sendResponseHeaders(200, response.getBytes().length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(response.getBytes());
            }
        });

        server.start();
        System.out.println("HTTPS server with mTLS started on port 8443");
    }
}
