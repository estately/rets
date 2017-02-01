RETS_NO_RECORDS_ERROR = <<-XML
<?xml version="1.0"?>
<RETS ReplyCode="20201" ReplyText="Error message">
</RETS>
XML

RETS_NO_OBJECT_ERROR = <<-XML
<?xml version="1.0"?>
<RETS ReplyCode="20403" ReplyText="Error message">
</RETS>
XML

RETS_INVALID_REQUEST_ERROR = <<-XML
<?xml version="1.0"?>
<RETS ReplyCode="123" ReplyText="Error message">
</RETS>
XML

RETS_REPLY = <<-XML
<?xml version="1.0"?>
<RETS ReplyCode="0" ReplyText="OK">
</RETS>
XML

CAPABILITIES = <<-XML
<RETS ReplyCode="0" ReplyText="OK">
  <RETS-RESPONSE>

    Abc=123
    Def=ghi=jk

  </RETS-RESPONSE>
</RETS>
XML

COUNT_ONLY = <<XML
<RETS ReplyCode="0" ReplyText="Success">
<COUNT Records="1234" />
</RETS>
XML

RETS_STATUS_NO_MATCHING_RECORDS = <<XML
<?xml version="1.0"?>
<RETS ReplyCode="0" ReplyText="Operation Successful">
<RETS-STATUS ReplyCode="20201" ReplyText="No matching records were found" />
</RETS>
XML

CAPABILITIES_WITH_WHITESPACE = <<XML
<RETS ReplyCode="0" ReplyText="Operation Successful">
<RETS-RESPONSE>
Action = /RETS/Action
</RETS-RESPONSE>
</RETS>
XML

# 44 is the ASCII code for comma; an invalid delimiter.
INVALID_DELIMETER = <<-XML
<?xml version="1.0"?>
<METADATA-RESOURCE Version="01.72.10306" Date="2011-03-15T19:51:22">
  <DELIMITER value="44" />
  <COLUMNS>A\tB</COLUMNS>
  <DATA>1\t2</DATA>
  <DATA>4\t5</DATA>
</METADATA>
XML

CHANGED_DELIMITER = <<-XML
<?xml version="1.0"?>
<METADATA-RESOURCE Version="01.72.10306" Date="2011-03-15T19:51:22">
  <DELIMITER value="45" />
  <COLUMNS>A-B</COLUMNS>
  <DATA>1-2</DATA>
  <DATA>4-5</DATA>
</METADATA>
XML

COMPACT = <<-XML
<?xml version="1.0"?>
<METADATA-RESOURCE Version="01.72.10306" Date="2011-03-15T19:51:22">
  <COLUMNS>A\tB</COLUMNS>
  <DATA>1\t2</DATA>
  <DATA>4\t5</DATA>
</METADATA>
XML


EMPTY_COMPACT = <<-XML
<METADATA-TABLE Resource="OpenHouse" Class="OpenHouse" Version="01.01.00000" Date="2011-07-29T12:09:16">
</METADATA-TABLE>
XML

METADATA_UNKNOWN = <<-XML
<?xml version="1.0"?>
<RETS ReplyCode="0" ReplyText="Operation successful.">
<METADATA-FOO Version="01.72.10306" Date="2011-03-15T19:51:22">
<UNKNOWN />
</METADATA-FOO>
XML

METADATA_SYSTEM = <<-XML
<?xml version="1.0"?>
<RETS ReplyCode="0" ReplyText="Operation successful.">
<METADATA-SYSTEM Version="01.72.10306" Date="2011-03-15T19:51:22">
<SYSTEM />
<COMMENTS />
</METADATA-SYSTEM>
XML

