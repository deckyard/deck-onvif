# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.27.0

# onvif - replies of real cameras from published captures, for vendor
# shapes other than the simulator's: EZVIZ DS-2DE2C400IG-W-W (Hikvision
# firmware), Dahua DHI-ITC413-PW4D-Z1 and DVC DCN-BF5365 (gSOAP) from
# github.com/2BAD/onvif fixtures/live (MIT, commit 912443cf, addresses
# scrubbed to 192.0.2.x), and Annex B of the ONVIF Application Programmer's
# Guide 1.0 (an Axis). Spliced into onvif_test.j.

# EZVIZ (Hikvision) GetSystemDateAndTime
def const EZ_TIME as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:soapenc="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:trt="http://www.onvif.org/ver10/media/wsdl" xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:tan="http://www.onvif.org/ver20/analytics/wsdl" xmlns:tst="http://www.onvif.org/ver10/storage/wsdl" xmlns:ter="http://www.onvif.org/ver10/error" xmlns:dn="http://www.onvif.org/ver10/network/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl" xmlns:wsoap12="http://schemas.xmlsoap.org/wsdl/soap12" xmlns:http="http://schemas.xmlsoap.org/wsdl/http" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:wsadis="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1" xmlns:wsrf-bf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:wsntw="http://docs.oasis-open.org/wsn/bw-2" xmlns:wsrf-rw="http://docs.oasis-open.org/wsrf/rw-2" xmlns:wsaw="http://www.w3.org/2006/05/addressing/wsdl" xmlns:wsrf-r="http://docs.oasis-open.org/wsrf/r-2" xmlns:trc="http://www.onvif.org/ver10/recording/wsdl" xmlns:tse="http://www.onvif.org/ver10/search/wsdl" xmlns:trp="http://www.onvif.org/ver10/replay/wsdl" xmlns:tnsn="http://www.eventextension.com/2011/event/topics" xmlns:extwsd="http://www.onvifext.com/onvif/ext/ver10/wsdl" xmlns:extxsd="http://www.onvifext.com/onvif/ext/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:axt="http://www.onvif.org/ver20/analytics"><env:Body><tds:GetSystemDateAndTimeResponse><tds:SystemDateAndTime><tt:DateTimeType>NTP</tt:DateTimeType>
<tt:DaylightSavings>true</tt:DaylightSavings>
<tt:TimeZone><tt:TZ>EST-1:00:00</tt:TZ>
</tt:TimeZone>
<tt:UTCDateTime><tt:Time><tt:Hour>17</tt:Hour>
<tt:Minute>46</tt:Minute>
<tt:Second>20</tt:Second>
</tt:Time>
<tt:Date><tt:Year>2026</tt:Year>
<tt:Month>10</tt:Month>
<tt:Day>7</tt:Day>
</tt:Date>
</tt:UTCDateTime>
<tt:LocalDateTime><tt:Time><tt:Hour>18</tt:Hour>
<tt:Minute>46</tt:Minute>
<tt:Second>20</tt:Second>
</tt:Time>
<tt:Date><tt:Year>2026</tt:Year>
<tt:Month>10</tt:Month>
<tt:Day>7</tt:Day>
</tt:Date>
</tt:LocalDateTime>
</tds:SystemDateAndTime>
</tds:GetSystemDateAndTimeResponse>
</env:Body>
</env:Envelope>';

# EZVIZ: an unsigned call, HTTP 401 with an HTML page
def const EZ_UNAUTHORIZED as string init "401\nContent-Type: text/html\n\n" +
    '<!DOCTYPE html>
<html><head><title>Document Error: Unauthorized</title></head>
<body><h2>Access Error: 401 -- Unauthorized</h2>
<p>Authentication Error: This onvif request requires authentication information</p>
</body>
</html>';

# EZVIZ GetDeviceInformation
def const EZ_INFO as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:soapenc="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:trt="http://www.onvif.org/ver10/media/wsdl" xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:tan="http://www.onvif.org/ver20/analytics/wsdl" xmlns:tst="http://www.onvif.org/ver10/storage/wsdl" xmlns:ter="http://www.onvif.org/ver10/error" xmlns:dn="http://www.onvif.org/ver10/network/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl" xmlns:wsoap12="http://schemas.xmlsoap.org/wsdl/soap12" xmlns:http="http://schemas.xmlsoap.org/wsdl/http" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:wsadis="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1" xmlns:wsrf-bf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:wsntw="http://docs.oasis-open.org/wsn/bw-2" xmlns:wsrf-rw="http://docs.oasis-open.org/wsrf/rw-2" xmlns:wsaw="http://www.w3.org/2006/05/addressing/wsdl" xmlns:wsrf-r="http://docs.oasis-open.org/wsrf/r-2" xmlns:trc="http://www.onvif.org/ver10/recording/wsdl" xmlns:tse="http://www.onvif.org/ver10/search/wsdl" xmlns:trp="http://www.onvif.org/ver10/replay/wsdl" xmlns:tnsn="http://www.eventextension.com/2011/event/topics" xmlns:extwsd="http://www.onvifext.com/onvif/ext/ver10/wsdl" xmlns:extxsd="http://www.onvifext.com/onvif/ext/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:axt="http://www.onvif.org/ver20/analytics"><env:Body><tds:GetDeviceInformationResponse><tds:Manufacturer>EZVIZ</tds:Manufacturer>
<tds:Model>DS-2DE2C400IG-W-W</tds:Model>
<tds:FirmwareVersion>V5.3.8 build 260123</tds:FirmwareVersion>
<tds:SerialNumber>REDACTED1</tds:SerialNumber>
<tds:HardwareId>88</tds:HardwareId>
</tds:GetDeviceInformationResponse>
</env:Body>
</env:Envelope>';

# EZVIZ GetServices
def const EZ_SERVICES as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:soapenc="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:trt="http://www.onvif.org/ver10/media/wsdl" xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:tan="http://www.onvif.org/ver20/analytics/wsdl" xmlns:tst="http://www.onvif.org/ver10/storage/wsdl" xmlns:ter="http://www.onvif.org/ver10/error" xmlns:dn="http://www.onvif.org/ver10/network/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl" xmlns:wsoap12="http://schemas.xmlsoap.org/wsdl/soap12" xmlns:http="http://schemas.xmlsoap.org/wsdl/http" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:wsadis="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1" xmlns:wsrf-bf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:wsntw="http://docs.oasis-open.org/wsn/bw-2" xmlns:wsrf-rw="http://docs.oasis-open.org/wsrf/rw-2" xmlns:wsaw="http://www.w3.org/2006/05/addressing/wsdl" xmlns:wsrf-r="http://docs.oasis-open.org/wsrf/r-2" xmlns:trc="http://www.onvif.org/ver10/recording/wsdl" xmlns:tse="http://www.onvif.org/ver10/search/wsdl" xmlns:trp="http://www.onvif.org/ver10/replay/wsdl" xmlns:tnsn="http://www.eventextension.com/2011/event/topics" xmlns:extwsd="http://www.onvifext.com/onvif/ext/ver10/wsdl" xmlns:extxsd="http://www.onvifext.com/onvif/ext/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:axt="http://www.onvif.org/ver20/analytics"><env:Body><tds:GetServicesResponse><tds:Service><tds:Namespace>http://www.onvif.org/ver10/device/wsdl</tds:Namespace>
<tds:XAddr>http://192.0.2.13/onvif/device_service</tds:XAddr>
<tds:Capabilities><tds:Capabilities><tds:Network IPFilter="false" ZeroConfiguration="true" IPVersion6="false" DHCPv6="false" DynDNS="false" Dot11Configuration="false" Dot1XConfigurations="0" HostnameFromDHCP="true" NTP="1"></tds:Network>
<tds:Security TLS1.0="true" TLS1.1="true" TLS1.2="true" OnboardKeyGeneration="false" AccessPolicyConfig="false" DefaultAccessPolicy="true" Dot1X="false" RemoteUserHandling="false" X.509Token="false" SAMLToken="false" KerberosToken="false" UsernameToken="true" HttpDigest="true" RELToken="false" SupportedEAPMethods="0" MaxUsers="32" MaxUserNameLength="32" MaxPasswordLength="16"></tds:Security>
<tds:System DiscoveryResolve="false" DiscoveryBye="true" RemoteDiscovery="true" SystemBackup="false" SystemLogging="false" FirmwareUpgrade="true" HttpFirmwareUpgrade="true" HttpSystemBackup="false" HttpSystemLogging="false" HttpSupportInformation="false" StorageConfiguration="false" MaxStorageConfigurations="0"></tds:System>
</tds:Capabilities>
</tds:Capabilities>
<tds:Version><tt:Major>18</tt:Major>
<tt:Minor>12</tt:Minor>
</tds:Version>
</tds:Service>
<tds:Service><tds:Namespace>http://www.onvif.org/ver10/media/wsdl</tds:Namespace>
<tds:XAddr>http://192.0.2.13/onvif/Media</tds:XAddr>
<tds:Capabilities><trt:Capabilities SnapshotUri="true" Rotation="false" VideoSourceMode="false" OSD="true"><trt:ProfileCapabilities MaximumNumberOfProfiles="10"></trt:ProfileCapabilities>
<trt:StreamingCapabilities RTPMulticast="false" RTP_TCP="true" RTP_RTSP_TCP="true" NonAggregateControl="false"></trt:StreamingCapabilities>
</trt:Capabilities>
</tds:Capabilities>
<tds:Version><tt:Major>2</tt:Major>
<tt:Minor>60</tt:Minor>
</tds:Version>
</tds:Service>
<tds:Service><tds:Namespace>http://www.onvif.org/ver20/media/wsdl</tds:Namespace>
<tds:XAddr>http://192.0.2.13/onvif/Media2</tds:XAddr>
<tds:Capabilities><tr2:Capabilities SnapshotUri="true" Rotation="false" VideoSourceMode="false" OSD="true" Mask="false" SourceMask="false"><tr2:ProfileCapabilities MaximumNumberOfProfiles="10" ConfigurationsSupported="VideoSource VideoEncoder AudioSource AudioEncoder AudioOutput AudioDecoder Analytics PTZ"></tr2:ProfileCapabilities>
<tr2:StreamingCapabilities RTSPStreaming="true" RTPMulticast="false" RTP_TCP="true" RTP_RTSP_TCP="true" NonAggregateControl="false"></tr2:StreamingCapabilities>
</tr2:Capabilities>
</tds:Capabilities>
<tds:Version><tt:Major>16</tt:Major>
<tt:Minor>12</tt:Minor>
</tds:Version>
</tds:Service>
<tds:Service><tds:Namespace>http://www.onvif.org/ver10/events/wsdl</tds:Namespace>
<tds:XAddr>http://192.0.2.13/onvif/Events</tds:XAddr>
<tds:Capabilities><tev:Capabilities WSSubscriptionPolicySupport="true" WSPullPointSupport="true" WSPausableSubscriptionManagerInterfaceSupport="false" MaxNotificationProducers="10" MaxPullPoints="10"></tev:Capabilities>
</tds:Capabilities>
<tds:Version><tt:Major>2</tt:Major>
<tt:Minor>60</tt:Minor>
</tds:Version>
</tds:Service>
<tds:Service><tds:Namespace>http://www.onvif.org/ver20/ptz/wsdl</tds:Namespace>
<tds:XAddr>http://192.0.2.13/onvif/PTZ</tds:XAddr>
<tds:Capabilities><tptz:Capabilities EFlip="false" Reverse="false" GetCompatibleConfigurations="true" MoveStatus="true" StatusPosition="false"></tptz:Capabilities>
</tds:Capabilities>
<tds:Version><tt:Major>16</tt:Major>
<tt:Minor>12</tt:Minor>
</tds:Version>
</tds:Service>
<tds:Service><tds:Namespace>http://www.onvif.org/ver20/imaging/wsdl</tds:Namespace>
<tds:XAddr>http://192.0.2.13/onvif/Imaging</tds:XAddr>
<tds:Capabilities><timg:Capabilities ImageStabilization="false"></timg:Capabilities>
</tds:Capabilities>
<tds:Version><tt:Major>16</tt:Major>
<tt:Minor>6</tt:Minor>
</tds:Version>
</tds:Service>
<tds:Service><tds:Namespace>http://www.onvif.org/ver10/deviceIO/wsdl</tds:Namespace>
<tds:XAddr>http://192.0.2.13/onvif/DeviceIO</tds:XAddr>
<tds:Capabilities><tmd:Capabilities VideoSources="1" VideoOutputs="0" AudioSources="1" AudioOutputs="1" RelayOutputs="0" DigitalInputs="0" SerialPorts="2" DigitalInputOptions="false"></tmd:Capabilities>
</tds:Capabilities>
<tds:Version><tt:Major>16</tt:Major>
<tt:Minor>12</tt:Minor>
</tds:Version>
</tds:Service>
<tds:Service><tds:Namespace>http://www.onvif.org/ver20/analytics/wsdl</tds:Namespace>
<tds:XAddr>http://192.0.2.13/onvif/Analytics</tds:XAddr>
<tds:Capabilities><tan:Capabilities RuleSupport="false" AnalyticsModuleSupport="false" CellBasedSceneDescriptionSupported="true" RuleOptionsSupported="true"/>
</tds:Capabilities>
<tds:Version><tt:Major>16</tt:Major>
<tt:Minor>12</tt:Minor>
</tds:Version>
</tds:Service>
<tds:Service><tds:Namespace>http://www.onvif.org/ver10/recording/wsdl</tds:Namespace>
<tds:XAddr>http://192.0.2.13/onvif/Recording</tds:XAddr>
<tds:Capabilities><trc:Capabilities DynamicRecordings="false" DynamicTracks="false" Encoding="G711 AAC H264" MaxRate="2048" MaxTotalRate="2048" MaxRecordings="1" MaxRecordingJobs="1" Options="true"></trc:Capabilities>
</tds:Capabilities>
<tds:Version><tt:Major>16</tt:Major>
<tt:Minor>12</tt:Minor>
</tds:Version>
</tds:Service>
<tds:Service><tds:Namespace>http://www.onvif.org/ver10/search/wsdl</tds:Namespace>
<tds:XAddr>http://192.0.2.13/onvif/SearchRecording</tds:XAddr>
<tds:Capabilities><tse:Capabilities MetadataSearch="false" GeneralStartEvents="false"></tse:Capabilities>
</tds:Capabilities>
<tds:Version><tt:Major>2</tt:Major>
<tt:Minor>42</tt:Minor>
</tds:Version>
</tds:Service>
<tds:Service><tds:Namespace>http://www.onvif.org/ver10/replay/wsdl</tds:Namespace>
<tds:XAddr>http://192.0.2.13/onvif/Replay</tds:XAddr>
<tds:Capabilities><trp:Capabilities ReversePlayback="false" SessionTimeoutRange="1 60" RTP_RTSP_TCP="true"></trp:Capabilities>
</tds:Capabilities>
<tds:Version><tt:Major>2</tt:Major>
<tt:Minor>21</tt:Minor>
</tds:Version>
</tds:Service>
</tds:GetServicesResponse>
</env:Body>
</env:Envelope>';

