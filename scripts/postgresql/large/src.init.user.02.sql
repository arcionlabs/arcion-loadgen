
CREATE TABLE if not exists test_table_large (
    id INT8 NOT NULL,
    uid UUID NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    occured_at TIMESTAMP NULL,
    reason VARCHAR(8000) NULL,
    CONSTRAINT test_table_large_pkey PRIMARY KEY (id)
);

# insert into test_table_large (id,uid,created_at,updated_at,occured_at,reason) select *,gen_random_uuid(),now(),now(),now(),random() from generate_series(1,10000000);