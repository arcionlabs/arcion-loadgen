import subprocess
import shlex

def runbash(cmd:str): 
    process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    output, error = process.communicate()
    for l in output:
        print()

runbash("sysbench oltp_read_write --mysql-host=127.0.0.1 --auto_inc=off --db-driver=mysql --mysql-port=33061 --mysql-user=sbt --mysql-password=password --mysql-db=sbt --report-interval=1 --time=60 --threads=1 run")
