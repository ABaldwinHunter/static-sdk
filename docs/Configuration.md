# Configuration

Publication compilers need to be configured with tokens and deployment info.
This configuration goes in the package’s `package.json`, under the `"marquee"`
property. They also need an entrypoint specified, under `"main"`.

    ...
    "main": "./main.cjsx",
    "marquee": {
        "PUBLICATION_SHORT_NAME"    : "<short_name>",
        "CONTENT_API_TOKEN"         : "<read-only Content API token>",
        "CONTENT_API_HOST"          : "marquee.by",
        "AWS_BUCKET"                : "<example.com>",
        "AWS_ACCESS_KEY_ID"         : "<AWS Access Key ID>",
        "AWS_SECRET_ACCESS_KEY"     : "<AWS Secret Access Key>",
        "WEBHOOK_TOKEN"             : "<randomly generated string>",
        "HOST"                      : "<example.com>",
        "SITE_TITLE"                : "<Site Title>",
        "SITE_TWITTER_SCREEN_NAME"  : "<@screen_name>",
        "auto_assets"               : true,
        "manual_only"               : false
    }

* `PUBLICATION_SHORT_NAME` - the `short_name` of the publication on Marquee
* `CONTENT_API_TOKEN` - a _read-only_ Content API token for the publication
* `CONTENT_API_HOST` - the host of the Content API to use
* `AWS_BUCKET` - the S3 bucket to deploy the compiled publication to
* `AWS_ACCESS_KEY_ID` - an AWS Access Key ID with put object permission in the above bucket
* `AWS_SECRET_ACCESS_KEY` - the corresponding Secret Access Key
* `WEBHOOK_TOKEN` - the token that is required for the webhook service to activate the compiler when it receives a webhook
* `HOST` - the domain of the publication, typically the same as the bucket, used to generate full sharing links
* `SITE_TITLE` - the title of the publication, used in the `<title>` attribute
* `SITE_TWITTER_SCREEN_NAME` - the Twitter `screen_name` for the publication, used for Twitter Cards
* `auto_assets` - set to `false` to disable automatic asset compilation
* `manual_only` - set to `true` to disable automatic deploy by the Marquee hosting service

### Multiple Configurations

A project configuration MAY have a `configurations` option which defines
additional configuration to be enabled using the `--configuration` command
option. This allows for staging deploy and multitenant projects.

If a configuration is specified, it is merged with the general configuration,
overriding any matching key names.

    ...
    "marquee": {
        ...
        "configurations": {
            "<name>": {
                "AWS_BUCKET": "<alternate-bucket.tld>",
                "manual_only": true
            }
        }
    }

The `manual_only` option is useful in these configurations to avoid compiling
to staging on every deploy or content change.

## Entrypoint

The entrypoint specified by `"main"` is the module that is loaded by the SDK
and starts the compiler. It MAY be a `js`, `coffee`, `jsx`, or `cjsx` file,
MAY be named anything, and MAY be located anywhere in the project.

## Tokens

The `CONTENT_API_TOKEN` MUST be a read-only token, identifiable by the `r0_`
prefix. (The prefix has no actual bearing on the permissions. It is only a
label.) Read-only tokens are used to ensure that the static generator cannot
make any changs to content. The SDK will reject tokens that are read-write.

## Deployment

Static sites are deployed to [Amazon S3](http://aws.amazon.com/s3/). The
configuration needs these properties to do so: `AWS_BUCKET`,
`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`. The given key MUST have — and
SHOULD only have — `s3:PutObject` and `s3:PutObjectAcl` permissions on the
publication’s bucket.

The permissions can be managed on the
[IAM User control panel](https://console.aws.amazon.com/iam/home?#users). A
suitable user policy looks like this:

    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "Stmt1411849330000",
          "Effect": "Allow",
          "Action": [
            "s3:PutObject",
            "s3:PutObjectAcl"
          ],
          "Resource": [
            "arn:aws:s3:::shortname.marquee.pub/*"
          ]
        }
      ]
    }

### Bucket

The bucket MUST be configured as a [static site host](https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html). The Index Document MUST be set
to `index.html`, and the Error Document SHOULD be `404.html`. (The Error
Document MAY be named differently, provided the compiler emits the correct
file name.) Note: S3 requires that the bucket name and the site host name
ddmatch. A compiler MAY target multiple buckets, using [Multiple Configurations](./#multiple-configurations).