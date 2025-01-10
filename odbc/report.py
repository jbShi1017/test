from lxml import etree

# 加载XML和XSLT文件
xml_doc = etree.parse('output.xml')
xslt_doc = etree.parse('gtest.xsl')

# 创建一个XSLT对象并应用到XML文档上
transform = etree.XSLT(xslt_doc)
result_tree = transform(xml_doc)

# 将结果保存为HTML文件
with open('report.html', 'wb') as output_file:
    output_file.write(result_tree)