METADATA_RESOURCE = <<-XML
<?xml version="1.0"?>
<RETS ReplyCode="0" ReplyText="Operation successful.">
<METADATA-RESOURCE Version="01.72.10306" Date="2011-03-15T19:51:22">
<COLUMNS>	ResourceID	StandardName	VisibleName	Description	KeyField	ClassCount	ClassVersion	ClassDate	ObjectVersion	ObjectDate	SearchHelpVersion	SearchHelpDate	EditMaskVersion	EditMaskDate	LookupVersion	LookupDate	UpdateHelpVersion	UpdateHelpDate	ValidationExpressionVersion	ValidationExpressionDate	ValidationLookupVersionValidationLookupDate	ValidationExternalVersion	ValidationExternalDate	</COLUMNS>
<DATA>	ActiveAgent	ActiveAgent	Active Agent Search	Contains information about active agents.	MemberNumber	1	01.72.10304	2011-03-03T00:29:23	01.72.10000	2010-08-16T15:08:20	01.72.10305	2011-03-09T21:33:41			01.72.10284	2011-02-24T06:56:43		</DATA>
<DATA>	Agent	Agent	Agent Search	Contains information about all agents.	MemberNumber	1	01.72.10303	2011-03-03T00:29:23	01.72.10000	2010-08-16T15:08:20	01.72.10305	2011-03-09T21:33:41			01.72.10284	2011-02-24T06:56:43						</DATA>
<DATA>	History	History	History Search	Contains information about accumulated changes to each listing.	TransactionRid	1	01.72.10185	2010-12-02T02:02:58	01.72.10000	2010-08-16T15:08:20	01.72.10000	2010-08-16T22:08:30			01.72.10000	2010-08-16T15:08:20			</DATA>
<DATA>	MemberAssociation		Member Association	Contains MLS member Association information.	MemberAssociationKey	1	01.72.10277	2011-02-23T19:11:10			01.72.10214	2011-01-06T16:41:05	01.72.10220	2011-01-06T16:41:06						</DATA>
<DATA>	Office	Office	Office Search	Contains information about broker offices.	OfficeNumber	1	01.72.10302	2011-03-03T00:29:23	01.72.10000	2010-08-16T15:08:20	01.72.10305	2011-03-09T21:33:41		01.72.10284	2011-02-24T06:56:43						</DATA>
<DATA>	OfficeAssociation		Office Association	Contains MLS office Association information.	OfficeAssociationKey	1	01.72.10306	2011-03-15T19:51:22			01.72.10245	2011-01-06T16:41:08	01.72.10251	2011-01-06T16:41:08						</DATA>
<DATA>	OpenHouse	OpenHouse	Open House Search	Contains information about public open house activities.	OpenHouseRid	1	01.72.10185	2010-12-02T02:02:58	01.72.10000	2010-08-16T15:08:20	01.72.10134	2010-11-12T13:57:32			01.72.10000	2010-08-16T15:08:20									</DATA>
<DATA>	Property	Property	Property Search	Contains information about listed properties.	ListingRid	8	01.72.10288	2011-02-24T06:59:11	01.72.10000	2010-08-16T15:08:20	01.72.10289	2011-02-24T06:59:19			01.72.10290	2011-03-01T11:06:31			</DATA>
<DATA>	PropertyDeleted		Deleted Property Search	Contains information about deleted properties.	ListingRid	1	01.72.10185	2010-12-02T02:02:58	01.72.10000	2010-08-16T15:08:20	01.72.10000	2010-08-16T22:08:30			01.72.10000	2010-08-16T22:08:34			</DATA>
<DATA>	PropertyWithheld		Withheld Property Search	Contains information about withheld properties.	ListingRid	8	01.72.10201	2011-01-05T19:34:36	01.72.10000	2010-08-16T15:08:20	01.72.10200	2011-01-05T19:34:34			01.72.10000	2010-08-16T22:08:34	</DATA>
<DATA>	Prospect	Prospect	Prospect Search	Contains information about sales or listing propects.	ProspectRid	1	01.72.10185	2010-12-02T02:02:58	01.72.10000	2010-08-16T15:08:20	01.72.10000	2010-08-16T15:08:20			01.72.10000	2010-08-16T15:08:20		</DATA>
<DATA>	Tour	Tour	Tour Search	Contains information about private tour activities.	TourRid	1	01.72.10185	2010-12-02T02:02:58	01.72.10000	2010-08-16T15:08:20	01.72.10000	2010-08-16T22:08:30		01.72.10000	2010-08-16T15:08:20						</DATA>
<DATA>	VirtualMedia		Virtual Media	Contains information about virtual media for MLS listings.	VirtualMediaRid	1	01.72.10126	2010-11-12T13:47:41			01.72.10127	2010-11-12T13:47:41		01.72.10086	2010-11-10T09:59:11						</DATA>
</METADATA-RESOURCE>
</RETS>
XML