# EZVIZ Media GetProfiles
def const EZ_PROFILES as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:soapenc="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:trt="http://www.onvif.org/ver10/media/wsdl" xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:tan="http://www.onvif.org/ver20/analytics/wsdl" xmlns:tst="http://www.onvif.org/ver10/storage/wsdl" xmlns:ter="http://www.onvif.org/ver10/error" xmlns:dn="http://www.onvif.org/ver10/network/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl" xmlns:wsoap12="http://schemas.xmlsoap.org/wsdl/soap12" xmlns:http="http://schemas.xmlsoap.org/wsdl/http" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:wsadis="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1" xmlns:wsrf-bf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:wsntw="http://docs.oasis-open.org/wsn/bw-2" xmlns:wsrf-rw="http://docs.oasis-open.org/wsrf/rw-2" xmlns:wsaw="http://www.w3.org/2006/05/addressing/wsdl" xmlns:wsrf-r="http://docs.oasis-open.org/wsrf/r-2" xmlns:trc="http://www.onvif.org/ver10/recording/wsdl" xmlns:tse="http://www.onvif.org/ver10/search/wsdl" xmlns:trp="http://www.onvif.org/ver10/replay/wsdl" xmlns:tnsn="http://www.eventextension.com/2011/event/topics" xmlns:extwsd="http://www.onvifext.com/onvif/ext/ver10/wsdl" xmlns:extxsd="http://www.onvifext.com/onvif/ext/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:axt="http://www.onvif.org/ver20/analytics"><env:Body><trt:GetProfilesResponse><trt:Profiles token="Profile_1" fixed="true"><tt:Name>mainStream</tt:Name>
<tt:VideoSourceConfiguration token="VideoSourceToken"><tt:Name>VideoSourceConfig</tt:Name>
<tt:UseCount>2</tt:UseCount>
<tt:SourceToken>VideoSource_1</tt:SourceToken>
<tt:Bounds x="0" y="0" width="2560" height="1440"></tt:Bounds>
</tt:VideoSourceConfiguration>
<tt:AudioSourceConfiguration token="AudioSourceConfigToken"><tt:Name>AudioSourceConfig</tt:Name>
<tt:UseCount>2</tt:UseCount>
<tt:SourceToken>AudioSourceChannel1</tt:SourceToken>
</tt:AudioSourceConfiguration>
<tt:VideoEncoderConfiguration token="VideoEncoderToken_1" encoding="H265"><tt:Name>VideoEncoder_1</tt:Name>
<tt:UseCount>1</tt:UseCount>
<tt:Encoding>H264</tt:Encoding>
<tt:Resolution><tt:Width>2560</tt:Width>
<tt:Height>1440</tt:Height>
</tt:Resolution>
<tt:Quality>3.000000</tt:Quality>
<tt:RateControl><tt:FrameRateLimit>25</tt:FrameRateLimit>
<tt:EncodingInterval>1</tt:EncodingInterval>
<tt:BitrateLimit>2048</tt:BitrateLimit>
</tt:RateControl>
<tt:H264><tt:GovLength>100</tt:GovLength>
<tt:H264Profile>Main</tt:H264Profile>
</tt:H264>
<tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type>
<tt:IPv4Address>0.0.0.0</tt:IPv4Address>
</tt:Address>
<tt:Port>8600</tt:Port>
<tt:TTL>128</tt:TTL>
<tt:AutoStart>false</tt:AutoStart>
</tt:Multicast>
<tt:SessionTimeout>PT5S</tt:SessionTimeout>
</tt:VideoEncoderConfiguration>
<tt:AudioEncoderConfiguration token="MainAudioEncoderToken"><tt:Name>AudioEncoderConfig</tt:Name>
<tt:UseCount>2</tt:UseCount>
<tt:Encoding>AAC</tt:Encoding>
<tt:Bitrate>32</tt:Bitrate>
<tt:SampleRate>16</tt:SampleRate>
<tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type>
<tt:IPv4Address>0.0.0.0</tt:IPv4Address>
</tt:Address>
<tt:Port>8600</tt:Port>
<tt:TTL>128</tt:TTL>
<tt:AutoStart>false</tt:AutoStart>
</tt:Multicast>
<tt:SessionTimeout>PT5S</tt:SessionTimeout>
</tt:AudioEncoderConfiguration>
<tt:VideoAnalyticsConfiguration token="VideoAnalyticsToken"><tt:Name>VideoAnalyticsName</tt:Name>
<tt:UseCount>2</tt:UseCount>
<tt:AnalyticsEngineConfiguration><tt:AnalyticsModule Name="MyCellMotionModule" Type="tt:CellMotionEngine"><tt:Parameters><tt:SimpleItem Name="Sensitivity" Value="60"/>
<tt:ElementItem Name="Layout"><tt:CellLayout Columns="22" Rows="18"><tt:Transformation><tt:Translate x="-1.000000" y="-1.000000"/>
<tt:Scale x="0.090909" y="0.111111"/>
</tt:Transformation>
</tt:CellLayout>
</tt:ElementItem>
</tt:Parameters>
</tt:AnalyticsModule>
</tt:AnalyticsEngineConfiguration>
<tt:RuleEngineConfiguration><tt:Rule Name="MyMotionDetectorRule" Type="tt:CellMotionDetector"><tt:Parameters><tt:SimpleItem Name="MinCount" Value="5"/>
<tt:SimpleItem Name="AlarmOnDelay" Value="1000"/>
<tt:SimpleItem Name="AlarmOffDelay" Value="1000"/>
<tt:SimpleItem Name="ActiveCells" Value="0P8A8A=="/>
</tt:Parameters>
</tt:Rule>
</tt:RuleEngineConfiguration>
</tt:VideoAnalyticsConfiguration>
<tt:PTZConfiguration token="PTZToken"><tt:Name>PTZ</tt:Name>
<tt:UseCount>2</tt:UseCount>
<tt:NodeToken>PTZNodeToken_1</tt:NodeToken>
<tt:DefaultContinuousPanTiltVelocitySpace>http://www.onvif.org/ver10/tptz/PanTiltSpaces/VelocityGenericSpace</tt:DefaultContinuousPanTiltVelocitySpace>
<tt:DefaultContinuousZoomVelocitySpace></tt:DefaultContinuousZoomVelocitySpace>
<tt:DefaultPTZTimeout>PT300S</tt:DefaultPTZTimeout>
</tt:PTZConfiguration>
<tt:MetadataConfiguration  token="MetaDataToken" GeoLocation="false"><tt:Name>metaData</tt:Name>
<tt:UseCount>2</tt:UseCount>
<tt:PTZStatus><tt:Status>false</tt:Status>
<tt:Position>false</tt:Position>
</tt:PTZStatus>
<tt:Analytics>false</tt:Analytics>
<tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type>
<tt:IPv4Address>0.0.0.0</tt:IPv4Address>
</tt:Address>
<tt:Port>8600</tt:Port>
<tt:TTL>128</tt:TTL>
<tt:AutoStart>false</tt:AutoStart>
</tt:Multicast>
<tt:SessionTimeout>PT5S</tt:SessionTimeout>
<tt:AnalyticsEngineConfiguration></tt:AnalyticsEngineConfiguration>
</tt:MetadataConfiguration >
<tt:Extension><tt:AudioOutputConfiguration token="AudioOutputConfigToken"><tt:Name>AudioOutputConfigName</tt:Name>
<tt:UseCount>2</tt:UseCount>
<tt:OutputToken>AudioOutputToken</tt:OutputToken>
<tt:OutputLevel>100</tt:OutputLevel>
</tt:AudioOutputConfiguration>
<tt:AudioDecoderConfiguration token="AudioDecoderConfigToken"><tt:Name>AudioDecoderConfig</tt:Name>
<tt:UseCount>2</tt:UseCount>
</tt:AudioDecoderConfiguration>
</tt:Extension>
</trt:Profiles>
<trt:Profiles token="Profile_2" fixed="true"><tt:Name>subStream</tt:Name>
<tt:VideoSourceConfiguration token="VideoSourceToken"><tt:Name>VideoSourceConfig</tt:Name>
<tt:UseCount>2</tt:UseCount>
<tt:SourceToken>VideoSource_1</tt:SourceToken>
<tt:Bounds x="0" y="0" width="2560" height="1440"></tt:Bounds>
</tt:VideoSourceConfiguration>
<tt:AudioSourceConfiguration token="AudioSourceConfigToken"><tt:Name>AudioSourceConfig</tt:Name>
<tt:UseCount>2</tt:UseCount>
<tt:SourceToken>AudioSourceChannel1</tt:SourceToken>
</tt:AudioSourceConfiguration>
<tt:VideoEncoderConfiguration token="VideoEncoderToken_2" encoding="H265"><tt:Name>VideoEncoder_2</tt:Name>
<tt:UseCount>1</tt:UseCount>
<tt:Encoding>H264</tt:Encoding>
<tt:Resolution><tt:Width>768</tt:Width>
<tt:Height>432</tt:Height>
</tt:Resolution>
<tt:Quality>3.000000</tt:Quality>
<tt:RateControl><tt:FrameRateLimit>10</tt:FrameRateLimit>
<tt:EncodingInterval>1</tt:EncodingInterval>
<tt:BitrateLimit>768</tt:BitrateLimit>
</tt:RateControl>
<tt:H264><tt:GovLength>40</tt:GovLength>
<tt:H264Profile>Main</tt:H264Profile>
</tt:H264>
<tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type>
<tt:IPv4Address>0.0.0.0</tt:IPv4Address>
</tt:Address>
<tt:Port>8600</tt:Port>
<tt:TTL>128</tt:TTL>
<tt:AutoStart>false</tt:AutoStart>
</tt:Multicast>
<tt:SessionTimeout>PT5S</tt:SessionTimeout>
</tt:VideoEncoderConfiguration>
<tt:AudioEncoderConfiguration token="MainAudioEncoderToken"><tt:Name>AudioEncoderConfig</tt:Name>
<tt:UseCount>2</tt:UseCount>
<tt:Encoding>AAC</tt:Encoding>
<tt:Bitrate>32</tt:Bitrate>
<tt:SampleRate>16</tt:SampleRate>
<tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type>
<tt:IPv4Address>0.0.0.0</tt:IPv4Address>
</tt:Address>
<tt:Port>8600</tt:Port>
<tt:TTL>128</tt:TTL>
<tt:AutoStart>false</tt:AutoStart>
</tt:Multicast>
<tt:SessionTimeout>PT5S</tt:SessionTimeout>
</tt:AudioEncoderConfiguration>
<tt:VideoAnalyticsConfiguration token="VideoAnalyticsToken"><tt:Name>VideoAnalyticsName</tt:Name>
<tt:UseCount>2</tt:UseCount>
<tt:AnalyticsEngineConfiguration><tt:AnalyticsModule Name="MyCellMotionModule" Type="tt:CellMotionEngine"><tt:Parameters><tt:SimpleItem Name="Sensitivity" Value="60"/>
<tt:ElementItem Name="Layout"><tt:CellLayout Columns="22" Rows="18"><tt:Transformation><tt:Translate x="-1.000000" y="-1.000000"/>
<tt:Scale x="0.090909" y="0.111111"/>
</tt:Transformation>
</tt:CellLayout>
</tt:ElementItem>
</tt:Parameters>
</tt:AnalyticsModule>
</tt:AnalyticsEngineConfiguration>
<tt:RuleEngineConfiguration><tt:Rule Name="MyMotionDetectorRule" Type="tt:CellMotionDetector"><tt:Parameters><tt:SimpleItem Name="MinCount" Value="5"/>
<tt:SimpleItem Name="AlarmOnDelay" Value="1000"/>
<tt:SimpleItem Name="AlarmOffDelay" Value="1000"/>
<tt:SimpleItem Name="ActiveCells" Value="0P8A8A=="/>
</tt:Parameters>
</tt:Rule>
</tt:RuleEngineConfiguration>
</tt:VideoAnalyticsConfiguration>
<tt:PTZConfiguration token="PTZToken"><tt:Name>PTZ</tt:Name>
<tt:UseCount>2</tt:UseCount>
<tt:NodeToken>PTZNodeToken_1</tt:NodeToken>
<tt:DefaultContinuousPanTiltVelocitySpace>http://www.onvif.org/ver10/tptz/PanTiltSpaces/VelocityGenericSpace</tt:DefaultContinuousPanTiltVelocitySpace>
<tt:DefaultContinuousZoomVelocitySpace></tt:DefaultContinuousZoomVelocitySpace>
<tt:DefaultPTZTimeout>PT300S</tt:DefaultPTZTimeout>
</tt:PTZConfiguration>
<tt:MetadataConfiguration  token="MetaDataToken" GeoLocation="false"><tt:Name>metaData</tt:Name>
<tt:UseCount>2</tt:UseCount>
<tt:PTZStatus><tt:Status>false</tt:Status>
<tt:Position>false</tt:Position>
</tt:PTZStatus>
<tt:Analytics>false</tt:Analytics>
<tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type>
<tt:IPv4Address>0.0.0.0</tt:IPv4Address>
</tt:Address>
<tt:Port>8600</tt:Port>
<tt:TTL>128</tt:TTL>
<tt:AutoStart>false</tt:AutoStart>
</tt:Multicast>
<tt:SessionTimeout>PT5S</tt:SessionTimeout>
<tt:AnalyticsEngineConfiguration></tt:AnalyticsEngineConfiguration>
</tt:MetadataConfiguration >
<tt:Extension><tt:AudioOutputConfiguration token="AudioOutputConfigToken"><tt:Name>AudioOutputConfigName</tt:Name>
<tt:UseCount>2</tt:UseCount>
<tt:OutputToken>AudioOutputToken</tt:OutputToken>
<tt:OutputLevel>100</tt:OutputLevel>
</tt:AudioOutputConfiguration>
<tt:AudioDecoderConfiguration token="AudioDecoderConfigToken"><tt:Name>AudioDecoderConfig</tt:Name>
<tt:UseCount>2</tt:UseCount>
</tt:AudioDecoderConfiguration>
</tt:Extension>
</trt:Profiles>
</trt:GetProfilesResponse>
</env:Body>
</env:Envelope>';

