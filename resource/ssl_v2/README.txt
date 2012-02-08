Installation Instructions for Apache
====================================

To correctly install your certificate, it is important to 
configure the server to use the intermediate DigiCertCA.crt 
file in addition to sagebusinessbuilder_com.crt.

Our online Apache installation guide is available here:

https://www.digicert.com/ssl-certificate-installation-apache.htm

A typical Apache installation will involve configuration lines 
like these in your <VirtualHost *:443> block:

SSLCertificateFile /your/path/to/sagebusinessbuilder_com.crt
SSLCertificateKeyFile /your/path/to/sagebusinessbuilder_com.key
SSLCertificateChainFile /your/path/to/DigiCertCA.crt

(The sagebusinessbuilder_com.key file refers to the private key which only you 
 control.  It was likely generated in the same place where your
 CSR was created on the day this certificate was ordered.)

After installing your certificate, you can verify that it is
correctly installed by using our Certificate Testing tool:

https://www.digicert.com/help/index.htm

If you are having difficulty installing your certificate, please
contact our friendly support team for more assistance.
