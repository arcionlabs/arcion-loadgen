Test github action locally

# .secrets
```
rm .secrets
echo "SINGLESTORE=xxx" >> .secrets
echo "ARCION_LIC=$(cat licenses/arcion/replicant.lic | base64)" >> .secrets
```

# .input


# run 

act -W .github/workflows/gui-mys2.yaml
