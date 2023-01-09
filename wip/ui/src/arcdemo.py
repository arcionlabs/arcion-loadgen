import streamlit as st

with st.expander("Docker Image Tags"):
    arcion_tag = st.text_input('ARCION_TAG', 'latest')
    mysql_tag = st.text_input('MYSQL_TAG', 'latest')
    postgres_tag = st.text_input('POSTGRES_TAG', 'latest')
    singlestore_tag = st.text_input('SINGLESTORE_TAG', 'latest')
    sybench_tag = st.text_input('SYBENCH_TAG', 'latest')

with st.expander("Docker Images"):
    arcion_img = st.text_input('ARCION_IMAGE', f'arcionlabs/replicant-on-premises')
    mysql_img = st.text_input('MYSQL_IMAGE', 'mysql')
    postgres_img = st.text_input('POSTGRES_IMAGE', 'postgres')
    singlestore_img = st.text_input('SINGLESTORE_IMAGE', 'singlestore/cluster-in-a-box')
    sybench_img = st.text_input('SYBENCH_IMAGE', 'robertslee/sybench')


submit=st.button("submit")

if submit:
    pull_images(client,
        [arcion_img,mysql_img,postgres_img,singlestore_img,sybench_img,],
        [arcion_tag,mysql_tag,postgres_tag,singlestore_tag,sybench_tag,],
        )