# EZVIZ Media GetStreamUri
def const EZ_STREAM as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:soapenc="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:trt="http://www.onvif.org/ver10/media/wsdl" xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:tan="http://www.onvif.org/ver20/analytics/wsdl" xmlns:tst="http://www.onvif.org/ver10/storage/wsdl" xmlns:ter="http://www.onvif.org/ver10/error" xmlns:dn="http://www.onvif.org/ver10/network/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl" xmlns:wsoap12="http://schemas.xmlsoap.org/wsdl/soap12" xmlns:http="http://schemas.xmlsoap.org/wsdl/http" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:wsadis="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1" xmlns:wsrf-bf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:wsntw="http://docs.oasis-open.org/wsn/bw-2" xmlns:wsrf-rw="http://docs.oasis-open.org/wsrf/rw-2" xmlns:wsaw="http://www.w3.org/2006/05/addressing/wsdl" xmlns:wsrf-r="http://docs.oasis-open.org/wsrf/r-2" xmlns:trc="http://www.onvif.org/ver10/recording/wsdl" xmlns:tse="http://www.onvif.org/ver10/search/wsdl" xmlns:trp="http://www.onvif.org/ver10/replay/wsdl" xmlns:tnsn="http://www.eventextension.com/2011/event/topics" xmlns:extwsd="http://www.onvifext.com/onvif/ext/ver10/wsdl" xmlns:extxsd="http://www.onvifext.com/onvif/ext/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:axt="http://www.onvif.org/ver20/analytics"><env:Body><trt:GetStreamUriResponse><trt:MediaUri><tt:Uri>rtsp://192.0.2.13:554/Streaming/Channels/101?transportmode=unicast&amp;profile=Profile_1</tt:Uri>
<tt:InvalidAfterConnect>false</tt:InvalidAfterConnect>
<tt:InvalidAfterReboot>false</tt:InvalidAfterReboot>
<tt:Timeout>PT60S</tt:Timeout>
</trt:MediaUri>
</trt:GetStreamUriResponse>
</env:Body>
</env:Envelope>';

# EZVIZ Media GetSnapshotUri
def const EZ_SNAPSHOT_URI as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:soapenc="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:trt="http://www.onvif.org/ver10/media/wsdl" xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:tan="http://www.onvif.org/ver20/analytics/wsdl" xmlns:tst="http://www.onvif.org/ver10/storage/wsdl" xmlns:ter="http://www.onvif.org/ver10/error" xmlns:dn="http://www.onvif.org/ver10/network/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl" xmlns:wsoap12="http://schemas.xmlsoap.org/wsdl/soap12" xmlns:http="http://schemas.xmlsoap.org/wsdl/http" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:wsadis="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1" xmlns:wsrf-bf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:wsntw="http://docs.oasis-open.org/wsn/bw-2" xmlns:wsrf-rw="http://docs.oasis-open.org/wsrf/rw-2" xmlns:wsaw="http://www.w3.org/2006/05/addressing/wsdl" xmlns:wsrf-r="http://docs.oasis-open.org/wsrf/r-2" xmlns:trc="http://www.onvif.org/ver10/recording/wsdl" xmlns:tse="http://www.onvif.org/ver10/search/wsdl" xmlns:trp="http://www.onvif.org/ver10/replay/wsdl" xmlns:tnsn="http://www.eventextension.com/2011/event/topics" xmlns:extwsd="http://www.onvifext.com/onvif/ext/ver10/wsdl" xmlns:extxsd="http://www.onvifext.com/onvif/ext/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:axt="http://www.onvif.org/ver20/analytics"><env:Body><trt:GetSnapshotUriResponse><trt:MediaUri><tt:Uri>http://192.0.2.13/onvif/snapshot?Profile_1</tt:Uri>
<tt:InvalidAfterConnect>false</tt:InvalidAfterConnect>
<tt:InvalidAfterReboot>false</tt:InvalidAfterReboot>
<tt:Timeout>PT0S</tt:Timeout>
</trt:MediaUri>
</trt:GetSnapshotUriResponse>
</env:Body>
</env:Envelope>';

# EZVIZ PTZ GetPresets with a preset
def const EZ_PRESETS as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:soapenc="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:trt="http://www.onvif.org/ver10/media/wsdl" xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:tan="http://www.onvif.org/ver20/analytics/wsdl" xmlns:tst="http://www.onvif.org/ver10/storage/wsdl" xmlns:ter="http://www.onvif.org/ver10/error" xmlns:dn="http://www.onvif.org/ver10/network/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl" xmlns:wsoap12="http://schemas.xmlsoap.org/wsdl/soap12" xmlns:http="http://schemas.xmlsoap.org/wsdl/http" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:wsadis="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1" xmlns:wsrf-bf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:wsntw="http://docs.oasis-open.org/wsn/bw-2" xmlns:wsrf-rw="http://docs.oasis-open.org/wsrf/rw-2" xmlns:wsaw="http://www.w3.org/2006/05/addressing/wsdl" xmlns:wsrf-r="http://docs.oasis-open.org/wsrf/r-2" xmlns:trc="http://www.onvif.org/ver10/recording/wsdl" xmlns:tse="http://www.onvif.org/ver10/search/wsdl" xmlns:trp="http://www.onvif.org/ver10/replay/wsdl" xmlns:tnsn="http://www.eventextension.com/2011/event/topics" xmlns:extwsd="http://www.onvifext.com/onvif/ext/ver10/wsdl" xmlns:extxsd="http://www.onvifext.com/onvif/ext/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:axt="http://www.onvif.org/ver20/analytics"><env:Body><tptz:GetPresetsResponse><tptz:Preset token="1"><tt:Name>onviftest</tt:Name>
</tptz:Preset>
</tptz:GetPresetsResponse>
</env:Body>
</env:Envelope>';

# EZVIZ PTZ GetStatus while moving
def const EZ_PTZ_STATUS as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:soapenc="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:trt="http://www.onvif.org/ver10/media/wsdl" xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:tan="http://www.onvif.org/ver20/analytics/wsdl" xmlns:tst="http://www.onvif.org/ver10/storage/wsdl" xmlns:ter="http://www.onvif.org/ver10/error" xmlns:dn="http://www.onvif.org/ver10/network/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl" xmlns:wsoap12="http://schemas.xmlsoap.org/wsdl/soap12" xmlns:http="http://schemas.xmlsoap.org/wsdl/http" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:wsadis="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1" xmlns:wsrf-bf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:wsntw="http://docs.oasis-open.org/wsn/bw-2" xmlns:wsrf-rw="http://docs.oasis-open.org/wsrf/rw-2" xmlns:wsaw="http://www.w3.org/2006/05/addressing/wsdl" xmlns:wsrf-r="http://docs.oasis-open.org/wsrf/r-2" xmlns:trc="http://www.onvif.org/ver10/recording/wsdl" xmlns:tse="http://www.onvif.org/ver10/search/wsdl" xmlns:trp="http://www.onvif.org/ver10/replay/wsdl" xmlns:tnsn="http://www.eventextension.com/2011/event/topics" xmlns:extwsd="http://www.onvifext.com/onvif/ext/ver10/wsdl" xmlns:extxsd="http://www.onvifext.com/onvif/ext/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:axt="http://www.onvif.org/ver20/analytics"><env:Body><tptz:GetStatusResponse><tptz:PTZStatus><tt:MoveStatus><tt:PanTilt>MOVING</tt:PanTilt>
<tt:Zoom>MOVING</tt:Zoom>
</tt:MoveStatus>
<tt:Error>NO error</tt:Error>
<tt:UtcTime>2026-10-07T20:19:04Z</tt:UtcTime>
</tptz:PTZStatus>
</tptz:GetStatusResponse>
</env:Body>
</env:Envelope>';

# EZVIZ PTZ GotoPreset of a missing preset
def const EZ_GOTO_MISSING as string init "500\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:soapenc="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:trt="http://www.onvif.org/ver10/media/wsdl" xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:tan="http://www.onvif.org/ver20/analytics/wsdl" xmlns:tst="http://www.onvif.org/ver10/storage/wsdl" xmlns:ter="http://www.onvif.org/ver10/error" xmlns:dn="http://www.onvif.org/ver10/network/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl" xmlns:wsoap12="http://schemas.xmlsoap.org/wsdl/soap12" xmlns:http="http://schemas.xmlsoap.org/wsdl/http" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:wsadis="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1" xmlns:wsrf-bf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:wsntw="http://docs.oasis-open.org/wsn/bw-2" xmlns:wsrf-rw="http://docs.oasis-open.org/wsrf/rw-2" xmlns:wsaw="http://www.w3.org/2006/05/addressing/wsdl" xmlns:wsrf-r="http://docs.oasis-open.org/wsrf/r-2" xmlns:trc="http://www.onvif.org/ver10/recording/wsdl" xmlns:tse="http://www.onvif.org/ver10/search/wsdl" xmlns:trp="http://www.onvif.org/ver10/replay/wsdl" xmlns:tnsn="http://www.eventextension.com/2011/event/topics" xmlns:extwsd="http://www.onvifext.com/onvif/ext/ver10/wsdl" xmlns:extxsd="http://www.onvifext.com/onvif/ext/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:axt="http://www.onvif.org/ver20/analytics"><env:Body><env:Fault><env:Code><env:Value>env:Sender</env:Value>
<env:Subcode><env:Value>ter:InvalidArgVal</env:Value>
<env:Subcode><env:Value>ter:InvalidParameter</env:Value>
</env:Subcode>
</env:Subcode>
</env:Code>
<env:Reason><env:Text xml:lang="en">the parameter value is illegal</env:Text>
</env:Reason>
</env:Fault>
</env:Body>
</env:Envelope>';

# EZVIZ PTZ AbsoluteMove: ter:SpaceNotSupported
def const EZ_ABSOLUTE as string init "500\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:soapenc="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:trt="http://www.onvif.org/ver10/media/wsdl" xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:tan="http://www.onvif.org/ver20/analytics/wsdl" xmlns:tst="http://www.onvif.org/ver10/storage/wsdl" xmlns:ter="http://www.onvif.org/ver10/error" xmlns:dn="http://www.onvif.org/ver10/network/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl" xmlns:wsoap12="http://schemas.xmlsoap.org/wsdl/soap12" xmlns:http="http://schemas.xmlsoap.org/wsdl/http" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:wsadis="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1" xmlns:wsrf-bf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:wsntw="http://docs.oasis-open.org/wsn/bw-2" xmlns:wsrf-rw="http://docs.oasis-open.org/wsrf/rw-2" xmlns:wsaw="http://www.w3.org/2006/05/addressing/wsdl" xmlns:wsrf-r="http://docs.oasis-open.org/wsrf/r-2" xmlns:trc="http://www.onvif.org/ver10/recording/wsdl" xmlns:tse="http://www.onvif.org/ver10/search/wsdl" xmlns:trp="http://www.onvif.org/ver10/replay/wsdl" xmlns:tnsn="http://www.eventextension.com/2011/event/topics" xmlns:extwsd="http://www.onvifext.com/onvif/ext/ver10/wsdl" xmlns:extxsd="http://www.onvifext.com/onvif/ext/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:axt="http://www.onvif.org/ver20/analytics"><env:Body><env:Fault><env:Code><env:Value>env:Sender</env:Value>
<env:Subcode><env:Value>ter:InvalidArgVal</env:Value>
<env:Subcode><env:Value>ter:SpaceNotSupported</env:Value>
</env:Subcode>
</env:Subcode>
</env:Code>
<env:Reason><env:Text xml:lang="en">A space is referenced in an argument which is not supported by the PTZ Node.</env:Text>
</env:Reason>
</env:Fault>
</env:Body>
</env:Envelope>';

# EZVIZ Imaging GetImagingSettings
def const EZ_IMAGING as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:soapenc="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:trt="http://www.onvif.org/ver10/media/wsdl" xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:tan="http://www.onvif.org/ver20/analytics/wsdl" xmlns:tst="http://www.onvif.org/ver10/storage/wsdl" xmlns:ter="http://www.onvif.org/ver10/error" xmlns:dn="http://www.onvif.org/ver10/network/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl" xmlns:wsoap12="http://schemas.xmlsoap.org/wsdl/soap12" xmlns:http="http://schemas.xmlsoap.org/wsdl/http" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:wsadis="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1" xmlns:wsrf-bf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:wsntw="http://docs.oasis-open.org/wsn/bw-2" xmlns:wsrf-rw="http://docs.oasis-open.org/wsrf/rw-2" xmlns:wsaw="http://www.w3.org/2006/05/addressing/wsdl" xmlns:wsrf-r="http://docs.oasis-open.org/wsrf/r-2" xmlns:trc="http://www.onvif.org/ver10/recording/wsdl" xmlns:tse="http://www.onvif.org/ver10/search/wsdl" xmlns:trp="http://www.onvif.org/ver10/replay/wsdl" xmlns:tnsn="http://www.eventextension.com/2011/event/topics" xmlns:extwsd="http://www.onvifext.com/onvif/ext/ver10/wsdl" xmlns:extxsd="http://www.onvifext.com/onvif/ext/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:axt="http://www.onvif.org/ver20/analytics"><env:Body><timg:GetImagingSettingsResponse><timg:ImagingSettings><tt:BacklightCompensation><tt:Mode>OFF</tt:Mode>
</tt:BacklightCompensation>
<tt:Brightness>50</tt:Brightness>
<tt:ColorSaturation>50</tt:ColorSaturation>
<tt:Contrast>50</tt:Contrast>
<tt:Focus><tt:AutoFocusMode>MANUAL</tt:AutoFocusMode>
<tt:DefaultSpeed>1</tt:DefaultSpeed>
</tt:Focus>
<tt:IrCutFilter>AUTO</tt:IrCutFilter>
<tt:Sharpness>50</tt:Sharpness>
<tt:WideDynamicRange><tt:Mode>OFF</tt:Mode>
</tt:WideDynamicRange>
<tt:WhiteBalance><tt:Mode>AUTO</tt:Mode>
</tt:WhiteBalance>
<tt:Extension><tt:Extension><tt:Extension><tt:NoiseReduction><tt:Level>0.500000</tt:Level>
</tt:NoiseReduction>
</tt:Extension>
</tt:Extension>
</tt:Extension>
</timg:ImagingSettings>
</timg:GetImagingSettingsResponse>
</env:Body>
</env:Envelope>';

