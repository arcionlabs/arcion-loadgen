

cat report.csv | psql $NEONURL -c "COPY runstat FROM STDIN DELIMITER ' ';"