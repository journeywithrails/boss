class Test::Unit::TestCase

####################  Billing Helpers ####################

  def successful_details_response(token='1234567890')
      <<-RESPONSE
  <?xml version='1.0' encoding='UTF-8'?>
  <SOAP-ENV:Envelope xmlns:cc='urn:ebay:apis:CoreComponentTypes' xmlns:sizeship='urn:ebay:api:PayPalAPI/sizeship.xsd' xmlns:SOAP-ENV='http://schemas.xmlsoap.org/soap/envelope/' xmlns:SOAP-ENC='http://schemas.xmlsoap.org/soap/encoding/' xmlns:saml='urn:oasis:names:tc:SAML:1.0:assertion' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:wsu='http://schemas.xmlsoap.org/ws/2002/07/utility' xmlns:ebl='urn:ebay:apis:eBLBaseComponents' xmlns:ds='http://www.w3.org/2000/09/xmldsig#' xmlns:xs='http://www.w3.org/2001/XMLSchema' xmlns:ns='urn:ebay:api:PayPalAPI' xmlns:market='urn:ebay:apis:Market' xmlns:ship='urn:ebay:apis:ship' xmlns:auction='urn:ebay:apis:Auction' xmlns:wsse='http://schemas.xmlsoap.org/ws/2002/12/secext' xmlns:xsd='http://www.w3.org/2001/XMLSchema'>
    <SOAP-ENV:Header>
      <Security xsi:type='wsse:SecurityType' xmlns='http://schemas.xmlsoap.org/ws/2002/12/secext'/>
      <RequesterCredentials xsi:type='ebl:CustomSecurityHeaderType' xmlns='urn:ebay:api:PayPalAPI'>
        <Credentials xsi:type='ebl:UserIdPasswordType' xmlns='urn:ebay:apis:eBLBaseComponents'>
          <Username xsi:type='xs:string'/>
          <Password xsi:type='xs:string'/>
          <Subject xsi:type='xs:string'/>
        </Credentials>
      </RequesterCredentials>
    </SOAP-ENV:Header>
    <SOAP-ENV:Body id='_0'>
      <GetExpressCheckoutDetailsResponse xmlns='urn:ebay:api:PayPalAPI'>
        <Timestamp xmlns='urn:ebay:apis:eBLBaseComponents'>2007-02-12T23:59:43Z</Timestamp>
        <Ack xmlns='urn:ebay:apis:eBLBaseComponents'>Success</Ack>
        <CorrelationID xmlns='urn:ebay:apis:eBLBaseComponents'>c73044f11da65</CorrelationID>
        <Version xmlns='urn:ebay:apis:eBLBaseComponents'>2.000000</Version>
        <Build xmlns='urn:ebay:apis:eBLBaseComponents'>1.0006</Build>
        <GetExpressCheckoutDetailsResponseDetails xsi:type='ebl:GetExpressCheckoutDetailsResponseDetailsType' xmlns='urn:ebay:apis:eBLBaseComponents'>
          <Token xsi:type='ebl:ExpressCheckoutTokenType'>#{token}</Token>
          <PayerInfo xsi:type='ebl:PayerInfoType'>
            <Payer xsi:type='ebl:EmailAddressType'>buyer@jadedpallet.com</Payer>
            <PayerID xsi:type='ebl:UserIDType'>FWRVKNRRZ3WUC</PayerID>
            <PayerStatus xsi:type='ebl:PayPalUserStatusCodeType'>verified</PayerStatus>
            <PayerName xsi:type='ebl:PersonNameType'>
              <Salutation xmlns='urn:ebay:apis:eBLBaseComponents'/>
              <FirstName xmlns='urn:ebay:apis:eBLBaseComponents'>Fred</FirstName>
              <MiddleName xmlns='urn:ebay:apis:eBLBaseComponents'/>
              <LastName xmlns='urn:ebay:apis:eBLBaseComponents'>Brooks</LastName>
              <Suffix xmlns='urn:ebay:apis:eBLBaseComponents'/>
            </PayerName>
            <PayerCountry xsi:type='ebl:CountryCodeType'>US</PayerCountry>
            <PayerBusiness xsi:type='xs:string'/>
            <Address xsi:type='ebl:AddressType'>
              <Name xsi:type='xs:string'>Fred Brooks</Name>
              <Street1 xsi:type='xs:string'>1234 Penny Lane</Street1>
              <Street2 xsi:type='xs:string'/>
              <CityName xsi:type='xs:string'>Jonsetown</CityName>
              <StateOrProvince xsi:type='xs:string'>NC</StateOrProvince>
              <Country xsi:type='ebl:CountryCodeType'>US</Country>
              <CountryName>United States</CountryName>
              <PostalCode xsi:type='xs:string'>23456</PostalCode>
              <AddressOwner xsi:type='ebl:AddressOwnerCodeType'>PayPal</AddressOwner>
              <AddressStatus xsi:type='ebl:AddressStatusCodeType'>Confirmed</AddressStatus>
            </Address>
          </PayerInfo>
          <InvoiceID xsi:type='xs:string'>1230123</InvoiceID>
        </GetExpressCheckoutDetailsResponseDetails>
      </GetExpressCheckoutDetailsResponse>
    </SOAP-ENV:Body>
  </SOAP-ENV:Envelope>    
      RESPONSE
    end

    def successful_setup_purchase_response(token='1234567890')
          <<-RESPONSE
      <?xml version='1.0' encoding='UTF-8'?>
      <SOAP-ENV:Envelope xmlns:cc='urn:ebay:apis:CoreComponentTypes' xmlns:sizeship='urn:ebay:api:PayPalAPI/sizeship.xsd' xmlns:SOAP-ENV='http://schemas.xmlsoap.org/soap/envelope/' xmlns:SOAP-ENC='http://schemas.xmlsoap.org/soap/encoding/' xmlns:saml='urn:oasis:names:tc:SAML:1.0:assertion' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:wsu='http://schemas.xmlsoap.org/ws/2002/07/utility' xmlns:ebl='urn:ebay:apis:eBLBaseComponents' xmlns:ds='http://www.w3.org/2000/09/xmldsig#' xmlns:xs='http://www.w3.org/2001/XMLSchema' xmlns:ns='urn:ebay:api:PayPalAPI' xmlns:market='urn:ebay:apis:Market' xmlns:ship='urn:ebay:apis:ship' xmlns:auction='urn:ebay:apis:Auction' xmlns:wsse='http://schemas.xmlsoap.org/ws/2002/12/secext' xmlns:xsd='http://www.w3.org/2001/XMLSchema'>
        <SOAP-ENV:Header>
          <Security xsi:type='wsse:SecurityType' xmlns='http://schemas.xmlsoap.org/ws/2002/12/secext'/>
          <RequesterCredentials xsi:type='ebl:CustomSecurityHeaderType' xmlns='urn:ebay:api:PayPalAPI'>
            <Credentials xsi:type='ebl:UserIdPasswordType' xmlns='urn:ebay:apis:eBLBaseComponents'>
              <Username xsi:type='xs:string'/>
              <Password xsi:type='xs:string'/>
              <Subject xsi:type='xs:string'/>
            </Credentials>
          </RequesterCredentials>
        </SOAP-ENV:Header>
        <SOAP-ENV:Body id='_0'>
          <SetExpressCheckoutResponse xmlns='urn:ebay:api:PayPalAPI'>
            <Timestamp xmlns='urn:ebay:apis:eBLBaseComponents'>2007-02-13T00:18:50Z</Timestamp>
            <Ack xmlns='urn:ebay:apis:eBLBaseComponents'>Success</Ack>
            <CorrelationID xmlns='urn:ebay:apis:eBLBaseComponents'>62450a4266d04</CorrelationID>
            <Version xmlns='urn:ebay:apis:eBLBaseComponents'>2.000000</Version>
            <Build xmlns='urn:ebay:apis:eBLBaseComponents'>1.0006</Build>
            <DoExpressCheckoutPaymentResponseDetails xsi:type='ebl:DoExpressCheckoutPaymentResponseDetailsType' xmlns='urn:ebay:apis:eBLBaseComponents'>
              <Token xsi:type='ebl:ExpressCheckoutTokenType'>#{token}</Token>
            </DoExpressCheckoutPaymentResponseDetails>
          </SetExpressCheckoutResponse>
        </SOAP-ENV:Body>
      </SOAP-ENV:Envelope>
          RESPONSE
    
    end
  
    def unsuccessful_setup_purchase_response(token='1234567890')
      <<-RESPONSE
      <?xml version="1.0" encoding="UTF-8"?><SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:cc="urn:ebay:apis:CoreComponentTypes" xmlns:wsu="http://schemas.xmlsoap.org/ws/2002/07/utility" xmlns:saml="urn:oasis:names:tc:SAML:1.0:assertion" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:market="urn:ebay:apis:Market" xmlns:auction="urn:ebay:apis:Auction" xmlns:sizeship="urn:ebay:api:PayPalAPI/sizeship.xsd" xmlns:ship="urn:ebay:apis:ship" xmlns:skype="urn:ebay:apis:skype" xmlns:wsse="http://schemas.xmlsoap.org/ws/2002/12/secext" xmlns:ebl="urn:ebay:apis:eBLBaseComponents" xmlns:ns="urn:ebay:api:PayPalAPI"><SOAP-ENV:Header><Security xmlns="http://schemas.xmlsoap.org/ws/2002/12/secext" xsi:type="wsse:SecurityType"></Security><RequesterCredentials xmlns="urn:ebay:api:PayPalAPI" xsi:type="ebl:CustomSecurityHeaderType"><Credentials xmlns="urn:ebay:apis:eBLBaseComponents" xsi:type="ebl:UserIdPasswordType"><Username xsi:type="xs:string"></Username><Password xsi:type="xs:string"></Password><Subject xsi:type="xs:string"></Subject></Credentials></RequesterCredentials></SOAP-ENV:Header><SOAP-ENV:Body id="_0"><SetExpressCheckoutResponse xmlns="urn:ebay:api:PayPalAPI"><Timestamp xmlns="urn:ebay:apis:eBLBaseComponents">2007-12-04T22:47:05Z</Timestamp><Ack xmlns="urn:ebay:apis:eBLBaseComponents">Failure</Ack><CorrelationID xmlns="urn:ebay:apis:eBLBaseComponents">b4d3c016e53c</CorrelationID><Errors xmlns="urn:ebay:apis:eBLBaseComponents" xsi:type="ebl:ErrorType"><ShortMessage xsi:type="xs:string">Security error</ShortMessage><LongMessage xsi:type="xs:string">Security header is not valid</LongMessage><ErrorCode xsi:type="xs:token">10002</ErrorCode><SeverityCode xmlns="urn:ebay:apis:eBLBaseComponents">Error</SeverityCode></Errors><Version xmlns="urn:ebay:apis:eBLBaseComponents">2.000000</Version><Build xmlns="urn:ebay:apis:eBLBaseComponents">1.0006</Build></SetExpressCheckoutResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>
      RESPONSE
    end
    def unsuccessful_details_for_response(token='1234567890')
      <<-RESPONSE
      <?xml version="1.0" encoding="UTF-8"?><SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:cc="urn:ebay:apis:CoreComponentTypes" xmlns:wsu="http://schemas.xmlsoap.org/ws/2002/07/utility" xmlns:saml="urn:oasis:names:tc:SAML:1.0:assertion" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:market="urn:ebay:apis:Market" xmlns:auction="urn:ebay:apis:Auction" xmlns:sizeship="urn:ebay:api:PayPalAPI/sizeship.xsd" xmlns:ship="urn:ebay:apis:ship" xmlns:skype="urn:ebay:apis:skype" xmlns:wsse="http://schemas.xmlsoap.org/ws/2002/12/secext" xmlns:ebl="urn:ebay:apis:eBLBaseComponents" xmlns:ns="urn:ebay:api:PayPalAPI"><SOAP-ENV:Header><Security xmlns="http://schemas.xmlsoap.org/ws/2002/12/secext" xsi:type="wsse:SecurityType"></Security><RequesterCredentials xmlns="urn:ebay:api:PayPalAPI" xsi:type="ebl:CustomSecurityHeaderType"><Credentials xmlns="urn:ebay:apis:eBLBaseComponents" xsi:type="ebl:UserIdPasswordType"><Username xsi:type="xs:string"></Username><Password xsi:type="xs:string"></Password><Subject xsi:type="xs:string"></Subject></Credentials></RequesterCredentials></SOAP-ENV:Header><SOAP-ENV:Body id="_0"><GetExpressCheckoutDetailsResponse xmlns="urn:ebay:api:PayPalAPI"><Timestamp xmlns="urn:ebay:apis:eBLBaseComponents">2007-12-04T23:57:04Z</Timestamp><Ack xmlns="urn:ebay:apis:eBLBaseComponents">Failure</Ack><CorrelationID xmlns="urn:ebay:apis:eBLBaseComponents">fa74a0762e8c1</CorrelationID><Errors xmlns="urn:ebay:apis:eBLBaseComponents" xsi:type="ebl:ErrorType"><ShortMessage xsi:type="xs:string">Security error</ShortMessage><LongMessage xsi:type="xs:string">Security header is not valid</LongMessage><ErrorCode xsi:type="xs:token">10002</ErrorCode><SeverityCode xmlns="urn:ebay:apis:eBLBaseComponents">Error</SeverityCode></Errors><Version xmlns="urn:ebay:apis:eBLBaseComponents">2.000000</Version><Build xmlns="urn:ebay:apis:eBLBaseComponents">1.0006</Build><GetExpressCheckoutDetailsResponseDetails xmlns="urn:ebay:apis:eBLBaseComponents" xsi:type="ebl:GetExpressCheckoutDetailsResponseDetailsType"><PayerInfo xsi:type="ebl:PayerInfoType"><PayerStatus xsi:type="ebl:PayPalUserStatusCodeType">verified</PayerStatus><PayerName xsi:type="ebl:PersonNameType"></PayerName><Address xsi:type="ebl:AddressType"><AddressOwner xsi:type="ebl:AddressOwnerCodeType">PayPal</AddressOwner><AddressStatus xsi:type="ebl:AddressStatusCodeType">None</AddressStatus></Address></PayerInfo></GetExpressCheckoutDetailsResponseDetails></GetExpressCheckoutDetailsResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>
      RESPONSE
    end
  
    def unsuccessful_purchase_response(token='1234567890')
      <<-RESPONSE
       <?xml version="1.0" encoding="UTF-8"?><SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:cc="urn:ebay:apis:CoreComponentTypes" xmlns:wsu="http://schemas.xmlsoap.org/ws/2002/07/utility" xmlns:saml="urn:oasis:names:tc:SAML:1.0:assertion" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:market="urn:ebay:apis:Market" xmlns:auction="urn:ebay:apis:Auction" xmlns:sizeship="urn:ebay:api:PayPalAPI/sizeship.xsd" xmlns:ship="urn:ebay:apis:ship" xmlns:skype="urn:ebay:apis:skype" xmlns:wsse="http://schemas.xmlsoap.org/ws/2002/12/secext" xmlns:ebl="urn:ebay:apis:eBLBaseComponents" xmlns:ns="urn:ebay:api:PayPalAPI"><SOAP-ENV:Header><Security xmlns="http://schemas.xmlsoap.org/ws/2002/12/secext" xsi:type="wsse:SecurityType"></Security><RequesterCredentials xmlns="urn:ebay:api:PayPalAPI" xsi:type="ebl:CustomSecurityHeaderType"><Credentials xmlns="urn:ebay:apis:eBLBaseComponents" xsi:type="ebl:UserIdPasswordType"><Username xsi:type="xs:string"></Username><Password xsi:type="xs:string"></Password><Subject xsi:type="xs:string"></Subject></Credentials></RequesterCredentials></SOAP-ENV:Header><SOAP-ENV:Body id="_0"><DoExpressCheckoutPaymentResponse xmlns="urn:ebay:api:PayPalAPI"><Timestamp xmlns="urn:ebay:apis:eBLBaseComponents">2007-12-05T00:08:22Z</Timestamp><Ack xmlns="urn:ebay:apis:eBLBaseComponents">Failure</Ack><CorrelationID xmlns="urn:ebay:apis:eBLBaseComponents">6d4872186dd51</CorrelationID><Errors xmlns="urn:ebay:apis:eBLBaseComponents" xsi:type="ebl:ErrorType"><ShortMessage xsi:type="xs:string">Security error</ShortMessage><LongMessage xsi:type="xs:string">Security header is not valid</LongMessage><ErrorCode xsi:type="xs:token">10002</ErrorCode><SeverityCode xmlns="urn:ebay:apis:eBLBaseComponents">Error</SeverityCode></Errors><Version xmlns="urn:ebay:apis:eBLBaseComponents">2.000000</Version><Build xmlns="urn:ebay:apis:eBLBaseComponents">1.0006</Build><DoExpressCheckoutPaymentResponseDetails xmlns="urn:ebay:apis:eBLBaseComponents" xsi:type="ebl:DoExpressCheckoutPaymentResponseDetailsType"><PaymentInfo xsi:type="ebl:PaymentInfoType"><TransactionType xsi:type="ebl:PaymentTransactionCodeType">none</TransactionType><PaymentType xsi:type="ebl:PaymentCodeType">none</PaymentType><PaymentStatus xsi:type="ebl:PaymentStatusCodeType">None</PaymentStatus><PendingReason xsi:type="ebl:PendingStatusCodeType">none</PendingReason><ReasonCode xsi:type="ebl:ReversalReasonCodeType">none</ReasonCode></PaymentInfo></DoExpressCheckoutPaymentResponseDetails></DoExpressCheckoutPaymentResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>
       RESPONSE
    end
    def successful_authorization_response(token='1234567890')
      <<-RESPONSE
  <?xml version='1.0' encoding='UTF-8'?>
  <SOAP-ENV:Envelope xmlns:cc='urn:ebay:apis:CoreComponentTypes' xmlns:sizeship='urn:ebay:api:PayPalAPI/sizeship.xsd' xmlns:SOAP-ENV='http://schemas.xmlsoap.org/soap/envelope/' xmlns:SOAP-ENC='http://schemas.xmlsoap.org/soap/encoding/' xmlns:saml='urn:oasis:names:tc:SAML:1.0:assertion' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:wsu='http://schemas.xmlsoap.org/ws/2002/07/utility' xmlns:ebl='urn:ebay:apis:eBLBaseComponents' xmlns:ds='http://www.w3.org/2000/09/xmldsig#' xmlns:xs='http://www.w3.org/2001/XMLSchema' xmlns:ns='urn:ebay:api:PayPalAPI' xmlns:market='urn:ebay:apis:Market' xmlns:ship='urn:ebay:apis:ship' xmlns:auction='urn:ebay:apis:Auction' xmlns:wsse='http://schemas.xmlsoap.org/ws/2002/12/secext' xmlns:xsd='http://www.w3.org/2001/XMLSchema'>
    <SOAP-ENV:Header>
      <Security xsi:type='wsse:SecurityType' xmlns='http://schemas.xmlsoap.org/ws/2002/12/secext'/>
      <RequesterCredentials xsi:type='ebl:CustomSecurityHeaderType' xmlns='urn:ebay:api:PayPalAPI'>
        <Credentials xsi:type='ebl:UserIdPasswordType' xmlns='urn:ebay:apis:eBLBaseComponents'>
          <Username xsi:type='xs:string'/>
          <Password xsi:type='xs:string'/>
          <Subject xsi:type='xs:string'/>
        </Credentials>
      </RequesterCredentials>
    </SOAP-ENV:Header>
    <SOAP-ENV:Body id='_0'>
      <DoExpressCheckoutPaymentResponse xmlns='urn:ebay:api:PayPalAPI'>
        <Timestamp xmlns='urn:ebay:apis:eBLBaseComponents'>2007-02-13T00:18:50Z</Timestamp>
        <Ack xmlns='urn:ebay:apis:eBLBaseComponents'>Success</Ack>
        <CorrelationID xmlns='urn:ebay:apis:eBLBaseComponents'>62450a4266d04</CorrelationID>
        <Version xmlns='urn:ebay:apis:eBLBaseComponents'>2.000000</Version>
        <Build xmlns='urn:ebay:apis:eBLBaseComponents'>1.0006</Build>
        <DoExpressCheckoutPaymentResponseDetails xsi:type='ebl:DoExpressCheckoutPaymentResponseDetailsType' xmlns='urn:ebay:apis:eBLBaseComponents'>
          <Token xsi:type='ebl:ExpressCheckoutTokenType'>#{token}</Token>
          <PaymentInfo xsi:type='ebl:PaymentInfoType'>
            <TransactionID>8B266858CH956410C</TransactionID>
            <ParentTransactionID xsi:type='ebl:TransactionId'/>
            <ReceiptID/>
            <TransactionType xsi:type='ebl:PaymentTransactionCodeType'>express-checkout</TransactionType>
            <PaymentType xsi:type='ebl:PaymentCodeType'>instant</PaymentType>
            <PaymentDate xsi:type='xs:dateTime'>2007-02-13T00:18:48Z</PaymentDate>
            <GrossAmount currencyID='USD' xsi:type='cc:BasicAmountType'>3.00</GrossAmount>
            <TaxAmount currencyID='USD' xsi:type='cc:BasicAmountType'>0.00</TaxAmount>
            <ExchangeRate xsi:type='xs:string'/>
            <PaymentStatus xsi:type='ebl:PaymentStatusCodeType'>Pending</PaymentStatus>
            <PendingReason xsi:type='ebl:PendingStatusCodeType'>authorization</PendingReason>
            <ReasonCode xsi:type='ebl:ReversalReasonCodeType'>none</ReasonCode>
          </PaymentInfo>
        </DoExpressCheckoutPaymentResponseDetails>
      </DoExpressCheckoutPaymentResponse>
    </SOAP-ENV:Body>
  </SOAP-ENV:Envelope>
      RESPONSE
    end

  def paypal_express_redirect_url(token='1234567890')
    "https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=#{token}"
  end

  def simulate_express_payment_in_paypal_sandbox(token)
    uri = URI.parse("https://www.sandbox.paypal.com")
    site = Net::HTTP.new(uri.host, uri.port)
    site.use_ssl = true
    site.verify_mode    = OpenSSL::SSL::VERIFY_NONE
    site.get("cgi-bin/webscr?cmd=_expresscheckout&token=#{token}").body
  end

end