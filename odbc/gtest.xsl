<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" indent="yes"/>
    111
    <!-- 根模板 -->
    <xsl:template match="/">
        <html>
            <head>
                <style>
                    body {
                        font-family: Arial, sans-serif;
                    }
                    .gmisc_table {
                        width: 80%;
                        border-collapse: collapse;
                    }
                    .gmisc_table th, .gmisc_table td {
                        padding: 8px;
                        text-align: left;
                        border-bottom: 1px solid #ddd;
                        border: 1px solid black;
                    }
                    .gmisc_table tr:hover {
                        background-color: #f5f5f5;
                    }
                    .gmisc_table th {
                        background-color: #4CAF50;
                        color: white;
                    }
                .failed { color: red; font-weight: bold; }
                .passed { color: green; }
                </style>
            </head>
            <body>
                <table class='gmisc_table'>
                    <thead>
                        <tr>
                            <th>Test Suite</th>
                            <th>Case Name</th>
                            <th>Status</th>
                            <th>Time (ms)</th>
                            <th>Failure Message</th>
                        </tr>
                    </thead>
                    <tbody>
                        <!-- 遍历每个测试套件 -->
                        <xsl:for-each select="testsuites/testsuite">
                            <!-- 显示所有失败的测试用例 -->
                            <xsl:apply-templates select="testcase[failure]" mode="failed"/>
                        </xsl:for-each>
                    </tbody>
                    <tbody>
                        <!-- 遍历每个测试套件 -->
                        <xsl:for-each select="testsuites/testsuite">
                            <!-- 显示通过的测试用例 -->
                            <xsl:apply-templates select="testcase[not(failure)]" mode="passed"/>
                        </xsl:for-each>
                    </tbody>
                </table>
            </body>
        </html>
    </xsl:template>

    <!-- 模板用于处理单个测试用例 -->
    <xsl:template match="testcase" mode="failed">
        <tr class="failed">
            <td><xsl:value-of select="../@name"/></td>
            <td><xsl:value-of select="@name"/></td>
            <td><span class="failed">Failed</span></td>
            <td><xsl:value-of select="@time"/></td>
            <td>
<!--                <pre><xsl:value-of select="failure/@message"/></pre>-->
                <pre>
                    <xsl:call-template name="replace-line-breaks">
                        <xsl:with-param name="text" select="failure/@message"/>
                    </xsl:call-template>
                </pre>
            </td>
        </tr>
    </xsl:template>

    <xsl:template match="testcase" mode="passed">
        <tr class="passed">
            <td><xsl:value-of select="../@name"/></td>
            <td><xsl:value-of select="@name"/></td>
            <td><span class="passed">Passed</span></td>
            <td><xsl:value-of select="@time"/></td>
            <td></td>
        </tr>
    </xsl:template>

    <xsl:template name="replace-line-breaks">
        <xsl:param name="text"/>
        <xsl:choose>
            <xsl:when test="contains($text, '&#x0A;')">
                <xsl:value-of select="substring-before($text, '&#x0A;')"/>
                <br/>
                <xsl:call-template name="replace-line-breaks">
                    <xsl:with-param name="text" select="substring-after($text, '&#x0A;')"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