METADATA_OBJECT = "<RETS ReplyCode=\"0\" ReplyText=\"V2.6.0 728: Success\">\r\n<METADATA-OBJECT Resource=\"Property\" Version=\"1.12.24\" Date=\"Wed, 1 Dec 2010 00:00:00 GMT\">\r\n<COLUMNS>\tMetadataEntryID\tObjectType\tStandardName\tMimeType\tVisibleName\tDescription\tObjectTimeStamp\tObjectCount\t</COLUMNS>\r\n<DATA>\t50045650619\tMedium\tMedium\timage/jpeg\tMedium\tA 320 x 240 Size Photo\tLastPhotoDate\tTotalPhotoCount\t</DATA>\r\n<DATA>\t20101753230\tDocumentPDF\tDocumentPDF\tapplication/pdf\tDocumentPDF\tDocumentPDF\t\t\t</DATA>\r\n<DATA>\t50045650620\tPhoto\tPhoto\timage/jpeg\tPhoto\tA 640 x 480 Size Photo\tLastPhotoDate\tTotalPhotoCount\t</DATA>\r\n<DATA>\t50045650621\tThumbnail\tThumbnail\timage/jpeg\tThumbnail\tA 128 x 96 Size Photo\tLastPhotoDate\tTotalPhotoCount\t</DATA>\r\n</METADATA-OBJECT>\r\n</RETS>\r\n"

MULITPART_RESPONSE = [
  "--simple boundary",
  "Content-Type: image/jpeg",
  "Content-Length: 10",
  "Content-ID: 90020062739",
  "Object-ID: 1",
  "",
  "xxxxxxxx",
  "--simple boundary",
  "Content-Type: image/jpeg",
  "Content-Length: 10",
  "Content-ID: 90020062739",
  "Object-ID: 2",
  "",
  "yyyyyyyy",
  "--simple boundary",
  ""
].join("\r\n")

MULTIPART_RESPONSE_URLS = [
  '--rets.object.content.boundary.1330546052739',
  'Content-ID: 38845440',
  'Object-ID: 1',
  'Content-Type: text/xml',
  'Location: http://foobarmls.com/RETS//MediaDisplay/98/hr2890998-1.jpg',
  '',
  '<RETS ReplyCode="0" ReplyText="Operation Successful" />',
  '',
  '--rets.object.content.boundary.1330546052739',
  'Content-ID: 38845440',
  'Object-ID: 2',
  'Content-Type: text/xml',
  'Location: http://foobarmls.com/RETS//MediaDisplay/98/hr2890998-2.jpg',
  '',
  '<RETS ReplyCode="0" ReplyText="Operation Successful" />',
  '',
  '--rets.object.content.boundary.1330546052739',
  'Content-ID: 38845440',
  'Object-ID: 3',
  'Content-Type: text/xml',
  'Location: http://foobarmls.com/RETS//MediaDisplay/98/hr2890998-3.jpg',
  '',
  '<RETS ReplyCode="0" ReplyText="Operation Successful" />',
  '',
  '--rets.object.content.boundary.1330546052739',
  'Content-ID: 38845440',
  'Object-ID: 4',
  'Content-Type: text/xml',
  'Location: http://foobarmls.com/RETS//MediaDisplay/98/hr2890998-4.jpg',
  '',
  '<RETS ReplyCode="0" ReplyText="Operation Successful" />',
  '',
  '--rets.object.content.boundary.1330546052739',
  'Content-ID: 38845440',
  'Object-ID: 5',
  'Content-Type: text/xml',
  'Location: http://foobarmls.com/RETS//MediaDisplay/98/hr2890998-5.jpg',
  '',
  '<RETS ReplyCode="0" ReplyText="Operation Successful" />',
  '',
  '--rets.object.content.boundary.1330546052739--'
].join("\r\n")

SAMPLE_COMPACT = <<XML
<RETS ReplyCode="0" ReplyText="Operation successful.">
<METADATA-TABLE Resource="ActiveAgent" Class="MEMB" Version="01.72.10236" Date="2011-03-03T00:29:23">
<COLUMNS>	MetadataEntryID	SystemName	StandardName	LongName	DBName	ShortName	MaximumLength	DataType	Precision	Searchable	Interpretation	Alignment	UseSeparator	EditMaskID	LookupName	MaxSelect	Units	Index	Minimum	Maximum	Default	Required	SearchHelpID	Unique	ModTimeStamp	ForeignKeyName	ForeignField	InKeyindex	</COLUMNS>
<DATA>	7	City		City	City	City	11	Character	0	1		Left	0			0		0	0	0	0	0	City	0	0	1	MemberNumber	0	</DATA>
<DATA>	9	ContactAddlPhoneType1		Contact Additional Phone Type 1	AddlPhTyp1	Contact Addl Ph Type 1	1	Character	0	1	Lookup	Left	0		ContactAddlPhoneType	0		0	0	0	0	0	ContactAddlPhoneType	0	0	1	MemberNumber	0	</DATA>
<DATA>	11	ContactAddlPhoneType2		Contact Additional Phone Type 2	AddlPhTyp2	Contact Addl Ph Type 2	1	Character	0	1	Lookup	Left	0		ContactAddlPhoneType	0		0	0	0	0	0	ContactAddlPhoneType	0	0	1	MemberNumber	0	</DATA>
<DATA>	13	ContactAddlPhoneType3		Contact Additional Phone Type 3	AddlPhTyp3	Contact Addl Ph Type 3	1	Character	0	1	Lookup	Left	0		ContactAddlPhoneType	0		0	0	0	0	0	ContactAddlPhoneType	0	0	1	MemberNumber	0	</DATA>
<DATA>	15	ContactPhoneAreaCode1		Contact Phone Area Code 1	ContPhAC1	Contact Phone AC 1	3	Character	0	1		Left	0			0		0	0	0	0	0	ContactPhoneAreaCode	0	0	1	MemberNumber	0	</DATA>
<DATA>	17	ContactPhoneAreaCode2		Contact Phone Area Code 2	ContPhAC2	Contact Phone AC 2	3	Character	0	1		Left	0			0		0	0	0	0	0	ContactPhoneAreaCode	0	0	1	MemberNumber	0	</DATA>
<DATA>	19	ContactPhoneAreaCode3		Contact Phone Area Code 3	ContPhAC3	Contact Phone AC 3	3	Character	0	1		Left	0			0		0	0	0	0	0	ContactPhoneAreaCode	0	0	1	MemberNumber	0	</DATA>
</METADATA-TABLE>
</RETS>
XML