# EZVIZ Imaging GetOptions
def const EZ_IMAGING_OPTIONS as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:soapenc="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:trt="http://www.onvif.org/ver10/media/wsdl" xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:tan="http://www.onvif.org/ver20/analytics/wsdl" xmlns:tst="http://www.onvif.org/ver10/storage/wsdl" xmlns:ter="http://www.onvif.org/ver10/error" xmlns:dn="http://www.onvif.org/ver10/network/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl" xmlns:wsoap12="http://schemas.xmlsoap.org/wsdl/soap12" xmlns:http="http://schemas.xmlsoap.org/wsdl/http" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:wsadis="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1" xmlns:wsrf-bf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:wsntw="http://docs.oasis-open.org/wsn/bw-2" xmlns:wsrf-rw="http://docs.oasis-open.org/wsrf/rw-2" xmlns:wsaw="http://www.w3.org/2006/05/addressing/wsdl" xmlns:wsrf-r="http://docs.oasis-open.org/wsrf/r-2" xmlns:trc="http://www.onvif.org/ver10/recording/wsdl" xmlns:tse="http://www.onvif.org/ver10/search/wsdl" xmlns:trp="http://www.onvif.org/ver10/replay/wsdl" xmlns:tnsn="http://www.eventextension.com/2011/event/topics" xmlns:extwsd="http://www.onvifext.com/onvif/ext/ver10/wsdl" xmlns:extxsd="http://www.onvifext.com/onvif/ext/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:axt="http://www.onvif.org/ver20/analytics"><env:Body><timg:GetOptionsResponse><timg:ImagingOptions><tt:BacklightCompensation><tt:Mode>OFF</tt:Mode>
<tt:Mode>ON</tt:Mode>
</tt:BacklightCompensation>
<tt:Brightness><tt:Min>0</tt:Min>
<tt:Max>100</tt:Max>
</tt:Brightness>
<tt:ColorSaturation><tt:Min>0</tt:Min>
<tt:Max>100</tt:Max>
</tt:ColorSaturation>
<tt:Contrast><tt:Min>0</tt:Min>
<tt:Max>100</tt:Max>
</tt:Contrast>
<tt:Focus><tt:AutoFocusModes>MANUAL</tt:AutoFocusModes>
<tt:DefaultSpeed><tt:Min>1</tt:Min>
<tt:Max>1</tt:Max>
</tt:DefaultSpeed>
</tt:Focus>
<tt:IrCutFilterModes>ON</tt:IrCutFilterModes>
<tt:IrCutFilterModes>OFF</tt:IrCutFilterModes>
<tt:IrCutFilterModes>AUTO</tt:IrCutFilterModes>
<tt:Sharpness><tt:Min>0</tt:Min>
<tt:Max>100</tt:Max>
</tt:Sharpness>
<tt:WideDynamicRange><tt:Mode>ON</tt:Mode>
<tt:Mode>OFF</tt:Mode>
<tt:Level><tt:Min>1</tt:Min>
<tt:Max>100</tt:Max>
</tt:Level>
</tt:WideDynamicRange>
<tt:WhiteBalance><tt:Mode>AUTO</tt:Mode>
</tt:WhiteBalance>
<tt:Extension><tt:Extension><tt:Extension><tt:NoiseReductionOptions><tt:Level>true</tt:Level>
</tt:NoiseReductionOptions>
</tt:Extension>
</tt:Extension>
</tt:Extension>
</timg:ImagingOptions>
</timg:GetOptionsResponse>
</env:Body>
</env:Envelope>';

# EZVIZ CreatePullPointSubscription: a raw % in the address
def const EZ_SUBSCRIBE as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:soapenc="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:trt="http://www.onvif.org/ver10/media/wsdl" xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:tan="http://www.onvif.org/ver20/analytics/wsdl" xmlns:tst="http://www.onvif.org/ver10/storage/wsdl" xmlns:ter="http://www.onvif.org/ver10/error" xmlns:dn="http://www.onvif.org/ver10/network/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl" xmlns:wsoap12="http://schemas.xmlsoap.org/wsdl/soap12" xmlns:http="http://schemas.xmlsoap.org/wsdl/http" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:wsadis="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1" xmlns:wsrf-bf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:wsntw="http://docs.oasis-open.org/wsn/bw-2" xmlns:wsrf-rw="http://docs.oasis-open.org/wsrf/rw-2" xmlns:wsaw="http://www.w3.org/2006/05/addressing/wsdl" xmlns:wsrf-r="http://docs.oasis-open.org/wsrf/r-2" xmlns:trc="http://www.onvif.org/ver10/recording/wsdl" xmlns:tse="http://www.onvif.org/ver10/search/wsdl" xmlns:trp="http://www.onvif.org/ver10/replay/wsdl" xmlns:tnsn="http://www.eventextension.com/2011/event/topics" xmlns:extwsd="http://www.onvifext.com/onvif/ext/ver10/wsdl" xmlns:extxsd="http://www.onvifext.com/onvif/ext/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:axt="http://www.onvif.org/ver20/analytics"><env:Header><wsa:Action>http://www.onvif.org/ver10/events/wsdl/EventPortType/CreatePullPointSubscriptionResponse</wsa:Action>
</env:Header>
<env:Body><tev:CreatePullPointSubscriptionResponse><tev:SubscriptionReference><wsa:Address>http://192.0.2.13/onvif/Events/PullSubManager_2026-10-07%17:46:23_0</wsa:Address>
</tev:SubscriptionReference>
<wsnt:CurrentTime>2026-10-07T17:46:23Z</wsnt:CurrentTime>
<wsnt:TerminationTime>2026-10-07T17:47:23Z</wsnt:TerminationTime>
</tev:CreatePullPointSubscriptionResponse>
</env:Body>
</env:Envelope>';

# EZVIZ PullMessages with motion
def const EZ_PULL_MOTION as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:soapenc="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:trt="http://www.onvif.org/ver10/media/wsdl" xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:tan="http://www.onvif.org/ver20/analytics/wsdl" xmlns:tst="http://www.onvif.org/ver10/storage/wsdl" xmlns:ter="http://www.onvif.org/ver10/error" xmlns:dn="http://www.onvif.org/ver10/network/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl" xmlns:wsoap12="http://schemas.xmlsoap.org/wsdl/soap12" xmlns:http="http://schemas.xmlsoap.org/wsdl/http" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:wsadis="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1" xmlns:wsrf-bf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:wsntw="http://docs.oasis-open.org/wsn/bw-2" xmlns:wsrf-rw="http://docs.oasis-open.org/wsrf/rw-2" xmlns:wsaw="http://www.w3.org/2006/05/addressing/wsdl" xmlns:wsrf-r="http://docs.oasis-open.org/wsrf/r-2" xmlns:trc="http://www.onvif.org/ver10/recording/wsdl" xmlns:tse="http://www.onvif.org/ver10/search/wsdl" xmlns:trp="http://www.onvif.org/ver10/replay/wsdl" xmlns:tnsn="http://www.eventextension.com/2011/event/topics" xmlns:extwsd="http://www.onvifext.com/onvif/ext/ver10/wsdl" xmlns:extxsd="http://www.onvifext.com/onvif/ext/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:axt="http://www.onvif.org/ver20/analytics"><env:Header><wsa:Action>http://www.onvif.org/ver10/events/wsdl/PullPointSubscription/PullMessagesResponse</wsa:Action>
</env:Header>
<env:Body><tev:PullMessagesResponse><tev:CurrentTime>2026-10-07T18:41:46Z</tev:CurrentTime>
<tev:TerminationTime>2026-10-07T18:51:38Z</tev:TerminationTime>
<wsnt:NotificationMessage><wsnt:Topic Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet">tns1:VideoSource/MotionAlarm</wsnt:Topic>
<wsnt:Message><tt:Message UtcTime="2026-10-07T18:41:46Z" PropertyOperation="Changed"><tt:Source><tt:SimpleItem Name="Source" Value="VideoSource_1"/>
</tt:Source>
<tt:Data><tt:SimpleItem Name="State" Value="true"/>
</tt:Data>
</tt:Message>
</wsnt:Message>
</wsnt:NotificationMessage>
</tev:PullMessagesResponse>
</env:Body>
</env:Envelope>';

# EZVIZ: an unknown operation
def const EZ_UNKNOWN as string init "500\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:soapenc="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:trt="http://www.onvif.org/ver10/media/wsdl" xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:tan="http://www.onvif.org/ver20/analytics/wsdl" xmlns:tst="http://www.onvif.org/ver10/storage/wsdl" xmlns:ter="http://www.onvif.org/ver10/error" xmlns:dn="http://www.onvif.org/ver10/network/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl" xmlns:wsoap12="http://schemas.xmlsoap.org/wsdl/soap12" xmlns:http="http://schemas.xmlsoap.org/wsdl/http" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:wsadis="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1" xmlns:wsrf-bf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:wsntw="http://docs.oasis-open.org/wsn/bw-2" xmlns:wsrf-rw="http://docs.oasis-open.org/wsrf/rw-2" xmlns:wsaw="http://www.w3.org/2006/05/addressing/wsdl" xmlns:wsrf-r="http://docs.oasis-open.org/wsrf/r-2" xmlns:trc="http://www.onvif.org/ver10/recording/wsdl" xmlns:tse="http://www.onvif.org/ver10/search/wsdl" xmlns:trp="http://www.onvif.org/ver10/replay/wsdl" xmlns:tnsn="http://www.eventextension.com/2011/event/topics" xmlns:extwsd="http://www.onvifext.com/onvif/ext/ver10/wsdl" xmlns:extxsd="http://www.onvifext.com/onvif/ext/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:axt="http://www.onvif.org/ver20/analytics"><env:Body><env:Fault><env:Code><env:Value>env:Receiver</env:Value>
<env:Subcode><env:Value>ter:ActionNotSupported</env:Value>
<env:Subcode><env:Value>ter:InvalidOperation</env:Value>
</env:Subcode>
</env:Subcode>
</env:Code>
<env:Reason><env:Text xml:lang="en">Optional Action Not Implemented</env:Text>
</env:Reason>
</env:Fault>
</env:Body>
</env:Envelope>';

# EZVIZ ProbeMatches
def const EZ_PROBE_MATCHES as string init "200\nContent-Type: application/soap+xml\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:soapenc="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:trt="http://www.onvif.org/ver10/media/wsdl" xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:tan="http://www.onvif.org/ver20/analytics/wsdl" xmlns:tst="http://www.onvif.org/ver10/storage/wsdl" xmlns:ter="http://www.onvif.org/ver10/error" xmlns:dn="http://www.onvif.org/ver10/network/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl" xmlns:wsoap12="http://schemas.xmlsoap.org/wsdl/soap12" xmlns:http="http://schemas.xmlsoap.org/wsdl/http" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:wsadis="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1" xmlns:wsrf-bf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:wsntw="http://docs.oasis-open.org/wsn/bw-2" xmlns:wsrf-rw="http://docs.oasis-open.org/wsrf/rw-2" xmlns:wsaw="http://www.w3.org/2006/05/addressing/wsdl" xmlns:wsrf-r="http://docs.oasis-open.org/wsrf/r-2" xmlns:trc="http://www.onvif.org/ver10/recording/wsdl" xmlns:tse="http://www.onvif.org/ver10/search/wsdl" xmlns:trp="http://www.onvif.org/ver10/replay/wsdl" xmlns:tnsn="http://www.eventextension.com/2011/event/topics" xmlns:extwsd="http://www.onvifext.com/onvif/ext/ver10/wsdl" xmlns:extxsd="http://www.onvifext.com/onvif/ext/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl" xmlns:axt="http://www.onvif.org/ver20/analytics"><env:Header><wsadis:MessageID>urn:uuid:00000000-0000-4000-8000-000000000012</wsadis:MessageID>
<wsadis:RelatesTo>urn:uuid:00000000-0000-4000-8000-000000000013</wsadis:RelatesTo>
<wsadis:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsadis:To>
<wsadis:Action>http://schemas.xmlsoap.org/ws/2005/04/discovery/ProbeMatches</wsadis:Action>
<d:AppSequence InstanceId="1791398783" MessageNumber="3"/>
</env:Header>
<env:Body><d:ProbeMatches><d:ProbeMatch><wsadis:EndpointReference><wsadis:Address>urn:uuid:00000000-0000-4000-8000-000000000012</wsadis:Address>
</wsadis:EndpointReference>
<d:Types>dn:NetworkVideoTransmitter tds:Device</d:Types>
<d:Scopes>onvif://www.onvif.org/type/video_encoder onvif://www.onvif.org/Profile/Streaming onvif://www.onvif.org/Profile/G onvif://www.onvif.org/type/audio_encoder onvif://www.onvif.org/type/ptz onvif://www.onvif.org/MAC/02:00:00:00:00:15 onvif://www.onvif.org/hardware/DS-2DE2C400IG-W-W onvif://www.onvif.org/name/REDACTED5</d:Scopes>
<d:XAddrs>http://192.0.2.13/onvif/device_service https://192.0.2.13/onvif/device_service </d:XAddrs>
<d:MetadataVersion>10</d:MetadataVersion>
</d:ProbeMatch>
</d:ProbeMatches>
</env:Body>
</env:Envelope>';

# Dahua GetSystemDateAndTime
def const DH_TIME as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="utf-8" standalone="yes" ?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:sc="http://www.w3.org/2003/05/soap-encoding" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl"><s:Header/><s:Body><tds:GetSystemDateAndTimeResponse><tds:SystemDateAndTime><tt:DateTimeType>Manual</tt:DateTimeType><tt:DaylightSavings>false</tt:DaylightSavings><tt:TimeZone><tt:TZ>GMT+01:00</tt:TZ></tt:TimeZone><tt:UTCDateTime><tt:Time><tt:Hour>17</tt:Hour><tt:Minute>40</tt:Minute><tt:Second>9</tt:Second></tt:Time><tt:Date><tt:Year>2026</tt:Year><tt:Month>10</tt:Month><tt:Day>15</tt:Day></tt:Date></tt:UTCDateTime><tt:LocalDateTime><tt:Time><tt:Hour>18</tt:Hour><tt:Minute>40</tt:Minute><tt:Second>9</tt:Second></tt:Time><tt:Date><tt:Year>2026</tt:Year><tt:Month>10</tt:Month><tt:Day>15</tt:Day></tt:Date></tt:LocalDateTime></tds:SystemDateAndTime></tds:GetSystemDateAndTimeResponse></s:Body></s:Envelope>';

