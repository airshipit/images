# Helm Chart Collator

The Helm Chart Collator is used to create a Helm Chart Repository served from a Docker
image via Chartmuseum. It allows a developer to request charts to be pulled from various
locations and packaged into the resulting Docker image, which can then be used as a
portable Helm Repository.

## Setup

Charts can be sourced from various locations. Each entry must be recorded in a
user-defined file before building the image. When the list of charts has been created,
the `build-image.sh` script can be used to create the image via the command:

```
./build-image.sh $CHARTSFILE
```

### Charts from Helm Repos

To pull a chart a from pre-existing Helm Repos by listing them under the `helm_repos`
heading. Each listing must include the following:

* `repo`: The name of the Helm Repo to add (e.g. `stable`)
* `url`: The URL where the Helm Repo is hosted (e.g. `https://kubernetes-charts.storage.googleapis.com`)
* `name`: The name of the desired chart (e.g. `mariadb`)
* `version`: The version of the desired chart (e.g. `7.3.14`)


### Charts from Git Repos

A Chart can be pulled and packaged from a git repo by listing it under the `git_repos`
heading. Listings must include:

* `name`: The name of the repository (e.g. `openstack-helm`). Note that this is simply
  used for caching during the cloning process.
* `path`: The path to the desired chart within the repo (e.g. `keystone`)
* `url`: The URL where the git repo is hosted (e.g. `https://github.com/openstack/openstack-helm`)
* `sha`: The SHA-1 of the commit from which the chart should be pulled (e.g. `30c9f003d227b799c636458dea161e24d5823c33`). (default: `HEAD`).
* `refspec`: The refspec associated with the `sha`. This is only required if the `sha`
  can't be reached from the default (e.g. `refs/heads/master`)
* `chart_version`: The version to package the chart with (e.g. `1.2.3`)

If a chart in a git repo specifies dependencies which are not accessible, the
dependencies must also be listed under the `dependencies` heading. Dependencies have the
same fields as git repos.

### Charts from Tarballs

A chart can be downloaded by listing it under the `tarred_charts` header. They
require the following:

* `url`: The URL from which the chart can be downloaded

## Example

The following shows an example file for including various helm charts:
* rook-ceph as a tarball from a git repo
* mariadb from the helm stable repo
* rook-ceph from the rook repo
* prometheus from the helm/charts git repo
* keystone from the openstack-helm git repo
  * The helm-toolkit is also pulled, since it is a dependency of keystone

```
tarred_charts:
  - url: https://github.com/project-azorian/rook-ceph-aio/raw/master/rook-ceph-aio/charts/rook-ceph-0.0.1.tgz
helm_repos:
  - repo: stable
    url: https://kubernetes-charts.storage.googleapis.com
    name: mariadb
    version: 7.3.14
  - repo: rook-release
    url: https://charts.rook.io/release
    name: rook-ceph
    version: v1.3.6
git_repos:
  - name: helm-stable
    path: stable/prometheus
    url: https://github.com/helm/charts
    sha: 79066e1f0f5ce735aeb4783f2adf4b85992d15de
    # Note: refspec is only needed when if the given sha is not already available
    refspec: refs/heads/master
  - name: openstack-helm
    path: keystone
    url: https://github.com/openstack/openstack-helm
    sha: 30c9f003d227b799c636458dea161e24d5823c33
    chart_version: 1.2.3
    dependencies:
      - name: openstack-helm-infra
        path: helm-toolkit
        url: https://github.com/openstack/openstack-helm-infra
        sha: b1e66fd308b6bc9df090aebb5b3807a0df2d87dd
```

Once this file has been created, the image can be built with the following:

```
./build-image.sh charts.yaml
```
