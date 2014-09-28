<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/dictionary">
<html>
  <head>
    <title>
      <xsl:for-each select="direction[1]">
        <xsl:call-template name="direction-title"/>
      </xsl:for-each>
    </title>
    <link rel="stylesheet" type="text/css" href="/export/jbovlaste.css"/>
  </head>
  <body>
    <xsl:for-each select="direction[1]">
      <xsl:call-template name="valsi-direction"/>
    </xsl:for-each>
    <xsl:for-each select="direction[2]">
      <xsl:call-template name="nlword-direction"/>
    </xsl:for-each>
  </body>
</html>
</xsl:template>

<xsl:template name="direction-title">
  <xsl:value-of select="@to"/> - <xsl:value-of select="@from"/>
</xsl:template>

<xsl:template name="valsi-direction">
  <div class="valsi">
    <h1><xsl:call-template name="direction-title"/></h1>
    <dl>
      <xsl:apply-templates />
    </dl>
  </div>
</xsl:template>

<xsl:template name="nlword-direction">
  <div class="nlword">
    <h1><xsl:call-template name="direction-title"/></h1>
    <dl>
      <xsl:apply-templates />
    </dl>
  </div>
</xsl:template>

<xsl:template match="valsi">
  <dt><xsl:value-of select="@word"/></dt>
  <dd>
    <p><xsl:value-of select="definition"/></p>
    <xsl:call-template name="valsi-attributes"/>
  </dd>
</xsl:template>

<xsl:template name="valsi-attributes">
  <dl>
    <dt>type</dt>
    <dd><xsl:value-of select="@type"/></dd>
    <xsl:call-template name="rafsi-list"/>
    <xsl:apply-templates select="glossword"/>
    <xsl:apply-templates select="keyword"/>
    <xsl:apply-templates select="user"/>
  </dl>
</xsl:template>

<xsl:template name="rafsi-list">
  <xsl:if test="rafsi">
    <dt>rafsi</dt>
    <dd>
      <xsl:for-each select="rafsi">
        <xsl:value-of select="text()"/>
        <xsl:if test="position() != last()">
          <xsl:text>, </xsl:text>
        </xsl:if>
      </xsl:for-each>
    </dd>
  </xsl:if>
</xsl:template>

<xsl:template match="glossword">
  <dt>gloss word</dt>
  <dd><xsl:value-of select="@word"/></dd>
</xsl:template>

<xsl:template match="keyword">
  <dt>keyword <xsl:value-of select="@place"/></dt>
  <dd><xsl:value-of select="@word"/></dd>
</xsl:template>

<xsl:template match="user">
  <dt>user</dt>
  <dd><xsl:value-of select="realname"/></dd>
</xsl:template>

<xsl:template match="nlword">
  <dt><xsl:value-of select="@word"/></dt>
  <dd>
    <dl>
      <dt>valsi</dt>
      <dd><xsl:value-of select="@valsi"/></dd>
      <xsl:if test="@place">
        <dt>place</dt>
        <dd><xsl:value-of select="@place"/></dd>
      </xsl:if>
    </dl>
  </dd>
</xsl:template>

</xsl:stylesheet>
