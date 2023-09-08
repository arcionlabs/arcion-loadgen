# Initial Set-Up
Set up your artifact repository however you want, and then adjust the `RCLONE_CONFIG` and `BUCKET_NAME` to correctly connect to it.
`MY_SECRET_NAME` is used as a workaround to scrub a private piece of information passed into the command `RCLONE_CONFIG`. NOTE: I do not know how reliable
this is in getting everything out of the log file. Be VERY careful. A more robust approach would see you editing the workflow itself to have a mostly hard coded rclone command where you pull an access key or password from secrets, rather than pasting it wholesale into the inputs and trusting that introducing a secret with the same access key or password will then scrub that from the log file's records of the inputs.
However, for the sake of allowing you to connect to almost any bucket/data hosting tool by just changing the `RCLONE_CONFIG` command, I've left this in. I strongly recommend changing it as soon you are settled on a provider. Please do not accidentally leak your password or access grant.

## If using storj
First, as this uses storj.io as the artifact repository, you need to have an account, bucket, and access grant set up as
instructed in [storj docs](https://docs.storj.io/dcs/getting-started/quickstart-uplink-cli/uploading-your-first-object/create-first-access-grant). 

Now, when you create the access grant, you should have the ability to copy it or download it as a txt. Choose to copy it,
head to repository secrets, and add it as the body of a secret called `UPLINK_ACC`. If you want, you can also keep it
for your own records, as you can't see it again once you finish creating the access grant.

# Running the Action

The action is currently set to be run on `workflow_dispatch` and takes in seven inputs: `SRC_DATABASES`, `DST_DATABASES`, `COMMANDS`,
`RCLONE_CONFIG`, `REMOTE_NAME`, `BUCKET_NAME`, and `MY_SECRET_NAME`.

### `SRC_DATABASES`
A list of databases to be used as sources. This should be formatted as such: `["database_1", "database_2", "database_3"]`, where `database_#` is both the short name for the database and the name of the folder containing the docker compose file.
Defaults to `["mysql"]`.

### `DST_DATABASES`
A list of databases to be used as destinations. In conjunction with `SRC_DATABASES`, this input allows you to enumerate
all of the database combinations you would like to test. This should be formatted as such: 
`["database_1", "database_2", "database_3"]`, where `database_#` is both the short name for the database and the name 
of the folder containing the docker compose file. Defaults to `["pg"]`.


### `COMMANDS`
A list of the commands to be run on the source and target databases. Usually starts with arcdemo.sh,
as we are running the demo on the databases. Does not work with options that have a space or newline in them (e.g. `command "path/to something/file"` doesn't work but `command path/to-something/file` does). Defaults to `["arcdemo.sh -r 0 snapshot", "arcdemo.sh -r 0 real-time", "arcdemo.sh -r 0 full" ]`.

### `RCLONE_CONFIG`
The rclone config command to run in order to set up your access. See [this](https://rclone.org/commands/rclone_config_create/) link
for more info on what the `rclone config create` command does. Different storage providers need different details supplied, hence why the whole command is an input. Defaults to `rclone config create myremote storj access_grant=*ACCESS GRANT HERE*`.

### `REMOTE_NAME`
The name of the remote access which rclone uses. It should match the name of the access created by `RCLONE_CONFIG`. Defaults to `myremote`.

### `BUCKET_NAME`
The name of the bucket to which the artifacts should be uploaded. Defaults to `artifact-data`.

### `MY_SECRET_NAME`
NOTE: This is the log scrubbing workaround of having to type out a private piece of info into the `RCLONE_CONFIG` command. I do not know how reliable it is.

The name of the github secret which contains a private piece of information you might be passing via the command line to `RCLONE_CONFIG`. For example, if you're passing a password in `RCLONE_CONFIG` like `password=P@55w0rd123`, you should create a github secret called `RCLONE_ACC_PASS` which contains `P@55w0rd123` and this input should be `RCLONE_ACC_PASS`, *not* the contents of the secret. Then, this secret can be introduced to the action and *should* be scrubbed from the log. Defaults to `UPLINK_ACC`.

### Notes:
> On a free plan, GitHub actions will only run at most [20 concurrent jobs](https://docs.github.com/en/actions/learn-github-actions/usage-limits-billing-and-administration#usage-limits), and a job matrix can assign at most [256 jobs](https://docs.github.com/en/actions/learn-github-actions/usage-limits-billing-and-administration#usage-limits). I have not tested running more than 20 because I don't want to go over the other limit of [2000 minutes per month](https://docs.github.com/en/billing/managing-billing-for-github-actions/about-billing-for-github-actions#included-storage-and-minutes), although this may be different for a public repository. The rates don't seem too expensive if you go over this, however it could get expensive fast if you have a lot of jobs running at once.

> In order to be careful of usage limits, the runtime on this job is limited to 30 minutes (see timeout-minutes under the job name). Otherwise, it's possible for it to pause for up to 6 hours before hitting the runtime limit.