# Dahua GetServices without capabilities
def const DH_SERVICES as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="utf-8" standalone="yes" ?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:sc="http://www.w3.org/2003/05/soap-encoding" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl"><s:Header/><s:Body><tds:GetServicesResponse><tds:Service><tds:Namespace>http://www.onvif.org/ver10/device/wsdl</tds:Namespace><tds:XAddr>http://192.0.2.13/onvif/device_service</tds:XAddr><tds:Version><tt:Major>25</tt:Major><tt:Minor>06</tt:Minor></tds:Version></tds:Service><tds:Service><tds:Namespace>http://www.onvif.org/ver20/analytics/wsdl</tds:Namespace><tds:XAddr>http://192.0.2.13/onvif/analytics_service</tds:XAddr><tds:Version><tt:Major>24</tt:Major><tt:Minor>12</tt:Minor></tds:Version></tds:Service><tds:Service><tds:Namespace>http://www.onvif.org/ver20/imaging/wsdl</tds:Namespace><tds:XAddr>http://192.0.2.13/onvif/imaging_service</tds:XAddr><tds:Version><tt:Major>22</tt:Major><tt:Minor>06</tt:Minor></tds:Version></tds:Service><tds:Service><tds:Namespace>http://www.onvif.org/ver10/media/wsdl</tds:Namespace><tds:XAddr>http://192.0.2.13/onvif/media_service</tds:XAddr><tds:Version><tt:Major>24</tt:Major><tt:Minor>12</tt:Minor></tds:Version></tds:Service><tds:Service><tds:Namespace>http://www.onvif.org/ver20/media/wsdl</tds:Namespace><tds:XAddr>http://192.0.2.13/onvif/media2_service</tds:XAddr><tds:Version><tt:Major>25</tt:Major><tt:Minor>06</tt:Minor></tds:Version></tds:Service><tds:Service><tds:Namespace>http://www.onvif.org/ver20/ptz/wsdl</tds:Namespace><tds:XAddr>http://192.0.2.13/onvif/ptz_service</tds:XAddr><tds:Version><tt:Major>23</tt:Major><tt:Minor>06</tt:Minor></tds:Version></tds:Service><tds:Service><tds:Namespace>http://www.onvif.org/ver10/events/wsdl</tds:Namespace><tds:XAddr>http://192.0.2.13/onvif/event_service</tds:XAddr><tds:Version><tt:Major>25</tt:Major><tt:Minor>06</tt:Minor></tds:Version></tds:Service><tds:Service><tds:Namespace>http://www.onvif.org/ver10/deviceIO/wsdl</tds:Namespace><tds:XAddr>http://192.0.2.13/onvif/deviceIO_service</tds:XAddr><tds:Version><tt:Major>22</tt:Major><tt:Minor>06</tt:Minor></tds:Version></tds:Service></tds:GetServicesResponse></s:Body></s:Envelope>';

# Dahua GetCapabilities
def const DH_CAPABILITIES as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="utf-8" standalone="yes" ?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:sc="http://www.w3.org/2003/05/soap-encoding" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tds="http://www.onvif.org/ver10/device/wsdl"><s:Header/><s:Body><tds:GetCapabilitiesResponse><tds:Capabilities><tt:Analytics><tt:XAddr>http://192.0.2.13/onvif/analytics_service</tt:XAddr><tt:RuleSupport>true</tt:RuleSupport><tt:AnalyticsModuleSupport>true</tt:AnalyticsModuleSupport></tt:Analytics><tt:Device><tt:XAddr>http://192.0.2.13/onvif/device_service</tt:XAddr><tt:Network><tt:IPFilter>false</tt:IPFilter><tt:ZeroConfiguration>false</tt:ZeroConfiguration><tt:IPVersion6>false</tt:IPVersion6><tt:DynDNS>false</tt:DynDNS><tt:Extension><tt:Dot11Configuration>false</tt:Dot11Configuration></tt:Extension></tt:Network><tt:System><tt:DiscoveryResolve>false</tt:DiscoveryResolve><tt:DiscoveryBye>true</tt:DiscoveryBye><tt:RemoteDiscovery>false</tt:RemoteDiscovery><tt:SystemBackup>false</tt:SystemBackup><tt:SystemLogging>true</tt:SystemLogging><tt:FirmwareUpgrade>true</tt:FirmwareUpgrade><tt:SupportedVersions><tt:Major>2</tt:Major><tt:Minor>00</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>2</tt:Major><tt:Minor>10</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>2</tt:Major><tt:Minor>20</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>2</tt:Major><tt:Minor>30</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>2</tt:Major><tt:Minor>40</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>2</tt:Major><tt:Minor>42</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>16</tt:Major><tt:Minor>12</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>18</tt:Major><tt:Minor>06</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>18</tt:Major><tt:Minor>12</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>19</tt:Major><tt:Minor>06</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>19</tt:Major><tt:Minor>12</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>20</tt:Major><tt:Minor>06</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>20</tt:Major><tt:Minor>12</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>21</tt:Major><tt:Minor>06</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>21</tt:Major><tt:Minor>12</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>22</tt:Major><tt:Minor>06</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>22</tt:Major><tt:Minor>12</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>23</tt:Major><tt:Minor>06</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>23</tt:Major><tt:Minor>12</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>24</tt:Major><tt:Minor>06</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>24</tt:Major><tt:Minor>12</tt:Minor></tt:SupportedVersions><tt:SupportedVersions><tt:Major>25</tt:Major><tt:Minor>06</tt:Minor></tt:SupportedVersions><tt:Extension><tt:HttpFirmwareUpgrade>true</tt:HttpFirmwareUpgrade><tt:HttpSystemBackup>false</tt:HttpSystemBackup><tt:HttpSystemLogging>false</tt:HttpSystemLogging><tt:HttpSupportInformation>false</tt:HttpSupportInformation></tt:Extension></tt:System><tt:IO><tt:InputConnectors>2</tt:InputConnectors><tt:RelayOutputs>2</tt:RelayOutputs><tt:Extension><tt:Auxiliary>false</tt:Auxiliary><tt:AuxiliaryCommands></tt:AuxiliaryCommands><tt:Extension></tt:Extension></tt:Extension></tt:IO><tt:Security><tt:TLS1.1>false</tt:TLS1.1><tt:TLS1.2>false</tt:TLS1.2><tt:OnboardKeyGeneration>false</tt:OnboardKeyGeneration><tt:AccessPolicyConfig>false</tt:AccessPolicyConfig><tt:X.509Token>false</tt:X.509Token><tt:SAMLToken>false</tt:SAMLToken><tt:KerberosToken>false</tt:KerberosToken><tt:RELToken>false</tt:RELToken><tt:Extension><tt:TLS1.0>false</tt:TLS1.0><tt:Extension><tt:Dot1X>false</tt:Dot1X><tt:SupportedEAPMethod>0</tt:SupportedEAPMethod><tt:RemoteUserHandling>false</tt:RemoteUserHandling></tt:Extension></tt:Extension></tt:Security></tt:Device><tt:Events><tt:XAddr>http://192.0.2.13/onvif/event_service</tt:XAddr><tt:WSSubscriptionPolicySupport>true</tt:WSSubscriptionPolicySupport><tt:WSPullPointSupport>true</tt:WSPullPointSupport><tt:WSPausableSubscriptionManagerInterfaceSupport>false</tt:WSPausableSubscriptionManagerInterfaceSupport></tt:Events><tt:Imaging><tt:XAddr>http://192.0.2.13/onvif/imaging_service</tt:XAddr></tt:Imaging><tt:Media><tt:XAddr>http://192.0.2.13/onvif/media_service</tt:XAddr><tt:StreamingCapabilities><tt:RTPMulticast>true</tt:RTPMulticast><tt:RTP_TCP>true</tt:RTP_TCP><tt:RTP_RTSP_TCP>true</tt:RTP_RTSP_TCP></tt:StreamingCapabilities><tt:Extension><tt:ProfileCapabilities><tt:MaximumNumberOfProfiles>6</tt:MaximumNumberOfProfiles></tt:ProfileCapabilities></tt:Extension></tt:Media><tt:PTZ><tt:XAddr>http://192.0.2.13/onvif/ptz_service</tt:XAddr></tt:PTZ><tt:Extension><tt:DeviceIO><tt:XAddr>http://192.0.2.13/onvif/deviceIO_service</tt:XAddr><tt:VideoSources>1</tt:VideoSources><tt:VideoOutputs>1</tt:VideoOutputs><tt:AudioSources>1</tt:AudioSources><tt:AudioOutputs>1</tt:AudioOutputs><tt:RelayOutputs>2</tt:RelayOutputs></tt:DeviceIO></tt:Extension></tds:Capabilities></tds:GetCapabilitiesResponse></s:Body></s:Envelope>';

