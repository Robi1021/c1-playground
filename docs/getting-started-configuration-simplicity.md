# Getting Started Configuration

- [Getting Started Configuration](#getting-started-configuration)
  - [Configure](#configure)

## Configure

Typically you don't need to change anything here besides setting your api-key and region for Cloud One. If you intent to run multiple clusters (e.g. a local and a GKE), adapt the `cluster_name` and the `policy_name`.

```json
{
    "cluster_name": "playground",
    "services": [
...
        {
            "name": "container_security",
            "policy_name": "relaxed_playground",
            "namespace": "trendmicro-system"
        },
...
        {
            "name": "cloudone",
            "region": "YOUR CLOUD ONE REGION HERE",
            "instance": "cloudone",
            "api_key": "YOUR CLOUD ONE API KEY HERE"
        }
...
    ]
}
```

Other service sections you might want to adjust to your needs:

*Pipelining*

By default, the configuration is pointing to the Uploader example from my GitHub. If you want to use a different app change the three github values accordingly.

```json
{
    "cluster_name": "playground",
    "services": [
...
        {
            "name": "pipeline",
            "github_username": "mawinkler",
            "github_email": "winkler.info@icloud.com",
            "github_project": "c1-app-sec-uploader",
            "docker_username": "YOUR USERNAME HERE",
            "docker_password": "YOUR PASSWORD HERE",
            "appsec_key": "YOUR KEY HERE",
            "appsec_secret": "YOUR SECRET HERE"
        },
...
    ]
}
```
