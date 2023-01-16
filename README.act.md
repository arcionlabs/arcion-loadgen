Test github action locally

# .secrets
```
rm .secrets
echo "SINGLESTORE=xxx" >> .secrets
echo "ARCION_LIC=$(cat licenses/arcion/replicant.lic | base64)" >> .secrets
```

# .input


# run 

act cli-mysql-mysql