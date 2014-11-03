<?xml version='1.0' encoding='utf-8'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:template match="/">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="manuscript">
    <table border="1">
      <xsl:apply-templates select="document|letter"/>
      <xsl:apply-templates select="archive"/>
    </table>
  </xsl:template>

  <xsl:template match="archive">
    <tr>
      <th colspan="2">Archive</th>
    </tr>
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="document">
    <tr>
      <th colspan="2">Document</th>
    </tr>
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="letter">
    <tr>
      <th colspan="2">Letter</th>
    </tr>
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="*">
    <tr>
      <td style="white-space: nowrap;">
	<xsl:for-each select="ancestor::*">
	  <xsl:text>_</xsl:text>
	</xsl:for-each>
      <xsl:value-of select="local-name(.)"/></td>
      <td>
	<xsl:if test="count(child::*) = 0">
	  <xsl:value-of select="."/>
	</xsl:if>
      </td>
    </tr>
    <xsl:if test="count(child::*) != 0">
      <xsl:apply-templates />
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