SAMPLE_COMPACT_2 = <<XML
<?xml version="1.0" encoding="utf-8"?>
<RETS ReplyCode="0" ReplyText="Success">
  <METADATA-TABLE Class="15" Date="2010-10-28T05:41:31Z" Resource="Office" Version="26.27.62891">
    <COLUMNS>	ModTimeStamp	MetadataEntryID	SystemName	StandardName	LongName	DBName	ShortName	MaximumLength	DataType	Precision	Searchable	Interpretation	Alignment	UseSeparator	EditMaskID	LookupName	MaxSelect	Units	Index	Minimum	Maximum	Default	Required	SearchHelpID	Unique	ForeignKeyName	ForeignField	InKeyIndex	</COLUMNS>
    <DATA>		sysid15	sysid		sysid	sysid	sysid	10	Int	0	1			0			0		1			0	0		1			1	</DATA>
    <DATA>		15n1155	OfficePhone_f1155	OfficePhone	Phone	Offic_1155	Phone	50	Character	0	1			0			0		0			0	0		0			0	</DATA>
    <DATA>		15n1158	AccessFlag_f1158		Office Status	Acces_1158	Status	50	Character	0	1			0			0		0			0	0		0			0	</DATA>
    <DATA>		15n1163	MODIFIED_f1163		Modified	MODIF_1163	Modified	20	DateTime	0	1			0			0		0			0	0		0			0	</DATA>
    <DATA>		15n1165	DESREALTOR_f1165		DesRealtor	DESRE_1165	DesRealtor	75	Character	0	1			0			0		0			0	0		0			0	</DATA>
    <DATA>		15n1166	DESREALTORUID_f1166		Designated Realtor Uid	DESRE_1166	RealtorUid	20	Character	0	1			0			0		0			0	0		0			0	</DATA>
    <DATA>		15n1167	INT_NO_f1167		Internet Syndication (Y/N)	INT_N_1167	Int.Syn.	1	Character	0	1	Lookup		0		YESNO	1		0			0	0		0			0	</DATA>
    <DATA>		15n1168	STATE_f1168		State	STATE_1168	State	50	Character	0	1	Lookup		0		1_523	1		0			0	0		0			0	</DATA>
    <DATA>		15n1169	CITY_f1169		City	CITY_1169	City	50	Character	0	1			0			0		0			0	0		0			0	</DATA>
    <DATA>		15n1170	IDX_NO_f1170		IDX (Y/N)	IDX_N_1170	IDX	1	Character	0	1			0			0		0			0	0		0			0	</DATA>
    <DATA>		15n1172	ZipCode_f1172		Zip	ZipCo_1172	Zip	50	Character	0	1			0			0		0			0	0		0			0	</DATA>
    <DATA>		15n1177	ADDRESS1_f1177		Address Line 1	ADDRE_1177	Address1	50	Character	0	1			0			0		0			0	0		0			0	</DATA>
    <DATA>		15n1182	MLSYN_f1182		MLS Y/N	MLSYN_1182	MLSYN	1	Character	0	1			0			0		0			0	0		0			0	</DATA>
    <DATA>		15n1184	OFFICENAME_f1184	Office Name	Office&#x2019;s Name	OFFIC_1184	Office Name	50	Character	0	1			0			0		0			0	0		0			0	</DATA>
    <DATA>		15n1193	OfficeCode_f1193	OfficeID	Office Code	Offic_1193	Office Code	12	Character	0	1			0			0		0			0	0		0			1	</DATA>
  </METADATA-TABLE>
