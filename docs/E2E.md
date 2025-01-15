# This  document explains about the e2e configuration in Konflux.

#### Release Test Repo:
Release tests are executed from this repo
    https://github.com/openshift-pipelines/release-tests

#### Required Secrets:
To run the release tests we need to have below secrets in konflux tenant.

- <b> github </b> <br/> 
This Secret is required to access private repositories on Github. in absence of this tests related to private repos will fail.

```
    oc create secret generic github --from-literal=github-token=$GITHUB_TOKEN
```


* <b> quay-io-dockerconfig </b> <br/> 
This secret is used to access repos from quay.io/openshift-pipeline
```
    oc create secret generic quay-io-dockerconfig --from-literal=config.json=$QUAY_DOCKERCONFIG
```

