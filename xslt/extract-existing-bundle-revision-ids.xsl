<?xml version="1.0"?>
<!-- Author: H. Buhrmester -->
<!-- Filename: extract-existing-bundle-revision-ids.xsl -->
<!-- This file extracts the following fields: -->
<!-- Field 1: Existing Bundle RevisionId -->
<!-- Note: This is one of the simplest XSLT files and may serve as a template for other files. -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:__="http://schemas.microsoft.com/msus/2004/02/OfflineSync" version="1.0">
  <xsl:output omit-xml-declaration="yes" indent="no" method="text" />
  <xsl:template match="/">
    <xsl:for-each select="__:OfflineSyncPackage/__:Updates/__:Update[@IsBundle='true']">
      <xsl:if test="@RevisionId != ''">
        <xsl:text>#</xsl:text>
        <xsl:value-of select="@RevisionId" />
        <xsl:text>#</xsl:text>
        <xsl:text>&#10;</xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
