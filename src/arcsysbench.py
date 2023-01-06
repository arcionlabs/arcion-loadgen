import streamlit as st
import docker
import shlex

client = docker.from_env()

sybench_tag="latest"

submit=st.button("submit")

if submit:
    st.write(client.containers.run(f"robertslee/sybench:{sybench_tag}",
        shlex.split("sysbench --help"),
        network="arcnet",
        remove=True,)    
    )      
    """
    st.write(client.containers.run(f"robertslee/sybench:{sybench_tag}",
        shlex.split("sysbench oltp_read_write --mysql-host=mysql1 --auto_inc=off --db-driver=mysql --mysql-user=sbt --mysql-password=password --mysql-db=sbt --report-interval=1 --time=60 --threads=1"),
        network="arcnet",
        remove=True,)    
    )                                                              
    """