# Dahua Media2 GetProfiles
def const DH_PROFILES2 as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="utf-8" standalone="yes" ?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:sc="http://www.w3.org/2003/05/soap-encoding" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl"><s:Header/><s:Body><tr2:GetProfilesResponse><tr2:Profiles token="MediaProfile00000" fixed="true"><tr2:Name>MediaProfile_Channel1_MainStream</tr2:Name><tr2:Configurations><tr2:VideoSource token="00000"><tt:Name>VideoSourceConfig_Channel1</tt:Name><tt:UseCount>2</tt:UseCount><tt:SourceToken>00000</tt:SourceToken><tt:Bounds x="0" y="0" width="2048" height="1536"/><tt:Extension><tt:Rotate><tt:Mode>OFF</tt:Mode></tt:Rotate></tt:Extension></tr2:VideoSource><tr2:AudioSource token="00000"><tt:Name>AudioSourceConfig_Channel1</tt:Name><tt:UseCount>2</tt:UseCount><tt:SourceToken>00000</tt:SourceToken></tr2:AudioSource><tr2:VideoEncoder token="00000" GovLength="50" Profile="Main"><tt:Name>VideoEncoderConfig_Channel1_MainStream</tt:Name><tt:UseCount>1</tt:UseCount><tt:Encoding>H264</tt:Encoding><tt:Resolution><tt:Width>2688</tt:Width><tt:Height>1520</tt:Height></tt:Resolution><tt:RateControl ConstantBitRate="false"><tt:FrameRateLimit>25.000000</tt:FrameRateLimit><tt:BitrateLimit>4096</tt:BitrateLimit></tt:RateControl><tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type><tt:IPv4Address>224.1.0.0</tt:IPv4Address></tt:Address><tt:Port>40000</tt:Port><tt:TTL>64</tt:TTL><tt:AutoStart>false</tt:AutoStart></tt:Multicast><tt:Quality>4.000000</tt:Quality></tr2:VideoEncoder><tr2:AudioEncoder token="00000"><tt:Name>AudioEncoderConfig_Channel1_MainStream</tt:Name><tt:UseCount>1</tt:UseCount><tt:Encoding>PCMU</tt:Encoding><tt:Bitrate>32</tt:Bitrate><tt:SampleRate>8</tt:SampleRate><tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type><tt:IPv4Address>224.1.0.0</tt:IPv4Address></tt:Address><tt:Port>40002</tt:Port><tt:TTL>64</tt:TTL><tt:AutoStart>false</tt:AutoStart></tt:Multicast><tt:SessionTimeout>PT60S</tt:SessionTimeout></tr2:AudioEncoder><tr2:Analytics token="00000"><tt:Name>AnalyticsConfig_Channel1</tt:Name><tt:UseCount>2</tt:UseCount><tt:AnalyticsEngineConfiguration><tt:AnalyticsModule Name="MyCellMotion" Type="tt:CellMotionEngine"><tt:Parameters><tt:SimpleItem Name="Sensitivity" Value="0"/><tt:ElementItem Name="Layout"><tt:CellLayout Columns="22" Rows="18"><tt:Transformation><tt:Translate x="-1" y="-1"/><tt:Scale x="0.0062500000000000003" y="0.0083400000000000002"/></tt:Transformation></tt:CellLayout></tt:ElementItem></tt:Parameters></tt:AnalyticsModule></tt:AnalyticsEngineConfiguration><tt:RuleEngineConfiguration><tt:Rule Name="Region" Type="tt:CellMotionDetector"><tt:Parameters><tt:SimpleItem Name="MinCount" Value="0"/><tt:SimpleItem Name="AlarmOnDelay" Value="1000"/><tt:SimpleItem Name="AlarmOffDelay" Value="1000"/><tt:SimpleItem Name="ActiveCells" Value="zwA="/></tt:Parameters></tt:Rule></tt:RuleEngineConfiguration></tr2:Analytics><tr2:PTZ token="00000" MoveRamp="0" PresetRamp="0" PresetTourRamp="0"><tt:Name>PTZConfig_Channel1</tt:Name><tt:UseCount>2</tt:UseCount><tt:NodeToken>00000</tt:NodeToken><tt:DefaultAbsoluteZoomPositionSpace>http://www.onvif.org/ver10/tptz/ZoomSpaces/PositionGenericSpace</tt:DefaultAbsoluteZoomPositionSpace><tt:DefaultRelativeZoomTranslationSpace>http://www.onvif.org/ver10/tptz/ZoomSpaces/TranslationGenericSpace</tt:DefaultRelativeZoomTranslationSpace><tt:DefaultContinuousZoomVelocitySpace>http://www.onvif.org/ver10/tptz/ZoomSpaces/VelocityGenericSpace</tt:DefaultContinuousZoomVelocitySpace><tt:DefaultPTZSpeed><tt:Zoom space="http://www.onvif.org/ver10/tptz/ZoomSpaces/ZoomGenericSpeedSpace" x="0.80000001192092896"/></tt:DefaultPTZSpeed><tt:DefaultPTZTimeout>PT10S</tt:DefaultPTZTimeout><tt:ZoomLimits><tt:Range><tt:URI>http://www.onvif.org/ver10/tptz/ZoomSpaces/PositionGenericSpace</tt:URI><tt:XRange><tt:Min>0.000000</tt:Min><tt:Max>1.000000</tt:Max></tt:XRange></tt:Range></tt:ZoomLimits></tr2:PTZ><tr2:Metadata token="00000" CompressionType=""><tt:Name>MetadataConfig_Channel1</tt:Name><tt:UseCount>2</tt:UseCount><tt:PTZStatus><tt:Status>false</tt:Status><tt:Position>false</tt:Position></tt:PTZStatus><tt:Events><tt:Filter><wsnt:TopicExpression Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:tns1="http://www.onvif.org/ver10/topics">tns1:RuleEngine/CellMotionDetector/Motion</wsnt:TopicExpression></tt:Filter></tt:Events><tt:Analytics>true</tt:Analytics><tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type><tt:IPv4Address>224.2.0.0</tt:IPv4Address></tt:Address><tt:Port>40020</tt:Port><tt:TTL>64</tt:TTL><tt:AutoStart>false</tt:AutoStart></tt:Multicast><tt:SessionTimeout>PT60S</tt:SessionTimeout></tr2:Metadata><tr2:AudioOutput token="00000"><tt:Name>AudioOutputConfig_Channel1</tt:Name><tt:UseCount>2</tt:UseCount><tt:OutputToken>00000</tt:OutputToken><tt:SendPrimacy>www.onvif.org/ver20/HalfDuplex/Auto</tt:SendPrimacy><tt:OutputLevel>50</tt:OutputLevel></tr2:AudioOutput><tr2:AudioDecoder token="00000"><tt:Name>AudioDecoderConfig_Channel1_MainStream</tt:Name><tt:UseCount>1</tt:UseCount></tr2:AudioDecoder></tr2:Configurations></tr2:Profiles><tr2:Profiles token="MediaProfile00001" fixed="true"><tr2:Name>MediaProfile_Channel1_SubStream1</tr2:Name><tr2:Configurations><tr2:VideoSource token="00000"><tt:Name>VideoSourceConfig_Channel1</tt:Name><tt:UseCount>2</tt:UseCount><tt:SourceToken>00000</tt:SourceToken><tt:Bounds x="0" y="0" width="2048" height="1536"/><tt:Extension><tt:Rotate><tt:Mode>OFF</tt:Mode></tt:Rotate></tt:Extension></tr2:VideoSource><tr2:AudioSource token="00000"><tt:Name>AudioSourceConfig_Channel1</tt:Name><tt:UseCount>2</tt:UseCount><tt:SourceToken>00000</tt:SourceToken></tr2:AudioSource><tr2:VideoEncoder token="00001" GovLength="50" Profile="Main"><tt:Name>VideoEncoderConfig_Channel1_SubStream1</tt:Name><tt:UseCount>1</tt:UseCount><tt:Encoding>H264</tt:Encoding><tt:Resolution><tt:Width>704</tt:Width><tt:Height>576</tt:Height></tt:Resolution><tt:RateControl ConstantBitRate="false"><tt:FrameRateLimit>25.000000</tt:FrameRateLimit><tt:BitrateLimit>768</tt:BitrateLimit></tt:RateControl><tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type><tt:IPv4Address>224.1.0.1</tt:IPv4Address></tt:Address><tt:Port>40008</tt:Port><tt:TTL>64</tt:TTL><tt:AutoStart>false</tt:AutoStart></tt:Multicast><tt:Quality>5.000000</tt:Quality></tr2:VideoEncoder><tr2:AudioEncoder token="00001"><tt:Name>AudioEncoderConfig_Channel1_SubStream1</tt:Name><tt:UseCount>1</tt:UseCount><tt:Encoding>PCMU</tt:Encoding><tt:Bitrate>32</tt:Bitrate><tt:SampleRate>8</tt:SampleRate><tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type><tt:IPv4Address>224.1.0.1</tt:IPv4Address></tt:Address><tt:Port>40010</tt:Port><tt:TTL>64</tt:TTL><tt:AutoStart>false</tt:AutoStart></tt:Multicast><tt:SessionTimeout>PT60S</tt:SessionTimeout></tr2:AudioEncoder><tr2:Analytics token="00000"><tt:Name>AnalyticsConfig_Channel1</tt:Name><tt:UseCount>2</tt:UseCount><tt:AnalyticsEngineConfiguration><tt:AnalyticsModule Name="MyCellMotion" Type="tt:CellMotionEngine"><tt:Parameters><tt:SimpleItem Name="Sensitivity" Value="0"/><tt:ElementItem Name="Layout"><tt:CellLayout Columns="22" Rows="18"><tt:Transformation><tt:Translate x="-1" y="-1"/><tt:Scale x="0.0062500000000000003" y="0.0083400000000000002"/></tt:Transformation></tt:CellLayout></tt:ElementItem></tt:Parameters></tt:AnalyticsModule></tt:AnalyticsEngineConfiguration><tt:RuleEngineConfiguration><tt:Rule Name="Region" Type="tt:CellMotionDetector"><tt:Parameters><tt:SimpleItem Name="MinCount" Value="0"/><tt:SimpleItem Name="AlarmOnDelay" Value="1000"/><tt:SimpleItem Name="AlarmOffDelay" Value="1000"/><tt:SimpleItem Name="ActiveCells" Value="zwA="/></tt:Parameters></tt:Rule></tt:RuleEngineConfiguration></tr2:Analytics><tr2:PTZ token="00000" MoveRamp="0" PresetRamp="0" PresetTourRamp="0"><tt:Name>PTZConfig_Channel1</tt:Name><tt:UseCount>2</tt:UseCount><tt:NodeToken>00000</tt:NodeToken><tt:DefaultAbsoluteZoomPositionSpace>http://www.onvif.org/ver10/tptz/ZoomSpaces/PositionGenericSpace</tt:DefaultAbsoluteZoomPositionSpace><tt:DefaultRelativeZoomTranslationSpace>http://www.onvif.org/ver10/tptz/ZoomSpaces/TranslationGenericSpace</tt:DefaultRelativeZoomTranslationSpace><tt:DefaultContinuousZoomVelocitySpace>http://www.onvif.org/ver10/tptz/ZoomSpaces/VelocityGenericSpace</tt:DefaultContinuousZoomVelocitySpace><tt:DefaultPTZSpeed><tt:Zoom space="http://www.onvif.org/ver10/tptz/ZoomSpaces/ZoomGenericSpeedSpace" x="0.80000001192092896"/></tt:DefaultPTZSpeed><tt:DefaultPTZTimeout>PT10S</tt:DefaultPTZTimeout><tt:ZoomLimits><tt:Range><tt:URI>http://www.onvif.org/ver10/tptz/ZoomSpaces/PositionGenericSpace</tt:URI><tt:XRange><tt:Min>0.000000</tt:Min><tt:Max>1.000000</tt:Max></tt:XRange></tt:Range></tt:ZoomLimits></tr2:PTZ><tr2:Metadata token="00000" CompressionType=""><tt:Name>MetadataConfig_Channel1</tt:Name><tt:UseCount>2</tt:UseCount><tt:PTZStatus><tt:Status>false</tt:Status><tt:Position>false</tt:Position></tt:PTZStatus><tt:Events><tt:Filter><wsnt:TopicExpression Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:tns1="http://www.onvif.org/ver10/topics">tns1:RuleEngine/CellMotionDetector/Motion</wsnt:TopicExpression></tt:Filter></tt:Events><tt:Analytics>true</tt:Analytics><tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type><tt:IPv4Address>224.2.0.0</tt:IPv4Address></tt:Address><tt:Port>40020</tt:Port><tt:TTL>64</tt:TTL><tt:AutoStart>false</tt:AutoStart></tt:Multicast><tt:SessionTimeout>PT60S</tt:SessionTimeout></tr2:Metadata><tr2:AudioOutput token="00000"><tt:Name>AudioOutputConfig_Channel1</tt:Name><tt:UseCount>2</tt:UseCount><tt:OutputToken>00000</tt:OutputToken><tt:SendPrimacy>www.onvif.org/ver20/HalfDuplex/Auto</tt:SendPrimacy><tt:OutputLevel>50</tt:OutputLevel></tr2:AudioOutput><tr2:AudioDecoder token="00001"><tt:Name>AudioDecoderConfig_Channel1_SubStream1</tt:Name><tt:UseCount>1</tt:UseCount></tr2:AudioDecoder></tr2:Configurations></tr2:Profiles></tr2:GetProfilesResponse></s:Body></s:Envelope>';

# Dahua Media2 GetStreamUri: a query with &amp;
def const DH_STREAM2 as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="utf-8" standalone="yes" ?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:sc="http://www.w3.org/2003/05/soap-encoding" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl"><s:Header/><s:Body><tr2:GetStreamUriResponse><tr2:Uri>rtsp://192.0.2.13:554/cam/realmonitor?channel=1&amp;subtype=0&amp;unicast=true&amp;proto=Onvif</tr2:Uri></tr2:GetStreamUriResponse></s:Body></s:Envelope>';

# Dahua Media2 GetSnapshotUri
def const DH_SNAPSHOT_URI2 as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="utf-8" standalone="yes" ?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:sc="http://www.w3.org/2003/05/soap-encoding" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:tr2="http://www.onvif.org/ver20/media/wsdl"><s:Header/><s:Body><tr2:GetSnapshotUriResponse><tr2:Uri>https://192.0.2.13/onvif/snapshot?channel=1&amp;subtype=0</tr2:Uri></tr2:GetSnapshotUriResponse></s:Body></s:Envelope>';

# Dahua Media2 GetStreamUri Rtsps: ter:InvalidStreamSetup
def const DH_RTSPS_FAULT as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="utf-8" standalone="yes" ?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:sc="http://www.w3.org/2003/05/soap-encoding" xmlns:ter="http://www.onvif.org/ver10/error" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:wsrf-bf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery"><s:Body><s:Fault><s:Code><s:Value>s:Sender</s:Value><s:Subcode><s:Value>ter:InvalidArgVal</s:Value><s:Subcode><s:Value>ter:InvalidStreamSetup</s:Value></s:Subcode></s:Subcode></s:Code><s:Reason><s:Text xml:lang="en">The specified Protocol is not supported</s:Text></s:Reason></s:Fault></s:Body></s:Envelope>';

# Dahua GetImagingSettings of a missing source
def const DH_NO_SOURCE as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="utf-8" standalone="yes" ?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:sc="http://www.w3.org/2003/05/soap-encoding" xmlns:ter="http://www.onvif.org/ver10/error" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:wsrf-bf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery"><s:Body><s:Fault><s:Code><s:Value>s:Sender</s:Value><s:Subcode><s:Value>ter:InvalidArgVal</s:Value><s:Subcode><s:Value>ter:NoSource</s:Value></s:Subcode></s:Subcode></s:Code><s:Reason><s:Text xml:lang="en">The requested VideoSource does not exist.</s:Text></s:Reason></s:Fault></s:Body></s:Envelope>';

# Dahua CreatePullPointSubscription
def const DH_SUBSCRIBE as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="utf-8" standalone="yes" ?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:sc="http://www.w3.org/2003/05/soap-encoding" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:wsa5="http://www.w3.org/2005/08/addressing" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1"><s:Header/><s:Body><tev:CreatePullPointSubscriptionResponse><tev:SubscriptionReference><wsa5:Address>http://192.0.2.13/onvif/Subscription?Idx=0</wsa5:Address></tev:SubscriptionReference><wsnt:CurrentTime>2026-10-15T17:40:13Z</wsnt:CurrentTime><wsnt:TerminationTime>2026-10-15T17:41:13Z</wsnt:TerminationTime></tev:CreatePullPointSubscriptionResponse></s:Body></s:Envelope>';

