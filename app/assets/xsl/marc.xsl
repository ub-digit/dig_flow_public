<?xml version='1.0' encoding='utf-8'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:template match="record">
<table border="1">
<tr>
<th NOWRAP="TRUE" ALIGN="RIGHT" VALIGN="TOP" colspan="3">000</th>
<td>
<xsl:value-of select="leader"/>
</td>
</tr>
<xsl:apply-templates select="datafield|controlfield"/>
</table>
</xsl:template>
<xsl:template match="controlfield">
<tr>
<th NOWRAP="TRUE" ALIGN="RIGHT" VALIGN="TOP" colspan="3">
<xsl:value-of select="@tag"/>
</th>
<td>
<xsl:value-of select="."/>
</td>
</tr>
</xsl:template>
<xsl:template match="datafield">
<tr>
<th NOWRAP="TRUE" ALIGN="RIGHT" VALIGN="TOP">
<xsl:value-of select="@tag"/>
</th>
<td><xsl:value-of select="@ind1"/></td>
<td><xsl:value-of select="@ind2"/></td>
<td style="word-break: break-word; word-wrap: break-word;">
<xsl:apply-templates select="subfield"/>
</td>
</tr>
</xsl:template>
<xsl:template match="subfield">
<strong>
|<xsl:value-of select="@code"/>&nbsp;</strong><xsl:value-of select="."/>
</xsl:template>
</xsl:stylesheet>