</RETS>
XML

HTML_AUTH_FAILURE = <<EOF
<html><head><title>Apache Tomcat/6.0.26 - Error report</title><style><!--H1 {font-family:Tahoma,Arial,sans-serif;color:white;background-color:#525D76;font-size:22px;} H2 {font-family:Tahoma,Arial,sans-serif;color:white;background-color:#525D76;font-size:16px;} H3 {font-family:Tahoma,Arial,sans-serif;color:white;background-color:#525D76;font-size:14px;} BODY {font-family:Tahoma,Arial,sans-serif;color:black;background-color:white;} B {font-family:Tahoma,Arial,sans-serif;color:white;background-color:#525D76;} P {font-family:Tahoma,Arial,sans-serif;background:white;color:black;font-size:12px;}A {color : black;}A.name {color : black;}HR {color : #525D76;}--></style> </head><body><h1>HTTP Status 401 - </h1><HR size="1" noshade="noshade"><p><b>type</b> Status report</p><p><b>message</b> <u></u></p><p><b>description</b> <u>This request requires HTTP authentication ().</u></p><HR size="1" noshade="noshade"><h3>Apache Tomcat/6.0.26</h3></body></html>
EOF

XHTML_AUTH_FAILURE = <<EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>401 - Unauthorized: Access is denied due to invalid credentials.</title>
</head>
<body>
<h1>401 - Unauthorized: Access is denied due to invalid credentials.</h1>
<p>You do not have permission to view this directory or page using the credentials that you supplied.</p>
</body>
</html>
EOF

SAMPLE_COMPACT_WITH_SPECIAL_CHARS = <<EOF
<RETS ReplyCode=\"0\" ReplyText=\"Operation Success.\">
  <DELIMITER value=\"09\" />
  <COLUMNS>	PublicRemarksNew	WindowCoverings	YearBuilt	Zoning	ZoningCompatibleYN	</COLUMNS>
  <DATA>	porte-coch&amp;#xE8;re welcomes 		1999	00		</DATA>
</RETS>
EOF

SAMPLE_COMPACT_WITH_SPECIAL_CHARS_2 = <<EOF
<RETS ReplyCode=\"0\" ReplyText=\"Operation Success.\">
  <DELIMITER value=\"09\" />
  <COLUMNS>	PublicRemarksNew	WindowCoverings	YearBuilt	Zoning	ZoningCompatibleYN	</COLUMNS>
  <DATA>	text with &lt;tag&gt;		1999	00		</DATA>
</RETS>
EOF

SAMPLE_COMPACT_WITH_DOUBLY_ENCODED_BAD_CHARACTER_REFERENCES = <<EOF
<RETS ReplyCode=\"0\" ReplyText=\"Operation Success.\">
  <DELIMITER value=\"09\" />
  <COLUMNS>	PublicRemarksNew	WindowCoverings	YearBuilt	Zoning	ZoningCompatibleYN	</COLUMNS>
  <DATA>	foo &amp;#56324; bar		1999	00		</DATA>
</RETS>
EOF

SAMPLE_PROPERTY_WITH_LOTS_OF_COLUMNS = <<EOF
<RETS ReplyCode=\"0\" ReplyText=\"Operation Success.\">
  <DELIMITER value=\"09\" />
  <COLUMNS>\t#{800.times.map { |x| "K%03d" % x }.join("\t") }\t</COLUMNS>
  <DATA>\t\t</DATA>
</RETS>
EOF

EXAMPLE_METADATA_TREE = <<EOF
# Resource: Properties (Key Field: matrix_unique_key)
## Class: T100
    Visible Name: Prop
    Description : some description
### Table: L_1
      Resource: Properties
      ShortName: Sq
      LongName: Square Footage
      StandardName: Sqft
      Units: Meters
      Searchable: Y
      Required: N
### LookupTable: L_10
      Resource: Properties
      Required: N
      Searchable: Y
      Units: 
      ShortName: HF
      LongName: HOA Frequency
      StandardName: HOA F
####  Types:
        Quarterly -> Q
        Annually -> A
### MultiLookupTable: L_11
      Resource: Properties
      Required: N
      Searchable: Y
      Units: 
      ShortName: HFs
      LongName: HOA Frequencies
      StandardName: HOA Fs
      Types:
        Quarterly -> Q
        Annually -> A
  Object: HiRes
    Visible Name: Photo
    Mime Type: photo/jpg
    Description: photo description
EOF
