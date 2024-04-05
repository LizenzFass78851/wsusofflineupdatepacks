<?xml version="1.0"?>
<!-- Author: H. Buhrmester -->
<!-- Filename: extract-superseding-and-superseded-revision-ids.xsl -->
<!-- This file extracts the following fields: -->
<!-- Field 1: Superseding Bundle RevisionId (unverified; in rare cases this RevisionId may not exist) -->
<!-- Field 2: Superseded Bundle RevisionId -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:__="http://schemas.microsoft.com/msus/2004/02/OfflineSync" version="1.0">
  <xsl:output omit-xml-declaration="yes" indent="no" method="text" />
  <xsl:template match="/">
    <xsl:for-each select="__:OfflineSyncPackage/__:Updates/__:Update/__:SupersededBy/__:Revision">
      <xsl:if test="@Id != '' and ../../@RevisionId != ''">
        <xsl:text>#</xsl:text>
        <xsl:value-of select="@Id" />
        <xsl:text>#,#</xsl:text>
        <xsl:value-of select="../../@RevisionId" />
        <xsl:text>#</xsl:text>
        <xsl:text>&#10;</xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