# Dahua PullMessages, the Initialized state
def const DH_PULL as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="utf-8" standalone="yes" ?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:sc="http://www.w3.org/2003/05/soap-encoding" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:wsa5="http://www.w3.org/2005/08/addressing" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1"><s:Header><wsa5:Action>http://www.onvif.org/ver10/events/wsdl/PullPointSubscription/PullMessagesResponse</wsa5:Action><wsa5:To>http://192.0.2.13/onvif/Subscription?Idx=0</wsa5:To></s:Header><s:Body><tev:PullMessagesResponse><tev:CurrentTime>2026-10-15T17:40:13Z</tev:CurrentTime><tev:TerminationTime>2026-10-15T17:41:13Z</tev:TerminationTime><wsnt:NotificationMessage><wsnt:Topic Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet">tns1:RuleEngine/CellMotionDetector/Motion</wsnt:Topic><wsnt:Message><tt:Message UtcTime="2026-10-15T17:40:13Z" PropertyOperation="Initialized"><tt:Source><tt:SimpleItem Name="VideoSourceConfigurationToken" Value="00000"/><tt:SimpleItem Name="VideoAnalyticsConfigurationToken" Value="00000"/><tt:SimpleItem Name="Rule" Value="00000"/></tt:Source><tt:Data><tt:SimpleItem Name="IsMotion" Value="false"/></tt:Data></tt:Message></wsnt:Message></wsnt:NotificationMessage><wsnt:NotificationMessage><wsnt:Topic Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet">tns1:VideoSource/MotionAlarm</wsnt:Topic><wsnt:Message><tt:Message UtcTime="2026-10-15T17:40:13Z" PropertyOperation="Initialized"><tt:Source><tt:SimpleItem Name="Source" Value="00000"/></tt:Source><tt:Data><tt:SimpleItem Name="State" Value="false"/></tt:Data></tt:Message></wsnt:Message></wsnt:NotificationMessage><wsnt:NotificationMessage><wsnt:Topic Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet">tns1:VideoSource/GlobalSceneChange/AnalyticsService</wsnt:Topic><wsnt:Message><tt:Message UtcTime="2026-10-15T17:40:13Z" PropertyOperation="Initialized"><tt:Source><tt:SimpleItem Name="Source" Value="00000"/></tt:Source><tt:Data><tt:SimpleItem Name="State" Value="false"/></tt:Data></tt:Message></wsnt:Message></wsnt:NotificationMessage><wsnt:NotificationMessage><wsnt:Topic Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet">tns1:Device/Trigger/DigitalInput</wsnt:Topic><wsnt:Message><tt:Message UtcTime="2026-10-15T17:40:13Z" PropertyOperation="Initialized"><tt:Source><tt:SimpleItem Name="InputToken" Value="00000"/></tt:Source><tt:Data><tt:SimpleItem Name="LogicalState" Value="false"/></tt:Data></tt:Message></wsnt:Message></wsnt:NotificationMessage><wsnt:NotificationMessage><wsnt:Topic Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet">tns1:Device/Trigger/DigitalInput</wsnt:Topic><wsnt:Message><tt:Message UtcTime="2026-10-15T17:40:13Z" PropertyOperation="Initialized"><tt:Source><tt:SimpleItem Name="InputToken" Value="00100"/></tt:Source><tt:Data><tt:SimpleItem Name="LogicalState" Value="false"/></tt:Data></tt:Message></wsnt:Message></wsnt:NotificationMessage><wsnt:NotificationMessage><wsnt:Topic Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet">tns1:Device/Trigger/Relay</wsnt:Topic><wsnt:Message><tt:Message UtcTime="2026-10-15T17:40:13Z" PropertyOperation="Initialized"><tt:Source><tt:SimpleItem Name="RelayToken" Value="00000"/></tt:Source><tt:Data><tt:SimpleItem Name="LogicalState" Value="inactive"/></tt:Data></tt:Message></wsnt:Message></wsnt:NotificationMessage><wsnt:NotificationMessage><wsnt:Topic Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet">tns1:Device/Trigger/Relay</wsnt:Topic><wsnt:Message><tt:Message UtcTime="2026-10-15T17:40:13Z" PropertyOperation="Initialized"><tt:Source><tt:SimpleItem Name="RelayToken" Value="00100"/></tt:Source><tt:Data><tt:SimpleItem Name="LogicalState" Value="inactive"/></tt:Data></tt:Message></wsnt:Message></wsnt:NotificationMessage><wsnt:NotificationMessage><wsnt:Topic Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet">tns1:Monitoring/ProcessorUsage</wsnt:Topic><wsnt:Message><tt:Message UtcTime="2026-10-15T17:40:13Z" PropertyOperation="Initialized"><tt:Source><tt:SimpleItem Name="Token" Value="000"/></tt:Source><tt:Data><tt:SimpleItem Name="Value" Value="0.440000"/></tt:Data></tt:Message></wsnt:Message></wsnt:NotificationMessage><wsnt:NotificationMessage><wsnt:Topic Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet">tns1:Monitoring/OperatingTime/LastReboot</wsnt:Topic><wsnt:Message><tt:Message UtcTime="2026-10-15T17:40:13Z" PropertyOperation="Initialized"><tt:Data><tt:SimpleItem Name="Status" Value="15-10-2026T18:29:45Z"/></tt:Data></tt:Message></wsnt:Message></wsnt:NotificationMessage><wsnt:NotificationMessage><wsnt:Topic Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet">tns1:Monitoring/OperatingTime/LastReset</wsnt:Topic><wsnt:Message><tt:Message UtcTime="2026-10-15T17:40:13Z" PropertyOperation="Initialized"><tt:Data><tt:SimpleItem Name="Status" Value="1970-01-01T00:00:00Z"/></tt:Data></tt:Message></wsnt:Message></wsnt:NotificationMessage><wsnt:NotificationMessage><wsnt:Topic Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet">tns1:Monitoring/OperatingTime/LastClockSynchronization</wsnt:Topic><wsnt:Message><tt:Message UtcTime="2026-10-15T17:40:13Z" PropertyOperation="Initialized"><tt:Data><tt:SimpleItem Name="Status" Value="1970-01-01T00:00:00Z"/></tt:Data></tt:Message></wsnt:Message></wsnt:NotificationMessage><wsnt:NotificationMessage><wsnt:Topic Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet">tns1:Device/HardwareFailure/StorageFailure</wsnt:Topic><wsnt:Message><tt:Message UtcTime="2026-10-15T17:40:13Z" PropertyOperation="Initialized"><tt:Source><tt:SimpleItem Name="Token" Value="00000"/></tt:Source><tt:Data><tt:SimpleItem Name="Failed" Value="false"/></tt:Data></tt:Message></wsnt:Message></wsnt:NotificationMessage><wsnt:NotificationMessage><wsnt:Topic Dialect="http://www.onvif.org/ver10/tev/topicExpression/ConcreteSet">tns1:RuleEngine/CountAggregation/Counter</wsnt:Topic><wsnt:Message><tt:Message UtcTime="2026-10-15T17:40:13Z" PropertyOperation="Initialized"><tt:Source><tt:SimpleItem Name="VideoSource" Value="00000"/><tt:SimpleItem Name="AnalyticsConfiguration" Value="00000"/><tt:SimpleItem Name="Rule" Value=""/></tt:Source><tt:Data><tt:SimpleItem Name="Count" Value="0"/></tt:Data></tt:Message></wsnt:Message></wsnt:NotificationMessage></tev:PullMessagesResponse></s:Body></s:Envelope>';

# Dahua Unsubscribe
def const DH_UNSUBSCRIBE as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="utf-8" standalone="yes" ?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:sc="http://www.w3.org/2003/05/soap-encoding" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:wsa5="http://www.w3.org/2005/08/addressing" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1"><s:Header><wsa5:Action>http://docs.oasis-open.org/wsn/bw-2/SubscriptionManager/UnsubscribeResponse</wsa5:Action><wsa5:To>http://192.0.2.13/onvif/Subscription?Idx=0</wsa5:To></s:Header><s:Body><wsnt:UnsubscribeResponse/></s:Body></s:Envelope>';

# DVC DCN-BF5365 (gSOAP) Media2 GetProfiles, prefix trt2
def const DVC_PROFILES2 as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:SOAP-ENC="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsdd="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:wsa5="http://www.w3.org/2005/08/addressing" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:tpa="http://www.onvif.org/ver10/pacs" xmlns:xmime="http://tempuri.org/xmime.xsd" xmlns:xop="http://www.w3.org/2004/08/xop/include" xmlns:wsrfbf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1" xmlns:wsrfr="http://docs.oasis-open.org/wsrf/r-2" xmlns:tac="http://www.onvif.org/ver10/accesscontrol/wsdl" xmlns:tad="http://www.onvif.org/ver10/analyticsdevice/wsdl" xmlns:tae="http://www.onvif.org/ver10/actionengine/wsdl" xmlns:tana="http://www.onvif.org/ver20/analytics/wsdl/AnalyticsEngineBinding" xmlns:tanr="http://www.onvif.org/ver20/analytics/wsdl/RuleEngineBinding" xmlns:tan="http://www.onvif.org/ver20/analytics/wsdl" xmlns:tar="http://www.onvif.org/ver10/accessrules/wsdl" xmlns:tasa="http://www.onvif.org/ver10/advancedsecurity/wsdl/AdvancedSecurityServiceBinding" xmlns:tasd="http://www.onvif.org/ver10/advancedsecurity/wsdl/Dot1XBinding" xmlns:task="http://www.onvif.org/ver10/advancedsecurity/wsdl/KeystoreBinding" xmlns:tast="http://www.onvif.org/ver10/advancedsecurity/wsdl/TLSServerBinding" xmlns:tas="http://www.onvif.org/ver10/advancedsecurity/wsdl" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:tec="http://www.onvif.org/ver10/events/wsdl/CreatePullPointBinding" xmlns:tee="http://www.onvif.org/ver10/events/wsdl/EventBinding" xmlns:tenc="http://www.onvif.org/ver10/events/wsdl/NotificationConsumerBinding" xmlns:tenp="http://www.onvif.org/ver10/events/wsdl/NotificationProducerBinding" xmlns:tep="http://www.onvif.org/ver10/events/wsdl/PullPointBinding" xmlns:tepa="http://www.onvif.org/ver10/events/wsdl/PausableSubscriptionManagerBinding" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:tepu="http://www.onvif.org/ver10/events/wsdl/PullPointSubscriptionBinding" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tesm="http://www.onvif.org/ver10/events/wsdl/SubscriptionManagerBinding" xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tls="http://www.onvif.org/ver10/display/wsdl" xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl" xmlns:tndl="http://www.onvif.org/ver10/network/wsdl/DiscoveryLookupBinding" xmlns:tdn="http://www.onvif.org/ver10/network/wsdl" xmlns:tnrd="http://www.onvif.org/ver10/network/wsdl/RemoteDiscoveryBinding" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:trc="http://www.onvif.org/ver10/recording/wsdl" xmlns:trp="http://www.onvif.org/ver10/replay/wsdl" xmlns:trt="http://www.onvif.org/ver10/media/wsdl" xmlns:trt2="http://www.onvif.org/ver20/media/wsdl" xmlns:trv="http://www.onvif.org/ver10/receiver/wsdl" xmlns:tse="http://www.onvif.org/ver10/search/wsdl" xmlns:tss="http://www.onvif.org/ver10/schedule/wsdl" xmlns:tth="http://www.onvif.org/ver10/thermal/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:ter="http://www.onvif.org/ver10/error"><SOAP-ENV:Header></SOAP-ENV:Header><SOAP-ENV:Body><trt2:GetProfilesResponse><trt2:Profiles fixed="true" token="profile_token_1"><trt2:Name>profile1</trt2:Name><trt2:Configurations><trt2:VideoSource token="VideoSource_token_1"><tt:Name>VideoSource_1</tt:Name><tt:UseCount>4</tt:UseCount><tt:SourceToken>VideoSource_token_1</tt:SourceToken><tt:Bounds height="1944" width="2592" y="0" x="0"></tt:Bounds></trt2:VideoSource><trt2:AudioSource token="VideoEncode_token_1"><tt:Name>VideoEncode_1</tt:Name><tt:UseCount>1</tt:UseCount><tt:SourceToken>VideoEncode_token_1</tt:SourceToken></trt2:AudioSource><trt2:VideoEncoder Profile="High" GovLength="40" token="VideoEncode_token_1"><tt:Name>VideoEncode_1</tt:Name><tt:UseCount>1</tt:UseCount><tt:Encoding>H265</tt:Encoding><tt:Resolution><tt:Width>2592</tt:Width><tt:Height>1944</tt:Height></tt:Resolution><tt:RateControl ConstantBitRate="false"><tt:FrameRateLimit>20</tt:FrameRateLimit><tt:BitrateLimit>4096</tt:BitrateLimit></tt:RateControl><tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type><tt:IPv4Address>239.0.0.0</tt:IPv4Address></tt:Address><tt:Port>50554</tt:Port><tt:TTL>1</tt:TTL><tt:AutoStart>false</tt:AutoStart></tt:Multicast><tt:Quality>4</tt:Quality></trt2:VideoEncoder><trt2:AudioEncoder token="AudioEncode_token_1"><tt:Name>AudioEncode_1</tt:Name><tt:UseCount>3</tt:UseCount><tt:Encoding>PCMA</tt:Encoding><tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type><tt:IPv4Address>239.0.0.3</tt:IPv4Address></tt:Address><tt:Port>53554</tt:Port><tt:TTL>1</tt:TTL><tt:AutoStart>false</tt:AutoStart></tt:Multicast><tt:Bitrate>128</tt:Bitrate><tt:SampleRate>8</tt:SampleRate></trt2:AudioEncoder><trt2:Analytics token="VideoAnalytics0"><tt:Name>MotionAnalytics_0</tt:Name><tt:UseCount>4</tt:UseCount><tt:AnalyticsEngineConfiguration><tt:AnalyticsModule Name="CellMotionModule" Type="tt:CellMotionEngine"><tt:Parameters><tt:SimpleItem Value="0" Name="Sensitivity"></tt:SimpleItem><tt:ElementItem Name="Layout"><tt:CellLayout Columns="22" Rows="18"><tt:Transformation><tt:Translate x="-1.000000" y="-1.000000"/><tt:Scale x="0.000772" y="0.001029"/></tt:Transformation></tt:CellLayout></tt:ElementItem></tt:Parameters></tt:AnalyticsModule></tt:AnalyticsEngineConfiguration><tt:RuleEngineConfiguration><tt:Rule Name="MotionDetectorRule0" Type="tt:CellMotionDetector"><tt:Parameters><tt:SimpleItem Value="1" Name="MinCount"></tt:SimpleItem><tt:SimpleItem Value="0" Name="AlarmOnDelay"></tt:SimpleItem><tt:SimpleItem Value="20000" Name="AlarmOffDelay"></tt:SimpleItem><tt:SimpleItem Value="0P8A8A==" Name="ActiveCells"></tt:SimpleItem></tt:Parameters></tt:Rule></tt:RuleEngineConfiguration></trt2:Analytics></trt2:Configurations></trt2:Profiles><trt2:Profiles fixed="true" token="profile_token_2"><trt2:Name>profile2</trt2:Name><trt2:Configurations><trt2:VideoSource token="VideoSource_token_1"><tt:Name>VideoSource_1</tt:Name><tt:UseCount>4</tt:UseCount><tt:SourceToken>VideoSource_token_1</tt:SourceToken><tt:Bounds height="1944" width="2592" y="0" x="0"></tt:Bounds></trt2:VideoSource><trt2:AudioSource token="VideoEncode_token_2"><tt:Name>VideoEncode_2</tt:Name><tt:UseCount>0</tt:UseCount><tt:SourceToken>VideoEncode_token_2</tt:SourceToken></trt2:AudioSource><trt2:VideoEncoder Profile="High" GovLength="50" token="VideoEncode_token_2"><tt:Name>VideoEncode_2</tt:Name><tt:UseCount>1</tt:UseCount><tt:Encoding>H264</tt:Encoding><tt:Resolution><tt:Width>1280</tt:Width><tt:Height>720</tt:Height></tt:Resolution><tt:RateControl ConstantBitRate="true"><tt:FrameRateLimit>10</tt:FrameRateLimit><tt:BitrateLimit>1024</tt:BitrateLimit></tt:RateControl><tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type><tt:IPv4Address>239.0.0.1</tt:IPv4Address></tt:Address><tt:Port>51554</tt:Port><tt:TTL>1</tt:TTL><tt:AutoStart>false</tt:AutoStart></tt:Multicast><tt:Quality>3</tt:Quality></trt2:VideoEncoder><trt2:AudioEncoder token="AudioEncode_token_1"><tt:Name>AudioEncode_1</tt:Name><tt:UseCount>3</tt:UseCount><tt:Encoding>PCMA</tt:Encoding><tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type><tt:IPv4Address>239.0.0.3</tt:IPv4Address></tt:Address><tt:Port>53554</tt:Port><tt:TTL>1</tt:TTL><tt:AutoStart>false</tt:AutoStart></tt:Multicast><tt:Bitrate>128</tt:Bitrate><tt:SampleRate>8</tt:SampleRate></trt2:AudioEncoder><trt2:Analytics token="VideoAnalytics0"><tt:Name>MotionAnalytics_0</tt:Name><tt:UseCount>4</tt:UseCount><tt:AnalyticsEngineConfiguration><tt:AnalyticsModule Name="CellMotionModule" Type="tt:CellMotionEngine"><tt:Parameters><tt:SimpleItem Value="0" Name="Sensitivity"></tt:SimpleItem><tt:ElementItem Name="Layout"><tt:CellLayout Columns="22" Rows="18"><tt:Transformation><tt:Translate x="-1.000000" y="-1.000000"/><tt:Scale x="0.001563" y="0.002778"/></tt:Transformation></tt:CellLayout></tt:ElementItem></tt:Parameters></tt:AnalyticsModule></tt:AnalyticsEngineConfiguration><tt:RuleEngineConfiguration><tt:Rule Name="MotionDetectorRule0" Type="tt:CellMotionDetector"><tt:Parameters><tt:SimpleItem Value="1" Name="MinCount"></tt:SimpleItem><tt:SimpleItem Value="0" Name="AlarmOnDelay"></tt:SimpleItem><tt:SimpleItem Value="20000" Name="AlarmOffDelay"></tt:SimpleItem><tt:SimpleItem Value="0P8A8A==" Name="ActiveCells"></tt:SimpleItem></tt:Parameters></tt:Rule></tt:RuleEngineConfiguration></trt2:Analytics></trt2:Configurations></trt2:Profiles><trt2:Profiles fixed="true" token="profile_token_3"><trt2:Name>profile3</trt2:Name><trt2:Configurations><trt2:VideoSource token="VideoSource_token_1"><tt:Name>VideoSource_1</tt:Name><tt:UseCount>4</tt:UseCount><tt:SourceToken>VideoSource_token_1</tt:SourceToken><tt:Bounds height="1944" width="2592" y="0" x="0"></tt:Bounds></trt2:VideoSource><trt2:AudioSource token="VideoEncode_token_3"><tt:Name>VideoEncode_3</tt:Name><tt:UseCount>1</tt:UseCount><tt:SourceToken>VideoEncode_token_3</tt:SourceToken></trt2:AudioSource><trt2:VideoEncoder Profile="High" GovLength="50" token="VideoEncode_token_3"><tt:Name>VideoEncode_3</tt:Name><tt:UseCount>1</tt:UseCount><tt:Encoding>H265</tt:Encoding><tt:Resolution><tt:Width>704</tt:Width><tt:Height>576</tt:Height></tt:Resolution><tt:RateControl ConstantBitRate="true"><tt:FrameRateLimit>25</tt:FrameRateLimit><tt:BitrateLimit>512</tt:BitrateLimit></tt:RateControl><tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type><tt:IPv4Address>239.0.0.2</tt:IPv4Address></tt:Address><tt:Port>52554</tt:Port><tt:TTL>1</tt:TTL><tt:AutoStart>false</tt:AutoStart></tt:Multicast><tt:Quality>4</tt:Quality></trt2:VideoEncoder><trt2:AudioEncoder token="AudioEncode_token_1"><tt:Name>AudioEncode_1</tt:Name><tt:UseCount>3</tt:UseCount><tt:Encoding>PCMA</tt:Encoding><tt:Multicast><tt:Address><tt:Type>IPv4</tt:Type><tt:IPv4Address>239.0.0.3</tt:IPv4Address></tt:Address><tt:Port>53554</tt:Port><tt:TTL>1</tt:TTL><tt:AutoStart>false</tt:AutoStart></tt:Multicast><tt:Bitrate>128</tt:Bitrate><tt:SampleRate>8</tt:SampleRate></trt2:AudioEncoder><trt2:Analytics token="VideoAnalytics0"><tt:Name>MotionAnalytics_0</tt:Name><tt:UseCount>4</tt:UseCount><tt:AnalyticsEngineConfiguration><tt:AnalyticsModule Name="CellMotionModule" Type="tt:CellMotionEngine"><tt:Parameters><tt:SimpleItem Value="0" Name="Sensitivity"></tt:SimpleItem><tt:ElementItem Name="Layout"><tt:CellLayout Columns="22" Rows="18"><tt:Transformation><tt:Translate x="-1.000000" y="-1.000000"/><tt:Scale x="0.002841" y="0.003472"/></tt:Transformation></tt:CellLayout></tt:ElementItem></tt:Parameters></tt:AnalyticsModule></tt:AnalyticsEngineConfiguration><tt:RuleEngineConfiguration><tt:Rule Name="MotionDetectorRule0" Type="tt:CellMotionDetector"><tt:Parameters><tt:SimpleItem Value="1" Name="MinCount"></tt:SimpleItem><tt:SimpleItem Value="0" Name="AlarmOnDelay"></tt:SimpleItem><tt:SimpleItem Value="20000" Name="AlarmOffDelay"></tt:SimpleItem><tt:SimpleItem Value="0P8A8A==" Name="ActiveCells"></tt:SimpleItem></tt:Parameters></tt:Rule></tt:RuleEngineConfiguration></trt2:Analytics></trt2:Configurations></trt2:Profiles></trt2:GetProfilesResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>';

