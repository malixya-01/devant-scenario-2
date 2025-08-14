
import ballerina/http;



listener http:Listener httpDefaultListener = http:getDefaultListener();


// REST client for countries
final http:Client countriesClient = check new ("https://dev-tools.wso2.com/gs/helpers/v1.0");
// SOAP client for country info
final http:Client soapClient = check new ("http://webservices.oorsprong.org/websamples.countryinfo/CountryInfoService.wso");

service /integration on httpDefaultListener {
        resource function get countryInfo(string countryCode = "US") returns json|error {
                // 1. Call REST endpoint to get countries
                json countries = check countriesClient->get("/countries");

                // 2. Prepare SOAP request for the given country code
                        string soapPayload = "<?xml version=\"1.0\" encoding=\"utf-8\"?>" +
                            "<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">" +
                            "<soap:Body>" +
                            "<CountryIntPhoneCode xmlns=\"http://www.oorsprong.org/websamples.countryinfo\">" +
                            "<sCountryISOCode>" + countryCode + "</sCountryISOCode>" +
                            "</CountryIntPhoneCode>" +
                            "</soap:Body>" +
                            "</soap:Envelope>";

                http:Request req = new;
                req.setHeader("Content-Type", "text/xml; charset=utf-8");
                req.setPayload(soapPayload);

                // 3. Call SOAP endpoint
                http:Response soapResp = check soapClient->post("", req);
            xml soapXml = check soapResp.getXmlPayload();

            // 4. Extract phone code from SOAP response using XML navigation
            // Namespace URIs

            string M_NS = "http://www.oorsprong.org/websamples.countryinfo";
            xml[] phoneCodeElems = [soapXml.selectDescendants("{" + M_NS + "}CountryIntPhoneCodeResult")];
                                        string? phoneCode = "";
                                        if phoneCodeElems.length() > 0 {
                                                xml elem = phoneCodeElems[0];
                                                // Extract text content using XML navigation
                                                phoneCode = elem.children().toString();
                                        }

            return { countries: countries, phoneCode: phoneCode };
        }
}
