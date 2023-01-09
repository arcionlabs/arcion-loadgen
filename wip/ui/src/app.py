import streamlit as st

st.set_page_config(
    page_title="Demo",
    page_icon="👋",
)

st.write("# Welcome to Arcion Demo! 👋")

st.sidebar.success("Select a demo above.")

st.markdown(
    """
    - create replication from [http://localhost:8080](http://localhost:8080)
    Follow [Arcion GUI docs](https://docs.arcion.io/docs/arcion-cloud-dashboard/quickstart/index.html).

    - run sysbench or YCSB to generate workload on source database

    - monitor the [Arcion replication status](https://docs.arcion.io/docs/arcion-cloud-dashboard/quickstart/index.html#monitoring-and-metrics-dashboard)
    """
)