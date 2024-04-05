<?xml version="1.0"?>
<!--
     Author: H. Buhrmester, 2020
             aker, 2020
     Filename: extract-revision-and-update-ids-w100.xsl

     This file selects updates by their Product Ids:
     Windows 10 = a3c2375d-0c8a-42f9-bce0-28333e198407
     [Windows 10, version 1903 and later = b3c75dc1-155f-4be4-b015-3f1a91758e52]
     Windows 10 LTSB = d2085b71-5f1f-43a9-880d-ed159016d5c6
     Windows Server 2016 = 569e8e8f-c6cd-42c8-92a3-efbb20a0f6f5
     Windows Server 2019 = f702a48c-919b-45d6-9aef-ca4248d50397
	 [Windows Server, version 1903 and later = 21210d67-50bc-4254-a695-281765e10665]
	 [Windows 10 GDR-DU = abc45868-0c9c-4bc0-a36d-03d54113baf4]

     It extracts the following fields:
     Field 1: Bundle RevisionId
     Field 2: UpdateId
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:__="http://schemas.microsoft.com/msus/2004/02/OfflineSync" version="1.0">
  <xsl:output omit-xml-declaration="yes" indent="no" method="text"/>
  <xsl:template match="/">
    <xsl:for-each select="__:OfflineSyncPackage/__:Updates/__:Update/__:Categories/__:Category[@Type='Product']">
      <xsl:if test="contains(@Id, 'a3c2375d-0c8a-42f9-bce0-28333e198407')
                 or contains(@Id, 'd2085b71-5f1f-43a9-880d-ed159016d5c6')
                 or contains(@Id, '569e8e8f-c6cd-42c8-92a3-efbb20a0f6f5')
                 or contains(@Id, 'f702a48c-919b-45d6-9aef-ca4248d50397')">
        <xsl:if test="../../@RevisionId != '' and ../../@UpdateId != ''">
          <xsl:text>#</xsl:text>
          <xsl:value-of select="../../@RevisionId"/>
          <xsl:text>#,</xsl:text>
          <xsl:value-of select="../../@UpdateId"/>
          <xsl:text>&#10;</xsl:text>
        </xsl:if>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
