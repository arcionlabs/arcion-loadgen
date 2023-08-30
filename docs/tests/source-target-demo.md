# Initial Set-Up

First, as this uses storj.io as the artifact repository, you need to have an account, bucket, and access grant set up as
instructed in [storj docs](https://docs.storj.io/dcs/getting-started/quickstart-uplink-cli/uploading-your-first-object/create-first-access-grant). 

Now, when you create the access grant, you should have the ability to copy it or download it as a txt. Choose to copy it,
head to repository secrets, and add it as the body of a secret called `UPLINK_ACC`. If you want, you can also keep it
for your own records, as you can't see it again once you finish creating the access grant.

# Running the Action

The action is currently set to be run on `workflow_dispatch` and takes in four inputs: `SRC_DATABASES`, `DST_DATABASES`, `BUCKET_NAME`, and `COMMANDS`.

### `SRC_DATABASES`
A list of databases to be used as sources. This should be formatted as such: `["database_1", "database_2", "database_3"]`, where `database_#` is both the short name for the database and the name of the folder containing the docker compose file.
Defaults to `["mysql"]`.

### `DST_DATABASES`
A list of databases to be used as destinations. In conjunction with `SRC_DATABASES`, this input allows you to enumerate
all of the database combinations you would like to test. This should be formatted as such: 
`["database_1", "database_2", "database_3"]`, where `database_#` is both the short name for the database and the name 
of the folder containing the docker compose file. Defaults to `["pg"]`.

### `BUCKET_NAME`
The name of the bucket in storj to which the artifacts should be uploaded. Defaults to `artifact-data`.

### `COMMANDS`
A list of the commands to be run on the source and target databases. Usually starts with arcdemo.sh,
as we are running the demo on the databases. Does not work with options that have a space or newline in them (e.g. `command "path/to something/file"` doesn't work but `command path/to-something/file` does). Defaults to `["arcdemo.sh -r 0 snapshot", "arcdemo.sh -r 0 real-time", "arcdemo.sh -r 0 full" ]`.

### Notes:
> On a free plan, GitHub actions will only run at most [20 concurrent jobs](https://docs.github.com/en/actions/learn-github-actions/usage-limits-billing-and-administration#usage-limits), and a job matrix can assign at most [256 jobs](https://docs.github.com/en/actions/learn-github-actions/usage-limits-billing-and-administration#usage-limits). I have not tested running more than 20 because I don't want to go over the other limit of [2000 minutes per month](https://docs.github.com/en/billing/managing-billing-for-github-actions/about-billing-for-github-actions#included-storage-and-minutes), although this may be different for a public repository. The rates don't seem too expensive if you go over this, however it could get expensive fast if you have a lot of jobs running at once.

> In order to be careful of usage limits, the runtime on this job is limited to 30 minutes (see timeout-minutes under the job name). Otherwise, it's possible for it to pause for up to 6 hours before hitting the runtime limit.

