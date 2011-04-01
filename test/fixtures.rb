RETS_ERROR = <<-XML
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

COMPACT = <<-XML
<?xml version="1.0"?>
<METADATA-RESOURCE Version="01.72.10306" Date="2011-03-15T19:51:22">
  <COLUMNS>A\tB</COLUMNS>
  <DATA>1\t2</DATA>
  <DATA>4\t5</DATA>
</METADATA>
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