# DVC: HTTP 401 with a SOAP fault and no subcode
def const DVC_UNAUTHORIZED as string init "401\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:SOAP-ENC="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsdd="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:wsa5="http://www.w3.org/2005/08/addressing" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:tpa="http://www.onvif.org/ver10/pacs" xmlns:xmime="http://tempuri.org/xmime.xsd" xmlns:xop="http://www.w3.org/2004/08/xop/include" xmlns:wsrfbf="http://docs.oasis-open.org/wsrf/bf-2" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:wstop="http://docs.oasis-open.org/wsn/t-1" xmlns:wsrfr="http://docs.oasis-open.org/wsrf/r-2" xmlns:tac="http://www.onvif.org/ver10/accesscontrol/wsdl" xmlns:tad="http://www.onvif.org/ver10/analyticsdevice/wsdl" xmlns:tae="http://www.onvif.org/ver10/actionengine/wsdl" xmlns:tana="http://www.onvif.org/ver20/analytics/wsdl/AnalyticsEngineBinding" xmlns:tanr="http://www.onvif.org/ver20/analytics/wsdl/RuleEngineBinding" xmlns:tan="http://www.onvif.org/ver20/analytics/wsdl" xmlns:tar="http://www.onvif.org/ver10/accessrules/wsdl" xmlns:tasa="http://www.onvif.org/ver10/advancedsecurity/wsdl/AdvancedSecurityServiceBinding" xmlns:tasd="http://www.onvif.org/ver10/advancedsecurity/wsdl/Dot1XBinding" xmlns:task="http://www.onvif.org/ver10/advancedsecurity/wsdl/KeystoreBinding" xmlns:tast="http://www.onvif.org/ver10/advancedsecurity/wsdl/TLSServerBinding" xmlns:tas="http://www.onvif.org/ver10/advancedsecurity/wsdl" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:tec="http://www.onvif.org/ver10/events/wsdl/CreatePullPointBinding" xmlns:tee="http://www.onvif.org/ver10/events/wsdl/EventBinding" xmlns:tenc="http://www.onvif.org/ver10/events/wsdl/NotificationConsumerBinding" xmlns:tenp="http://www.onvif.org/ver10/events/wsdl/NotificationProducerBinding" xmlns:tep="http://www.onvif.org/ver10/events/wsdl/PullPointBinding" xmlns:tepa="http://www.onvif.org/ver10/events/wsdl/PausableSubscriptionManagerBinding" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:tepu="http://www.onvif.org/ver10/events/wsdl/PullPointSubscriptionBinding" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tesm="http://www.onvif.org/ver10/events/wsdl/SubscriptionManagerBinding" xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl" xmlns:tls="http://www.onvif.org/ver10/display/wsdl" xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl" xmlns:tndl="http://www.onvif.org/ver10/network/wsdl/DiscoveryLookupBinding" xmlns:tdn="http://www.onvif.org/ver10/network/wsdl" xmlns:tnrd="http://www.onvif.org/ver10/network/wsdl/RemoteDiscoveryBinding" xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl" xmlns:trc="http://www.onvif.org/ver10/recording/wsdl" xmlns:trp="http://www.onvif.org/ver10/replay/wsdl" xmlns:trt="http://www.onvif.org/ver10/media/wsdl" xmlns:trt2="http://www.onvif.org/ver20/media/wsdl" xmlns:trv="http://www.onvif.org/ver10/receiver/wsdl" xmlns:tse="http://www.onvif.org/ver10/search/wsdl" xmlns:tss="http://www.onvif.org/ver10/schedule/wsdl" xmlns:tth="http://www.onvif.org/ver10/thermal/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:ter="http://www.onvif.org/ver10/error"><SOAP-ENV:Header></SOAP-ENV:Header><SOAP-ENV:Body><SOAP-ENV:Fault><SOAP-ENV:Code><SOAP-ENV:Value>SOAP-ENV:Sender</SOAP-ENV:Value></SOAP-ENV:Code><SOAP-ENV:Reason><SOAP-ENV:Text xml:lang="en">HTTP Error: 401 Unauthorized</SOAP-ENV:Text></SOAP-ENV:Reason></SOAP-ENV:Fault></SOAP-ENV:Body></SOAP-ENV:Envelope>';

# DVC ProbeMatches: an IPv4 and an IPv6 XAddr
def const DVC_PROBE_MATCHES as string init "200\nContent-Type: application/soap+xml\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:SOAP-ENC="http://www.w3.org/2003/05/soap-encoding" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa5="http://www.w3.org/2005/08/addressing" xmlns:c14n="http://www.w3.org/2001/10/xml-exc-c14n#" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:wsdd="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:tdn="http://www.onvif.org/ver10/network/wsdl"><SOAP-ENV:Header><wsa:MessageID>urn:uuid:00000000-0000-4000-8000-000000000011</wsa:MessageID><wsa:RelatesTo>urn:uuid:00000000-0000-4000-8000-000000000012</wsa:RelatesTo><wsa:To SOAP-ENV:mustUnderstand="true">http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To><wsa:Action SOAP-ENV:mustUnderstand="true">http://schemas.xmlsoap.org/ws/2005/04/discovery/ProbeMatches</wsa:Action></SOAP-ENV:Header><SOAP-ENV:Body><wsdd:ProbeMatches><wsdd:ProbeMatch><wsa:EndpointReference><wsa:Address>urn:uuid:00000000-0000-4000-8000-000000000011</wsa:Address></wsa:EndpointReference><wsdd:Types>tdn:NetworkVideoTransmitter tds:Device</wsdd:Types><wsdd:Scopes>onvif://www.onvif.org/type/video_encoder onvif://www.onvif.org/type/ptz onvif://www.onvif.org/type/audio_encoder onvif://www.onvif.org/hardware/DCN-BF5365 onvif://www.onvif.org/Profile/Streaming onvif://www.onvif.org/location/REDACTED6 onvif://www.onvif.org/name/REDACTED7 onvif://www.onvif.org/Profile/G </wsdd:Scopes><wsdd:XAddrs>http://192.0.2.14:80/onvif/device_service http://[fe80::a]:80/onvif/device_service</wsdd:XAddrs><wsdd:MetadataVersion>10</wsdd:MetadataVersion><tns1:Extension>TDigitalIPC</tns1:Extension></wsdd:ProbeMatch></wsdd:ProbeMatches></SOAP-ENV:Body></SOAP-ENV:Envelope>';

# ONVIF Application Programmer's Guide (an Axis): reference parameters
def const APG_SUBSCRIBE as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:wsa5="http://www.w3.org/2005/08/addressing" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:tev="http://www.onvif.org/ver10/events/wsdl">
  <SOAP-ENV:Header>
    <wsa5:Action SOAP-ENV:mustUnderstand="true">http://www.onvif.org/ver10/events/wsdl/EventPortType/CreatePullPointSubscriptionResponse</wsa5:Action>
  </SOAP-ENV:Header>
  <SOAP-ENV:Body>
    <tev:CreatePullPointSubscriptionResponse>
      <tev:SubscriptionReference>
        <wsa5:Address>http://192.168.1.24/onvif/services</wsa5:Address>
        <wsa5:ReferenceParameters>
          <dom0:SubscriptionId xmlns:dom0="http://www.example.com/2009/event">6</dom0:SubscriptionId>
        </wsa5:ReferenceParameters>
      </tev:SubscriptionReference>
      <wsnt:CurrentTime>2010-10-29T15:52:30Z</wsnt:CurrentTime>
      <wsnt:TerminationTime>2010-10-29T15:53:30Z</wsnt:TerminationTime>
    </tev:CreatePullPointSubscriptionResponse>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>';

# ONVIF Application Programmer's Guide: PullMessages with a message
def const APG_PULL as string init "200\nContent-Type: application/soap+xml; charset=utf-8\n\n" +
    '<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:wsa5="http://www.w3.org/2005/08/addressing" xmlns:tt="http://www.onvif.org/ver10/schema" xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:tev="http://www.onvif.org/ver10/events/wsdl" xmlns:tns1="http://www.onvif.org/ver10/topics" xmlns:tnsvendor="http://www.vendor.com/2009/event/topics">
  <SOAP-ENV:Header>
    <wsa5:Action SOAP-ENV:mustUnderstand="true" >http://www.onvif.org/ver10/events/wsdl/PullPointSubscription/PullMessagesResponse</wsa5:Action>
  </SOAP-ENV:Header>
  <SOAP-ENV:Body>
    <tev:PullMessagesResponse>
      <tev:CurrentTime>2010-10-29T15:52:36Z</tev:CurrentTime>
      <tev:TerminationTime>2010-10-29T15:53:30Z</tev:TerminationTime>
      <wsnt:NotificationMessage>
        <wsnt:Topic Dialect="http://docs.oasis-open.org/wsn/t-1/TopicExpression/Simple">tns1:Device/tnsvendor:IO/VirtualPort</wsnt:Topic>
        <wsnt:ProducerReference>
          <wsa5:Address>uri://a1f48ac2-dc8b-11df-b255-00408c1836b2/ProducerReference</wsa5:Address>
        </wsnt:ProducerReference>
        <wsnt:Message>
          <tt:Message UtcTime="2010-10-29T15:52:30Z" PropertyOperation="Initialized">
            <tt:Source>
              <tt:SimpleItem Name="port" Value="0">
              </tt:SimpleItem>
            </tt:Source>
            <tt:Key/>
            <tt:Data>
              <tt:SimpleItem Name="state" Value="0">
              </tt:SimpleItem>
            </tt:Data>
          </tt:Message>
        </wsnt:Message>
      </wsnt:NotificationMessage>
    </tev:PullMessagesResponse>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>';

