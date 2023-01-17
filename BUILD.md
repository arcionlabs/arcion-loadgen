Develop and demo by running GitHub Actions locally.
The same script is used in the cloud to scale.

# Directory Structure

- `.github/workflows/`
- `compose/`

# Run GitHub Action Locally

## Install Act
Install [`act`](https://github.com/nektos/act).
Must build from source in order to use `--input-file string`.

```
brew install act --HEAD
```

## Create .secrets file
Create `.secrets` file with GitHub Secrets. 
```
rm .secrets
echo "SINGLESTORE=xxx" >> .secrets
echo "ARCION_LICENSE=$(cat licenses/arcion/replicant.lic | base64)" >> .secrets
```

## Create .input file
Create `.input` file with [GitHub workflow_dispatch inputs](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#onworkflow_dispatchinputs).
```
ARCION_BIN_URL="https://arcion-releases.s3.us-west-1.amazonaws.com/general/replicant/replicant-cli-23.01.05.3.zip"
```

## Run preconfigured demos

These intentionally do not tear down the containers.

- Start the GUI
```
act -W .github/workflows/gui-mys2.yaml
```

- Start the CLI
```
act -W .github/workflows/cli-mymy.yaml
```

# Run in the cloud

TODO: public repo will be used to run in the cloud.  

# Tools

```
brew install yq
brew install act --HEAD
```