# Oracle Cloud Insights

An Oracle Cloud dashboarding tool that can be used to view dashboards and reports across all of your Oracle Cloud accounts.

**NOTE: This mod is a work in progress and may not work with your current Steampipe version**

## Getting started

### Installation

1) Download and install Steampipe (https://steampipe.io/downloads). Or use Brew:

```shell
brew tap turbot/tap
brew install steampipe

steampipe -v
steampipe version 0.13.0
```

2) Install the OCI plugin:

```shell
steampipe plugin install oci
```

3) Clone this repo:

```sh
git clone https://github.com/turbot/steampipe-mod-oci-insights.git
cd steampipe-mod-oci-insights
```

### Usage

Start your dashboard server to get started:

```shell
steampipe dashboard
```

## Contributing

If you have an idea for additional dashboards or reports, or just want to help maintain and extend this mod ([or others](https://github.com/topics/steampipe-mod)) we would love you to join the community and start contributing.

- **[Join our Slack community →](https://steampipe.io/community/join)** and hang out with other Mod developers.

Please see the [contribution guidelines](https://github.com/turbot/steampipe/blob/main/CONTRIBUTING.md) and our [code of conduct](https://github.com/turbot/steampipe/blob/main/CODE_OF_CONDUCT.md). All contributions are subject to the [Apache 2.0 open source license](https://github.com/turbot/steampipe-mod-oci-insights/blob/main/LICENSE).

`help wanted` issues:
- [Steampipe](https://github.com/turbot/steampipe/labels/help%20wanted)
- [Oracle Cloud Insights Mod](https://github.com/turbot/steampipe-mod-oci-insights/labels/help%20wanted)
