<?xml version="1.0"?>
<!--
     Author: H. Buhrmester, 2020
             aker, 2020
     Filename: extract-revision-and-update-ids-w63.xsl

     This file selects updates by their Product Ids:
     Windows 8.1 = 6407468e-edc7-4ecd-8c32-521f64cee65e
     Windows Server 2012 R2 = d31bd4c3-d872-41c9-a2e7-231f372588cb

     It extracts the following fields:
     Field 1: Bundle RevisionId
     Field 2: UpdateId
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:__="http://schemas.microsoft.com/msus/2004/02/OfflineSync" version="1.0">
  <xsl:output omit-xml-declaration="yes" indent="no" method="text"/>
  <xsl:template match="/">
    <xsl:for-each select="__:OfflineSyncPackage/__:Updates/__:Update/__:Categories/__:Category[@Type='Product']">
      <xsl:if test="contains(@Id, '6407468e-edc7-4ecd-8c32-521f64cee65e')
                 or contains(@Id, 'd31bd4c3-d872-41c9-a2e7-231f372588cb')">
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
