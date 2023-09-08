# Initial Set-Up

In order to run the script, it requires a few repository secrets, namely your Docker username and password (or a Personal Access Token). You should set these under repository secrets as `DOCKER_USERNAME` and `DOCKER_PASSWORD`.

If you're looking to create a personal access token to use instead of your password, see [these](https://docs.docker.com/docker-hub/access-tokens/) instructions.

# Running the Action

The action is currently set to be run on `workflow_dispatch` and takes in six inputs: `REPLICANT_CLI_URL`, `ROW_VERIFICATOR_URL`, `IMAGE_TAG`, `CHECKOUT_CHOICE`, `RETRY`, and `RETRY_AGAIN`.

### `REPLICANT_CLI_URL`
The URL from which the replicant binary is downloaded. It defaults to https://arcion-releases.s3.us-west-1.amazonaws.com/general/replicant/replicant-cli-23.05.31.4.zip.

### `ROW_VERIFICATOR_URL`
The URL from which the row verificator binary is downloaded. It defaults to https://arcion-releases.s3.us-west-1.amazonaws.com/general/row-verificator/replicate-row-verificator-22.02.01.3.zip.

### `IMAGE_TAG`
The tag to apply to the docker image that is built and pushed. Defaults to `latest`.

### `CHECKOUT_CHOICE`
The branch, tag, or SHA which is applied to the checkout action. Use this to choose which branch the image is built from, or use a commit hash to get even more specific. Defaults to `main`.

## `RETRY` and `RETRY_AGAIN`
These allow you to retry the build-push action once or twice, in case of network issues during the first attempt. Currently there is no
delay before retrying, it may be a good idea to add a sleep for a minute or two.