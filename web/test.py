import dolphindb as ddb
import sys
TEST_BRANCH=sys.argv[1]
conn=ddb.Session("192.168.100.26",35603,"admin","123456")
conn.msg_logger.disable_stdout_sink()
x=conn.run(f"test('/root/web_auto_test/{TEST_BRANCH}/codes/testing/web_testing')")
print(x)
conn.close()
